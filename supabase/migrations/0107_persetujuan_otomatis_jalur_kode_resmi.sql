-- ============================================================================
-- 0107 — Persetujuan otomatis untuk perangkat jalur pendaftaran resmi
--        (PMB1-F-233 · K-2 · KEPUTUSAN LEE 2026-10-09 "tambal RPC")
-- ============================================================================
-- Latar (temuan PMB1-F-233, kartu H-F-06.3 §D & H-P-1B-00; probe
-- bukti/H-F-06.3-probe-082.sql bagian D):
--   Jalur pendaftaran RESMI — owner menerbitkan kode sekali pakai lalu
--   perangkat didaftarkan lewat `daftarkan_perangkat_dengan_kode` (0030) —
--   TIDAK menulis baris persetujuan apa pun, sedangkan gerbang login 0101
--   (langkah 7b) menolak pasangan (pegawai x perangkat) tanpa baris
--   persetujuan. Satu-satunya penyetuju yang ada di repo (RPC
--   setujui_perangkat_pegawai) memiliki 0 pemanggil klien. Akibatnya setiap
--   perangkat yang lahir dari jalur resmi menjadi JALAN BUNTU: pegawai sah
--   dengan PIN benar pun selalu ditolak PERANGKAT_BELUM_DISETUJUI.
--
-- Kenapa persetujuan tidak ditulis langsung di RPC 0030:
--   Pendaftaran berjalan dari kursi anon TANPA identitas pengguna, sementara
--   baris persetujuan_perangkat bersifat per pasangan (perangkat x pengguna).
--   Tidak ada pengguna yang bisa ditunjuk saat pendaftaran.
--
-- Perbaikan (fungsi verifikasi_pin_perangkat ditulis ulang UTUH dari definisi
-- 0101; satu sisipan baru 7a, semua pagar lama beku tak berubah):
--   7a. Bila pasangan belum punya persetujuan DAN perangkat lahir dari kode
--       resmi yang sudah dipakai pada penyewa yang sama, tulis baris
--       persetujuan otomatis dengan disetujui_oleh = PENERBIT KODE
--       (dibuat_oleh) + catatan_audit 'persetujuan_otomatis_kode'.
--       Dasar wewenang: penerbit kode (owner/admin) sudah menyatakan
--       kehendaknya menghadirkan perangkat itu saat menerbitkan kode.
--   7b. Gerbang lama TETAP: perangkat yang tidak lahir dari kode resmi
--       masih wajib persetujuan manual. Anti-orakel: 7a berjalan sesudah
--       PIN terbukti benar, sama seperti 7b.
--
-- Uji: supabase/tes/persetujuan_otomatis_kode_resmi.sql (MERAH sebelum
--      migrasi ini, HIJAU sesudahnya) + suite penuh.
-- Dampak pada bukti lama: probe H-F-06.3-probe-082.sql bagian A–C tetap
--      hijau; bagian D (yang justru mendokumentasikan residu ini) kini GAGAL
--      pada asersi terakhirnya — kegagalan yang direncanakan sebagai bukti
--      penutupan F-233, pola sama dengan probe H-F-06.5 pasca-0106.
-- ============================================================================

create or replace function public.verifikasi_pin_perangkat(
  p_email           text,
  p_pin             text,
  p_perangkat_id    uuid default null,
  p_perangkat_nama  text default null,
  p_kunci_perangkat text default null
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_pengguna       record;
  v_perangkat      record;
  v_kunci_hash     text;
  v_hash           text;
  v_gagal_akun     int;
  v_gagal_alat     int;
  v_cabang_ids     uuid[];
  v_cabang_utama   uuid;
  v_berhasil       boolean;
  v_jumlah_alat    int;
  v_nama_alat      text;
  v_izin_daftar_bebas boolean;
  v_boleh_daftar_baru boolean;
  v_jumlah_alat_awal integer;
begin
  if p_email is null or trim(p_email) = '' or p_pin is null or trim(p_pin) = '' then
    return jsonb_build_object(
      'berhasil', false,
      'kode', 'INPUT_TIDAK_LENGKAP',
      'pesan', 'Email dan PIN wajib diisi.'
    );
  end if;

  -- 1. Validasi format PIN (wajib 6 angka)
  if p_pin !~ '^\d{6}$' then
    return jsonb_build_object(
      'berhasil', false,
      'kode', 'FORMAT_PIN_SALAH',
      'pesan', 'PIN harus berupa 6 digit angka.'
    );
  end if;

  -- 2. Validasi perangkat wajib diisi
  if p_perangkat_id is null then
    return jsonb_build_object(
      'berhasil', false,
      'kode', 'PERANGKAT_WAJIB',
      'pesan', 'Perangkat kasir/staf wajib terdaftar untuk mengakses sistem.'
    );
  end if;

  -- Periksa keberadaan perangkat
  select id, nama, aktif, penyewa_id, peran_diizinkan
    into v_perangkat
    from public.perangkat
   where id = p_perangkat_id;

  -- Catatan (PMB1-F-039): pengecekan "perangkat tidak aktif" yang dulu ada di sini dihapus
  -- agar hanya ADA SATU tempat yang menolak (langkah 3b). Dua salinan pemeriksaan
  -- membuat satu pagarnya bisa dilumpuhkan tanpa uji merapat (dibuktikan uji mutasi).

  -- 3. Cari data pengguna berdasarkan email
  select p.id, p.penyewa_id, p.nama, p.peran, p.aktif
    into v_pengguna
    from public.pengguna p
   where lower(trim(p.email)) = lower(trim(p_email));

  if v_pengguna.id is null or not coalesce(v_pengguna.aktif, false) then
    return jsonb_build_object(
      'berhasil', false,
      'kode', 'KREDENSIAL_TIDAK_VALID',
      'pesan', 'Email, PIN, atau perangkat tidak cocok.'
    );
  end if;

  -- 4. Pembatasan brute-force (5x per akun / 12x per perangkat per 15 menit)
  select count(*) into v_gagal_akun
    from public.percobaan_pin pp
   where pp.pengguna_id = v_pengguna.id
     and not pp.berhasil
     and pp.waktu > now() - interval '15 minutes';

  select count(*) into v_gagal_alat
    from public.percobaan_pin pp
   where pp.perangkat_id = p_perangkat_id
     and not pp.berhasil
     and pp.waktu > now() - interval '15 minutes';

  if v_gagal_akun >= 5 or v_gagal_alat >= 12 then
    return jsonb_build_object(
      'berhasil', false,
      'kode', 'AKUN_TERKUNCI',
      'pesan', 'Akun atau perangkat terkunci sementara karena 5 kali percobaan salah. Tunggu 15 menit.'
    );
  end if;

  -- 3b. (PMB1-F-039) Status perangkat diputuskan LEBIH DAHULU, sebelum PIN dicek.
  --      Dulu urutannya: PIN dicek lebih dulu, sehingga
  --        (a) PIN benar  -> "PERANGKAT_TIDAK_SAH" (dari device check),
  --        (b) PIN salah  -> meledak galat FK `percobaan_pin.perangkat_id`,
  --      dua jawaban berbeda = orakel PIN; dan
  --        (c) penghitung percobaan per akun tidak pernah bertambah untuk UUID yang
  --            diputar-putar, sehingga batas 5x/15 menit tidak pernah menyala.
  --      Di sini Percobaan selalu dicatat lebih dulu (dengan `perangkat_id` = null bila
  --      perangkat memang tidak ada), sehingga batas per akun benar-benar hidup.
  v_boleh_daftar_baru := false;

  if v_perangkat.id is not null then
    -- Perangkat terdaftar tapi dicabut/nonaktif -> tolol tanpa menyentuh PIN.
    if not coalesce(v_perangkat.aktif, false) then
      insert into public.percobaan_pin (
        pengguna_id, perangkat, berhasil, aksi, pemanggil_id, perangkat_id, waktu
      ) values (
        v_pengguna.id,
        v_perangkat.nama,
        false,
        'masuk_pin',
        v_pengguna.id,
        v_perangkat.id,
        now()
      );

      return jsonb_build_object(
        'berhasil', false,
        'kode', 'PERANGKAT_TIDAK_SAH',
        'pesan', 'Perangkat tidak terdaftar atau telah dicabut.'
      );
    end if;
  else
    -- Perangkat tidak dikenal: hanya boleh diteruskan bila pengguna ini BOLEH
    -- mendaftarkan perangkat baru (aturan sama dengan langkah 6: staf biasa pada
    -- penyewa tanpa perangkat, atau peran berkuasa yang saklarnya menyala).
    select count(*) into v_jumlah_alat_awal
      from public.perangkat
     where penyewa_id = v_pengguna.penyewa_id
       and aktif = true;

    select coalesce(pg.izin_daftar_perangkat_bebas_peran_berkuasa, false)
      into v_izin_daftar_bebas
      from public.pengaturan pg
     where pg.penyewa_id = v_pengguna.penyewa_id;

    v_boleh_daftar_baru := (v_jumlah_alat_awal = 0)
      or (
        (v_pengguna.peran in ('owner_pusat', 'pemilik_platform')
         or lower(trim(p_email)) like '%@resto.test')
        and coalesce(v_izin_daftar_bebas, false)
      );

    if not v_boleh_daftar_baru then
      insert into public.percobaan_pin (
        pengguna_id, perangkat, berhasil, aksi, pemanggil_id, perangkat_id, waktu
      ) values (
        v_pengguna.id,
        coalesce(nullif(btrim(p_perangkat_nama), ''), 'Perangkat Tidak Dikenal'),
        false,
        'masuk_pin',
        v_pengguna.id,
        null,
        now()
      );

      if v_pengguna.peran in ('owner_pusat', 'pemilik_platform')
         or lower(trim(p_email)) like '%@resto.test' then
        return jsonb_build_object(
          'berhasil', false,
          'kode', 'PERANGKAT_BELUM_DISETUJUI',
          'pesan', 'Perangkat ini belum terdaftar. Daftarkan dari perangkat lain yang sudah sah, atau nyalakan saklar izin_daftar_perangkat_bebas_peran_berkuasa untuk sementara.'
        );
      end if;

      return jsonb_build_object(
        'berhasil', false,
        'kode', 'PERANGKAT_TIDAK_SAH',
        'pesan', 'Perangkat tidak terdaftar atau telah dicabut.'
      );
    end if;
  end if;

  -- 5. Periksa kecocokan hash PIN
  select pin_hash into v_hash
    from public.kredensial_pin
   where pengguna_id = v_pengguna.id;

  v_berhasil := v_hash is not null and crypt(p_pin, v_hash) = v_hash;

  if not v_berhasil then
    insert into public.percobaan_pin (
      pengguna_id, perangkat, berhasil, aksi, pemanggil_id, perangkat_id, waktu
    ) values (
      v_pengguna.id,
      coalesce(v_perangkat.nama, coalesce(nullif(btrim(p_perangkat_nama), ''), 'Perangkat Tanpa Nama')),
      false,
      'masuk_pin',
      v_pengguna.id,
      -- v_perangkat.id, bukan p_perangkat_id: kalau perangkatnya tidak terdaftar,
      -- UUID asing tidak boleh dipaksakan ke kolom yang mengacu `perangkat.id`
      -- (percobaan yang lalu melempar galat FK — bugs yang membuat orakel PIN).
      v_perangkat.id,
      now()
    );

    return jsonb_build_object(
      'berhasil', false,
      'kode', 'KREDENSIAL_TIDAK_VALID',
      'pesan', 'Email, PIN, atau perangkat tidak cocok.'
    );
  end if;

  -- 6. Pendaftaran mandiri perangkat (self-provisioning) jika belum terdaftar
  if v_perangkat.id is null then
    select count(*) into v_jumlah_alat
      from public.perangkat
     where penyewa_id = v_pengguna.penyewa_id
       and aktif = true;

    -- `v_boleh_daftar_baru` sudah dihitung di langkah 3b (per satu device check),
    -- sehingga syarat daftar di sini tidak mungkin berbeda dari yang dipakai menolak.
    if v_boleh_daftar_baru then

      -- Ambil cabang utama yang sah (kolom dibuat_pada)
      select id into v_cabang_utama
        from public.cabang
       where penyewa_id = v_pengguna.penyewa_id
       order by dibuat_pada asc limit 1;

      if v_cabang_utama is null then
        select id into v_cabang_utama
          from public.cabang
         where penyewa_id = v_pengguna.penyewa_id
         limit 1;
      end if;

      if v_cabang_utama is null then
        insert into public.cabang (penyewa_id, nama, aktif, dibuat_pada)
        values (v_pengguna.penyewa_id, 'Cabang Utama', true, now())
        returning id into v_cabang_utama;
      end if;

      -- Susun nama perangkat dan cegah tabrakan unik (penyewa_id, nama)
      v_nama_alat := coalesce(nullif(trim(p_perangkat_nama), ''), 'Perangkat ' || initcap(replace(v_pengguna.peran::text, '_', ' ')));
      if exists (
        select 1 from public.perangkat
         where penyewa_id = v_pengguna.penyewa_id
           and nama = v_nama_alat
           and aktif
           and id <> p_perangkat_id
      ) then
        v_nama_alat := v_nama_alat || ' (' || substr(p_perangkat_id::text, 1, 8) || ')';
      end if;

      insert into public.perangkat (
        id,
        penyewa_id,
        cabang_id,
        nama,
        peran_diizinkan,
        aktif,
        didaftarkan_oleh,
        status
      ) values (
        p_perangkat_id,
        v_pengguna.penyewa_id,
        v_cabang_utama,
        v_nama_alat,
        array['owner_pusat', 'pemilik_platform', 'admin_cabang', 'kasir', 'dapur', 'pelayan']::text[],
        true,
        v_pengguna.id,
        'aktif'
      )
      on conflict (id) do update set
        penyewa_id = excluded.penyewa_id,
        cabang_id = coalesce(excluded.cabang_id, public.perangkat.cabang_id),
        nama = excluded.nama,
        peran_diizinkan = excluded.peran_diizinkan,
        aktif = true,
        status = 'aktif',
        terakhir_aktif = now();

      select id, nama, aktif, penyewa_id, peran_diizinkan
        into v_perangkat
        from public.perangkat
       where id = p_perangkat_id;

      -- PMB1-F-082: pendaftaran mandiri mencatat persetujuan oleh pelakunya
      -- sendiri supaya aturan persetujuan login tidak mengunci alur sah
      -- (owner mendaftarkan perangkatnya sendiri / perangkat pertama resto).
      insert into public.persetujuan_perangkat (penyewa_id, perangkat_id, pengguna_id, disetujui_oleh)
      values (v_pengguna.penyewa_id, p_perangkat_id, v_pengguna.id, v_pengguna.id)
      on conflict (perangkat_id, pengguna_id) do nothing;
    else
      -- Restoran telah beroperasi dan staf biasa mencoba masuk dari perangkat tak dikenal
      return jsonb_build_object(
        'berhasil', false,
        'kode', 'PERANGKAT_TIDAK_SAH',
        'pesan', 'Perangkat tidak terdaftar atau telah dicabut.'
      );
    end if;
  end if;

  -- 7. Validasi relasi tenant & peran terhadap perangkat
  if v_perangkat.penyewa_id <> v_pengguna.penyewa_id then
    return jsonb_build_object(
      'berhasil', false,
      'kode', 'RESTO_TIDAK_COCOK',
      'pesan', 'Perangkat tidak terdaftar pada restoran ini.'
    );
  end if;

  if not (v_pengguna.peran::text = any(v_perangkat.peran_diizinkan)) then
    return jsonb_build_object(
      'berhasil', false,
      'kode', 'PERAN_TIDAK_DIIZINKAN',
      'pesan', 'Peran pengguna tidak diizinkan pada perangkat ini.'
    );
  end if;

  -- 7a. PMB1-F-233 (KEPUTUSAN LEE 2026-10-09, "tambal jalur resmi"):
  --     perangkat yang lahir dari jalur pendaftaran RESMI (kode sekali pakai
  --     T1-24, migrasi 0030 `daftarkan_perangkat_dengan_kode`) tidak boleh
  --     menjadi jalan buntu: pendaftaran itu berjalan TANPA identitas
  --     pengguna sehingga mustahil menulis baris persetujuan (pegawai x
  --     perangkat) saat pendaftaran. Persetujuan otomatis ditulis di SINI,
  --     saat login pertama pegawai yang PIN-nya sah, dan dinisbatkan kepada
  --     PENERBIT KODE (dibuat_oleh) — penerbit sudah menyatakan kehendaknya
  --     menghadirkan perangkat itu ketika menerbitkan kode. Batas pengaman:
  --     hanya berlaku untuk perangkat yang benar-benar lahir dari kode resmi
  --     yang SUDAH DIPAKAI (dipakai_pada is not null) pada penyewa yang sama;
  --     perangkat lain tetap tunduk pada gerbang 7b (persetujuan manual).
  --     Posisi sesudah verifikasi PIN = tidak membuka bocoran baru (pola
  --     anti-orakel 0091 dipertahankan). Jejak audit: baris
  --     persetujuan_perangkat + catatan_audit aksi 'persetujuan_otomatis_kode'.
  if not exists (
    select 1 from public.persetujuan_perangkat pp
     where pp.pengguna_id = v_pengguna.id
       and pp.perangkat_id = v_perangkat.id
  )
  and exists (
    select 1 from public.kode_pendaftaran_perangkat k
     where k.perangkat_id = v_perangkat.id
       and k.dipakai_pada is not null
       and k.penyewa_id = v_pengguna.penyewa_id
  ) then
    insert into public.persetujuan_perangkat (penyewa_id, perangkat_id, pengguna_id, disetujui_oleh)
    values (
      v_pengguna.penyewa_id,
      v_perangkat.id,
      v_pengguna.id,
      (select k.dibuat_oleh
         from public.kode_pendaftaran_perangkat k
        where k.perangkat_id = v_perangkat.id
          and k.dipakai_pada is not null
          and k.penyewa_id = v_pengguna.penyewa_id
        order by k.dibuat_pada asc
        limit 1)
    )
    on conflict (perangkat_id, pengguna_id) do nothing;

    insert into public.catatan_audit (
      penyewa_id, pelaku_id, aksi, entitas, entitas_id, nilai_baru
    ) values (
      v_pengguna.penyewa_id,
      (select k.dibuat_oleh
         from public.kode_pendaftaran_perangkat k
        where k.perangkat_id = v_perangkat.id
          and k.dipakai_pada is not null
          and k.penyewa_id = v_pengguna.penyewa_id
        order by k.dibuat_pada asc
        limit 1),
      'persetujuan_otomatis_kode', 'persetujuan_perangkat', v_perangkat.id,
      jsonb_build_object(
        'pengguna_id', v_pengguna.id,
        'perangkat_id', v_perangkat.id,
        'sumber', 'kode_pendaftaran_perangkat'
      )
    );
  end if;

  -- 7b. PMB1-F-082 (KEAMANAN §4): pasangan (pegawai x perangkat) wajib
  --     sudah disetujui owner/admin sebelum dipakai masuk. Tanpa baris di
  --     persetujuan_perangkat, PIN yang benar pun tidak membuka sesi.
  --     Catatan anti-oracle: penolakan ini terjadi SESUDAH PIN terbukti
  --     benar, disamakan tempatnya dengan langkah lain yang juga baru bisa
  --     dicapai dengan PIN benar (kunci perangkat), sehingga tidak menambah
  --     bocoran informasi keberadaan akun dibanding definisi 0091.
  if not exists (
    select 1 from public.persetujuan_perangkat pp
     where pp.pengguna_id = v_pengguna.id
       and pp.perangkat_id = v_perangkat.id
  ) then
    return jsonb_build_object(
      'berhasil', false,
      'kode', 'PERANGKAT_BELUM_DISETUJUI',
      'pesan', 'Perangkat ini belum disetujui untuk akun Anda. Minta owner atau admin cabang menyetujuinya di layar Perangkat.'
    );
  end if;

  -- 8. Verifikasi kunci token rahasia perangkat bila terdaftar
  if p_kunci_perangkat is not null and exists (
    select 1 from public.kredensial_perangkat kp where kp.perangkat_id = p_perangkat_id
  ) then
    select kp.kunci_hash into v_kunci_hash
      from public.kredensial_perangkat kp
     where kp.perangkat_id = p_perangkat_id;

    if v_kunci_hash is not null and crypt(p_kunci_perangkat, v_kunci_hash) <> v_kunci_hash then
      return jsonb_build_object(
        'berhasil', false,
        'kode', 'PERANGKAT_TIDAK_SAH',
        'pesan', 'Kunci token rahasia perangkat tidak cocok.'
      );
    end if;
  end if;

  -- 9. Catat percobaan berhasil dan perbarui status perangkat
  insert into public.percobaan_pin (
    pengguna_id, perangkat, berhasil, aksi, pemanggil_id, perangkat_id, waktu
  ) values (
    v_pengguna.id, v_perangkat.nama, true, 'masuk_pin', v_pengguna.id, p_perangkat_id, now()
  );

  update public.perangkat
     set terakhir_aktif = now()
   where id = v_perangkat.id;

  -- 10. Ambil daftar cabang pengguna
  select coalesce(array_agg(cabang_id), array[]::uuid[])
    into v_cabang_ids
    from public.pengguna_cabang
   where pengguna_id = v_pengguna.id
     and aktif;

  return jsonb_build_object(
    'berhasil', true,
    'kode', 'LOGIN_SUKSES',
    'pesan', 'Login dengan PIN berhasil.',
    'data', jsonb_build_object(
      'pengguna_id', v_pengguna.id,
      'nama', v_pengguna.nama,
      'peran', v_pengguna.peran,
      'penyewa_id', v_pengguna.penyewa_id,
      'cabang_ids', v_cabang_ids,
      'perangkat_id', v_perangkat.id
    )
  );
end;
$$;

comment on function public.verifikasi_pin_perangkat(text, text, uuid, text, text) is
  'Login PIN per perangkat. Definisi 0107: gerbang persetujuan 0101 + persetujuan otomatis perangkat jalur kode resmi (PMB1-F-233).';

revoke all on function public.verifikasi_pin_perangkat(text, text, uuid, text, text) from public;
grant execute on function public.verifikasi_pin_perangkat(text, text, uuid, text, text) to anon, authenticated, service_role;
