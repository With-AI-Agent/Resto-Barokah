-- ============================================================================
-- 0084 — Pegawai Berhenti: Cabut Akses Cepat & Serah Terima (T10-12)
--
-- Referensi:
--   - PRD M3 & M12: Kasus pegawai keluar / resign -> owner/admin menekan satu tombol
--     "Pegawai Berhenti" untuk mencabut akses seketika secara atomik, tanpa
--     merusak atau menghapus riwayat transaksi masa lalu (pesanan, kasir, laporan).
--   - TECH_SPEC §9 ART-2 (Role & Permission) & Aturan Bisnis 11:
--     "Menonaktifkan, bukan menghapus — data finansial dan jejak audit kekal."
--   - Catatan ROADMAP T10-12 (T-013):
--     Penutup shift kasir terbuka staf yang berhenti = Admin Cabang;
--     bila yang berhenti Admin Cabang = Owner Pusat.
--
-- Solusi yang disediakan migrasi ini:
--   1. Penambahan kolom pada `public.shift_kas`:
--      - `perlu_tutup_atasan boolean not null default false`
--      - `catatan_serah_terima text`
--      - `ditutup_oleh_atasan boolean not null default false`
--   2. RPC `public.pegawai_berhenti(p_pengguna_id uuid, p_alasan text, p_catatan_serah_terima text)`:
--      - Nonaktifkan akun pegawai (soft-disable: aktif = false di pengguna & pengguna_cabang).
--      - Cabut SELURUH sesi perangkat aktif seketika (sesi_perangkat & sesi_cabang).
--      - Hapus kredensial PIN di kredensial_pin.
--      - Periksa shift kasir terbuka miliknya: tandai `perlu_tutup_atasan = true`
--        agar atasan melakukan rekonsiliasi kas fisik di laci saat serah terima.
--      - Catat jejak audit kekal ke `public.catatan_audit`.
--   3. RPC `public.ambil_shift_perlu_tutup(p_cabang_id uuid)`:
--      - Mengambil daftar shift kasir menggantung yang wajib ditutup atasan.
--   4. Pembaruan RPC `public.tutup_shift`:
--      - Menyetel penanda `ditutup_oleh_atasan` dan membersihkan `perlu_tutup_atasan`.
-- ============================================================================

-- ---------------------------------------------------------------------------
-- 1. Penambahan Kolom pada shift_kas
-- ---------------------------------------------------------------------------
alter table public.shift_kas
  add column if not exists perlu_tutup_atasan boolean not null default false,
  add column if not exists catatan_serah_terima text,
  add column if not exists ditutup_oleh_atasan boolean not null default false;

comment on column public.shift_kas.perlu_tutup_atasan is
  'Menandai shift kasir yang dibuka oleh pegawai yang telah berhenti dan wajib ditutup oleh atasan saat serah terima kas (T10-12).';

comment on column public.shift_kas.catatan_serah_terima is
  'Catatan serah terima kas, inventaris, dan alasan pemberhentian pegawai pada shift kas (T10-12).';

comment on column public.shift_kas.ditutup_oleh_atasan is
  'Menandai apakah shift kas ditutup oleh atasan/orang lain selain pembuka shift (T10-12 / T-013).';

-- ---------------------------------------------------------------------------
-- 2. RPC public.pegawai_berhenti
-- ---------------------------------------------------------------------------
create or replace function public.pegawai_berhenti(
  p_pengguna_id          uuid,
  p_alasan               text default null,
  p_catatan_serah_terima text default null
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_penyewa            uuid;
  v_peran_saya         text;
  v_target             record;
  v_pelaku_nama        text;
  v_sesi_dicabut       integer := 0;
  v_pin_dihapus        integer := 0;
  v_ada_shift_terbuka  boolean := false;
  v_shift_terbuka_id   uuid := null;
  v_shift_terbuka      record;
  v_penutup_disarankan text;
  v_alasan_final       text;
begin
  -- 1. Autentikasi Pemanggil
  if auth.uid() is null then
    raise exception 'Anda harus masuk lebih dulu.';
  end if;

  v_penyewa := public.penyewa_saya();
  if v_penyewa is null then
    raise exception 'Penyewa tidak ditemukan atau sesi tidak sah.';
  end if;

  -- 2. Otorisasi Pemanggil (Owner Pusat atau Pemegang Izin kelola_pegawai)
  v_peran_saya := coalesce(public.peran_saya(), '');
  if v_peran_saya <> 'owner_pusat' and not public.boleh('kelola_pegawai') then
    raise exception 'Hanya owner pusat atau pemegang izin kelola_pegawai yang dapat mencabut akses pegawai.';
  end if;

  -- 3. Cegah Mencabut Diri Sendiri Lewat Alur Pegawai Berhenti
  if p_pengguna_id = auth.uid() then
    raise exception 'Anda tidak dapat mencabut akses akun Anda sendiri melalui alur pegawai berhenti.';
  end if;

  -- 4. Kunci dan Baca Data Target Pegawai
  select id, penyewa_id, nama, email, peran, aktif
    into v_target
    from public.pengguna
   where id = p_pengguna_id
     and penyewa_id = v_penyewa
   for update;

  if v_target.id is null then
    raise exception 'Pegawai tidak ditemukan atau bukan bagian dari restoran Anda.';
  end if;

  -- Baca nama pelaku untuk jejak serah terima
  select coalesce(nama, 'Atasan') into v_pelaku_nama
    from public.pengguna
   where id = auth.uid();

  -- 5. Pagar Hierarki & Keberlanjutan Restoran
  -- Pagar hierarki: Admin cabang / staf dilarang memberhentikan owner_pusat
  if v_target.peran = 'owner_pusat' and v_peran_saya <> 'owner_pusat' then
    raise exception 'Hanya sesama owner pusat yang dapat memberhentikan owner pusat.';
  end if;

  -- Pagar: Tidak boleh memberhentikan satu-satunya owner pusat aktif di resto
  if v_target.peran = 'owner_pusat' then
    if (
      select count(*)
        from public.pengguna
       where penyewa_id = v_penyewa
         and peran = 'owner_pusat'
         and aktif = true
         and id <> p_pengguna_id
    ) = 0 then
      raise exception 'Restoran minimal harus memiliki satu owner pusat yang aktif.';
    end if;
  end if;

  v_alasan_final := coalesce(nullif(btrim(p_alasan), ''), 'Pegawai berhenti / cabut akses cepat & serah terima');

  -- 6. Operasi Atomik 1: Nonaktifkan Akun Pengguna (Soft-Disable — ART-2)
  update public.pengguna
     set aktif = false
   where id = p_pengguna_id;

  update public.pengguna_cabang
     set aktif = false
   where pengguna_id = p_pengguna_id;

  -- 7. Operasi Atomik 2: Cabut Seluruh Sesi Perangkat & Cabang Seketika (T10-06)
  update public.sesi_perangkat
     set status = 'dicabut',
         diperbarui_pada = now()
   where penyewa_id = v_penyewa
     and pengguna_id = p_pengguna_id
     and status = 'aktif';
  get diagnostics v_sesi_dicabut = row_count;

  delete from public.sesi_cabang
   where pengguna_id = p_pengguna_id;

  -- 8. Operasi Atomik 3: Hapus Kredensial PIN
  delete from public.kredensial_pin
   where pengguna_id = p_pengguna_id;
  get diagnostics v_pin_dihapus = row_count;

  -- 9. Operasi Atomik 4: Tangani Shift Kasir Terbuka Milik Pegawai
  -- Bila pegawai memiliki shift kasir yang masih 'terbuka', tandai untuk serah terima & penutupan oleh atasan.
  -- Kas fisik tidak ditutup otomatis dengan angka fiktif karena uang di laci kas wajib dihitung riil saat serah terima.
  select id, cabang_id, modal_awal, dibuka_pada
    into v_shift_terbuka
    from public.shift_kas
   where penyewa_id = v_penyewa
     and dibuka_oleh = p_pengguna_id
     and status = 'terbuka'
   order by dibuka_pada desc
   limit 1
   for update;

  if v_shift_terbuka.id is not null then
    v_ada_shift_terbuka := true;
    v_shift_terbuka_id  := v_shift_terbuka.id;

    -- Tentukan atasan penutup shift sesuai catatan T-013:
    -- Bila yang berhenti Admin Cabang -> Owner Pusat;
    -- Staf kasir / peran lain -> Admin Cabang atau Owner Pusat.
    if v_target.peran = 'admin_cabang' then
      v_penutup_disarankan := 'Owner Pusat';
    else
      v_penutup_disarankan := 'Admin Cabang atau Owner Pusat';
    end if;

    update public.shift_kas
       set perlu_tutup_atasan = true,
           catatan_serah_terima = concat_ws(
             ' | ',
             format('Pegawai berhenti (%s). Shift wajib ditutup oleh %s setelah rekonsiliasi kas fisik.', v_target.nama, v_penutup_disarankan),
             format('Dicabut oleh %s pada %s. Alasan: %s.', v_pelaku_nama, to_char(now() at time zone 'Asia/Jakarta', 'YYYY-MM-DD HH24:MI:SS "WIB"'), v_alasan_final),
             nullif(btrim(coalesce(p_catatan_serah_terima, '')), '')
           )
     where id = v_shift_terbuka.id;
  end if;

  -- 10. Operasi Atomik 5: Jejak Audit Kekal di public.catatan_audit
  insert into public.catatan_audit (
    penyewa_id,
    pelaku_id,
    aksi,
    entitas,
    entitas_id,
    nilai_lama,
    nilai_baru
  ) values (
    v_penyewa,
    auth.uid(),
    'pegawai_berhenti',
    'pengguna',
    p_pengguna_id,
    jsonb_build_object(
      'aktif', v_target.aktif,
      'peran', v_target.peran,
      'nama', v_target.nama,
      'email', v_target.email
    ),
    jsonb_build_object(
      'aktif', false,
      'alasan', v_alasan_final,
      'catatan_serah_terima', p_catatan_serah_terima,
      'sesi_dicabut', v_sesi_dicabut,
      'pin_dihapus', (v_pin_dihapus > 0),
      'ada_shift_terbuka', v_ada_shift_terbuka,
      'shift_terbuka_id', v_shift_terbuka_id,
      'penutup_disarankan', v_penutup_disarankan
    )
  );

  return jsonb_build_object(
    'berhasil', true,
    'kode', 'PEGAWAI_BERHENTI_SUKSES',
    'pesan', format('Akses pegawai "%s" berhasil dicabut seketika dan serah terima dicatat.', v_target.nama),
    'data', jsonb_build_object(
      'pengguna_id', p_pengguna_id,
      'nama', v_target.nama,
      'email', v_target.email,
      'peran', v_target.peran,
      'aktif', false,
      'sesi_dicabut', v_sesi_dicabut,
      'pin_dihapus', (v_pin_dihapus > 0),
      'ada_shift_terbuka', v_ada_shift_terbuka,
      'shift_terbuka_id', v_shift_terbuka_id,
      'penutup_disarankan', v_penutup_disarankan
    )
  );
end;
$$;

comment on function public.pegawai_berhenti(uuid, text, text) is
  'Mencabut seluruh akses pegawai yang berhenti secara atomik: soft-disable akun, putus sesi, hapus PIN, tandai serah terima shift kas, dan jaga integritas audit (T10-12 / ART-2).';

revoke all on function public.pegawai_berhenti(uuid, text, text) from public;
grant execute on function public.pegawai_berhenti(uuid, text, text) to authenticated, service_role;

-- ---------------------------------------------------------------------------
-- 3. RPC public.ambil_shift_perlu_tutup
-- ---------------------------------------------------------------------------
create or replace function public.ambil_shift_perlu_tutup(
  p_cabang_id uuid default null
)
returns table (
  shift_id              uuid,
  cabang_id             uuid,
  nama_cabang           text,
  dibuka_oleh           uuid,
  nama_kasir            text,
  peran_kasir           text,
  dibuka_pada           timestamptz,
  modal_awal            integer,
  tunai_masuk           bigint,
  uang_seharusnya       integer,
  perlu_tutup_atasan    boolean,
  catatan_serah_terima  text
)
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
  v_penyewa uuid;
begin
  if auth.uid() is null then
    raise exception 'Anda harus masuk dulu.';
  end if;

  v_penyewa := public.penyewa_saya();
  if v_penyewa is null then
    raise exception 'Penyewa tidak ditemukan.';
  end if;

  -- Wajib berizin kelola_pegawai, tutup_kas, atau lihat_laporan
  if not (
    public.boleh('kelola_pegawai') or
    public.boleh('tutup_kas') or
    public.boleh('lihat_laporan')
  ) then
    raise exception 'Anda tidak berwenang melihat daftar shift serah terima atasan.';
  end if;

  return query
  select
    s.id as shift_id,
    s.cabang_id,
    c.nama as nama_cabang,
    s.dibuka_oleh,
    coalesce(u.nama, 'Pegawai Nonaktif') as nama_kasir,
    coalesce(u.peran, 'kasir') as peran_kasir,
    s.dibuka_pada,
    s.modal_awal,
    coalesce((
      select sum(pb.jumlah)
        from public.pembayaran pb
       where pb.shift_id = s.id
         and pb.jenis_saat_itu = 'tunai'
    ), 0)::bigint as tunai_masuk,
    greatest(
      0,
      s.modal_awal + coalesce((
        select sum(pb.jumlah)
          from public.pembayaran pb
         where pb.shift_id = s.id
           and pb.jenis_saat_itu = 'tunai'
      ), 0)
    )::integer as uang_seharusnya,
    s.perlu_tutup_atasan,
    s.catatan_serah_terima
  from public.shift_kas s
  join public.cabang c on c.id = s.cabang_id
  left join public.pengguna u on u.id = s.dibuka_oleh
  where s.penyewa_id = v_penyewa
    and s.status = 'terbuka'
    and s.perlu_tutup_atasan = true
    and (p_cabang_id is null or s.cabang_id = p_cabang_id)
    and public.cabang_pantau_saya(s.cabang_id)
  order by s.dibuka_pada asc;
end;
$$;

comment on function public.ambil_shift_perlu_tutup(uuid) is
  'Mengembalikan daftar shift kasir menggantung yang perlu ditutup atasan saat serah terima kasir berhenti (T10-12).';

revoke all on function public.ambil_shift_perlu_tutup(uuid) from public;
grant execute on function public.ambil_shift_perlu_tutup(uuid) to authenticated, service_role;

-- ---------------------------------------------------------------------------
-- 4. Sinkronisasi public.tutup_shift dengan Penanda Atasan (T10-12 / T-013)
-- ---------------------------------------------------------------------------
create or replace function public.tutup_shift(
  p_uang_fisik      integer,
  p_alasan_selisih  text    default null,
  p_shift_id        uuid    default null,
  p_catatan         text    default null
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_penyewa               uuid;
  v_shift                 public.shift_kas%rowtype;
  v_penjualan_tunai       integer := 0;
  v_kas_masuk             integer := 0;
  v_kas_keluar            integer := 0;
  v_tunai_masuk           integer := 0;
  v_tunai_keluar          integer := 0;
  v_uang_seharusnya       integer;
  v_selisih               integer;
  v_alasan                text;
  v_hasil                 public.shift_kas%rowtype;
  v_melewati_tengah_malam boolean := false;
  v_ditutup_atasan        boolean := false;
begin
  if auth.uid() is null then
    raise exception 'Anda harus masuk dulu.';
  end if;

  v_penyewa := public.penyewa_saya();
  if v_penyewa is null then
    raise exception 'Anda belum terdaftar di resto mana pun.';
  end if;

  -- Validasi masukan uang fisik
  if p_uang_fisik is null or p_uang_fisik < 0 then
    raise exception 'Jumlah uang fisik wajib diisi dan tidak boleh negatif.';
  end if;

  -- Cari shift yang akan ditutup
  if p_shift_id is not null then
    select *
      into v_shift
      from public.shift_kas
     where id = p_shift_id
       and penyewa_id = v_penyewa
       for update;

    if v_shift.id is null then
      raise exception 'Shift kas tidak ditemukan.';
    end if;

    if v_shift.status <> 'terbuka' then
      raise exception 'Shift kas ini sudah ditutup sebelumnya.';
    end if;
  else
    -- Cari shift kasir aktif milik akun ini
    select *
      into v_shift
      from public.shift_kas
     where penyewa_id = v_penyewa
       and dibuka_oleh = auth.uid()
       and status = 'terbuka'
     order by dibuka_pada desc
     limit 1
     for update;

    -- Bila tidak ada shift yang dibuka sendiri, cari shift terbuka di cabang yang dipantau
    if v_shift.id is null then
      select *
        into v_shift
        from public.shift_kas
       where penyewa_id = v_penyewa
         and public.cabang_pantau_saya(cabang_id)
         and status = 'terbuka'
       order by dibuka_pada asc
       limit 1
       for update;
    end if;

    if v_shift.id is null then
      raise exception 'Tidak ada shift kas terbuka yang dapat ditutup.';
    end if;
  end if;

  -- Verifikasi izin tutup_kas di cabang shift bersangkutan
  if not public.boleh('tutup_kas', v_shift.cabang_id) then
    raise exception 'Peran % tidak berwenang menutup shift kas di cabang ini.', coalesce(public.peran_saya(), '(kosong)');
  end if;

  -- Deteksi apakah ditutup oleh atasan/orang lain (T10-12 / T-013)
  v_ditutup_atasan := (auth.uid() is distinct from v_shift.dibuka_oleh);

  -- Kaitkan pembayaran tunai belum terikat yang terjadi di cabang selama rentang shift
  update public.pembayaran
     set shift_id = v_shift.id
   where shift_id is null
     and pesanan_id in (select id from public.pesanan where cabang_id = v_shift.cabang_id and penyewa_id = v_penyewa)
     and waktu >= v_shift.dibuka_pada
     and waktu <= now();

  -- Hitung penerimaan tunai dari pembayaran pesanan
  select coalesce(sum(jumlah), 0)
    into v_penjualan_tunai
    from public.pembayaran
   where shift_id = v_shift.id
     and jenis_saat_itu = 'tunai';

  -- Perhitungkan kas_pergerakan:
  if to_regclass('public.kas_pergerakan') is not null then
    -- Uang masuk (tambahan modal)
    select coalesce(sum(jumlah), 0)
      into v_kas_masuk
      from public.kas_pergerakan
     where shift_id = v_shift.id
       and jenis = 'masuk';

    -- Uang keluar (belanja mendadak, kasbon) & setoran
    select coalesce(sum(jumlah), 0)
      into v_kas_keluar
      from public.kas_pergerakan
     where shift_id = v_shift.id
       and jenis in ('keluar', 'setoran');
  end if;

  v_tunai_masuk := v_penjualan_tunai + v_kas_masuk;
  v_tunai_keluar := v_kas_keluar;

  -- Hitung uang seharusnya: modal_awal + tunai_masuk - tunai_keluar
  v_uang_seharusnya := v_shift.modal_awal + v_tunai_masuk - v_tunai_keluar;
  if v_uang_seharusnya < 0 then
    v_uang_seharusnya := 0;
  end if;

  -- Hitung selisih: fisik - seharusnya
  v_selisih := p_uang_fisik - v_uang_seharusnya;

  -- Validasi alasan selisih (DoD T7-02: bila selisih -> alasan wajib)
  v_alasan := btrim(coalesce(p_alasan_selisih, ''));
  if v_selisih <> 0 and v_alasan = '' then
    raise exception 'Alasan selisih wajib diisi jika uang fisik berbeda dari uang seharusnya.';
  end if;

  if v_alasan = '' then
    v_alasan := null;
  end if;

  -- Evaluasi apakah shift melewati tengah malam di zona waktu lokal Asia/Jakarta (T7-05)
  if timezone('Asia/Jakarta', now())::date > timezone('Asia/Jakarta', v_shift.dibuka_pada)::date then
    v_melewati_tengah_malam := true;
  end if;

  -- Tutup shift kas dan sinkronisasi penanda atasan (T10-12)
  update public.shift_kas
     set status = 'ditutup',
         ditutup_oleh = auth.uid(),
         ditutup_pada = now(),
         uang_seharusnya = v_uang_seharusnya,
         uang_fisik = p_uang_fisik,
         selisih = v_selisih,
         alasan_selisih = v_alasan,
         ditutup_oleh_atasan = v_ditutup_atasan,
         perlu_tutup_atasan = false,
         melewati_tengah_malam = (v_shift.melewati_tengah_malam or v_melewati_tengah_malam),
         catatan = case
           when p_catatan is not null and btrim(p_catatan) <> '' then btrim(p_catatan)
           else catatan
         end
   where id = v_shift.id
  returning * into v_hasil;

  -- Jejak audit berantai kriptografis (ART-6 / T1-13 / T10-12)
  insert into public.catatan_audit (
    penyewa_id,
    pelaku_id,
    aksi,
    entitas,
    entitas_id,
    nilai_lama,
    nilai_baru
  )
  values (
    v_penyewa,
    auth.uid(),
    'tutup_shift',
    'shift_kas',
    v_hasil.id,
    jsonb_build_object(
      'status', 'terbuka',
      'modal_awal', v_shift.modal_awal,
      'perlu_tutup_atasan', v_shift.perlu_tutup_atasan
    ),
    jsonb_build_object(
      'shift_id', v_hasil.id,
      'status', 'ditutup',
      'ditutup_oleh', auth.uid(),
      'ditutup_pada', to_char(v_hasil.ditutup_pada at time zone 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS.US"Z"'),
      'ditutup_oleh_atasan', v_ditutup_atasan,
      'modal_awal', v_hasil.modal_awal,
      'penjualan_tunai', v_penjualan_tunai,
      'kas_masuk', v_kas_masuk,
      'kas_keluar', v_kas_keluar,
      'tunai_masuk', v_tunai_masuk,
      'tunai_keluar', v_tunai_keluar,
      'uang_seharusnya', v_hasil.uang_seharusnya,
      'uang_fisik', v_hasil.uang_fisik,
      'selisih', v_hasil.selisih,
      'alasan_selisih', v_hasil.alasan_selisih,
      'melewati_tengah_malam', v_hasil.melewati_tengah_malam,
      'catatan_serah_terima', v_hasil.catatan_serah_terima
    )
  );

  -- Jika shift melewati tengah malam, catat jejak audit khusus untuk laporan owner (T7-05)
  if v_melewati_tengah_malam or v_hasil.melewati_tengah_malam then
    insert into public.catatan_audit (
      penyewa_id,
      pelaku_id,
      aksi,
      entitas,
      entitas_id,
      nilai_lama,
      nilai_baru
    )
    values (
      v_penyewa,
      auth.uid(),
      'shift_melewati_tengah_malam',
      'shift_kas',
      v_hasil.id,
      null,
      jsonb_build_object(
        'shift_id', v_hasil.id,
        'cabang_id', v_hasil.cabang_id,
        'dibuka_pada', to_char(v_hasil.dibuka_pada at time zone 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS.US"Z"'),
        'ditutup_pada', to_char(v_hasil.ditutup_pada at time zone 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS.US"Z"'),
        'melewati_tengah_malam', true
      )
    );
  end if;

  return jsonb_build_object(
    'berhasil', true,
    'kode', 'SH-200',
    'pesan', case
      when v_ditutup_atasan then 'Shift kas berhasil ditutup oleh atasan saat serah terima.'
      else 'Shift kas berhasil ditutup.'
    end,
    'data', jsonb_build_object(
      'shift_id', v_hasil.id,
      'cabang_id', v_hasil.cabang_id,
      'dibuka_oleh', v_hasil.dibuka_oleh,
      'ditutup_oleh', v_hasil.ditutup_oleh,
      'ditutup_oleh_atasan', v_hasil.ditutup_oleh_atasan,
      'dibuka_pada', v_hasil.dibuka_pada,
      'ditutup_pada', v_hasil.ditutup_pada,
      'modal_awal', v_hasil.modal_awal,
      'penjualan_tunai', v_penjualan_tunai,
      'kas_masuk', v_kas_masuk,
      'kas_keluar', v_kas_keluar,
      'tunai_masuk', v_tunai_masuk,
      'tunai_keluar', v_tunai_keluar,
      'uang_seharusnya', v_hasil.uang_seharusnya,
      'uang_fisik', v_hasil.uang_fisik,
      'selisih', v_hasil.selisih,
      'alasan_selisih', v_hasil.alasan_selisih,
      'melewati_tengah_malam', v_hasil.melewati_tengah_malam,
      'status', v_hasil.status,
      'catatan', v_hasil.catatan,
      'catatan_serah_terima', v_hasil.catatan_serah_terima
    )
  );
end;
$$;

comment on function public.tutup_shift(integer, text, uuid, text) is
  'M7 / T10-12: Menutup sesi shift kasir dengan rekonsiliasi uang seharusnya vs fisik, selisih beralasan, penanda serah terima atasan, dan audit kriptografis.';

revoke all on function public.tutup_shift(integer, text, uuid, text) from public;
grant execute on function public.tutup_shift(integer, text, uuid, text) to authenticated, service_role;
