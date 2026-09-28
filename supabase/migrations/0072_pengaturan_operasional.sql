-- ============================================================================
-- 0072 — Pengaturan Operasional Resto (T9-03 / PRD M2, M6 / TECH_SPEC §9 ART-3)
--
-- Memungkinkan Owner / Admin berwenang mengelola konfigurasi operasional kedai:
--  1. Tarif Pajak PB1 (%) & Service Charge (%)
--  2. Aturan Pembulatan Nilai Akhir (none, 100, 500, 1000)
--  3. Alur Cara Pesan (kasir, mandiri, meja, campur)
--  4. Jam Operasional Kedai (jam_buka)
--  5. Teks Header & Footer Struk Kasir
--  6. Kebijakan Tumpuk Diskon (tumpuk_diskon)
--
-- Pagar Keamanan, Integritas Finansial, & Aturan Bisnis (ART-3):
--  1. Validasi Rentang Nilai:
--     - PB1 & service charge wajib di antara 0% s/d 100%.
--     - Pembulatan wajib salah satu dari: 'none', '100', '500', '1000'.
--     - Cara pesan wajib salah satu dari: 'kasir', 'mandiri', 'meja', 'campur'.
--  2. Perlindungan Transaksi Masa Lalu:
--     - Nilai nominal rupiah pajak & service charge telah disalin ke transaksi
--       saat pesanan dibuat (harga_saat_itu). Transaksi yang sudah terbit / lunas
--       TIDAK BOLEH berubah nominalnya ketika persentase operasional diperbarui.
--  3. Otorisasi Ketat:
--     - Hanya owner_pusat atau pemegang izin 'atur_pengaturan' yang boleh menyimpan.
--     - Isolasi penyewa terjamin via penyewa_saya().
--  4. Optimistic Concurrency Control:
--     - Penolakan benturan edit simultan dengan kode P0001 bila versi_lama tidak cocok.
--  5. Jejak Audit Kekal:
--     - Setiap perubahan mencatat baris riwayat di public.catatan_audit dengan
--       aksi 'ubah_operasional_resto' berisi nilai_lama dan nilai_baru.
-- ============================================================================

-- 1. Pastikan komentar kolom operasional terdokumentasi rapi
comment on column public.pengaturan.pajak_pb1_persen is
  'Tarif Pajak Restoran / PB1 dalam persen (0 - 100). Dihitung dari subtotal setelah diskon (ART-3).';
comment on column public.pengaturan.service_persen is
  'Tarif Service Charge dalam persen (0 - 100). Dihitung dari subtotal setelah diskon (ART-3).';
comment on column public.pengaturan.pembulatan is
  'Aturan pembulatan total tagihan akhir: none, 100, 500, atau 1000 rupiah.';
comment on column public.pengaturan.cara_pesan is
  'Alur pemesanan aktif: kasir (kasir langsung), mandiri (self-order/QR), meja (pelayan), campur (kombinasi).';
comment on column public.pengaturan.header_struk is
  'Teks salam / pesan di bagian kepala struk belanja cetak kasir.';
comment on column public.pengaturan.footer_struk is
  'Teks catatan / penutup di bagian bawah struk belanja cetak kasir.';
comment on column public.pengaturan.jam_buka is
  'Teks keterangan jam operasional buka restoran yang ditampilkan di katalog publik dan struk.';

-- 2. RPC simpan_operasional
create or replace function public.simpan_operasional(
  p_pajak_pb1_persen numeric default null,
  p_service_persen   numeric default null,
  p_pembulatan       text default null,
  p_cara_pesan       text default null,
  p_jam_buka         text default null,
  p_header_struk     text default null,
  p_footer_struk     text default null,
  p_tumpuk_diskon    boolean default null,
  p_versi_lama       timestamptz default null
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_uid            uuid;
  v_penyewa_id     uuid;
  v_peran          text;
  v_pengaturan     public.pengaturan%rowtype;
  v_versi_baru     timestamptz;
  v_pajak_final    numeric(5, 2);
  v_service_final  numeric(5, 2);
  v_bulat_final    text;
  v_cara_final     text;
  v_jam_final      text;
  v_header_final   text;
  v_footer_final   text;
  v_tumpuk_final   boolean;
begin
  -- 1. Verifikasi otentikasi
  v_uid := auth.uid();
  if v_uid is null then
    raise exception 'Tidak diautentikasi.' using errcode = '42501';
  end if;

  v_penyewa_id := (select public.penyewa_saya());
  if v_penyewa_id is null then
    raise exception 'Penyewa tidak ditemukan.' using errcode = '42501';
  end if;

  v_peran := (select public.peran_saya());

  -- 2. Verifikasi otorisasi: owner_pusat atau memiliki izin atur_pengaturan
  if v_peran <> 'owner_pusat' and not public.boleh('atur_pengaturan') then
    raise exception 'Anda tidak memiliki wewenang untuk mengubah pengaturan resto.'
      using errcode = '42501';
  end if;

  -- 3. Kunci baris pengaturan penyewa untuk update aman
  select * into v_pengaturan
    from public.pengaturan
   where penyewa_id = v_penyewa_id
   for update;

  if v_pengaturan.penyewa_id is null then
    raise exception 'Baris pengaturan tidak ditemukan.' using errcode = 'P0002';
  end if;

  -- 4. Optimistic locking: tolak jika versi lama yang dikirim tidak cocok
  if p_versi_lama is not null and v_pengaturan.versi_pengaturan is not null then
    if v_pengaturan.versi_pengaturan <> p_versi_lama then
      raise exception 'Data pengaturan sudah diubah oleh pengguna lain. Silakan muat ulang halaman.'
        using errcode = 'P0001';
    end if;
  end if;

  -- 5. Validasi ketat batas tarif pajak PB1 (0% s/d 100%)
  if p_pajak_pb1_persen is not null then
    if p_pajak_pb1_persen < 0 or p_pajak_pb1_persen > 100 then
      raise exception 'Persentase pajak PB1 harus di antara 0%% dan 100%%.'
        using errcode = '22023';
    end if;
    v_pajak_final := round(p_pajak_pb1_persen::numeric, 2);
  else
    v_pajak_final := v_pengaturan.pajak_pb1_persen;
  end if;

  -- 6. Validasi ketat batas service charge (0% s/d 100%)
  if p_service_persen is not null then
    if p_service_persen < 0 or p_service_persen > 100 then
      raise exception 'Persentase service charge harus di antara 0%% dan 100%%.'
        using errcode = '22023';
    end if;
    v_service_final := round(p_service_persen::numeric, 2);
  else
    v_service_final := v_pengaturan.service_persen;
  end if;

  -- 7. Validasi aturan pembulatan
  if p_pembulatan is not null then
    if p_pembulatan not in ('none', '100', '500', '1000') then
      raise exception 'Aturan pembulatan tidak sah.' using errcode = '22023';
    end if;
    v_bulat_final := p_pembulatan;
  else
    v_bulat_final := v_pengaturan.pembulatan;
  end if;

  -- 8. Validasi pilihan alur cara pesan
  if p_cara_pesan is not null then
    if p_cara_pesan not in ('kasir', 'mandiri', 'meja', 'campur') then
      raise exception 'Pilihan alur cara pesan tidak sah.' using errcode = '22023';
    end if;
    v_cara_final := p_cara_pesan;
  else
    v_cara_final := v_pengaturan.cara_pesan;
  end if;

  -- 9. Batas panjang teks wajar
  if p_jam_buka is not null then
    if length(trim(p_jam_buka)) > 200 then
      raise exception 'Keterangan jam buka maksimal 200 karakter.' using errcode = '22023';
    end if;
    v_jam_final := trim(p_jam_buka);
  else
    v_jam_final := coalesce(v_pengaturan.jam_buka, '');
  end if;

  if p_header_struk is not null then
    if length(p_header_struk) > 500 then
      raise exception 'Teks header struk maksimal 500 karakter.' using errcode = '22023';
    end if;
    v_header_final := p_header_struk;
  else
    v_header_final := coalesce(v_pengaturan.header_struk, '');
  end if;

  if p_footer_struk is not null then
    if length(p_footer_struk) > 500 then
      raise exception 'Teks footer struk maksimal 500 karakter.' using errcode = '22023';
    end if;
    v_footer_final := p_footer_struk;
  else
    v_footer_final := coalesce(v_pengaturan.footer_struk, '');
  end if;

  if p_tumpuk_diskon is not null then
    v_tumpuk_final := p_tumpuk_diskon;
  else
    v_tumpuk_final := v_pengaturan.tumpuk_diskon;
  end if;

  v_versi_baru := clock_timestamp();

  -- 10. Update tabel pengaturan
  update public.pengaturan
     set pajak_pb1_persen          = v_pajak_final,
         service_persen            = v_service_final,
         pembulatan                = v_bulat_final,
         cara_pesan                = v_cara_final,
         jam_buka                  = v_jam_final,
         header_struk              = v_header_final,
         footer_struk              = v_footer_final,
         tumpuk_diskon             = v_tumpuk_final,
         diubah_oleh               = v_uid,
         diubah_pada               = now(),
         versi_pengaturan          = v_versi_baru
   where penyewa_id = v_penyewa_id;

  -- 11. Catat ke jejak audit kekal
  insert into public.catatan_audit (
    penyewa_id,
    pelaku_id,
    aksi,
    entitas,
    entitas_id,
    nilai_lama,
    nilai_baru
  ) values (
    v_penyewa_id,
    v_uid,
    'ubah_operasional_resto',
    'pengaturan',
    v_penyewa_id,
    jsonb_build_object(
      'pajak_pb1_persen', v_pengaturan.pajak_pb1_persen,
      'service_persen', v_pengaturan.service_persen,
      'pembulatan', v_pengaturan.pembulatan,
      'cara_pesan', v_pengaturan.cara_pesan,
      'jam_buka', coalesce(v_pengaturan.jam_buka, ''),
      'header_struk', coalesce(v_pengaturan.header_struk, ''),
      'footer_struk', coalesce(v_pengaturan.footer_struk, ''),
      'tumpuk_diskon', v_pengaturan.tumpuk_diskon,
      'versi_pengaturan', v_pengaturan.versi_pengaturan
    ),
    jsonb_build_object(
      'pajak_pb1_persen', v_pajak_final,
      'service_persen', v_service_final,
      'pembulatan', v_bulat_final,
      'cara_pesan', v_cara_final,
      'jam_buka', v_jam_final,
      'header_struk', v_header_final,
      'footer_struk', v_footer_final,
      'tumpuk_diskon', v_tumpuk_final,
      'versi_pengaturan', v_versi_baru
    )
  );

  return jsonb_build_object(
    'berhasil', true,
    'kode', 'SUKSES',
    'pesan', 'Pengaturan operasional resto berhasil disimpan.',
    'versi_pengaturan', v_versi_baru,
    'data', jsonb_build_object(
      'pajak_pb1_persen', v_pajak_final,
      'service_persen', v_service_final,
      'pembulatan', v_bulat_final,
      'cara_pesan', v_cara_final,
      'jam_buka', v_jam_final,
      'header_struk', v_header_final,
      'footer_struk', v_footer_final,
      'tumpuk_diskon', v_tumpuk_final,
      'versi_pengaturan', v_versi_baru
    )
  );
end;
$$;

comment on function public.simpan_operasional(
  numeric, numeric, text, text, text, text, text, boolean, timestamptz
) is 'T9-03: Menyimpan konfigurasi operasional resto (pajak PB1, service charge, pembulatan, alur pesan, jam buka, struk) dengan kontrol versi dan jejak audit.';

revoke all on function public.simpan_operasional(
  numeric, numeric, text, text, text, text, text, boolean, timestamptz
) from public;

grant execute on function public.simpan_operasional(
  numeric, numeric, text, text, text, text, text, boolean, timestamptz
) to authenticated;

-- 3. RPC ambil_pengaturan_operasional
create or replace function public.ambil_pengaturan_operasional()
returns jsonb
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
  v_penyewa_id uuid;
  v_res        jsonb;
begin
  if auth.uid() is null then
    raise exception 'Tidak diautentikasi.' using errcode = '42501';
  end if;

  v_penyewa_id := (select public.penyewa_saya());
  if v_penyewa_id is null then
    raise exception 'Penyewa tidak ditemukan.' using errcode = '42501';
  end if;

  select jsonb_build_object(
    'penyewa_id', peng.penyewa_id,
    'pajak_pb1_persen', peng.pajak_pb1_persen,
    'service_persen', peng.service_persen,
    'pembulatan', peng.pembulatan,
    'cara_pesan', peng.cara_pesan,
    'jam_buka', coalesce(peng.jam_buka, ''),
    'header_struk', coalesce(peng.header_struk, ''),
    'footer_struk', coalesce(peng.footer_struk, ''),
    'tumpuk_diskon', peng.tumpuk_diskon,
    'versi_pengaturan', peng.versi_pengaturan
  ) into v_res
  from public.pengaturan peng
  where peng.penyewa_id = v_penyewa_id;

  return jsonb_build_object(
    'berhasil', true,
    'data', v_res
  );
end;
$$;

comment on function public.ambil_pengaturan_operasional() is
  'T9-03: Mengambil data konfigurasi operasional resto aktif untuk layar formulir pengaturan.';

revoke all on function public.ambil_pengaturan_operasional() from public;
grant execute on function public.ambil_pengaturan_operasional() to authenticated;
