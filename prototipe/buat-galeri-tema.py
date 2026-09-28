#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
buat-galeri-tema.py — membuat 04-tema.html (galeri 10 tema berdampingan).

Kenapa pakai pembuat: 10 kartu tema isinya sama, cuma beda warna/huruf/gambar.
Kalau ditulis tangan, gampang ada yang kelewat atau salah tulis. Jalankan lagi
kalau daftar tema berubah:

    python3 buat-galeri-tema.py
"""
import os

BASE = os.path.dirname(os.path.abspath(__file__))

TEMAS = [
    dict(kode="terang", nama="Terang Bersih", sifat="Untuk siang hari, paling aman & paling jelas",
         jenis="Aksen hijau daun, kartu putih bersih, sudut 14 px",
         fontdisplay="Outfit", fontbody="Work Sans", lencana="Buka sekarang",
         judul="Makan enak, tak perlu nunggu lama.",
         hero="hero-warung.jpg", c1="nasi-goreng.jpg", c2="es-teh.jpg",
         m1=("Nasi Goreng Spesial", "25.000"), m2=("Es Teh Manis", "6.000")),
    dict(kode="hangat", nama="Hangat Kedai", sifat="Hangat seperti kedai kayu, enak dibaca lama",
         jenis="Kertas krem, huruf serif hangat, sudut 18 px",
         fontdisplay="Lora", fontbody="Work Sans", lencana="Buka · 09.00–21.00",
         judul="Rasa rumah, setiap hari.",
         hero="interior.jpg", c1="mie-ayam.jpg", c2="kopi-susu.jpg",
         m1=("Mie Ayam Bakso", "20.000"), m2=("Kopi Susu Gula Aren", "18.000")),
    dict(kode="gelap", nama="Gelap Dapur", sifat="Nyaman untuk shift malam, hemat mata",
         jenis="Latar arang, aksen kuning, cahaya lembut (glow)",
         fontdisplay="Outfit", fontbody="Work Sans", lencana="Buka sampai 23.00",
         judul="Dapur tetap hidup malam ini.",
         hero="ayam-geprek.jpg", c1="sate.jpg", c2="es-kelapa.jpg",
         m1=("Sate Ayam Madura", "28.000"), m2=("Es Kelapa Muda", "12.000")),
    dict(kode="kontras", nama="Kontras Tinggi", sifat="Untuk yang matanya sudah tua atau layar kena matahari",
         jenis="Hitam-putih murni, garis 2 px, sudut 4 px, tanpa blur",
         fontdisplay="huruf sistem", fontbody="huruf sistem", lencana="TANPA BAYANGAN",
         judul="Cepat, jelas, tanpa ragu.",
         hero="sate.jpg", c1="nasi-goreng.jpg", c2="es-teh.jpg",
         m1=("Nasi Goreng Spesial", "25.000"), m2=("Es Teh Manis", "6.000")),
    dict(kode="bara", nama="Bara Panggang", sifat="Seperti poster grill — meniru gambar kirimanmu",
         jenis="Huruf kapital raksasa, arang + emas, sudut 16 px",
         fontdisplay="Big Shoulders", fontbody="Instrument Sans", lencana="BARU · PANGGANG",
         judul="BARA PANGGANG SEPANJANG MALAM",
         hero="banner-kedai.jpg", c1="ayam-geprek.jpg", c2="pisang-goreng.jpg",
         m1=("Ayam Geprek Bakar", "22.000"), m2=("Pisang Goreng (3 pcs)", "12.000")),
    dict(kode="vintage", nama="Vintage Klasik", sifat="Rasa warung zaman dulu, kertas tua",
         jenis="Kertas tua berbintik, marun, sudut 7 px",
         fontdisplay="Arsenal SC", fontbody="Crimson Pro", lencana="RESEP SEJAK 1998",
         judul="Sejak 1998, resep keluarga.",
         hero="kopi-susu.jpg", c1="mie-ayam.jpg", c2="pisang-goreng.jpg",
         m1=("Mie Ayam Bakso", "20.000"), m2=("Pisang Goreng (3 pcs)", "12.000")),
    dict(kode="alam", nama="Alam Hijau", sifat="Sejuk, daun, tenang — enak untuk kafe taman",
         jenis="Latar embun, pola daun samar, sudut 22 px",
         fontdisplay="Gloock", fontbody="Work Sans", lencana="SAYUR SEGAR",
         judul="Segar dari kebun kami.",
         hero="salad.jpg", c1="nasi-goreng.jpg", c2="es-kelapa.jpg",
         m1=("Gado-gado Segar", "20.000"), m2=("Es Kelapa Muda", "12.000")),
    dict(kode="tropis", nama="Tropis Segar", sifat="Ceria, pantai, cocok untuk es & minuman",
         jenis="Biru laut, pola gelombang, sudut 16 px",
         fontdisplay="Outfit", fontbody="Work Sans", lencana="DINGIN & SEGAR",
         judul="Dingin, manis, menyegarkan.",
         hero="es-kelapa.jpg", c1="es-teh.jpg", c2="sate.jpg",
         m1=("Es Kelapa Muda", "12.000"), m2=("Es Teh Manis", "6.000")),
    dict(kode="pastel", nama="Pastel Manis", sifat="Lembut & ramah anak — cocok kue dan dessert",
         jenis="Merah muda, bayangan ganda (offset), sudut 22 px",
         fontdisplay="Bricolage Grotesque", fontbody="Outfit", lencana="BARU DIPANGGANG",
         judul="Manis untuk hari manis.",
         hero="dessert.jpg", c1="pisang-goreng.jpg", c2="es-teh.jpg",
         m1=("Kue Coklat Potong", "32.000"), m2=("Pisang Goreng (3 pcs)", "12.000")),
    dict(kode="etnik", nama="Etnik Nusantara", sifat="Batik & tanah liat, kuat untuk rumah makan daerah",
         jenis="Terakota, pola batik samar, sudut 12 px",
         fontdisplay="Young Serif", fontbody="Work Sans", lencana="MASAKAN NUSANTARA",
         judul="Rasa nusantara, satu meja.",
         hero="hero-warung.jpg", c1="sate.jpg", c2="kopi-susu.jpg",
         m1=("Sate Ayam Madura", "28.000"), m2=("Kopi Susu Gula Aren", "18.000")),
]

KARTU = """      <article class="tema-kartu naik" data-theme="{kode}" id="tema-{kode}">
        <div class="kelapa">
          <div>
            <span class="label">{nomor} &middot; data-theme="{kode}"</span>
            <h3 style="font-size:var(--t-6);margin:2px 0 0">{nama}</h3>
            <p class="small muted" style="margin:2px 0 0">{sifat}</p>
          </div>
          <div class="sw-3" aria-hidden="true">
            <i style="background:var(--bg)"></i><i style="background:var(--surface)"></i><i style="background:var(--accent)"></i><i style="background:var(--text)"></i>
          </div>
        </div>

        <div class="isi">
          <div class="mini-telepon">
            <div class="hero">
              <img src="aset/{hero}" alt="">
              <span class="selubung"></span>
              <div class="isi">
                <span class="chip chip-kaca">{lencana}</span>
                <h4 class="display">{judul}</h4>
                <div class="bawah">
                  <span class="btn btn-primary btn-sm">Pesan</span>
                  <span class="small" style="color:rgba(255,255,255,.85)">★ 4,8</span>
                </div>
              </div>
            </div>

            <div class="geser" style="padding:0 10px 12px">
              <article class="kartu-makan">
                <div class="foto"><img src="aset/{c1}" alt=""><span class="lencana">Terlaris</span></div>
                <div class="isi">
                  <span class="nm">{m1n}</span>
                  <div class="between"><span class="pr num">Rp {m1h}</span><span class="tombol-tambah" style="width:32px;height:32px;font-size:18px" aria-hidden="true">+</span></div>
                </div>
              </article>
              <article class="kartu-makan">
                <div class="foto"><img src="aset/{c2}" alt=""></div>
                <div class="isi">
                  <span class="nm">{m2n}</span>
                  <div class="between"><span class="pr num">Rp {m2h}</span><span class="tombol-tambah" style="width:32px;height:32px;font-size:18px" aria-hidden="true">+</span></div>
                </div>
              </article>
            </div>

            <div class="row" style="padding:0 12px 10px;gap:6px;flex-wrap:wrap">
              <span class="chip chip-accent">Promo</span>
              <span class="chip chip-success"><i class="dot"></i>Buka</span>
              <span class="chip chip-warn">Stok terbatas</span>
            </div>
            <div class="row" style="padding:0 12px 14px;gap:8px">
              <span class="btn btn-sm" style="flex:1;justify-content:center">Detail</span>
              <span class="btn btn-sm btn-primary" style="flex:1;justify-content:center">Tambah</span>
            </div>
          </div>

          <div class="palet" aria-label="Warna tema {nama}">
            <div style="background:var(--bg)"><span data-hex="--bg"></span></div>
            <div style="background:var(--surface)"><span data-hex="--surface"></span></div>
            <div style="background:var(--surface-2)"><span data-hex="--surface-2"></span></div>
            <div style="background:var(--accent)"><span data-hex="--accent"></span></div>
            <div style="background:var(--text)"><span data-hex="--text"></span></div>
          </div>

          <p class="small muted" style="margin:0">
            <strong>{jenis}.</strong> Huruf judul <em>{fontdisplay}</em>, huruf isi <em>{fontbody}</em> —
            semua huruf ikut tersimpan di aplikasi, jadi tetap tampil sama walau internet mati.
          </p>
        </div>

        <div class="catatan">
          <div class="between wrap-row" style="gap:var(--s-3)">
            <span class="small">Sudah diperiksa: 13 pasang warna per tema, kontras ≥ 4,5 : 1</span>
            <button class="btn btn-primary btn-sm" type="button" data-set-tema="{kode}" data-ke-atas>Pakai tema ini</button>
          </div>
        </div>
      </article>
"""

HALAMAN = """<!DOCTYPE html>
<html lang="id" data-theme="terang" data-density="nyaman">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>10 Tema — Contoh Tampilan</title>
<link rel="stylesheet" href="css/tokens.css">
</head>
<body>

<div class="demo-bar">
  <span><strong>CONTOH TAMPILAN</strong> &middot; Kedai Oasis &middot; 10 tema, tinggal tekan (data contoh)</span>
  <span class="center small"><a href="index.html">beranda</a> &middot; <a href="01-laporan.html">laporan</a> &middot; <a href="02-kasir.html">kasir</a> &middot; <a href="03-katalog.html">katalog</a></span>
</div>

<div class="bilah-atas">
  <div class="wrap between wrap-row" style="padding:14px 0">
    <div>
      <span class="aksen">Cukup tekan, tidak perlu ubah kode</span>
      <h1 style="font-size:var(--t-8)">10 Tema</h1>
      <p class="small muted">Semua tema di bawah ini hidup: tekan <strong>Pakai tema ini</strong> dan seluruh contoh ikut berubah.</p>
    </div>
    <div class="row wrap-row" style="align-items:center">
      <div class="segmen" role="group" aria-label="Kerapatan tampilan">
        <button type="button" data-set-rapat="padat">Padat</button>
        <button type="button" data-set-rapat="nyaman">Nyaman</button>
      </div>
      <span data-pemilih-tema></span>
    </div>
  </div>
</div>

<main class="wrap">
  <section class="bagian">
    <div class="judul-bagian">
      <div>
        <span class="label">Cara ganti tema</span>
        <h2>3 langkah, selesai</h2>
      </div>
      <span class="small muted">Pilihan tema tersimpan di perangkat itu (di aplikasi asli tersimpan di pengaturan resto)</span>
    </div>
    <div class="kpi-3">
      <div class="card naik">
        <span class="nomer">1</span>
        <h3 style="font-size:var(--t-6)">Tekan tombol Tema</h3>
        <p class="small muted">Ada di kanan atas setiap halaman. Muncul daftar 10 tema dengan contoh warnanya.</p>
      </div>
      <div class="card naik">
        <span class="nomer">2</span>
        <h3 style="font-size:var(--t-6)">Pilih yang paling cocok</h3>
        <p class="small muted">Warna, huruf, bayangan, dan bentuk sudut ikut berubah seketika — tidak ada yang perlu diatur lagi.</p>
      </div>
      <div class="card naik">
        <span class="nomer">3</span>
        <h3 style="font-size:var(--t-6)">Simpan sendiri</h3>
        <p class="small muted">Pilihan langsung tersimpan. Buka lagi besok, temanya masih sama.</p>
      </div>
    </div>
  </section>

  <section class="bagian">
    <div class="judul-bagian">
      <div>
        <span class="aksen">Sepuluh suasana, satu aplikasi</span>
        <h2>Semua tema berdampingan</h2>
      </div>
      <span class="small muted">Contoh di bawah = tampilan halaman pelanggan di HP</span>
    </div>

    <div class="galeri">
@@KARTU@@    </div>
  </section>

  <section class="bagian card lega naik">
    <div class="card-head">
      <div>
        <span class="label">Tentang huruf</span>
        <h2 style="font-size:var(--t-7)">13 huruf, semuanya boleh dipakai gratis</h2>
      </div>
      <span class="chip chip-accent">tersimpan di dalam aplikasi</span>
    </div>
    <p class="small muted" style="max-width:78ch">
      Huruf diambil dari kumpulan skill desain yang kamu pasang, semuanya berlisensi terbuka (SIL Open Font License)
      sehingga aman dipakai untuk usaha. Berkasnya ikut tersimpan di aplikasi (bukan diambil dari internet),
      jadi tampilan tetap sama walau koneksi lambat atau putus.
    </p>
    <div class="row wrap-row" style="gap:var(--s-4);align-items:stretch">
      <div class="card grow" style="min-width:260px">
        <span class="label">Judul — tebal, berani</span>
        <div class="display" style="font-size:var(--t-8);line-height:1.05;margin-top:6px">Nasi Goreng</div>
        <p class="small muted" style="margin:6px 0 0">Outfit &middot; Lora &middot; Big Shoulders &middot; Arsenal SC &middot; Gloock &middot; Young Serif &middot; Bricolage Grotesque &middot; National Park</p>
      </div>
      <div class="card grow" style="min-width:260px">
        <span class="label">Isi bacaan — enak dibaca lama</span>
        <div style="font-size:var(--t-6);line-height:1.6;margin-top:6px">Rasa rumahan, harga bersahabat, porsi jujur.</div>
        <p class="small muted" style="margin:6px 0 0">Work Sans &middot; Instrument Sans &middot; Crimson Pro &middot; Outfit</p>
      </div>
      <div class="card grow" style="min-width:260px">
        <span class="label">Angka &amp; struk — tidak salah baca</span>
        <div class="mono" style="font-size:var(--t-7);margin-top:6px">Rp 1.250.000</div>
        <p class="small muted" style="margin:6px 0 0">Mono — dipakai khusus untuk uang, jam, dan nomor struk supaya angka 0 dan 8 tidak tertukar.</p>
      </div>
    </div>
  </section>

  <section class="bagian">
    <div class="judul-bagian">
      <div>
        <span class="aksen">Yang sengaja kami jaga</span>
        <h2>Catatan jujur</h2>
      </div>
    </div>
    <div class="kpi-3">
      <div class="card">
        <span class="label">Keterbacaan</span>
        <p class="small muted">Setiap tema diuji otomatis: 13 pasang warna (teks di atas latar, tombol, label, peringatan) harus lolos kontras minimal 4,5 : 1. Tema yang gagal tidak boleh masuk daftar.</p>
      </div>
      <div class="card">
        <span class="label">Kenyamanan sentuh</span>
        <p class="small muted">Semua tombol minimal 44 px dan ada reaksi saat ditekan. Pengguna yang mengaktifkan “kurangi gerakan” di HP-nya tetap dapat tampilan tanpa animasi.</p>
      </div>
      <div class="card">
        <span class="label">Cakupan</span>
        <p class="small muted">Tema hanya mengubah tampilan — aturan bisnis (pajak, service, void, voucher) tidak ikut berubah. Semua angka di halaman ini contoh.</p>
      </div>
    </div>
    <p class="small muted center mt-24">Sudah puas? <a href="index.html">kembali ke beranda contoh</a> &middot; atau lihat <a href="01-laporan.html">laporan</a>, <a href="02-kasir.html">kasir</a>, dan <a href="03-katalog.html">katalog pelanggan</a>.</p>
  </section>
</main>

<script src="js/ui.js"></script>
<script>
/* Isi label warna (hex) di setiap kartu tema, dibaca dari warna aslinya.
   Kalau JS mati, labelnya cuma kosong — kotak warnanya tetap tampil. */
(function () {
  function keHex(v) {
    v = (v || '').trim();
    var m = v.match(/^rgba?\\(([^)]+)\\)$/);
    if (!m) return v.toUpperCase();
    var p = m[1].split(',').map(function (x) { return parseFloat(x); });
    return '#' + p.slice(0, 3).map(function (n) {
      var s = Math.round(n).toString(16).toUpperCase();
      return s.length < 2 ? '0' + s : s;
    }).join('');
  }
  document.querySelectorAll('.tema-kartu').forEach(function (kartu) {
    var cs = getComputedStyle(kartu);
    kartu.querySelectorAll('[data-hex]').forEach(function (el) {
      el.textContent = keHex(cs.getPropertyValue(el.getAttribute('data-hex')));
    });
  });
})();
</script>
</body>
</html>
"""


def main():
    potongan = []
    for i, t in enumerate(TEMAS, start=1):
        potongan.append(KARTU.format(
            kode=t['kode'], nomor='%02d' % i, nama=t['nama'], sifat=t['sifat'],
            jenis=t['jenis'], fontdisplay=t['fontdisplay'], fontbody=t['fontbody'],
            lencana=t['lencana'], judul=t['judul'], hero=t['hero'], c1=t['c1'], c2=t['c2'],
            m1n=t['m1'][0], m1h=t['m1'][1], m2n=t['m2'][0], m2h=t['m2'][1],
        ))
    html = HALAMAN.replace('@@KARTU@@', ''.join(potongan))
    with open(os.path.join(BASE, '04-tema.html'), 'w', encoding='utf-8') as f:
        f.write(html)
    print('04-tema.html dibuat:', len(html), 'huruf,', len(TEMAS), 'tema')


if __name__ == '__main__':
    main()
