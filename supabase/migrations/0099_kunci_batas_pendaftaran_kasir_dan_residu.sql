-- ============================================================================
-- MIGRASI 0099 — PMB1-F-038 BAGIAN B RONDE 2 (temuan hakim H-F-03.7) + F-230:
-- (a) menutup RACE CONDITION pagar batas 0097; (b) penolakan batas tanpa residu.
-- ============================================================================
-- Temuan H-F-03.7 (kartu `kartu/H-F-03.7.md`, bukti `bukti/H-F-03.7-konkurensi.py`
-- + `.txt`): dua transaksi daftar_voucher SERENTAK sama-sama membaca hitungan 2
-- lalu sama-sama menerbitkan voucher ke-3 dan ke-4 (batas bawaan 3 terlampaui) —
-- pagar hitung-lalu-terbit 0097 tidak mengunci rentang baca-ke-tulis (TOCTOU).
-- Bukti direproduksi ulang di sandbox Perencana sebelum migrasi ini ditulis
-- (MERAH), dan menjadi HIJAU sesudahnya (bukti `bukti/B-F-03.5-*`).
--
-- Perbaikan (tanpa mengubah 0097; berkas berlaku terakhir = 0099):
--   1. `pg_advisory_xact_lock(hashtext(penyewa|kasir), hashtext(kampanye))`
--      diambil SEBELUM hitungan pada jalur `cara_masuk = 'kasir'` dan lepas
--      otomatis di akhir transaksi: penerbitan voucher untuk kombinasi
--      (penyewa, kasir, kampanye) yang sama terserial; kombinasi lain tidak
--      ikut terblokir. Jalur google/email tidak disentuh.
--   2. PMB1-F-230: bila pendaftaran ditolak batas, baris pelanggan yang BARU
--      dibuat oleh panggilan itu dihapus lagi — tidak ada pelanggan yatim
--      dengan `persetujuan_privasi = true` tanpa voucher.
-- Dijaga oleh: kasus 27 `supabase/tes/voucher_kasir_wajib_identitas.sql`
-- (tanpa residu) + harness konkurensi `bukti/H-F-03.7-konkurensi.py` (sekarang
-- harus menunjukkan salah satu permintaan serentak DITOLAK) + suite penuh.
-- ============================================================================

-- `daftar_voucher` ditulis ulang dari definisi berlaku (0097) dengan dua pagar
-- baru; migrasi lama tidak diubah.
create or replace function public.daftar_voucher(
  p_penyewa_id uuid,
  p_kampanye_id uuid,
  p_nama text,
  p_email text,
  p_telepon text default null,
  p_alamat text default null,
  p_persetujuan_privasi boolean default true,
  p_cara_masuk text default 'email',
  p_perangkat text default null,
  p_ip text default null
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_kmp record;
  v_email_norm text;
  v_pelanggan_id uuid;
  v_terbit_count integer;
  v_kode_voucher text;
  v_voucher_id uuid;
  v_ada record;
  v_jumlah_voucher_pelanggan integer := 0;
  v_uid_sesi uuid;
  v_peran_sesi text;
  v_email_sesi text;
  v_kasir_id uuid;
  v_batas_daftar integer;
  v_pelanggan_baru boolean := false;
  v_sudah_didaftarkan integer;
begin
  -- Lapis 0 (BARU — PMB1-F-031): voucher hanya boleh terbit untuk identitas yang
  -- bisa diverifikasi oleh PELADEN.
  --   - cara_masuk 'kasir'   → pemanggil harus staf yang sedang masuk (auth.uid() + peran staf).
  --   - cara_masuk google/email → pemanggil harus punya sesi terverifikasi dan alamat yang
  --     diklaim harus sama dengan alamat pada sesi itu (JWT / auth.users).
  -- Tanpa pagar ini peran anon bisa mengaku "Google" atas alamat mana pun, satu voucher
  -- terbit per alamat, dan `terverifikasi_pada` ditandai padahal tidak ada verifikasi.
  v_uid_sesi := auth.uid();
  v_peran_sesi := public.peran_saya();
  -- Jejak staf pada `voucher_percobaan.kasir_id` hanya diisi bila pemanggil memang staf
  -- (kolom itu mengacu ke `public.pengguna`). Sesi pelanggan menulis null — kalau tidak,
  -- klaim pelanggan yang sah akan gagal karena kunci asing.
  v_kasir_id := case when v_peran_sesi is not null then v_uid_sesi else null end;

  if p_cara_masuk = 'kasir' then
    if v_uid_sesi is null
       or v_peran_sesi is null
       or v_peran_sesi not in ('owner_pusat', 'admin_cabang', 'kasir') then
      return jsonb_build_object(
        'berhasil', false,
        'kode', 'PENDAFTARAN_HARUS_OLEH_STAF',
        'pesan', 'Pendaftaran pelanggan lewat kasir hanya bisa dilakukan staf yang sedang masuk.'
      );
    end if;
  else
    if v_uid_sesi is null then
      return jsonb_build_object(
        'berhasil', false,
        'kode', 'VERIFIKASI_WAJIB',
        'pesan', 'Verifikasi identitas (Google atau email) wajib selesai sebelum mengambil voucher.'
      );
    end if;

    v_email_sesi := lower(btrim(coalesce(auth.jwt() ->> 'email', '')));
    if v_email_sesi = '' then
      select lower(btrim(u.email)) into v_email_sesi
        from auth.users u
       where u.id = v_uid_sesi;
    end if;

    -- Kedua sisi dinormalisasi (alamat sesi bisa memakai titik/tag `+` yang tidak dipakai
    -- pemanggil, atau sebaliknya) agar "alamat yang sama" tidak salah ditolak.
    if v_email_sesi is null or v_email_sesi = ''
       or public.normalisasi_email(v_email_sesi) is distinct from public.normalisasi_email(p_email) then
      return jsonb_build_object(
        'berhasil', false,
        'kode', 'VERIFIKASI_WAJIB',
        'pesan', 'Alamat yang diklaim harus sama dengan alamat yang sudah diverifikasi pada sesi ini.'
      );
    end if;
  end if;
  -- Lapis 8: Batas Percobaan Per Perangkat / IP (Rate Limiting)
  if p_penyewa_id is not null and public.apakah_perangkat_terblokir(p_penyewa_id, p_perangkat, p_ip) then
    insert into public.voucher_percobaan (penyewa_id, kode_dicoba, hasil, alasan, kasir_id, cabang_id, perangkat, ip_pengakses, aksi, waktu)
    values (p_penyewa_id, 'KLAIM_BARU', 'gagal', 'Terlalu banyak percobaan kode voucher yang gagal.', v_kasir_id, null, p_perangkat, p_ip, 'daftar', now());

    return jsonb_build_object(
      'berhasil', false,
      'kode', 'TERLALU_BANYAK_PERCOBAAN',
      'pesan', 'Terlalu banyak percobaan kode voucher yang gagal dari perangkat ini. Mohon tunggu 15 menit.'
    );
  end if;

  -- 1. Validasi Persetujuan Privasi (UU PDP & T-011)
  if coalesce(p_persetujuan_privasi, false) is not true then
    return jsonb_build_object(
      'berhasil', false,
      'kode', 'PRIVASI_WAJIB',
      'pesan', 'Persetujuan pemrosesan data pribadi (UU PDP) wajib diberikan.'
    );
  end if;

  -- 2. Validasi Nama
  if p_nama is null or length(trim(p_nama)) = 0 then
    return jsonb_build_object(
      'berhasil', false,
      'kode', 'NAMA_WAJIB',
      'pesan', 'Nama lengkap wajib diisi.'
    );
  end if;

  -- 3. Lapis 9 & 10: Validasi, Anti-Disposable, dan Normalisasi Email Gmail
  if (p_email is null or length(trim(p_email)) = 0) and p_cara_masuk != 'kasir' then
    return jsonb_build_object(
      'berhasil', false,
      'kode', 'EMAIL_WAJIB',
      'pesan', 'Alamat email wajib diisi.'
    );
  end if;

  if p_email is not null and length(trim(p_email)) > 0 then
    if public.apakah_email_sekali_pakai(p_email) then
      return jsonb_build_object(
        'berhasil', false,
        'kode', 'EMAIL_SEKALI_PAKAI',
        'pesan', 'Email sementara atau sekali-pakai tidak diizinkan. Mohon gunakan email pribadi aktif.'
      );
    end if;

    v_email_norm := public.normalisasi_email(p_email);
    if v_email_norm is null then
      return jsonb_build_object(
        'berhasil', false,
        'kode', 'EMAIL_TIDAK_SAH',
        'pesan', 'Format alamat email tidak sah.'
      );
    end if;
  end if;

  -- 4. Periksa Kampanye
  select * into v_kmp
    from public.kampanye_voucher
   where id = p_kampanye_id
     and penyewa_id = p_penyewa_id;

  if v_kmp.id is null or v_kmp.aktif is not true then
    return jsonb_build_object(
      'berhasil', false,
      'kode', 'KAMPANYE_TIDAK_AKTIF',
      'pesan', 'Kampanye voucher tidak ditemukan atau sudah tidak aktif.'
    );
  end if;

  if now() < v_kmp.mulai or now() > v_kmp.selesai then
    return jsonb_build_object(
      'berhasil', false,
      'kode', 'KAMPANYE_BERAKHIR',
      'pesan', 'Masa berlaku kampanye voucher telah berakhir.'
    );
  end if;

  select count(1) into v_terbit_count
    from public.voucher
   where kampanye_id = p_kampanye_id;

  if v_terbit_count >= v_kmp.kuota then
    return jsonb_build_object(
      'berhasil', false,
      'kode', 'KUOTA_HABIS',
      'pesan', 'Mohon maaf, kuota voucher untuk kampanye ini telah habis.'
    );
  end if;

  -- 5. Ambil atau Buat Pelanggan
  if v_email_norm is not null then
    select id into v_pelanggan_id
      from public.pelanggan
     where penyewa_id = p_penyewa_id
       and email_normalisasi = v_email_norm;
  end if;

  if v_pelanggan_id is null then
    insert into public.pelanggan (
      penyewa_id,
      nama,
      email,
      telepon,
      alamat,
      cara_masuk,
      persetujuan_privasi,
      didaftarkan_oleh
    ) values (
      p_penyewa_id,
      trim(p_nama),
      trim(p_email),
      nullif(trim(coalesce(p_telepon, '')), ''),
      nullif(trim(coalesce(p_alamat, '')), ''),
      p_cara_masuk,
      true,
      case when p_cara_masuk = 'kasir' then v_kasir_id else null end
    ) returning id into v_pelanggan_id;
    v_pelanggan_baru := true;
  end if;

  -- Lapis 1: Satu Voucher Per Identitas Per Kampanye (kuota_per_pelanggan)
  select count(1) into v_jumlah_voucher_pelanggan
    from public.voucher
   where kampanye_id = p_kampanye_id
     and pelanggan_id = v_pelanggan_id;

  if v_jumlah_voucher_pelanggan >= coalesce(v_kmp.kuota_per_pelanggan, 1) then
    select kode, status into v_ada
      from public.voucher
     where kampanye_id = p_kampanye_id
       and pelanggan_id = v_pelanggan_id
     limit 1;

    return jsonb_build_object(
      'berhasil', false,
      'kode', 'VOUCHER_SUDAH_DIKLAIM',
      'pesan', 'Satu identitas hanya berhak mengklaim 1 voucher untuk kampanye ini.',
      'data', jsonb_build_object(
        'kode_voucher', v_ada.kode,
        'status', v_ada.status
      )
    );
  end if;

  -- Lapis BARU (PMB1-F-038 Bagian B, OPSI 3 — keputusan Lee 2026-10-04):
  -- BATAS PENDAFTARAN PELANGGAN OLEH SATU KASIR UNTUK SATU KAMPANYE.
  -- Skenario kerugian Bagian B: kasir mengarang pelanggan (nomor karangan) lalu
  -- mencairkan vouchernya dengan PIN sendiri. Menutup penuh skenario itu butuh
  -- keputusan kebijakan (PIN atasan dsb.); pagar ini membuat serangan MASSAL jadi
  -- mahal: satu kasir paling banyak menerbitkan
  -- `pengaturan.batas_daftar_pelanggan_kasir_per_kampanye` voucher per kampanye
  -- (bawaan 3; 0 = tanpa batas sebagai pelarian resmi operator). Yang dihitung
  -- hanya pelanggan yang DIDAFTARKAN KASIR INI (didaftarkan_oleh) dan menerima
  -- voucher pada kampanye itu; pendaftaran kasir lain dan pendaftar mandiri
  -- (google/email) tidak ikut dihitung. Posisi pagar SESUDAH penolakan identitas
  -- ganda (kunci unik + Lapis 1) supaya jalur penolakan lama tidak berubah.
  if p_cara_masuk = 'kasir' then
    -- PMB1-F-038 Bagian B ronde 2 (temuan H-F-03.7): hitung-lalu-terbit tanpa
    -- kunci bisa dilewati dua transaksi serentak (TOCTOU; bukti konkurensi
    -- PostgreSQL 16.2: batas 3, terbit 4). Kunci transakasi per kombinasi
    -- (penyewa, kasir, kampanye) menserialkan hitung-dan-terbit; kombinasi lain
    -- tidak saling menunggu. Lepas otomatis saat transaksi selesai.
    perform pg_advisory_xact_lock(
      hashtext(p_penyewa_id::text || '|' || coalesce(v_kasir_id, '00000000-0000-0000-0000-000000000000')::text),
      hashtext(coalesce(p_kampanye_id, '00000000-0000-0000-0000-000000000000')::text)
    );

    select coalesce(pg.batas_daftar_pelanggan_kasir_per_kampanye, 3)
      into v_batas_daftar
      from public.pengaturan pg
     where pg.penyewa_id = p_penyewa_id;

    if coalesce(v_batas_daftar, 3) > 0 then
      select count(1) into v_sudah_didaftarkan
        from public.voucher vo
        join public.pelanggan pl on pl.id = vo.pelanggan_id
       where vo.kampanye_id = p_kampanye_id
         and pl.didaftarkan_oleh = v_kasir_id;

      if coalesce(v_sudah_didaftarkan, 0) >= v_batas_daftar then
        -- PMB1-F-230 (temuan H-F-03.7): penolakan batas tidak boleh meninggalkan
        -- baris pelanggan yatim (dibuat pada langkah 5 sebelum cek ini). Hapus
        -- hanya baris yang BARU dibuat oleh panggilan ini; pelanggan yang sudah
        -- ada tidak pernah disentuh.
        if v_pelanggan_baru then
          delete from public.pelanggan where id = v_pelanggan_id;
        end if;

        insert into public.voucher_percobaan (penyewa_id, kode_dicoba, hasil, alasan, kasir_id, cabang_id, perangkat, ip_pengakses, aksi, waktu)
        values (p_penyewa_id, 'KLAIM_BARU', 'gagal', 'Batas pendaftaran pelanggan per kasir per kampanye tercapai.', v_kasir_id, null, p_perangkat, p_ip, 'daftar', now());

        return jsonb_build_object(
          'berhasil', false,
          'kode', 'BATAS_PENDAFTARAN_KASIR',
          'pesan', 'Batas pendaftaran pelanggan oleh satu kasir untuk kampanye ini sudah tercapai. Minta kasir lain atau atur ulang batasnya di pengaturan.'
        );
      end if;
    end if;
  end if;

  -- Lapis 7: Terbitkan Kode Acak Tidak Berurutan (T8-08)
  loop
    v_kode_voucher := public.buat_kode_voucher_acak();
    exit when not exists (
      select 1 from public.voucher where penyewa_id = p_penyewa_id and kode = v_kode_voucher
    );
  end loop;

  insert into public.voucher (
    penyewa_id,
    kampanye_id,
    pelanggan_id,
    kode,
    status,
    berlaku_sampai
  ) values (
    p_penyewa_id,
    p_kampanye_id,
    v_pelanggan_id,
    v_kode_voucher,
    'aktif',
    v_kmp.selesai
  ) returning id into v_voucher_id;

  -- Lapis 8: Log Percobaan Sukses
  insert into public.voucher_percobaan (penyewa_id, kode_dicoba, hasil, alasan, kasir_id, cabang_id, perangkat, ip_pengakses, aksi, waktu)
  values (p_penyewa_id, v_kode_voucher, 'sukses', 'Klaim voucher berhasil diterbitkan.', v_kasir_id, null, p_perangkat, p_ip, 'daftar', now());

  return jsonb_build_object(
    'berhasil', true,
    'kode', 'SUKSES',
    'pesan', 'Voucher berhasil diterbitkan.',
    'data', jsonb_build_object(
      'voucher_id', v_voucher_id,
      'kode_voucher', v_kode_voucher,
      'nama_pelanggan', trim(p_nama),
      'nilai', v_kmp.nilai,
      'jenis', v_kmp.jenis,
      'min_belanja', v_kmp.min_belanja,
      'maks_potongan', v_kmp.maks_potongan,
      'berlaku_sampai', v_kmp.selesai,
      'pola_barcode', public.pola_barcode_garis(v_kode_voucher)
    )
  );
end;
$$;

comment on function public.daftar_voucher(uuid, uuid, text, text, text, text, boolean, text, text, text) is
  'Menerbitkan kode voucher untuk identitas yang sudah diverifikasi peladen (PMB1-F-031 — M10 PRD baris 164). Cara kasir hanya untuk staf yang sedang masuk.';

-- Pertahanan lapis kedua: peran anon tidak diberi hak eksekusi sama sekali.
-- Grant lama ke peran `anon` (0063/0067) harus dicabut sendiri-sendiri: `revoke ... from
-- public` saja TIDAK menghapus grant eksplisit yang sudah diberikan ke `anon`.
revoke all on function public.daftar_voucher(uuid, uuid, text, text, text, text, boolean, text, text, text) from public;
revoke all on function public.daftar_voucher(uuid, uuid, text, text, text, text, boolean, text, text, text) from anon;
grant execute on function public.daftar_voucher(uuid, uuid, text, text, text, text, boolean, text, text, text) to authenticated, service_role;
