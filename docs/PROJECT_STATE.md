# Keadaan Proyek

- [x] Fase 1–3: fondasi, keamanan, kasir POS (CI hijau terbukti).
- [x] Fase 4 SQL: 0032/0033/0035/0036/0037 + tes anti_dobel (suite 78 lulus, mutasi 9/9 merah).
- [x] Fase 4 UI: KDS (LayarDapur/Bar/KartuPesanan/TombolHabis) + Stok/Opname (253 tes lulus).
- [x] T4-09: uji anti-dobel dua koneksi nyata terkalibrasi (alat/uji-konkuren.py).
- [ ] Bukti manual/visual Lee (T4-03 foto, uji dua perangkat manual T4-05, cabut-jaringan T4-10).
- [x] Fase 5: T5-01 layar Bayar + kasir tersambung · T5-02 RPC `bayar_pesanan` (0039) · T5-03 struk
      (pajak & service terpisah) · T5-04 diskon (bukti pagar 0019: `diskon_tumpuk.sql` + mutasi 5/5 MERAH).
- [ ] Fase 5 sisa: struk termal, buka/tutup shift (lihat `docs/ROADMAP.md`).
- [ ] Infra e2e Playwright (`aplikasi/uji/e2e/dapur.spec.ts` — rencana, belum dibuat) — **T-026**, Chromium tidak bisa diunduh di ruang kerja agent; butuh keputusan Lee.
- [ ] Kabel data realtime (langganan perubahan) untuk KDS & penanda habis.
- [ ] Fase 5: pembayaran multimode & tutup kasir/shift.
