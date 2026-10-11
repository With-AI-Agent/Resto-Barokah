-- ============================================================================
-- PROBE HAKIM H-P-1B-00.3 (bagian baris) — siapa yang TERCATAT menyetujui
-- pasangan Dedi (pelayan) x perangkat hasil kode resmi?
-- Dasar: docs/KEAMANAN.md:58 (persetujuan owner/admin untuk pasangan baru).
-- Cara jalan: node alat/uji-sql.mjs docs/uji/pemeriksaan/PMB-1/bukti/H-P-1B-00.3-probe-lintas-baris.sql
-- Harapan desain: 0 baris persetujuan dengan penyetuju = owner (owner tak pernah
-- menyetujui pasangan ini). GAGAL = cacat hidup (baris ditulis otomatis, penyetuju owner).
-- ============================================================================

delete from public.percobaan_pin;
insert into public.kredensial_pin (pengguna_id, pin_hash)
values ('90000000-0000-0000-0000-000000000005', crypt('246810', gen_salt('bf')))
on conflict (pengguna_id) do update set pin_hash = excluded.pin_hash;

insert into public.kode_pendaftaran_perangkat (penyewa_id, cabang_id, kode, nama_perangkat, jenis, dibuat_oleh)
values ('11111111-1111-1111-1111-111111111111', 'a1a1a1a1-0000-0000-0000-000000000001',
        'LINTASBARIS', 'Tablet Lintas Baris', 'pos', '90000000-0000-0000-0000-000000000002');

select uji.klaim(null);
set local role anon;
select uji.harap(
  (public.daftarkan_perangkat_dengan_kode('LINTASBARIS', 'kunci-lintas-baris-0123456789')->>'berhasil')::boolean,
  'H-P-1B-00.3 baris: pendaftaran kode resmi berhasil'
);
reset role;
create temp table probe_baris_dev as
  select id from public.perangkat where nama = 'Tablet Lintas Baris' limit 1;
grant select on probe_baris_dev to anon;

-- Login Dedi dari kursi anon (hasilnya sengaja tidak diasersi di sini; efek tulisnya yang diuji).
set local role anon;
select (public.verifikasi_pin_perangkat('pelayan.a@contoh.test', '246810',
         (select id from probe_baris_dev), 'Tablet Lintas Baris', null))->>'kode' as kode_login_dedi;
reset role;

-- CACAT NYATA: tidak boleh ada baris persetujuan Dedi x perangkat yang disetujui owner.
select uji.sama(
  (select count(*)::int from public.persetujuan_perangkat pp
    where pp.pengguna_id = '90000000-0000-0000-0000-000000000005'
      and pp.perangkat_id = (select id from probe_baris_dev)
      and pp.disetujui_oleh = '90000000-0000-0000-0000-000000000002'),
  0,
  'CACAT NYATA H-P-1B-00.3: baris persetujuan Dedi x perangkat kode resmi tertulis dengan penyetuju = owner (tanpa persetujuan owner)'
);
