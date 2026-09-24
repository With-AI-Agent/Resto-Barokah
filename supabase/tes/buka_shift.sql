-- ============================================================================
-- UJI BUKA SHIFT (T7-01, PRD M7, TECH_SPEC §4.3 & §9 ART-6)
--
-- Yang dibuktikan:
--   1. Pintu RPC aman: anon & peran tanpa hak (pelayan/dapur) ditolak.
--   2. Modal awal wajib: null atau negatif ditolak.
--   3. Cabang di luar wewenang/lintas penyewa ditolak.
--   4. Satu shift terbuka per kasir per cabang (DoD T7-01):
--      - shift pertama berhasil dibuka.
--      - shift kedua oleh kasir yang sama di cabang yang sama ditolak (SH-409).
--      - indeks unik parsial menjaga integritas bila ada balapan.
--   5. Tercatat siapa & kapan: dibuka_oleh & dibuka_pada tersimpan dari peladen.
--   6. Audit log terisi dan rantai hash tetap valid.
--   7. RLS mengisolasi data: kasir resto B tidak melihat shift resto A.
--   8. Trigger penjaga menolak penghapusan baris dan perubahan modal awal langsung.
-- ============================================================================

-- ---------------------------------------------------------------------------
-- 1. Tanpa autentikasi / anon ditolak
-- ---------------------------------------------------------------------------
select uji.klaim(null);
set local role anon;

select uji.harap_gagal_sebab(
  $$select public.buka_shift(100000, 'a1a1a1a1-0000-0000-0000-000000000001'::uuid)$$,
  'permission denied for function buka_shift',
  'Anon ditolak mengeksekusi buka_shift (ACL terpasang)'
);

reset role;

-- ---------------------------------------------------------------------------
-- 2. Peran tidak berwenang ditolak (pelayan / dapur)
-- ---------------------------------------------------------------------------
-- Dedi: pelayan di resto A
select uji.klaim('90000000-0000-0000-0000-000000000005');
set local role authenticated;

select uji.harap_gagal_sebab(
  $$select public.buka_shift(100000, 'a1a1a1a1-0000-0000-0000-000000000001'::uuid)$$,
  'Peran pelayan tidak berwenang membuka shift kasir',
  'Pelayan tidak boleh membuka shift kasir'
);

-- Sari: dapur di resto A
select uji.klaim('90000000-0000-0000-0000-000000000006');

select uji.harap_gagal_sebab(
  $$select public.buka_shift(100000, 'a1a1a1a1-0000-0000-0000-000000000002'::uuid)$$,
  'Peran dapur tidak berwenang membuka shift kasir',
  'Dapur tidak boleh membuka shift kasir'
);

reset role;

-- ---------------------------------------------------------------------------
-- 3. Validasi modal awal & cabang (Rina - Kasir A1)
-- ---------------------------------------------------------------------------
select uji.klaim('90000000-0000-0000-0000-000000000004');
set local role authenticated;

-- Modal awal null ditolak
select uji.harap_gagal_sebab(
  $$select public.buka_shift(null, 'a1a1a1a1-0000-0000-0000-000000000001'::uuid)$$,
  'Modal awal wajib diisi',
  'Modal awal null ditolak'
);

-- Modal awal negatif ditolak
select uji.harap_gagal_sebab(
  $$select public.buka_shift(-50000, 'a1a1a1a1-0000-0000-0000-000000000001'::uuid)$$,
  'Modal awal tidak boleh bernilai negatif',
  'Modal awal negatif ditolak'
);

-- Cabang milik resto lain (Warung Bandung) ditolak
select uji.harap_gagal_sebab(
  $$select public.buka_shift(100000, 'b1b1b1b1-0000-0000-0000-000000000001'::uuid)$$,
  'Cabang tidak ditemukan atau di luar wewenang Anda',
  'Cabang lintas penyewa ditolak'
);

-- ---------------------------------------------------------------------------
-- 4. Buka shift sukses: tercatat siapa, kapan, & modal awal
-- ---------------------------------------------------------------------------
do $$
declare
  v_res jsonb;
  v_shift_id uuid;
  v_baris record;
begin
  v_res := public.buka_shift(150000, 'a1a1a1a1-0000-0000-0000-000000000001'::uuid, 'Modal awal pagi');
  perform uji.harap((v_res->>'berhasil')::boolean = true, 'Buka shift pertama berhasil');
  perform uji.harap(v_res->>'kode' = 'SH-200', 'Kode balasan SH-200');
  perform uji.harap((v_res->>'modal_awal')::integer = 150000, 'Modal awal sesuai input');
  perform uji.harap(v_res->>'status' = 'terbuka', 'Status shift terbuka');

  v_shift_id := (v_res->>'shift_id')::uuid;
  perform uji.harap(v_shift_id is not null, 'ID shift diterbitkan');

  select * into v_baris from public.shift_kas where id = v_shift_id;
  perform uji.harap(v_baris.dibuka_oleh = auth.uid(), 'Siapa tercatat (dibuka_oleh = auth.uid())');
  perform uji.harap(v_baris.dibuka_pada is not null, 'Kapan tercatat (dibuka_pada tidak null)');
  perform uji.harap(v_baris.catatan = 'Modal awal pagi', 'Catatan pembukaan tersimpan');
end;
$$;

-- ---------------------------------------------------------------------------
-- 5. Aturan DoD: Satu shift terbuka per kasir per cabang (SH-409)
-- ---------------------------------------------------------------------------
select uji.harap_gagal_sebab(
  $$select public.buka_shift(100000, 'a1a1a1a1-0000-0000-0000-000000000001'::uuid)$$,
  'SH-409: Anda masih memiliki shift kasir yang aktif di cabang ini',
  'Mencegah membuka shift ganda di cabang yang sama selagi masih terbuka'
);

-- Bukti indeks unik parsial shift_kas_aktif_unik menolak duplikasi langsung
reset role;
select uji.harap_gagal_sebab(
  $$
  insert into public.shift_kas (
    penyewa_id, cabang_id, dibuka_oleh, modal_awal, status
  ) values (
    '11111111-1111-1111-1111-111111111111',
    'a1a1a1a1-0000-0000-0000-000000000001',
    '90000000-0000-0000-0000-000000000004',
    200000,
    'terbuka'
  );
  $$,
  'duplicate key value violates unique constraint "shift_kas_aktif_unik"',
  'Indeks parsial unik shift_kas_aktif_unik mencegah balapan shift ganda'
);

-- Kasir lain atau Admin di cabang yang sama BOLEH membuka shift tersendiri
select uji.klaim('90000000-0000-0000-0000-000000000003'); -- Admin Andi
set local role authenticated;

do $$
declare
  v_res jsonb;
begin
  v_res := public.buka_shift(200000, 'a1a1a1a1-0000-0000-0000-000000000001'::uuid, 'Shift supervisor');
  perform uji.harap((v_res->>'berhasil')::boolean = true, 'Pegawai lain boleh buka shift di cabang yang sama');
end;
$$;

reset role;

-- ---------------------------------------------------------------------------
-- 6. Jejak audit & integritas rantai hash
-- ---------------------------------------------------------------------------
do $$
declare
  v_hitung integer;
  v_valid boolean;
  v_pesan text;
begin
  select count(*) into v_hitung
    from public.catatan_audit
   where aksi = 'buka_shift'
     and entitas = 'shift_kas';
  perform uji.harap(v_hitung >= 2, 'Peristiwa buka shift tercatat di catatan_audit');

  select valid, pesan into v_valid, v_pesan
    from public.verifikasi_rantai_audit('11111111-1111-1111-1111-111111111111'::uuid);
  perform uji.harap(v_valid = true, 'Rantai audit penyewa A tetap valid setelah buka_shift: ' || coalesce(v_pesan, ''));
end;
$$;

-- ---------------------------------------------------------------------------
-- 7. RLS: Kasir Resto B tidak dapat melihat baris shift Resto A
-- ---------------------------------------------------------------------------
select uji.klaim('90000000-0000-0000-0000-000000000007'); -- Ujang (Warung Bandung)
set local role authenticated;

do $$
declare
  v_bocor integer;
begin
  select count(*) into v_bocor
    from public.shift_kas
   where penyewa_id = '11111111-1111-1111-1111-111111111111';
  perform uji.harap(v_bocor = 0, 'Kasir resto B tidak melihat shift milik resto A (RLS kedap)');
end;
$$;

reset role;

-- ---------------------------------------------------------------------------
-- 8. Pemicu penjaga: larangan DELETE dan penguncian modal awal langsung
-- ---------------------------------------------------------------------------
select uji.harap_gagal_sebab(
  $$delete from public.shift_kas where status = 'terbuka'$$,
  'Baris shift kas tidak boleh dihapus demi integritas jejak audit',
  'Pemicu mencegah penghapusan riwayat shift kas'
);

select uji.harap_gagal_sebab(
  $$update public.shift_kas set modal_awal = 999999 where status = 'terbuka'$$,
  'Modal awal tidak boleh diubah langsung',
  'Pemicu mencegah pengubahan modal awal langsung'
);

select uji.klaim(null);
