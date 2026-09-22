-- ============================================================================
-- 0027 — Optimasi InitPlan pada kebijakan RLS (T1-30)
-- Menutup utang InitPlan: seluruh pemanggilan helper identitas/peran/izin
-- tanpa argumen berkorelasi (penyewa_saya, peran_saya, cabang_saya, auth.uid, boleh)
-- dibungkus (select ...) agar perencana PostgreSQL mengevaluasinya sekali per query
-- (InitPlan), bukan dievaluasi per baris yang dipindai.
-- ============================================================================

-- --------------------------------------------------------------------- cabang
drop policy if exists cabang_pilih on public.cabang;
create policy cabang_pilih on public.cabang
  for select to authenticated
  using (penyewa_id = (select public.penyewa_saya()));

drop policy if exists cabang_tambah on public.cabang;
create policy cabang_tambah on public.cabang
  for insert to authenticated
  with check (
    penyewa_id = (select public.penyewa_saya())
    and (select public.peran_saya()) = 'owner_pusat'
  );

drop policy if exists cabang_ubah on public.cabang;
create policy cabang_ubah on public.cabang
  for update to authenticated
  using (
    penyewa_id = (select public.penyewa_saya())
    and (select public.peran_saya()) = 'owner_pusat'
  )
  with check (penyewa_id = (select public.penyewa_saya()));

-- -------------------------------------------------------------- catatan_audit
drop policy if exists catatan_audit_pilih on public.catatan_audit;
create policy catatan_audit_pilih on public.catatan_audit
  for select to authenticated
  using (
    penyewa_id = (select public.penyewa_saya())
    and (select public.boleh('kelola_pegawai'))
  );

-- ----------------------------------------------------------- diskon_transaksi
drop policy if exists diskon_transaksi_tambah on public.diskon_transaksi;
create policy diskon_transaksi_tambah on public.diskon_transaksi
  for insert to authenticated
  with check (
    public.pesanan_sepenyewa(pesanan_id)
    and (select public.peran_saya()) in ('owner_pusat', 'admin_cabang', 'kasir')
  );

-- ----------------------------------------------------------------------- izin
drop policy if exists izin_pilih on public.izin;
create policy izin_pilih on public.izin
  for select to authenticated
  using (
    pengguna_id = (select auth.uid())
    or (
      public.sepenyewa(pengguna_id)
      and (select public.peran_saya()) = 'owner_pusat'
    )
    or (
      public.sepenyewa(pengguna_id)
      and (select public.peran_saya()) = 'admin_cabang'
      and exists (
        select 1
          from public.pengguna_cabang pc
         where pc.pengguna_id = public.izin.pengguna_id
           and pc.cabang_id = (select public.cabang_saya())
      )
    )
  );

-- ----------------------------------------------------------------- izin_peran
drop policy if exists izin_peran_pilih on public.izin_peran;
create policy izin_peran_pilih on public.izin_peran
  for select to authenticated
  using (penyewa_id = (select public.penyewa_saya()));

drop policy if exists izin_peran_tambah on public.izin_peran;
create policy izin_peran_tambah on public.izin_peran
  for insert to authenticated
  with check (
    penyewa_id = (select public.penyewa_saya())
    and (select public.peran_saya()) = 'owner_pusat'
  );

drop policy if exists izin_peran_ubah on public.izin_peran;
create policy izin_peran_ubah on public.izin_peran
  for update to authenticated
  using (
    penyewa_id = (select public.penyewa_saya())
    and (select public.peran_saya()) = 'owner_pusat'
  )
  with check (penyewa_id = (select public.penyewa_saya()));

-- -------------------------------------------------------------- kategori_menu
drop policy if exists kategori_menu_pilih on public.kategori_menu;
create policy kategori_menu_pilih on public.kategori_menu
  for select to authenticated
  using (penyewa_id = (select public.penyewa_saya()));

drop policy if exists kategori_menu_ubah on public.kategori_menu;
create policy kategori_menu_ubah on public.kategori_menu
  for all to authenticated
  using (
    penyewa_id = (select public.penyewa_saya())
    and (select public.peran_saya()) in ('owner_pusat', 'admin_cabang')
  )
  with check (
    penyewa_id = (select public.penyewa_saya())
    and (select public.peran_saya()) in ('owner_pusat', 'admin_cabang')
  );

-- ----------------------------------------------------------------------- meja
drop policy if exists meja_hapus on public.meja;
create policy meja_hapus on public.meja
  for delete to authenticated
  using (
    public.cabang_pantau_saya(cabang_id)
    and (select public.peran_saya()) in ('owner_pusat', 'admin_cabang')
  );

drop policy if exists meja_tambah on public.meja;
create policy meja_tambah on public.meja
  for insert to authenticated
  with check (
    public.cabang_pantau_saya(cabang_id)
    and (select public.peran_saya()) in ('owner_pusat', 'admin_cabang')
  );

drop policy if exists meja_ubah_status on public.meja;
create policy meja_ubah_status on public.meja
  for update to authenticated
  using (
    public.cabang_pantau_saya(cabang_id)
    and (select public.peran_saya()) in ('owner_pusat', 'admin_cabang', 'kasir', 'pelayan')
  )
  with check (
    public.cabang_pantau_saya(cabang_id)
    and (select public.peran_saya()) in ('owner_pusat', 'admin_cabang', 'kasir', 'pelayan')
  );

-- ---------------------------------------------------------------- menu_cabang
drop policy if exists menu_cabang_ubah on public.menu_cabang;
create policy menu_cabang_ubah on public.menu_cabang
  for all to authenticated
  using (
    public.cabang_pantau_saya(cabang_id)
    and (
      (select public.peran_saya()) in ('owner_pusat', 'admin_cabang')
      or (select public.boleh('ubah_stok'))
    )
  )
  with check (
    public.cabang_pantau_saya(cabang_id)
    and (
      (select public.peran_saya()) in ('owner_pusat', 'admin_cabang')
      or (select public.boleh('ubah_stok'))
    )
  );

-- ------------------------------------------------------------------ menu_item
drop policy if exists menu_item_pilih on public.menu_item;
create policy menu_item_pilih on public.menu_item
  for select to authenticated
  using (penyewa_id = (select public.penyewa_saya()));

drop policy if exists menu_item_ubah on public.menu_item;
create policy menu_item_ubah on public.menu_item
  for all to authenticated
  using (
    penyewa_id = (select public.penyewa_saya())
    and (select public.peran_saya()) in ('owner_pusat', 'admin_cabang')
  )
  with check (
    penyewa_id = (select public.penyewa_saya())
    and (select public.peran_saya()) in ('owner_pusat', 'admin_cabang')
  );

-- -------------------------------------------------------------- menu_tambahan
drop policy if exists menu_tambahan_pilih on public.menu_tambahan;
create policy menu_tambahan_pilih on public.menu_tambahan
  for select to authenticated
  using (penyewa_id = (select public.penyewa_saya()));

drop policy if exists menu_tambahan_ubah on public.menu_tambahan;
create policy menu_tambahan_ubah on public.menu_tambahan
  for all to authenticated
  using (
    penyewa_id = (select public.penyewa_saya())
    and (select public.peran_saya()) in ('owner_pusat', 'admin_cabang')
  )
  with check (
    penyewa_id = (select public.penyewa_saya())
    and (select public.peran_saya()) in ('owner_pusat', 'admin_cabang')
  );

-- ---------------------------------------------------------------- menu_varian
drop policy if exists menu_varian_ubah on public.menu_varian;
create policy menu_varian_ubah on public.menu_varian
  for all to authenticated
  using (
    (select public.peran_saya()) in ('owner_pusat', 'admin_cabang')
    and public.menu_sepenyewa(menu_item_id)
  )
  with check (
    (select public.peran_saya()) in ('owner_pusat', 'admin_cabang')
    and public.menu_sepenyewa(menu_item_id)
  );

-- --------------------------------------------------------------- metode_bayar
drop policy if exists metode_bayar_pilih on public.metode_bayar;
create policy metode_bayar_pilih on public.metode_bayar
  for select to authenticated
  using (penyewa_id = (select public.penyewa_saya()));

drop policy if exists metode_bayar_ubah on public.metode_bayar;
create policy metode_bayar_ubah on public.metode_bayar
  for all to authenticated
  using (
    penyewa_id = (select public.penyewa_saya())
    and (select public.peran_saya()) in ('owner_pusat', 'admin_cabang')
  )
  with check (
    penyewa_id = (select public.penyewa_saya())
    and (select public.peran_saya()) in ('owner_pusat', 'admin_cabang')
  );

-- ----------------------------------------------------------------- pembatalan
drop policy if exists pembatalan_tambah on public.pembatalan;
create policy pembatalan_tambah on public.pembatalan
  for insert to authenticated
  with check (
    public.pesanan_sepenyewa(pesanan_id)
    and (select public.peran_saya()) in ('owner_pusat', 'admin_cabang', 'kasir', 'pelayan')
  );

-- ----------------------------------------------------------------- pembayaran
drop policy if exists pembayaran_tambah on public.pembayaran;
create policy pembayaran_tambah on public.pembayaran
  for insert to authenticated
  with check (
    public.pesanan_sepenyewa(pesanan_id)
    and (select public.peran_saya()) in ('owner_pusat', 'admin_cabang', 'kasir')
  );

-- ----------------------------------------------------------------- pengaturan
drop policy if exists pengaturan_pilih on public.pengaturan;
create policy pengaturan_pilih on public.pengaturan
  for select to authenticated
  using (penyewa_id = (select public.penyewa_saya()));

drop policy if exists pengaturan_ubah on public.pengaturan;
create policy pengaturan_ubah on public.pengaturan
  for update to authenticated
  using (
    penyewa_id = (select public.penyewa_saya())
    and (select public.peran_saya()) = 'owner_pusat'
  )
  with check (penyewa_id = (select public.penyewa_saya()));

-- ------------------------------------------------------------------- pengguna
drop policy if exists pengguna_pilih on public.pengguna;
create policy pengguna_pilih on public.pengguna
  for select to authenticated
  using (
    id = (select auth.uid())
    or (
      penyewa_id = (select public.penyewa_saya())
      and (select public.peran_saya()) = 'owner_pusat'
    )
    or (
      penyewa_id = (select public.penyewa_saya())
      and (select public.peran_saya()) = 'admin_cabang'
      and exists (
        select 1
          from public.pengguna_cabang pc
         where pc.pengguna_id = public.pengguna.id
           and pc.cabang_id = (select public.cabang_saya())
      )
    )
  );

-- ------------------------------------------------------------ pengguna_cabang
drop policy if exists pengguna_cabang_pilih on public.pengguna_cabang;
create policy pengguna_cabang_pilih on public.pengguna_cabang
  for select to authenticated
  using (
    pengguna_id = (select auth.uid())
    or cabang_id in (select public.cabang_ids_saya())
  );

-- -------------------------------------------------------------------- penyewa
drop policy if exists penyewa_pilih on public.penyewa;
create policy penyewa_pilih on public.penyewa
  for select to authenticated
  using (id = (select public.penyewa_saya()));

-- ------------------------------------------------------------------ perangkat
drop policy if exists perangkat_pilih on public.perangkat;
create policy perangkat_pilih on public.perangkat
  for select to authenticated
  using (
    penyewa_id = (select public.penyewa_saya())
    and (select public.boleh('kelola_pegawai'))
  );

-- -------------------------------------------------------------- percobaan_pin
drop policy if exists percobaan_pin_pilih on public.percobaan_pin;
create policy percobaan_pin_pilih on public.percobaan_pin
  for select to authenticated
  using (
    pengguna_id = (select auth.uid())
    or (
      public.sepenyewa(pengguna_id)
      and (select public.boleh('kelola_pegawai'))
    )
  );

-- ------------------------------------------------------- percobaan_simpan_pin
drop policy if exists percobaan_simpan_pin_korban on public.percobaan_simpan_pin;
create policy percobaan_simpan_pin_korban on public.percobaan_simpan_pin
  for select to authenticated
  using (target_id = (select auth.uid()));

-- -------------------------------------------------------------------- pesanan
drop policy if exists pesanan_pilih on public.pesanan;
create policy pesanan_pilih on public.pesanan
  for select to authenticated
  using (
    penyewa_id = (select public.penyewa_saya())
    and public.cabang_pantau_saya(cabang_id)
  );

drop policy if exists pesanan_tambah on public.pesanan;
create policy pesanan_tambah on public.pesanan
  for insert to authenticated
  with check (
    penyewa_id = (select public.penyewa_saya())
    and public.cabang_pantau_saya(cabang_id)
    and (select public.peran_saya()) in ('owner_pusat', 'admin_cabang', 'kasir', 'pelayan')
  );

drop policy if exists pesanan_ubah on public.pesanan;
create policy pesanan_ubah on public.pesanan
  for update to authenticated
  using (
    penyewa_id = (select public.penyewa_saya())
    and public.cabang_pantau_saya(cabang_id)
    and (select public.peran_saya()) in ('owner_pusat', 'admin_cabang', 'kasir', 'pelayan')
  )
  with check (
    penyewa_id = (select public.penyewa_saya())
    and public.cabang_pantau_saya(cabang_id)
    and (select public.peran_saya()) in ('owner_pusat', 'admin_cabang', 'kasir', 'pelayan')
  );

-- --------------------------------------------------------------- pesanan_item
drop policy if exists pesanan_item_dapur on public.pesanan_item;
create policy pesanan_item_dapur on public.pesanan_item
  for update to authenticated
  using (
    public.pesanan_sepenyewa(pesanan_id)
    and (select public.peran_saya()) = 'dapur'
  )
  with check (
    public.pesanan_sepenyewa(pesanan_id)
    and (select public.peran_saya()) = 'dapur'
  );

drop policy if exists pesanan_item_tambah on public.pesanan_item;
create policy pesanan_item_tambah on public.pesanan_item
  for insert to authenticated
  with check (
    public.pesanan_sepenyewa(pesanan_id)
    and (select public.peran_saya()) in ('owner_pusat', 'admin_cabang', 'kasir', 'pelayan')
  );

drop policy if exists pesanan_item_ubah on public.pesanan_item;
create policy pesanan_item_ubah on public.pesanan_item
  for update to authenticated
  using (
    public.pesanan_sepenyewa(pesanan_id)
    and (select public.peran_saya()) in ('owner_pusat', 'admin_cabang', 'kasir', 'pelayan')
  )
  with check (
    public.pesanan_sepenyewa(pesanan_id)
    and (select public.peran_saya()) in ('owner_pusat', 'admin_cabang', 'kasir', 'pelayan')
  );

-- ----------------------------------------------------------------- stok_bahan
drop policy if exists stok_bahan_pilih on public.stok_bahan;
create policy stok_bahan_pilih on public.stok_bahan
  for select to authenticated
  using (penyewa_id = (select public.penyewa_saya()));

drop policy if exists stok_bahan_tambah on public.stok_bahan;
create policy stok_bahan_tambah on public.stok_bahan
  for insert to authenticated
  with check (
    penyewa_id = (select public.penyewa_saya())
    and (select public.peran_saya()) in ('owner_pusat', 'admin_cabang')
  );

drop policy if exists stok_bahan_ubah on public.stok_bahan;
create policy stok_bahan_ubah on public.stok_bahan
  for update to authenticated
  using (
    penyewa_id = (select public.penyewa_saya())
    and (select public.boleh('ubah_stok'))
  )
  with check (
    penyewa_id = (select public.penyewa_saya())
    and (select public.boleh('ubah_stok'))
  );

-- ------------------------------------------------------------ stok_pergerakan
drop policy if exists stok_pergerakan_pilih on public.stok_pergerakan;
create policy stok_pergerakan_pilih on public.stok_pergerakan
  for select to authenticated
  using (penyewa_id = (select public.penyewa_saya()));

drop policy if exists stok_pergerakan_tambah on public.stok_pergerakan;
create policy stok_pergerakan_tambah on public.stok_pergerakan
  for insert to authenticated
  with check (
    penyewa_id = (select public.penyewa_saya())
    and (select public.boleh('ubah_stok'))
  );
