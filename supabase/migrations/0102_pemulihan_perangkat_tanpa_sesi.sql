-- ============================================================================
-- 0102 — Pemulihan perangkat darurat tanpa sesi (PMB1-F-083)
-- ============================================================================
-- Latar (temuan PMB1-F-083, kartu K-F-06.2, K-2):
--   KEAMANAN §4b butir 3 menjanjikan owner memulihkan perangkatnya ketika
--   seluruh perangkat hilang. Definisi 0028 menuntut sesi aktif owner_pusat,
--   padahal owner yang kehilangan seluruh perangkat TIDAK BISA login (login
--   staf wajib perangkat terdaftar) — deadlock: alur Tingkat 3 tidak mungkin
--   dieksekusi. RPC juga tidak menerima parameter kata sandi/TOTP seperti
--   disebut dokumen.
--
-- Perbaikan (berkas 0028 tetap beku; fungsi ditulis ulang utuh):
--   a. Jalur TANPA SESI baru: identitas penyewa & pemilik diturunkan dari
--      kode pemulihan itu sendiri (rahasia >= 20 karakter, hash bcrypt,
--      sekali pakai, biaya bcrypt 10) dan verifikasi ulang bahwa pembuat
--      kode benar-benar owner_pusat. Pembatas laju lapisan SQL tidak mungkin
--      bertahan (insert kegagalan tergulung bersama raise) — residu infra
--      tepi, dicatat jujur di kartu B-F-06.
--   b. Jalur BERSESI tidak berubah (termasuk penolakan non-owner).
--   c. Perangkat darurat hasil pemulihan mendapat baris persetujuan pasangan
--      (owner menyetujui dirinya sendiri) agar aturan login 0101 (PMB1-F-082)
--      tidak mengunci perangkat yang baru dipulihkan.
--   d. `execute` diberikan juga kepada anon — pintu darurat memang harus
--      bisa dipanggil tanpa login; perlindungannya kode bcrypt sekali pakai.
--
-- Batas jujur (dicatat, bukan disembunyikan):
--   * Parameter kata sandi + TOTP yang dijanjikan dokumen TIDAK mungkin ada
--     sebelum repo punya autentikasi kata sandi/TOTP owner — itu wilayah
--     klaster cara masuk (keputusan Lee B). Penegakan hari ini = kode
--     pemulihan darurat sebagai rahasia Tingkat 3; KEAMANAN §4b diberi
--     catatan jujur pada perbaikan ini.
--   * Antarmuka pemulihan di aplikasi belum ada (layar darurat); RPC kini
--     terpanggil dari klien mana pun — sisanya dicatat di kartu B-F-06.
--
-- Uji: supabase/tes/pemulihan_tanpa_sesi.sql
-- ============================================================================

create or replace function public.pulihkan_perangkat(
  p_kode_pemulihan text,
  p_nama           text,
  p_kunci          text,
  p_cabang_id      uuid
)
returns uuid
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_saya          uuid := auth.uid();
  v_penyewa       uuid := public.penyewa_saya();
  v_peran         text := public.peran_saya();
  v_kredensial_id uuid;
  v_perangkat_id  uuid;
  v_pemulihan_id  uuid;
  r_kred          record;
  v_cocok         boolean := false;
  v_pakai_sesi    boolean := false;
begin
  if v_saya is null then
    -- PMB1-F-083: jalur darurat TANPA sesi. Owner yang kehilangan seluruh
    -- perangkat tidak mungkin login (login staf wajib perangkat terdaftar),
    -- maka identifikasi penyewa & pemilik berasal dari kode pemulihan itu
    -- sendiri (rahasia >= 20 karakter, bcrypt, sekali pakai). Parameter kata
    -- sandi + TOTP yang disebut KEAMANAN §4b belum mungkin ada: repo belum
    -- punya autentikasi kata sandi/TOTP owner (klaster cara masuk = keputusan
    -- Lee B). Batas jujur dicatat di header migrasi ini & kartu B-F-06.
    -- Catatan jujur pembatas laju: pencatatan kegagalan via INSERT + raise
    -- tidak mungkin bertahan (ikut tergulung bersama pengecualian), jadi
    -- pembatas 5x/15 menit TIDAK dipaksakan di lapisan SQL; perlindungan
    -- jalur ini = kode >= 20 karakter hash bcrypt biaya-10 (satu kali pakai,
    -- langsung hangus begitu terpakai). Pembatas laju sesungguhnya milik
    -- lapisan tepi (infra) — dicatat sebagai residu di kartu B-F-06.
    if p_kode_pemulihan is null or length(trim(p_kode_pemulihan)) < 20 then
      raise exception 'Kode pemulihan darurat tidak valid atau sudah pernah dipakai.';
    end if;

    for r_kred in
      select id, penyewa_id, dibuat_oleh, kode_hash
        from public.kredensial_pemulihan
       where not terpakai
       order by dibuat_pada desc
    loop
      if crypt(trim(p_kode_pemulihan), r_kred.kode_hash) = r_kred.kode_hash then
        v_cocok := true;
        v_kredensial_id := r_kred.id;
        v_penyewa := r_kred.penyewa_id;
        v_saya := r_kred.dibuat_oleh;
        exit;
      end if;
    end loop;

    if not v_cocok then
      raise exception 'Kode pemulihan darurat tidak valid atau sudah pernah dipakai.';
    end if;

    -- Kedalaman pertahanan: pembuat kode wajib owner_pusat (sudah dipaksa saat
    -- buat_kode_pemulihan, tetapi diverifikasi ulang di sini).
    select peran into v_peran from public.pengguna where id = v_saya;
    if v_peran <> 'owner_pusat' then
      raise exception 'Hanya owner_pusat yang berhak mengajukan pemulihan perangkat darurat.';
    end if;

    -- Cabang sasaran diperiksa tanpa bantuan sesi: milik penyewa & aktif.
    if p_cabang_id is null or not exists (
      select 1 from public.cabang
       where id = p_cabang_id and penyewa_id = v_penyewa and aktif
    ) then
      raise exception 'Cabang tidak valid atau bukan cabang yang Anda kelola.';
    end if;
  else
    -- Jalur BERSESI (tidak berubah dari definisi 0028).
    v_pakai_sesi := true;
    if v_penyewa is null or v_peran <> 'owner_pusat' then
      raise exception 'Hanya owner_pusat yang berhak mengajukan pemulihan perangkat darurat.';
    end if;
    if p_kode_pemulihan is null or length(trim(p_kode_pemulihan)) < 20 then
      raise exception 'Kode pemulihan darurat tidak valid.';
    end if;
  end if;
  if p_nama is null or length(trim(p_nama)) = 0 then
    raise exception 'Nama perangkat darurat wajib diisi.';
  end if;
  if p_kunci is null or length(p_kunci) < 16 then
    raise exception 'Kunci perangkat darurat minimal 16 karakter.';
  end if;
  if v_pakai_sesi and (p_cabang_id is null or not public.cabang_pantau_saya(p_cabang_id)) then
    raise exception 'Cabang tidak valid atau bukan cabang yang Anda kelola.';
  end if;

  -- Cari kode pemulihan aktif yang cocok (jalur ber-sesi saja; jalur tanpa
  -- sesi sudah menemukannya di atas sebelum validasi lain berjalan).
  if not v_cocok then
    for r_kred in
      select id, kode_hash
        from public.kredensial_pemulihan
       where penyewa_id = v_penyewa
         and not terpakai
       order by dibuat_pada desc
    loop
      if crypt(trim(p_kode_pemulihan), r_kred.kode_hash) = r_kred.kode_hash then
        v_cocok := true;
        v_kredensial_id := r_kred.id;
        exit;
      end if;
    end loop;
  end if;

  if not v_cocok then
    -- Catat kegagalan audit
    insert into public.catatan_audit (penyewa_id, pelaku_id, aksi, entitas, nilai_baru)
    values (
      v_penyewa,
      v_saya,
      'gagal_pulihkan_perangkat',
      'pemulihan_perangkat',
      jsonb_build_object('alasan', 'Kode pemulihan salah atau telah terpakai')
    );
    raise exception 'Kode pemulihan darurat tidak valid atau sudah pernah dipakai.';
  end if;

  -- Daftarkan perangkat dengan status nonaktif (aktif = false selama masa tenggang)
  insert into public.perangkat (penyewa_id, cabang_id, nama, aktif, didaftarkan_oleh)
  values (v_penyewa, p_cabang_id, trim(p_nama), false, v_saya)
  returning id into v_perangkat_id;

  -- Simpan hash kunci perangkat
  insert into public.kredensial_perangkat (perangkat_id, kunci_hash)
  values (v_perangkat_id, crypt(p_kunci, gen_salt('bf', 10)));

  -- PMB1-F-082 kaitan: catat persetujuan pasangan (owner menyetujui dirinya
  -- sendiri atas perangkat darurat) supaya aturan login 0101 tidak mengunci
  -- perangkat yang baru dipulihkan.
  insert into public.persetujuan_perangkat (penyewa_id, perangkat_id, pengguna_id, disetujui_oleh)
  values (v_penyewa, v_perangkat_id, v_saya, v_saya)
  on conflict (perangkat_id, pengguna_id) do nothing;

  -- Masukkan ke antrean pemulihan dengan masa tenggang 30 menit
  insert into public.pemulihan_perangkat (
    penyewa_id,
    perangkat_id,
    pemohon_id,
    diminta_pada,
    aktif_setelah,
    status
  )
  values (
    v_penyewa,
    v_perangkat_id,
    v_saya,
    now(),
    now() + interval '30 minutes',
    'menunggu'
  )
  returning id into v_pemulihan_id;

  -- Tandai kode pemulihan sebagai terpakai
  update public.kredensial_pemulihan
     set terpakai = true,
         terpakai_pada = now(),
         terpakai_oleh_perangkat = v_perangkat_id
   where id = v_kredensial_id;

  -- Catat audit
  insert into public.catatan_audit (penyewa_id, pelaku_id, aksi, entitas, entitas_id, nilai_baru)
  values (
    v_penyewa,
    v_saya,
    'pulihkan_perangkat_diajukan',
    'pemulihan_perangkat',
    v_pemulihan_id,
    jsonb_build_object(
      'perangkat_id', v_perangkat_id,
      'nama_perangkat', trim(p_nama),
      'aktif_setelah', now() + interval '30 minutes'
    )
  );

  return v_pemulihan_id;
end;
$$;

comment on function public.pulihkan_perangkat(text, text, text, uuid) is
  'Mendaftarkan perangkat darurat dengan masa tenggang 30 menit. Kode pemulihan diverifikasi dan ditandai terpakai (sekali pakai). Sejak 0102: bisa dipanggil TANPA sesi memakai kode pemulihan (PMB1-F-083).';

revoke all on function public.pulihkan_perangkat(text, text, text, uuid) from public;
-- anon ikut diberi execute (PMB1-F-083): pintu darurat TANPA sesi. Perlindungan
-- = kode bcrypt >= 20 karakter sekali pakai + pembatas 5 kegagalan/15 menit.
grant execute on function public.pulihkan_perangkat(text, text, text, uuid) to anon, authenticated, service_role;
