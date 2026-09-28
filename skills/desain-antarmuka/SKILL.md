# Kemampuan: Desain Antarmuka — Kerapatan, Penutupan Panel, Tepi Gulir

> **Kenapa berkas ini ada.** Permintaan pemilik, 2026-09-17 (pesan ke-31):
> *"kamu harus pelajari ilmu desain dan visual dari internet dan simpan hasil yang kamu pelajari itu
> untuk menjadi kemampuan. Dan ingat, jangan hanya disimpan, tapi juga harus digunakan sebagai
> kemampuan."*
>
> Isinya: tiga pelajaran yang **dipelajari dari sumber, dipakai memperbaiki tiga cacat nyata**, dan
> **dikunci oleh pemeriksa otomatis** supaya tidak luntur. Setiap aturan di bawah menyebut sumber
> dan alat yang menegakkannya di repo ini.

Dipakai saat: mengubah komponen tampilan, kerapatan (Nyaman/Padat), panel/popover, daftar yang bisa
digeser, atau ketika pemilik melaporkan "kurang rapi / tidak berfungsi / terasa aneh".

---

## 1. Kerapatan (Compact / Padat) — yang mengecil adalah TINGGI, bukan LEBAR

**Apa yang salah di proyek ini sampai 2026-09-17** (dilaporkan pemilik tiga kali, terakhir:
*"blok-bloknya hanya berkurang panjangnya, tapi lebar (atas-bawah) nya ga ikut mengecil"*):
mode Padat hanya menyempitkan tepi **kiri-kanan** (`padding:0 var(--s-3)`) sementara **tinggi**
(`min-height`) tidak pernah turun → proporsi blok jadi aneh dan terasa "ga pas".

**Aturan yang benar** (dari sistem desain besar, bukan selera):

1. **Kerapatan menurunkan tinggi komponen.** Material 3: *"Higher density is typically applied by
   decreasing the top and bottom padding or overall height by 4dp"* — dan skala densitasnya
   berjalan -1, -2, -3 dengan tiap langkah = **4 px**.
2. **Jarak kiri-kanan DI DALAM komponen tidak dikurangi.** Material 3 (Grids & spacing → Density):
   *"Each increment also decreases the height of a component by 4px. But it does not affect the
   horizontal spacing within the component."*
3. **Kalau tinggi dikurangi, jarak mendatar justru boleh ditambah** supaya teks tidak terjepit:
   *"Increase horizontal spacing as you decrease vertical spacing."* (Material, "Using Material
   Density on the Web").
4. **Ukuran huruf tidak ikut berubah.** Material 3: *"Text size shouldn't change as the container
   size scales."*
5. **Lantai sasaran sentuh dijaga.** Material: *"No matter the density, all touch targets should be
   at least 48px"*; kalau blok tampak lebih kecil, daerah sentuhnya diperluas (mis. `::after`).
   Proyek ini memakai **lantai 44 px** (WCAG 2.5.5 AAA & Apple HIG 44 pt) — dikunci
   `aplikasi/alat/uji-kontras.py` dan uji `src/gaya/kerapatan-css.test.ts`.
6. **Popover (daftar pilihan/tema) dipadatkan HANYA sedikit.** Cloudscape: mode padat *"is not fully
   applied to elements with limited target space such as dropdowns in select, multiselect,
   autosuggest, date picker"*. Di proyek ini baris daftar tema turun 56 → 48 px, tidak lebih.
7. **Pengguna memilih kerapatannya sendiri** (Material: *"People should be able to opt in to dense
   layouts"*), dan tombol pemilihnya sendiri tetap berukuran sasaran normal.

**Cara menerapkan di kode ini:** token dipisah **per sumbu** di `prototipe/css/tokens.css`:
`--tinggi-kendali`, `--tinggi-baris-tema`, `--pad-v-blok`, `--baris-isi` (boleh turun di Padat) vs
`--pad-h-blok`, `--pad-h-kendali`, `--pad-h-sel` (dikunci sama dengan mode Nyaman).
Berkas aplikasi `aplikasi/src/gaya/token/tema.css` wajib **salinan apa adanya** dari sumber prototipe.

**Ditegakkan oleh:** `aplikasi/alat/periksa-kerapatan.py` (menolak kalau token tinggi tidak turun,
kalau token lebar ikut menyempit, atau kalau ukuran huruf diubah) + `uji-kontras.py` + uji kaskade
`src/gaya/kerapatan-css.test.ts`.

---

## 2. Panel/popover: cara menutup yang lazim (Esc · klik di luar · fokus keluar)

**Apa yang salah di proyek ini sampai 2026-09-17:** panel tema memakai `<details>/<summary>` bawaan
peramban. Pemilik melaporkan: *"aku harus klik lagi tombol 'Ganti tema (10)'"* — dan itu memang
perilaku bawaan: **`<details>` tidak menutup saat Esc ditekan** (panduan Evinced: *"Native disclosures
do not automatically close when the Escape key is pressed"*).

**Aturan yang benar** (WAI-ARIA Authoring Practices, pola *disclosure* + panduan menu aksesibel):

1. **Esc menutup panel DAN mengembalikan fokus ke tombol pembukanya.** APG: *"If a dropdown is open,
   pressing Escape closes it and sets focus on the button that controls that dropdown."* Tanpa
   pengembalian fokus, pengguna papan tik "terdampar".
2. **Klik/ketuk di luar menutup** — pada kasus ini **fokus tidak dirampas** (panduan menu aksesibel:
   *"Clicking outside closes the menu without stealing focus back"*).
3. **Fokus pindah keluar panel juga menutup.** APG: *"Moving focus out of the navigation region also
   closes an open dropdown."*
4. **Keadaan diumumkan**: `aria-expanded="true|false"` di tombol + `aria-controls` ke id panel, dan
   panel `aria-labelledby` ke tombolnya. (Panduan Evinced; APG tabel atribut.)
5. **Pilih satu pilihan → panel menutup**, fokus pulang ke tombol.
6. **Jangan pakai `role="menu"` untuk daftar yang bukan menu perintah** — untuk daftar pilihan/link,
   pola *disclosure* lebih benar (daftar menu aksesibel: *"For a dropdown of destinations, the better
   answer is not to use the menu pattern at all"*).

**Diterapkan di:** `aplikasi/src/komponen/PemilihRingkas.tsx` (dipakai layar contoh) dan pasangannya
di sumber desain `prototipe/js/ui.js` — keduanya wajib berperilaku sama.
**Ditegakkan oleh:** uji `src/komponen/PemilihRingkas.test.tsx` (8 kasus, jsdom) +
`aplikasi/alat/periksa-antarmuka.py` (menolak kalau salah satu jalan menutup hilang).

---

## 3. Tepi area gulir: isi memudar, bukan terpotong mentah

**Apa yang salah sampai 2026-09-17:** saat daftar tema digeser, isinya "nabrak" tepat di ujung kotak
(pemilik: *"bagusnya kan ga nabrak… ada semacam blur/feather… bikin dia kepotongnya ga nabrak ujungnya"*
— pemilik menambahkan *"aku juga ga yakin, bisa jadi itu cuma perasaan aku"*; **ternyata bukan
perasaan**: ini pola baku yang disebut *scroll fade / scroll edge effect*).

**Aturan yang benar** (riset 2025–2026: utilitas `scroll-fade` shadcn/ui, `scroll-mask`
twilson.net yang dipakai argos-ci, artikel codefronts & panelui):

1. **Pakai `mask-image` (gradien), bukan lapisan warna.** Maska memudarkan isi elemennya sehingga
   ikut tema/latar apa pun tanpa perlu tahu warnanya; lapisan warna harus dicocokkan manual ke latar
   (dan gagal di latar kaca/gambar).
2. **Maska dipasang pada elemen yang MENGGESER, bukan pada wadahnya.** Kalau dipasang di wadah,
   justru **bordir, sudut, dan bayangan panelnya sendiri** yang ikut luntur. Karena itu di proyek ini
   panel dipecah: `.picker-panel` (latar/bordir/sudut) + `.picker-daftar` (yang menggeser + maska).
3. **Pudarnya mengikuti posisi gulir, jangan "berbohong".** Pakai `animation-timeline: scroll(...)`
   (tanpa JavaScript): ujung atas baru memudar setelah digeser, ujung bawah berhenti memudar begitu
   sudah di dasar, dan **kalau isinya tidak melebihi kotak, tidak ada pudar sama sekali**.
   Peramban lama (tanpa animasi-terkait-gulir) dapat cadangan **hanya ujung bawah** — jujur, karena
   posisi gulir tidak bisa diketahui tanpa dukungan itu.
4. **Sisakan bantalan agar cincin fokus tidak ikut luntur.** Maska memotong apa pun di ujung,
   termasuk cincin fokus baris pertama/terakhir (catatan gotcha pada artikel maska gulir).
5. **Ukuran pudar sebagian dari tinggi wadah** (bukan angka tetap), supaya panel pendek dan panel
   tinggi sama enaknya dilihat (shadcn: 12% tinggi wadah, dibatasi ±40 px).

**Diterapkan di:** `prototipe/css/tokens.css` blok `.picker-daftar` (+ `@keyframes pudar-gulir`,
`@supports (animation-timeline: scroll(self block))`, cadangan `@supports not (...)`).
**Ditegakkan oleh:** uji `src/gaya/kerapatan-css.test.ts` ("daftar tema punya JEJAK PUDAR…") +
`aplikasi/alat/periksa-antarmuka.py` (menolak kalau maska pindah ke wadah ber-bordir).

---

## Sumber (dibaca 2026-09-17)

- Material 3, *Grids & spacing → Density* — <https://m3.material.io/foundations/layout/grids-spacing/density>
  (tiap langkah -4 dp; tidak mengubah jarak mendatar; huruf tidak berubah; sasaran sentuh 48 px; pengguna memilih).
- Material, *Using Material Density on the Web* — <https://m3.material.io/blog/material-density-web>
  (*"Increase horizontal spacing as you decrease vertical spacing"*; rumus tinggi komponen).
- Cloudscape, *Content density* — <https://cloudscape.design/foundation/visual-foundation/content-density/>
  (padat = padding vertikal + jarak; popover tidak dipadatkan penuh).
- W3C WAI-ARIA APG, *Disclosure (navigation) example* — <https://www.w3.org/WAI/ARIA/apg/patterns/disclosure/examples/disclosure-navigation/>
  (Esc menutup & fokus kembali; fokus keluar region = menutup; `aria-expanded`/`aria-controls`).
- Evinced, *Disclosure* — <https://knowledge.evinced.com/components/disclosure>
  (*"Native disclosures do not automatically close when the Escape key is pressed"*).
- accessibility.build, *Accessible Menu & Menu Button Guide* — <https://accessibility.build/guides/accessible-menu>
  (klik di luar menutup tanpa merebut fokus; pilihan daftar tujuan → pakai pola disclosure, bukan `role="menu"`).
- shadcn/ui, *scroll-fade* — <https://ui.shadcn.com/docs/utils/scroll-fade> (maska, `animation-timeline: scroll(self y)`, tanpa JS).
- codefronts, *Gradient Scroll Mask Fade* & argos-ci PR #2584 (adaptasi `scroll-mask` twilson.net)
  — maska di elemen penggeser, cadangan statis untuk peramban lama, cincin fokus di ujung.

## Daftar periksa singkat sebelum mengubah tampilan

- [ ] Kalau menyentuh kerapatan: yang turun harus **tinggi/atas-bawah**; kiri-kanan tetap; huruf tetap; lantai sentuh 44 px.
- [ ] Kalau membuat panel/popover: Esc, klik di luar, fokus keluar, pilih-lalu-tutup, `aria-expanded`/`aria-controls` — semuanya ada.
- [ ] Kalau ada daftar yang bisa digeser: maska pudar di elemen penggeser (bukan wadahnya), mengikuti gulir, ada bantalan fokus.
- [ ] Jalankan: `python3 aplikasi/alat/periksa-kerapatan.py --uji-diri`, `python3 aplikasi/alat/periksa-antarmuka.py --uji-diri`, dan `bash aplikasi/alat/periksa-semua.sh`.
