-- ============================================================================
-- MIGRASI 0060 — Jejak Audit Wajib & Integritas Status Pembayaran (M F-01)
--
-- Referensi:
--   - AUDIT_LAPORAN_audit_7ccbb132 M F-01: Baris pembayaran langsung tidak
--     memiliki pemicu catatan_audit, sehingga uang masuk tanpa jejak audit.
--   - docs/KEAMANAN.md §1 & §10: Setiap tindakan sensitif wajib meninggalkan jejak.
--
-- Solusi:
--   1. Tambahkan trigger AFTER INSERT pada public.pembayaran yang memastikan
--      setiap pembayaran (baik lewat RPC bayar_pesanan maupun insert langsung)
--      selalu tercatat di public.catatan_audit secara kekal.
--   2. Pada bayar_pesanan, pasang penanda sesi 'app.di_dalam_bayar_pesanan'
--      agar audit bayar_pesanan yang kaya rincian tidak terduplikasi.
--   3. Pada pembayaran langsung yang menutup total pesanan, sinkronkan
--      status pesanan menjadi 'lunas' sehingga total dibayar dan status pesanan
--      selalu konsisten.
-- ============================================================================

-- 1. Perbarui bayar_pesanan untuk memasang penanda transaksi
create or replace function public.bayar_pesanan(
  p_pesanan_id      uuid,
  p_metode_id       uuid,
  p_jumlah          integer,
  p_diterima        integer default null,
  p_referensi       text    default null,
  p_kunci_idempoten text    default null
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_penyewa   uuid;
  v_pesanan   record;
  v_metode    record;
  v_sudah     integer;
  v_kembalian integer;
  v_lama      record;
  v_baru      record;
  v_kunci     text;
  v_total     integer;
begin
  if auth.uid() is null then
    raise exception 'Anda harus masuk dulu.';
  end if;

  v_penyewa := public.penyewa_saya();
  if v_penyewa is null then
    raise exception 'Anda belum terdaftar di resto mana pun.';
  end if;

  if public.peran_saya() not in ('owner_pusat', 'admin_cabang', 'kasir') then
    raise exception 'Peran % tidak berwenang mencatat uang masuk.', coalesce(public.peran_saya(), '(kosong)');
  end if;

  if p_jumlah is null or p_jumlah <= 0 then
    raise exception 'Jumlah bayar harus lebih besar dari nol.';
  end if;

  select m.id, m.nama, m.jenis, m.aktif
    into v_metode
    from public.metode_bayar m
   where m.id = p_metode_id
     and m.penyewa_id = v_penyewa;

  if v_metode.id is null then
    raise exception 'Metode bayar itu tidak ada di resto ini.';
  end if;
  if not v_metode.aktif then
    raise exception 'Metode bayar "%" sedang tidak aktif.', v_metode.nama;
  end if;

  select p.id, p.penyewa_id, p.status, p.total, p.shift_id
    into v_pesanan
    from public.pesanan p
   where p.id = p_pesanan_id
     and p.penyewa_id = v_penyewa
     for update;

  if v_pesanan.id is null then
    raise exception 'Pesanan tidak ditemukan.';
  end if;

  if v_pesanan.status = 'batal' then
    raise exception 'Pesanan ini sudah dibatalkan — uang tidak boleh dicatat lagi.';
  end if;

  if coalesce(v_pesanan.total, 0) <= 0 then
    raise exception 'Total pesanan belum dihitung — pembayaran belum boleh dicatat.';
  end if;

  if v_metode.jenis = 'tunai' then
    if p_diterima is null then
      raise exception 'Pembayaran tunai wajib menyebut uang yang diterima.';
    end if;
    if p_diterima < p_jumlah then
      raise exception 'Uang diterima (%) lebih kecil dari jumlah bayar (%).', p_diterima, p_jumlah;
    end if;
    v_kembalian := p_diterima - p_jumlah;
  else
    if p_referensi is null or length(btrim(p_referensi)) = 0 then
      raise exception 'Pembayaran bukan tunai wajib menyebut nomor referensi.';
    end if;
    v_kembalian := null;
  end if;

  v_total := coalesce(v_pesanan.total, 0);
  v_sudah := public.total_dibayar(p_pesanan_id);
  if v_sudah + p_jumlah > v_total then
    raise exception 'BY-301: pembayaran % membuat total dibayar % melebihi total pesanan %.',
      p_jumlah, v_sudah + p_jumlah, v_total;
  end if;

  v_kunci := coalesce(nullif(btrim(p_kunci_idempoten), ''), 'bayar-' || gen_random_uuid()::text);

  select pb.id, pb.jumlah, pb.kembalian into v_lama
    from public.pembayaran pb
   where pb.pesanan_id = p_pesanan_id
     and pb.kunci_idempoten = v_kunci;

  if v_lama.id is not null then
    return jsonb_build_object(
      'berhasil',      true,
      'kode',          'BY-200',
      'pesan',         'Pembayaran dengan kunci ini sudah tercatat — tidak dicatat dua kali.',
      'pembayaran_id', v_lama.id,
      'jumlah',        v_lama.jumlah,
      'kembalian',     v_lama.kembalian,
      'total_dibayar', v_sudah,
      'total_pesanan', v_total,
      'lunas',         v_sudah >= v_total,
      'dobel',         true
    );
  end if;

  -- Pasang penanda sesi transaksi sebelum INSERT agar trigger audit mengenali jalur RPC
  perform set_config('app.di_dalam_bayar_pesanan', 'true', true);

  insert into public.pembayaran (
    pesanan_id, metode_id, jumlah, diterima, kembalian, referensi, kasir_id, shift_id, kunci_idempoten
  ) values (
    p_pesanan_id,
    v_metode.id,
    p_jumlah,
    case when v_metode.jenis = 'tunai' then p_diterima else null end,
    v_kembalian,
    case when v_metode.jenis = 'tunai' then null else btrim(p_referensi) end,
    auth.uid(),
    v_pesanan.shift_id,
    v_kunci
  )
  returning id, jumlah, kembalian into v_baru;

  if v_sudah + p_jumlah >= v_total and v_pesanan.status <> 'lunas' then
    update public.pesanan
       set status = 'lunas',
           dibayar_pada = coalesce(dibayar_pada, now())
     where id = p_pesanan_id;
  end if;

  insert into public.catatan_audit (penyewa_id, pelaku_id, aksi, entitas, entitas_id, nilai_lama, nilai_baru)
  values (
    v_penyewa,
    auth.uid(),
    'bayar_pesanan',
    'pembayaran',
    v_baru.id,
    jsonb_build_object('total_dibayar', v_sudah, 'status_pesanan', v_pesanan.status),
    jsonb_build_object(
      'pesanan_id',    p_pesanan_id,
      'metode',        v_metode.nama,
      'jenis',         v_metode.jenis,
      'jumlah',        v_baru.jumlah,
      'kembalian',     v_baru.kembalian,
      'total_dibayar', v_sudah + p_jumlah,
      'total_pesanan', v_total,
      'lunas',         v_sudah + p_jumlah >= v_total
    )
  );

  return jsonb_build_object(
    'berhasil',      true,
    'kode',          'BY-200',
    'pesan',         case
                       when v_sudah + p_jumlah >= v_total
                         then 'Pembayaran lunas tercatat.'
                       else 'Pembayaran sebagian tercatat.'
                     end,
    'pembayaran_id', v_baru.id,
    'jumlah',        v_baru.jumlah,
    'kembalian',     v_baru.kembalian,
    'total_dibayar', v_sudah + p_jumlah,
    'total_pesanan', v_total,
    'lunas',         v_sudah + p_jumlah >= v_total,
    'dobel',         false
  );
end
$$;

comment on function public.bayar_pesanan(uuid, uuid, integer, integer, text, text) is
  'T5-02: pintu tunggal pencatatan uang masuk. Kunci baris pesanan (anti balap dua kasir), kembalian dihitung peladen, idempoten per kunci, memajukan pesanan ke lunas tepat saat total tertutup, dan menulis jejak audit berantai hash.';

revoke all on function public.bayar_pesanan(uuid, uuid, integer, integer, text, text) from public, anon;
grant execute on function public.bayar_pesanan(uuid, uuid, integer, integer, text, text) to authenticated;

-- 2. Pemicu Audit Pembayaran Wajib (AFTER INSERT)
create or replace function public.picu_pembayaran_audit()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_penyewa uuid;
  v_total   integer;
  v_sudah   integer;
  v_status  text;
begin
  -- Jika dieksekusi di dalam RPC bayar_pesanan, lewati agar tidak dobel jejak
  if current_setting('app.di_dalam_bayar_pesanan', true) = 'true' then
    return new;
  end if;

  select p.penyewa_id, p.total, p.status
    into v_penyewa, v_total, v_status
    from public.pesanan p
   where p.id = new.pesanan_id;

  v_sudah := public.total_dibayar(new.pesanan_id);

  -- Bila pembayaran ini menutup total pesanan, sinkronkan status pesanan menjadi lunas
  if v_total > 0 and v_sudah >= v_total and v_status <> 'lunas' then
    update public.pesanan
       set status = 'lunas',
           dibayar_pada = coalesce(dibayar_pada, now())
     where id = new.pesanan_id;
  end if;

  insert into public.catatan_audit (
    penyewa_id, pelaku_id, aksi, entitas, entitas_id, nilai_baru
  ) values (
    v_penyewa,
    coalesce(new.kasir_id, auth.uid()),
    'pembayaran_langsung',
    'pembayaran',
    new.id,
    jsonb_build_object(
      'pesanan_id', new.pesanan_id,
      'metode_id', new.metode_id,
      'jumlah', new.jumlah,
      'diterima', new.diterima,
      'kembalian', new.kembalian,
      'shift_id', new.shift_id,
      'kunci_idempoten', new.kunci_idempoten,
      'total_dibayar', v_sudah,
      'total_pesanan', v_total,
      'lunas', v_sudah >= v_total
    )
  );

  return new;
end;
$$;

comment on function public.picu_pembayaran_audit() is
  'Memastikan seluruh baris pembayaran (termasuk direct insert) meninggalkan jejak audit kekal di catatan_audit (M F-01).';

revoke all on function public.picu_pembayaran_audit() from public, anon, authenticated;
grant execute on function public.picu_pembayaran_audit() to service_role;

drop trigger if exists pembayaran_audit on public.pembayaran;
create trigger pembayaran_audit
  after insert on public.pembayaran
  for each row execute function public.picu_pembayaran_audit();
