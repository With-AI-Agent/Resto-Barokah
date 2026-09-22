# Keadaan Proyek (akar repo — dipakai bootstrap sesi baru oleh alat/lanjut-sesi.py)

STATUS: Fase 4 (KDS + Stok + anti-dobel) tuntas di kode & uji; lanjut = bukti manual Lee / e2e / kabel realtime / Fase 5

Rincian panjang di `docs/PROJECT_STATE.md`; rencana di `docs/ops/SIAP-LANJUT.md` §3.

- [x] Fase 1–3: fondasi, keamanan, kasir POS (CI hijau terbukti).
- [x] Fase 4 SQL: 0032/0033/0035/0036/0037 + tes anti_dobel (suite 78 lulus, mutasi 9/9 merah).
- [x] Fase 4 UI: KDS (LayarDapur/Bar/KartuPesanan/TombolHabis) + Stok/Opname (253 tes lulus).
- [x] T4-09: uji anti-dobel dua koneksi nyata terkalibrasi (alat/uji-konkuren.py).
- [ ] Bukti manual/visual Lee (T4-03 foto, uji dua perangkat T4-05, cabut-jaringan T4-10).
- [ ] Infra e2e Playwright — butuh keputusan Lee.
- [ ] Kabel data realtime untuk KDS & penanda habis.
- [ ] Fase 5: pembayaran multimode & tutup kasir/shift.
