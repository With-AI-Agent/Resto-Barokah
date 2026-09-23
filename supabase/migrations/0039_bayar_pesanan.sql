-- ============================================================================
-- 0039 — RPC bayar_pesanan (T5-02, TECH_SPEC §5 M4 · ART-3 uang · ART-4 state)
--
-- Mengapa perlu (padahal tabel `pembayaran` sudah dijaga `picu_pembayaran_jujur`
-- di migrasi beku 0010): pagar 0010 menjaga BARIS uang, tetapi tidak ada satu
-- pintu pun yang (a) menolak dua pembayaran bersamaan yang jumlahnya kalau
-- dijumlah melebihi total, (b) memajukan status pesanan menjadi `lunas` tepat
-- saat total tertutup, dan (c) menulis jejak audit. Kasir yang menulis baris
-- langsung bisa mendapat tiga masalah itu sekaligus. RPC ini pintu tunggalnya.
--
-- Aturan yang dipegang (semua sudah ada di fondasi, tidak ada yang dilonggarkan):
--   * Angka uang pesanan HANYA dari `hitung_total` (0013/0014) — RPC ini tidak
--     pernah menulis kolom uang pesanan.
--   * Baris `pembayaran` hanya-tambah; koreksi lewat pembatalan berjejak.
--   * Setelah uang pertama tercatat, pesanan beku (0022/0024) — jadi status
--     `lunas` ditulis SEKALI di transaksi yang sama dengan pembayaran penutup.
--   * Jejak pelaku diisi sistem (auth.uid()), tidak bisa dikarang klien.
--   * Idempoten: kunci sama = satu pembayaran (ulangan tidak menambah uang,
--     tidak membuat baris kedua) — sama seperti `set_status_item` (0032).
--   * Kunci baris `for update` pada pesanan: dua kasir menekan bayar bersamaan
--     tidak bisa bersama-sama melewati batas total.
--   * Metode bayar dicari di RESTO PEMANGGIL dan pesanan di RESTO PESANAN: dua
--     UUID lintas penyewa selalu berujung "tidak ditemukan", tanpa membocorkan
--     pesanan mana yang benar-benar ada (pola `total_dibayar`, temuan AUD-3).
-- ============================================================================

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

  -- Pagar peran DITEGASKAN DI SINI, bukan diserahkan ke RLS: fungsi ini SECURITY
  -- DEFINER sehingga berjalan sebagai pemilik tabel dan RLS `pembayaran_tambah`
  -- TIDAK berlaku di dalamnya. Tanpa baris ini dapur/pelayan bisa mencatat uang
  -- lewat RPC padahal insert langsung mereka ditolak RLS (celah jalur pintas).
  if public.peran_saya() not in ('owner_pusat', 'admin_cabang', 'kasir') then
    raise exception 'Peran % tidak berwenang mencatat uang masuk.', coalesce(public.peran_saya(), '(kosong)');
  end if;

  if p_jumlah is null or p_jumlah <= 0 then
    raise exception 'Jumlah bayar harus lebih besar dari nol.';
  end if;

  -- Metode bayar milik RESTO PEMANGGIL (bukan milik resto pesanan): metode asing
  -- ditolak di sini, sebelum pesanan resto lain sempat tersentuh.
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

  -- Kunci baris pesanan DULU: tanpa ini dua transaksi serentak sama-sama
  -- menghitung total_dibayar yang lama dan keduanya lolos penjaga batas.
  select p.id, p.penyewa_id, p.status, p.total, p.shift_id
    into v_pesanan
    from public.pesanan p
   where p.id = p_pesanan_id
     and p.penyewa_id = v_penyewa
     for update;

  if v_pesanan.id is null then
    -- Pesan yang sama untuk "tidak ada" dan "milik resto lain" supaya keberadaan
    -- pesanan lintas penyewa tidak bisa ditebak.
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
    -- Kode BY-301 SENGAJA beda dari pesan pemicu 0010 yang serupa: dengan begitu uji
    -- bisa memastikan yang menolak adalah PINTU ini, bukan penjaga di lapisan bawah.
    raise exception 'BY-301: pembayaran % membuat total dibayar % melebihi total pesanan %.',
      p_jumlah, v_sudah + p_jumlah, v_total;
  end if;

  v_kunci := coalesce(nullif(btrim(p_kunci_idempoten), ''), 'bayar-' || gen_random_uuid()::text);

  -- Ulangan kunci yang sama (mis. tombol terkirim dua kali saat jaringan goyah):
  -- kembalikan pembayaran yang SUDAH ada, jangan tambah uang.
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

  -- Uang tertutup penuh → pesanan LUNAS + stempel waktu (ditulis di transaksi
  -- yang sama; sesudah ini pesanan beku bagi perangkat — 0017/0022/0024).
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
  'T5-02: pintu tunggal pencatatan uang masuk. Kunci baris pesanan (anti balap dua kasir), kembalian dihitung peladen, idempoten per kunci, memajukan pesanan ke lunas tepat saat total tertutup, dan menulis jejak audit berantai hash. Pagar baris uang tetap di picu_pembayaran_jujur (0010) — RPC ini tidak melonggarkannya.';

revoke all on function public.bayar_pesanan(uuid, uuid, integer, integer, text, text) from public, anon;
grant execute on function public.bayar_pesanan(uuid, uuid, integer, integer, text, text) to authenticated;
