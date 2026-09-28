/* ============================================================================
   Resto Barokah — Papan mockup (mockup sheet) untuk beberapa tema
   Hasil: docs/desain/mockup/*.png   (dipakai sebagai bahan periksa pemilik)

   Cara pakai:  node prototipe/alat/mockup.js           (semua papan)
                node prototipe/alat/mockup.js bara      (satu papan saja)
   ============================================================================ */
const { fs, path, createCanvas, loadImage, ASET, KELUAR, TEMA, hex, rr, lapis, glow, tulis,
  bungkus, bulat, bintang, foto, taburan, lebarTeks, tulisPotong } = require('./gambar.js');

/* ------------------------------ pemuatan foto ------------------------------ */
let FOTO = {};
async function muatFoto() {
  const nama = ['nasi-goreng', 'ayam-geprek', 'mie-ayam', 'kopi-susu', 'es-teh', 'pisang-goreng', 'banner-kedai'];
  for (const n of nama) FOTO[n] = await loadImage(path.join(ASET, n + '.jpg'));
}

/* ======================== POTONGAN YANG DIPAKAI ULANG ====================== */

// Tombol pil dengan lingkaran panah (pola P16 Grill & Co.)
function tombolPil(x, cx, cy, teks, t, { lebar = 168, tinggi = 46, panah = true } = {}) {
  x.save();
  x.shadowColor = hex(t['--accent'], 0.45); x.shadowBlur = 26; x.shadowOffsetY = 8;
  x.fillStyle = hex(t['--accent']);
  rr.call(x, cx, cy, lebar, tinggi, tinggi / 2); x.fill();
  x.restore();
  tulis(x, teks, 15, { huruf: t.fBody === 'LoraBold' ? 'WorkSansBold' : 'WorkSansBold', x: cx + 20, y: cy + tinggi / 2 + 5, warna: hex(t['--accent-contrast']), lebar: 1.1 });
  if (panah) {
    bulat(x, cx + lebar - 30, cy + tinggi / 2, 17, hex(t['--accent-contrast']));
    x.strokeStyle = hex(t['--accent']); x.lineWidth = 2.2;
    x.beginPath(); x.moveTo(cx + lebar - 36, cy + tinggi / 2); x.lineTo(cx + lebar - 25, cy + tinggi / 2);
    x.moveTo(cx + lebar - 29, cy + tinggi / 2 - 4); x.lineTo(cx + lebar - 25, cy + tinggi / 2); x.lineTo(cx + lebar - 29, cy + tinggi / 2 + 4);
    x.stroke();
  }
}

// Label kecil HURUF BESAR (pola "BESTSELLER")
function label(x, teks, cx, cy, t, { warnaLat = null } = {}) {
  x.font = `700 10.5px WorkSansBold`;
  const w = x.measureText(teks).width + 22;
  x.fillStyle = warnaLat || hex(t['--accent']);
  rr.call(x, cx, cy, w, 22, 11); x.fill();
  tulis(x, teks, 10.5, { huruf: 'WorkSansBold', x: cx + 11, y: cy + 15, warna: warnaLat ? hex(t['--accent-contrast']) : hex(t['--accent-contrast']), lebar: 0.9 });
  return w;
}

// Kartu menu (foto + label + nama + keterangan + bintang + harga + tombol bulat +)
function kartuMenu(x, t, img, dx, dy, w, { nama, ket, harga, ulasan, lencana, tinggiFoto = 128 } = {}) {
  const h = tinggiFoto + 108;
  lapis(x, () => { x.fillStyle = hex(t['--surface']); rr.call(x, dx, dy, w, h, 18); x.fill(); },
    { blur: 26, warna: hex('#000', 0.18), geserY: 10 });
  x.strokeStyle = hex(t['--border'], 0.9); x.lineWidth = 1; rr.call(x, dx, dy, w, h, 18); x.stroke();
  foto(x, img, dx, dy, w, tinggiFoto, 18);
  if (lencana) label(x, lencana, dx + 12, dy + 12, t);
  let y = dy + tinggiFoto + 24;
  tulis(x, nama, 15, { huruf: 'WorkSansBold', x: dx + 14, y, warna: hex(t['--text']) });
  y += 20;
  const baris = bungkus(x, ket, w - 28, 'WorkSansReg', 11.5);
  for (const b of baris.slice(0, 2)) { tulis(x, b, 11.5, { x: dx + 14, y, warna: hex(t['--text-muted']) }); y += 15; }
  y += 4;
  bintang(x, dx + 18, y - 4, 6.5, hex(t['--warn']));
  tulis(x, ulasan, 11, { x: dx + 28, y, warna: hex(t['--text-muted']) });
  y += 22;
  tulis(x, harga, 17, { huruf: 'OutfitBold', x: dx + 14, y: y + 4, warna: hex(t['--text']) });
  const cxp = dx + w - 26, cyp = y - 6;
  lapis(x, () => { bulat(x, cxp, cyp, 19, hex(t['--accent'])); }, { blur: 18, warna: hex(t['--accent'], 0.45), geserY: 5 });
  x.strokeStyle = hex(t['--accent-contrast']); x.lineWidth = 2.4;
  x.beginPath(); x.moveTo(cxp - 6, cyp); x.lineTo(cxp + 6, cyp); x.moveTo(cxp, cyp - 6); x.lineTo(cxp, cyp + 6); x.stroke();
}

// Tab kategori (pola P32: pil berisi ikon + label, aktif bergaris tepi aksen)
function tabKategori(x, t, dx, dy, w, h, teks, aktif) {
  x.fillStyle = aktif ? hex(t['--accent-soft']) : hex(t['--surface']);
  rr.call(x, dx, dy, w, h, 14); x.fill();
  x.strokeStyle = aktif ? hex(t['--accent']) : hex(t['--border'], 0.9);
  x.lineWidth = aktif ? 2 : 1; rr.call(x, dx, dy, w, h, 14); x.stroke();
  bulat(x, dx + 26, dy + h / 2, 14, hex(t['--accent-soft']));
  x.strokeStyle = hex(t['--accent']); x.lineWidth = 1.6;
  const icy = dy + h / 2;
  if (teks === 'Makanan') { x.beginPath(); x.arc(dx + 26, icy + 1, 6, Math.PI, 0); x.stroke(); x.beginPath(); x.moveTo(dx + 20, icy + 1); x.lineTo(dx + 32, icy + 1); x.stroke(); }
  else if (teks === 'Minuman') { x.beginPath(); x.moveTo(dx + 21, icy - 6); x.lineTo(dx + 31, icy - 6); x.lineTo(dx + 30, icy + 7); x.lineTo(dx + 22, icy + 7); x.closePath(); x.stroke(); }
  else if (teks === 'Camilan') { x.beginPath(); x.arc(dx + 26, icy, 5.5, 0, Math.PI * 2); x.stroke(); }
  else if (teks === 'Paket') { x.beginPath(); x.rect(dx + 21, icy - 6, 10, 6); x.stroke(); x.beginPath(); x.rect(dx + 21, icy + 1, 10, 6); x.stroke(); }
  else { x.beginPath(); x.moveTo(dx + 20, icy); x.lineTo(dx + 26, icy - 6); x.lineTo(dx + 32, icy); x.lineTo(dx + 26, icy + 7); x.closePath(); x.stroke(); }
  tulis(x, teks, 13.5, { huruf: 'WorkSansBold', x: dx + 48, y: dy + h / 2 + 5, warna: hex(t['--text']) });
}

/* ============================== LAYAR: KATALOG ============================= */
function layarKatalog(x, t) {
  const W = 400, H = 880;
  x.save();
  x.fillStyle = hex(t['--bg']); x.fillRect(0, 0, W, H);
  // hiasan latar sesuai tema
  const motif = t['--bg-pattern'] && t['--bg-pattern'].includes('circle') ? 'lingkaran'
    : (t['--bg-pattern'] || '').includes('path') ? 'daun' : 'tidak';
  if (motif !== 'tidak') taburan(x, W, H, t['--accent'], motif);
  x.restore();

  // ---- bilah atas mengambang (kaca: tembus pandang + garis tipis + bayangan) ----
  x.save();
  lapis(x, () => { x.fillStyle = hex(t['--surface'], 0.88); rr.call(x, 10, 10, W - 20, 58, 20); x.fill(); },
    { blur: 20, warna: hex('#000', 0.22), geserY: 6 });
  x.strokeStyle = hex(t['--border'], 0.75); x.lineWidth = 1; rr.call(x, 10, 10, W - 20, 58, 20); x.stroke();
  x.restore();
  bulat(x, 38, 39, 15, hex(t['--accent']));
  tulis(x, 'KO', 12, { huruf: 'WorkSansBold', x: 30, y: 44, warna: hex(t['--accent-contrast']) });
  tulis(x, 'Kedai Oasis', 15.5, { huruf: 'WorkSansBold', x: 62, y: 37, warna: hex(t['--text']) });
  tulis(x, 'Buka · 09.00–21.00', 11, { x: 62, y: 52, warna: hex(t['--success']) });
  bulat(x, W - 44, 39, 17, hex(t['--surface-2']));
  x.strokeStyle = hex(t['--text']); x.lineWidth = 1.8; x.beginPath();
  x.arc(W - 47, 36, 6, 0, Math.PI * 1.7); x.stroke();
  x.beginPath(); x.moveTo(W - 42, 41); x.lineTo(W - 37, 46); x.stroke();
  bulat(x, W - 28, 24, 9, hex(t['--danger']));
  tulis(x, '2', 10, { huruf: 'WorkSansBold', x: W - 31, y: 27, warna: '#fff' });

  // ---- pencarian ----
  x.fillStyle = hex(t['--surface']); rr.call(x, 14, 80, W - 28, 44, 14); x.fill();
  x.strokeStyle = hex(t['--border'], 0.9); x.lineWidth = 1; rr.call(x, 14, 80, W - 28, 44, 14); x.stroke();
  x.strokeStyle = hex(t['--text-muted']); x.lineWidth = 1.8;
  x.beginPath(); x.arc(36, 100, 6.5, 0, Math.PI * 2); x.stroke();
  x.beginPath(); x.moveTo(41, 105); x.lineTo(46, 110); x.stroke();
  tulis(x, 'Cari makanan atau minuman…', 12.5, { x: 56, y: 106, warna: hex(t['--text-muted']) });

  // ---- hero card (irama vertikal eksplisit supaya tidak ada yang bertumpuk) ----
  const hx = 14, hy = 132, hw = W - 28, hh = 232;
  x.save(); rr.call(x, hx, hy, hw, hh, 24); x.clip();
  foto(x, FOTO['banner-kedai'], hx, hy, hw, hh, 24);
  const sc = x.createLinearGradient(hx, hy + 30, hx, hy + hh);
  sc.addColorStop(0, 'rgba(0,0,0,.18)'); sc.addColorStop(1, 'rgba(0,0,0,.90)');
  x.fillStyle = sc; x.fillRect(hx, hy, hw, hh);
  x.restore();
  const pakaiBesar = (t['--head-transform'] || '').includes('uppercase');
  const fJud = pakaiBesar ? 40 : 30, fHar = pakaiBesar ? 40 : 30;
  tulis(x, 'Diskon Makan Berdua', 11, { huruf: 'WorkSansBold', x: hx + 20, y: hy + 26, warna: hex(t['--accent']) });
  tulis(x, pakaiBesar ? 'MAKAN BERDUA' : 'Makan Berdua', fJud,
    { huruf: t.fDisplay, x: hx + 20, y: hy + 26 + fJud * 1.20, warna: '#fff', lebar: pakaiBesar ? 0.4 : 0 });
  tulis(x, 'Rp 45.000', fHar, { huruf: t.fDisplay, x: hx + 20, y: hy + 26 + fJud * 1.20 + fHar * 1.25, warna: hex(t['--accent']), lebar: pakaiBesar ? 0.4 : 0 });
  tulis(x, 'Nasi Goreng Spesial + Es Teh ×2 · s/d 30 Sep', 11,
    { x: hx + 20, y: hy + 26 + fJud * 1.20 + fHar * 1.25 + 24, warna: 'rgba(255,255,255,.82)' });
  tombolPil(x, hx + 20, hy + hh - 62, 'PESAN', t, { lebar: 126, tinggi: 44 });
  bulat(x, hx + hw / 2 - 18, hy + hh - 12, 3.2, hex(t['--accent']));
  for (let i = 1; i < 4; i++) bulat(x, hx + hw / 2 - 18 + i * 12, hy + hh - 12, 3.2, 'rgba(255,255,255,.45)');

  // ---- kategori bulat (pola P16: yang aktif terisi penuh) ----
  const kategori = ['Makanan', 'Minuman', 'Camilan', 'Paket', 'Promo'];
  let cx = 42;
  kategori.forEach((k, i) => {
    const aktif = i === 0, cy = 402;
    if (aktif) lapis(x, () => { bulat(x, cx, cy, 27, hex(t['--accent'])); }, { blur: 20, warna: hex(t['--accent'], 0.5), geserY: 6 });
    else {
      bulat(x, cx, cy, 27, hex(t['--surface']));
      x.strokeStyle = hex(t['--border']); x.lineWidth = 1; x.beginPath(); x.arc(cx, cy, 27, 0, Math.PI * 2); x.stroke();
    }
    const ic = aktif ? hex(t['--accent-contrast']) : hex(t['--text']);
    x.strokeStyle = ic; x.lineWidth = 1.9;
    if (i === 0) { x.beginPath(); x.arc(cx, cy + 2, 10, Math.PI, 0); x.stroke(); x.beginPath(); x.moveTo(cx - 10, cy + 2); x.lineTo(cx + 10, cy + 2); x.stroke(); }
    if (i === 1) { x.beginPath(); x.moveTo(cx - 7, cy - 7); x.lineTo(cx + 7, cy - 7); x.lineTo(cx + 5, cy + 8); x.lineTo(cx - 5, cy + 8); x.closePath(); x.stroke(); }
    if (i === 2) { x.beginPath(); x.arc(cx, cy, 8, 0, Math.PI * 2); x.stroke(); }
    if (i === 3) { x.beginPath(); x.rect(cx - 8, cy - 8, 16, 7); x.stroke(); x.beginPath(); x.rect(cx - 8, cy + 1, 16, 7); x.stroke(); }
    if (i === 4) { x.beginPath(); x.moveTo(cx - 8, cy - 4); x.lineTo(cx, cy - 10); x.lineTo(cx + 8, cy - 4); x.lineTo(cx, cy + 9); x.closePath(); x.stroke(); }
    tulis(x, k, 11, { x: cx, y: cy + 44, warna: aktif ? hex(t['--text']) : hex(t['--text-muted']), huruf: 'WorkSansReg', tengah: true });
    cx += 79;
  });

  // ---- judul bagian ----
  tulis(x, 'Menu Favorit', 21, { huruf: t.fDisplay, x: 16, y: 480, warna: hex(t['--text']) });
  x.font = '700 11.5px WorkSansBold';
  tulis(x, 'Lihat semua →', 11.5, { huruf: 'WorkSansBold', x: W - 18 - x.measureText('Lihat semua →').width, y: 478, warna: hex(t['--accent']) });

  // ---- dua kartu menu ----
  const kw2 = (W - 40) / 2;
  kartuMenu(x, t, FOTO['nasi-goreng'], 14, 490, kw2,
    { nama: 'Nasi Goreng Spesial', ket: 'Telur, ayam, kerupuk & acar segar', harga: 'Rp 25.000', ulasan: '4,8 (1,2rb)', lencana: 'FAVORIT', tinggiFoto: 118 });
  kartuMenu(x, t, FOTO['ayam-geprek'], 14 + kw2 + 12, 490, kw2,
    { nama: 'Ayam Geprek', ket: 'Sambal bawang, lalapan, nasi hangat', harga: 'Rp 22.000', ulasan: '4,9 (856)', lencana: 'PEDAS', tinggiFoto: 118 });

  // ---- pita promo ringkas (tidak lagi bertabrakan dengan bilah keranjang) ----
  const px2 = 14, py2 = 722, pw2 = W - 28, ph2 = 56;
  lapis(x, () => { x.fillStyle = hex(t['--accent']); rr.call(x, px2, py2, pw2, ph2, 16); x.fill(); },
    { blur: 22, warna: hex(t['--accent'], 0.45), geserY: 8 });
  tulis(x, 'SPESIAL AKHIR PEKAN', 9.5, { huruf: 'WorkSansBold', x: px2 + 16, y: py2 + 22, warna: hex(t['--accent-contrast']), lebar: 1.3 });
  tulis(x, '20% OFF semua paket', 15, { huruf: t.fDisplay, x: px2 + 16, y: py2 + 44, warna: hex(t['--accent-contrast']) });
  bulat(x, px2 + pw2 - 36, py2 + ph2 / 2, 18, hex(t['--surface'], 0.9));
  x.strokeStyle = hex(t['--accent']); x.lineWidth = 2;
  x.beginPath(); x.moveTo(px2 + pw2 - 43, py2 + ph2 / 2); x.lineTo(px2 + pw2 - 29, py2 + ph2 / 2); x.moveTo(px2 + pw2 - 34, py2 + ph2 / 2 - 5); x.lineTo(px2 + pw2 - 29, py2 + ph2 / 2); x.lineTo(px2 + pw2 - 34, py2 + ph2 / 2 + 5); x.stroke();

  // ---- bilah keranjang mengambang (kaca + glow) ----
  const cy2 = 790;
  x.save();
  lapis(x, () => { x.fillStyle = hex(t['--surface'], 0.92); rr.call(x, 12, cy2, W - 24, 56, 20); x.fill(); },
    { blur: 28, warna: hex(t['--accent'], 0.32), geserY: 10 });
  x.strokeStyle = hex(t['--border'], 0.8); x.lineWidth = 1; rr.call(x, 12, cy2, W - 24, 56, 20); x.stroke();
  x.restore();
  bulat(x, 40, cy2 + 28, 14, hex(t['--accent-soft']));
  tulis(x, '3', 12, { huruf: 'WorkSansBold', x: 40, y: cy2 + 33, warna: hex(t['--accent']), tengah: true });
  tulis(x, 'Rp 81.600', 14, { huruf: 'WorkSansBold', x: 62, y: cy2 + 34, warna: hex(t['--text']) });
  tombolPil(x, W - 148, cy2 + 6, 'LIHAT', t, { lebar: 118, tinggi: 44, panah: false });

  // ---- bilah bawah dengan tombol tengah menonjol ----
  x.fillStyle = hex(t['--surface']); x.fillRect(0, H - 30, W, 30);
  x.fillStyle = hex(t['--border'], 0.8); x.fillRect(0, H - 30, W, 1);
  ['Beranda', 'Menu', 'Voucher', 'Pesanan'].forEach((n, i) => {
    const nx = 52 + i * 96; if (i >= 2) { }
  });
  lapis(x, () => { bulat(x, W / 2, H - 44, 26, hex(t['--accent'])); }, { blur: 20, warna: hex(t['--accent'], 0.5), geserY: 6 });
  x.strokeStyle = hex(t['--accent-contrast']); x.lineWidth = 2.4;
  x.beginPath(); x.moveTo(W / 2 - 7, H - 44); x.lineTo(W / 2 + 7, H - 44); x.moveTo(W / 2, H - 51); x.lineTo(W / 2, H - 37); x.stroke();
  [['Beranda', 52], ['Menu', 138], ['Voucher', W - 138], ['Pesanan', W - 52]].forEach(([n, nx]) => {
    x.strokeStyle = hex(t['--text-muted']); x.lineWidth = 1.6;
    x.beginPath(); x.arc(nx, H - 22, 5, 0, Math.PI * 2); x.stroke();
    tulis(x, n, 9.5, { x: nx, y: H - 8, warna: hex(t['--text-muted']), tengah: true });
  });
}

function kotakKacaPOS(x, t, dx, dy, w, h) {
  lapis(x, () => { x.fillStyle = hex(t['--surface'], 0.92); rr.call(x, dx, dy, w, h, 16); x.fill(); },
    { blur: 20, warna: hex('#000', 0.14), geserY: 7 });
  x.strokeStyle = hex(t['--border'], 0.8); x.lineWidth = 1; rr.call(x, dx, dy, w, h, 16); x.stroke();
}

/* ============================== LAYAR: KASIR ============================== */
function layarKasir(x, t) {
  const W = 1080, H = 668;
  x.save();
  x.fillStyle = hex(t['--bg']); x.fillRect(0, 0, W, H);
  if ((t['--bg-pattern'] || '').includes('path')) taburan(x, W, H, t['--accent'], 'daun');
  x.restore();

  // ---- rel kiri ----
  x.fillStyle = hex(t['--surface']); x.fillRect(0, 0, 86, H);
  x.fillStyle = hex(t['--border'], 0.8); x.fillRect(86, 0, 1, H);
  lapis(x, () => { x.fillStyle = hex(t['--accent']); rr.call(x, 19, 20, 48, 48, 16); x.fill(); }, { blur: 18, warna: hex(t['--accent'], 0.45), geserY: 6 });
  tulis(x, 'KO', 15, { huruf: 'WorkSansBold', x: 30, y: 51, warna: hex(t['--accent-contrast']) });
  const menu = ['Kasir', 'Pesanan', 'Dapur', 'Meja', 'Laporan', 'Setelan'];
  menu.forEach((m, i) => {
    const y = 104 + i * 62, aktif = i === 0;
    if (aktif) { x.fillStyle = hex(t['--accent-soft']); rr.call(x, 13, y - 20, 60, 56, 16); x.fill(); }
    x.strokeStyle = aktif ? hex(t['--accent']) : hex(t['--text-muted']); x.lineWidth = 1.9;
    x.beginPath(); x.rect(37, y - 12, 14, 11); x.stroke();
    x.beginPath(); x.moveTo(33, y + 12); x.lineTo(55, y + 12); x.stroke();
    tulis(x, m, 9.5, { x: 44, y: y + 26, warna: aktif ? hex(t['--accent']) : hex(t['--text-muted']), huruf: 'WorkSansReg' });
    // tengahkan label
  });

  // ---- kepala ----
  tulis(x, 'Kasir — Kedai Oasis', 24, { huruf: t.fDisplay, x: 112, y: 48, warna: hex(t['--text']) });
  tulis(x, 'Selasa, 16 Sep 2026 · Shift 1 · Kasir: Rina', 12, { x: 112, y: 70, warna: hex(t['--text-muted']) });
  // chip status mengambang
  lapis(x, () => { x.fillStyle = hex(t['--success-soft']); rr.call(x, W - 300, 26, 128, 34, 17); x.fill(); }, { blur: 14, warna: hex(t['--success'], 0.25), geserY: 5 });
  bulat(x, W - 284, 43, 4, hex(t['--success']));
  tulis(x, 'Kas terbuka', 12, { huruf: 'WorkSansBold', x: W - 274, y: 47, warna: hex(t['--success']) });
  lapis(x, () => { x.fillStyle = hex(t['--surface']); rr.call(x, W - 156, 26, 132, 34, 12); x.fill(); }, { blur: 12, warna: hex('#000', 0.18), geserY: 4 });
  tulis(x, 'Tutup Kas', 12, { huruf: 'WorkSansBold', x: W - 118, y: 47, warna: hex(t['--text']) });

  // ---- tab kategori (pola P32) ----
  const tabs = ['Makanan', 'Minuman', 'Camilan', 'Paket', 'Promo'];
  tabs.forEach((k, i) => tabKategori(x, t, 112 + i * 158, 92, 146, 50, k, i === 0));

  // ---- kisi menu (tata letak: foto · nama · harga + tombol bulat) ----
  const kolom = 4, kx = 112, ky = 164, kg = 14;
  const kw = (W - 112 - 336 - kg * (kolom - 1) - 24) / kolom;
  const th = Math.round(kw * 0.66), kt = th + 84;               // tinggi foto & tinggi kartu
  const daftar = [
    ['nasi-goreng', 'Nasi Goreng Spesial', 'Rp 25.000', '24 porsi'],
    ['ayam-geprek', 'Ayam Geprek', 'Rp 22.000', '18 porsi'],
    ['mie-ayam', 'Mie Ayam Bakso', 'Rp 20.000', '11 porsi'],
    ['kopi-susu', 'Kopi Susu Aren', 'Rp 18.000', '30 porsi'],
    ['es-teh', 'Es Teh Manis', 'Rp 6.000', '40 porsi'],
    ['pisang-goreng', 'Pisang Goreng (3 pcs)', 'Rp 12.000', '9 porsi'],
    ['nasi-goreng', 'Nasi Uduk Komplit', 'Rp 23.000', '14 porsi'],
    ['banner-kedai', 'Paket Keluarga', 'Rp 85.000', '6 paket'],
  ];
  daftar.forEach((d, i) => {
    const c2 = i % kolom, r = Math.floor(i / kolom);
    const dx = kx + c2 * (kw + kg), dy = ky + r * (kt + kg);
    lapis(x, () => { x.fillStyle = hex(t['--surface']); rr.call(x, dx, dy, kw, kt, 16); x.fill(); },
      { blur: 20, warna: hex('#000', 0.14), geserY: 7 });
    x.strokeStyle = hex(t['--border'], 0.85); x.lineWidth = 1; rr.call(x, dx, dy, kw, kt, 16); x.stroke();
    foto(x, FOTO[d[0]], dx + 8, dy + 8, kw - 16, th - 8, 12);
    // nama (dipotong bila panjang) + harga
    tulisPotong(x, d[1], 12.5, { huruf: 'WorkSansBold', x: dx + 12, y: dy + th + 22, warna: hex(t['--text']), max: kw - 20 });
    tulis(x, d[2], 15, { huruf: 'OutfitBold', x: dx + 12, y: dy + th + 48, warna: hex(t['--accent']) });
    // stok menipis -> chip di pojok foto (hanya muncul bila perlu)
    const sisa = parseInt(String(d[3]).replace(/\D/g, ''), 10);
    if (sisa <= 10) {
      x.font = '700 9.5px WorkSansBold';
      const cw = x.measureText('SISA ' + sisa).width + 18;
      x.fillStyle = hex(t['--warn-soft']); rr.call(x, dx + kw - 12 - cw, dy + 14, cw, 20, 10); x.fill();
      tulis(x, 'SISA ' + sisa, 9.5, { huruf: 'WorkSansBold', x: dx + kw - 12 - cw + 9, y: dy + 28, warna: hex(t['--warn']) });
    }
    // tombol bulat + di kanan bawah (44px sentuh)
    const r2 = 17, cxp = dx + kw - 12 - r2, cyp = dy + th + 40;
    lapis(x, () => { bulat(x, cxp, cyp, r2, hex(t['--accent'])); }, { blur: 16, warna: hex(t['--accent'], 0.45), geserY: 4 });
    x.strokeStyle = hex(t['--accent-contrast']); x.lineWidth = 2.2;
    x.beginPath(); x.moveTo(cxp - 5, cyp); x.lineTo(cxp + 5, cyp); x.moveTo(cxp, cyp - 5); x.lineTo(cxp, cyp + 5); x.stroke();
  });

  // ---- bilah aksi bawah (mengisi ruang & memang dibutuhkan kasir) ----
  const ay2 = 578, ah = 62, lebarBilah = W - 112 - 336 - 24;
  kotakKacaPOS(x, t, 112, ay2, lebarBilah, ah);
  ['Simpan', 'Kirim ke Dapur', 'Cetak Struk'].forEach((a, i) => {
    const bw = 158, bx = 128 + i * (bw + 10);
    x.fillStyle = hex(t['--surface-2']); rr.call(x, bx, ay2 + 12, bw, 38, 12); x.fill();
    tulis(x, a, 12, { huruf: 'WorkSansBold', x: bx + (bw - lebarTeks(x, a, 12, 'WorkSansBold')) / 2, y: ay2 + 36, warna: hex(t['--text']) });
  });
  const txtBatal = 'Batalkan';
  tulis(x, txtBatal, 12, { huruf: 'WorkSansBold', x: 112 + lebarBilah - 16 - lebarTeks(x, txtBatal, 12, 'WorkSansBold'), y: ay2 + 36, warna: hex(t['--danger']) });

  // ---- panel keranjang (mengambang) ----
  const px3 = W - 336, py3 = 92, pw = 312, ph = H - 116;
  lapis(x, () => { x.fillStyle = hex(t['--surface']); rr.call(x, px3, py3, pw, ph, 20); x.fill(); },
    { blur: 34, warna: hex('#000', 0.22), geserY: 12 });
  x.strokeStyle = hex(t['--border'], 0.9); x.lineWidth = 1; rr.call(x, px3, py3, pw, ph, 20); x.stroke();
  tulis(x, 'Pesanan #1024', 17, { huruf: 'WorkSansBold', x: px3 + 18, y: py3 + 32, warna: hex(t['--text']) });
  tulis(x, 'Meja 3 · Dine-in', 11.5, { x: px3 + 18, y: py3 + 50, warna: hex(t['--text-muted']) });
  x.fillStyle = hex(t['--border'], 0.7); x.fillRect(px3 + 18, py3 + 62, pw - 36, 1);
  const isi = [
    ['nasi-goreng', 'Nasi Goreng Spesial', '2× · tanpa pedas', 'Rp 50.000'],
    ['ayam-geprek', 'Ayam Geprek', '1× · sambal dipisah', 'Rp 22.000'],
    ['es-teh', 'Es Teh Manis', '2× · es sedikit', 'Rp 12.000'],
  ];
  let oy = py3 + 78;
  isi.forEach((o) => {
    foto(x, FOTO[o[0]], px3 + 18, oy, 42, 42, 10);
    tulis(x, o[1], 12.5, { huruf: 'WorkSansBold', x: px3 + 70, y: oy + 15, warna: hex(t['--text']) });
    tulis(x, o[2], 11, { x: px3 + 70, y: oy + 31, warna: hex(t['--text-muted']) });
    tulis(x, o[3], 12.5, { huruf: 'WorkSansBold', x: px3 + pw - 18 - lebarTeks(x, o[3], 12.5, 'WorkSansBold'), y: oy + 20, warna: hex(t['--text']) });
    oy += 54;
  });
  // ringkasan
  let sy = oy + 14;
  const baris = [['Sub total', 'Rp 84.000'], ['PB1 10%', 'Rp 8.400'], ['Service 5%', 'Rp 4.200'], ['Diskon voucher', '− Rp 15.000']];
  baris.forEach((b, i) => {
    tulis(x, b[0], 12, { x: px3 + 18, y: sy, warna: hex(t['--text-muted']) });
    tulis(x, b[1], 12, { huruf: 'WorkSansBold', x: px3 + pw - 18 - lebarTeks(x, b[1], 12, 'WorkSansBold'), y: sy, warna: i === 3 ? hex(t['--accent']) : hex(t['--text']) });
    sy += 22;
  });
  // garis putus-putus sebelum total (pola P32)
  x.save(); x.setLineDash([5, 5]); x.strokeStyle = hex(t['--border']); x.lineWidth = 1.4;
  x.beginPath(); x.moveTo(px3 + 18, sy - 4); x.lineTo(px3 + pw - 18, sy - 4); x.stroke(); x.restore();
  sy += 20;
  tulis(x, 'Total', 15, { huruf: 'WorkSansBold', x: px3 + 18, y: sy, warna: hex(t['--text']) });
  const tw = lebarTeks(x, 'Rp 81.600', 19, 'OutfitBold');
  tulis(x, 'Rp 81.600', 19, { huruf: 'OutfitBold', x: px3 + pw - 18 - tw, y: sy + 1, warna: hex(t['--text']) });
  // tombol bayar besar
  const by = py3 + ph - 74;
  lapis(x, () => { x.fillStyle = hex(t['--accent']); rr.call(x, px3 + 18, by, pw - 36, 54, 16); x.fill(); },
    { blur: 28, warna: hex(t['--accent'], 0.5), geserY: 10 });
  tulis(x, 'BAYAR SEKARANG · Rp 81.600', 12.5, { huruf: 'WorkSansBold', x: px3 + 32, y: by + 33, warna: hex(t['--accent-contrast']) });
  // pemilih metode
  ['Tunai', 'QRIS', 'E-Wallet', 'Transfer'].forEach((m, i) => {
    const bw = (pw - 36 - 3 * 8) / 4, bx = px3 + 18 + i * (bw + 8);
    x.fillStyle = i === 1 ? hex(t['--accent-soft']) : hex(t['--surface-2']);
    rr.call(x, bx, by - 46, bw, 34, 10); x.fill();
    if (i === 1) { x.strokeStyle = hex(t['--accent']); x.lineWidth = 1.5; rr.call(x, bx, by - 46, bw, 34, 10); x.stroke(); }
    tulis(x, m, 10, { huruf: 'WorkSansBold', x: bx + 8, y: by - 24, warna: i === 1 ? hex(t['--accent']) : hex(t['--text-muted']) });
  });
}

/* ============================== PAPAN (SHEET) ============================== */
function judulPapan(x, t, nama, ket, rujukan) {
  tulis(x, 'RESTO BAROKAH · CONTOH TAMPILAN', 13, { huruf: 'WorkSansBold', x: 60, y: 66, warna: hex(t['--accent']), lebar: 1.6 });
  tulis(x, nama, 54, { huruf: t.fDisplay, x: 60, y: 122, warna: hex(t['--text']), lebar: (t['--head-transform'] || '').includes('uppercase') ? 0.6 : 0 });
  tulis(x, ket, 16, { x: 60, y: 154, warna: hex(t['--text-muted']) });
  tulis(x, rujukan, 13, { x: 60, y: 178, warna: hex(t['--text-muted']) });
}

function kotakKaca(x, t, dx, dy, w, h, r = 16, alpha = 0.86) {
  lapis(x, () => { x.fillStyle = hex(t['--surface'], alpha); rr.call(x, dx, dy, w, h, r); x.fill(); },
    { blur: 24, warna: hex('#000', 0.2), geserY: 8 });
  x.strokeStyle = hex(t['--border'], 0.8); x.lineWidth = 1; rr.call(x, dx, dy, w, h, r); x.stroke();
}

function panelGaya(x, t, dx, dy, w) {
  kotakKaca(x, t, dx, dy, w, 250, 18);
  tulis(x, 'HURUF & WARNA', 10.5, { huruf: 'WorkSansBold', x: dx + 20, y: dy + 26, warna: hex(t['--text-muted']), lebar: 1.2 });
  tulis(x, 'Aa Bb 123', 34, { huruf: t.fDisplay, x: dx + 20, y: dy + 74, warna: hex(t['--text']) });
  tulis(x, 'Teks isi 16px · angka tegas untuk harga', 12.5, { x: dx + 20, y: dy + 98, warna: hex(t['--text-muted']) });
  tulis(x, 'Rp 81.600', 26, { huruf: 'OutfitBold', x: dx + 20, y: dy + 136, warna: hex(t['--accent']) });
  // contoh tombol & label
  tombolPil(x, dx + 20, dy + 154, 'PESAN', t, { lebar: 128, tinggi: 40 });
  const px4 = dx + 160;
  x.fillStyle = hex(t['--surface-2']); rr.call(x, px4, dy + 154, 108, 40, 12); x.fill();
  tulis(x, 'Simpan', 12.5, { huruf: 'WorkSansBold', x: px4 + 30, y: dy + 179, warna: hex(t['--text']) });
  // label status
  let lx = dx + 20, ly = dy + 212;
  [['Lunas', '--success', '--success-soft'], ['Dimasak', '--warn', '--warn-soft'], ['Baru', '--info', '--info-soft'], ['Habis', '--danger', '--danger-soft']].forEach((s) => {
    x.font = '700 10.5px WorkSansBold';
    const w2 = x.measureText(s[0]).width + 26;
    x.fillStyle = hex(t[s[2]]); rr.call(x, lx, ly, w2, 24, 12); x.fill();
    bulat(x, lx + 11, ly + 12, 3.2, hex(t[s[1]]));
    tulis(x, s[0], 10.5, { huruf: 'WorkSansBold', x: lx + 19, y: ly + 16, warna: hex(t[s[1]]) });
    lx += w2 + 8;
  });
}

// Panel "LAPISAN MENGAMBANG": modal + toast + dropdown dengan efek kaca (blur)
function panelMengambang(x, t, dx, dy, w, h) {
  kotakKaca(x, t, dx, dy, w, h, 18);
  tulis(x, 'LAPISAN MENGAMBANG (KACA & BLUR)', 10.5, { huruf: 'WorkSansBold', x: dx + 20, y: dy + 26, warna: hex(t['--text-muted']), lebar: 1.2 });
  // konten di belakang (buram)
  x.save(); rr.call(x, dx + 20, dy + 42, w - 40, h - 62, 14); x.clip();
  x.fillStyle = hex(t['--bg']); x.fillRect(dx + 20, dy + 42, w - 40, h - 62);
  for (let i = 0; i < 6; i++) {
    x.fillStyle = hex(t['--surface']); rr.call(x, dx + 32 + i * 150, dy + 56, 128, 90, 12); x.fill();
    tulis(x, 'Menu ' + (i + 1), 11, { huruf: 'WorkSansBold', x: dx + 44 + i * 150, y: dy + 120, warna: hex(t['--text']) });
  }
  // modal mengambang: bayangan + garis tepi
  const mx = dx + w / 2 - 210, my = dy + 70, mw = 420, mh = 132;
  x.fillStyle = 'rgba(0,0,0,.45)'; x.fillRect(dx + 20, dy + 42, w - 40, h - 62);
  x.restore();
  lapis(x, () => { x.fillStyle = hex(t['--surface'], 0.97); rr.call(x, mx, my, mw, mh, 18); x.fill(); },
    { blur: 40, warna: hex('#000', 0.4), geserY: 16 });
  x.strokeStyle = hex(t['--border'], 0.9); x.lineWidth = 1; rr.call(x, mx, my, mw, mh, 18); x.stroke();
  tulis(x, 'Bayar pesanan #1024?', 16, { huruf: 'WorkSansBold', x: mx + 20, y: my + 32, warna: hex(t['--text']) });
  tulis(x, 'Total Rp 81.600 · QRIS · Meja 3', 12, { x: mx + 20, y: my + 54, warna: hex(t['--text-muted']) });
  tombolPil(x, mx + 20, my + 70, 'BAYAR', t, { lebar: 150, tinggi: 42 });
  x.fillStyle = hex(t['--surface-2']); rr.call(x, mx + 184, my + 70, 108, 42, 12); x.fill();
  tulis(x, 'Batal', 12.5, { huruf: 'WorkSansBold', x: mx + 214, y: my + 97, warna: hex(t['--text']) });
  // toast (pojok kanan bawah panel)
  const tx = dx + w - 300, ty = dy + h - 54;
  lapis(x, () => { x.fillStyle = hex(t['--surface'], 0.96); rr.call(x, tx - 60, ty - 20, 280, 46, 14); x.fill(); },
    { blur: 26, warna: hex(t['--success'], 0.3), geserY: 10 });
  bulat(x, tx - 40, ty + 3, 9, hex(t['--success']));
  x.strokeStyle = hex(t['--success-soft']); x.lineWidth = 2.2;
  x.beginPath(); x.moveTo(tx - 44, ty + 3); x.lineTo(tx - 41, ty + 7); x.lineTo(tx - 35, ty - 2); x.stroke();
  tulis(x, 'Pesanan tersimpan ke Dapur', 12, { huruf: 'WorkSansBold', x: tx - 24, y: ty + 8, warna: hex(t['--text']) });
  // dropdown tema (kanan atas)
  const dx2 = dx + w - 232, dy2 = dy + 40;
  lapis(x, () => { x.fillStyle = hex(t['--surface'], 0.97); rr.call(x, dx2, dy2, 212, 92, 14); x.fill(); },
    { blur: 30, warna: hex('#000', 0.35), geserY: 12 });
  x.strokeStyle = hex(t['--border'], 0.9); x.lineWidth = 1; rr.call(x, dx2, dy2, 212, 92, 14); x.stroke();
  [['Terang Bersih', false], ['Bara Panggang', true], ['Vintage Klasik', false]].forEach(([n, aktif], i) => {
    const ry = dy2 + 8 + i * 26;
    if (aktif) { x.fillStyle = hex(t['--accent-soft']); rr.call(x, dx2 + 6, ry, 200, 24, 8); x.fill(); }
    bulat(x, dx2 + 20, ry + 12, 6, aktif ? hex(t['--accent']) : hex(t['--text-muted']));
    tulis(x, n, 11.5, { x: dx2 + 34, y: ry + 16, warna: hex(t['--text']) });
  });
}

function panelWarna(x, t, dx, dy, w) {
  const tinggi = 128;
  kotakKaca(x, t, dx, dy, w, tinggi, 18);
  tulis(x, 'PALET', 10.5, { huruf: 'WorkSansBold', x: dx + 20, y: dy + 26, warna: hex(t['--text-muted']), lebar: 1.2 });
  const kunci = ['--bg', '--surface', '--surface-2', '--accent', '--text', '--text-muted', '--success', '--warn'];
  const bw = (w - 40 - 7 * 6) / 8;
  kunci.forEach((k, i) => {
    const bx = dx + 20 + i * (bw + 6);
    x.fillStyle = hex(t[k]); rr.call(x, bx, dy + 42, bw, 40, 8); x.fill();
    x.strokeStyle = hex(t['--border']); x.lineWidth = 1; rr.call(x, bx, dy + 42, bw, 40, 8); x.stroke();
    tulis(x, k.replace('--', ''), 9.5, { x: bx + 1, y: dy + 98, warna: hex(t['--text-muted']), huruf: 'WorkSansReg' });
  });
}

async function papan({ tema, nama, ket, rujukan, layar = 'katalog', berkas }) {
  const t = TEMA[tema];
  const W = 1720, H = 1180;
  const c = createCanvas(W, H), x = c.getContext('2d');
  // latar + glow
  x.fillStyle = hex(t['--bg']); x.fillRect(0, 0, W, H);
  glow(x, 240, 90, 520, t['--accent'], 0.20, 90);
  glow(x, W - 180, H - 120, 560, t['--accent'], 0.14, 110);
  if ((t['--bg-pattern'] || '').length > 10) {
    const motif = t['--bg-pattern'].includes('circle') || t['--bg-pattern'].includes('circle') ? 'lingkaran'
      : (t['--bg-pattern'].includes('path') && t['--bg-pattern'].includes('ellipse')) ? 'daun'
        : (t['--bg-pattern'].includes('path')) ? 'ombak' : 'garis';
    // tebak dari nama berkas svg
    if (t['--bg-pattern'].includes('stroke-opacity')) taburan(x, W, H, t['--accent'], 'tidak' === motif ? 'lingkaran' : motif);
  }

  judulPapan(x, t, nama, ket, rujukan);

  if (layar === 'katalog') {
    // kerangka HP
    const ph = 950, px = 90, py = 206;
    const s2skala = (ph - 28) / 880, pw = 400 * s2skala + 28;
    lapis(x, () => { x.fillStyle = '#0d0f11'; rr.call(x, px, py, pw, ph, 54); x.fill(); }, { blur: 60, warna: hex('#000', 0.45), geserY: 26 });
    x.fillStyle = '#14181b'; rr.call(x, px + 8, py + 8, pw - 16, ph - 16, 46); x.fill();
    x.save(); rr.call(x, px + 14, py + 14, pw - 28, ph - 28, 40); x.clip();
    x.translate(px + 14, py + 14); x.scale(s2skala, s2skala);
    layarKatalog(x, t);
    x.restore();
    // kolom kanan (4 panel, total 866 px -> masuk papan)
    const sx = px + pw + 78, sw = W - sx - 70, sy = py;
    panelGaya(x, t, sx, sy, sw);
    panelWarna(x, t, sx, sy + 252, sw);
    panelMengambang(x, t, sx, sy + 384, sw, 300);
    kotakKaca(x, t, sx, sy + 696, sw, 170, 18);
    tulis(x, 'CATATAN DESAIN & EFEK', 10.5, { huruf: 'WorkSansBold', x: sx + 20, y: sy + 722, warna: hex(t['--text-muted']), lebar: 1.2 });
    const catatan = [
      'Kartu menu: sudut 18px · foto 118px · bayangan berlapis (2 lapis)',
      'Tombol bulat + 19px pada tiap kartu (pola P16 Grill & Co.)',
      'Label kecil HURUF BESAR di pojok foto (BESTSELLER/PEDAS/FAVORIT)',
      'Jarak antar objek kelipatan 4 · 8 · 12 · 16 · 24 px',
      'Kaca (blur) untuk modal, bilah keranjang, dan bilah atas',
      'Transisi 180–260 ms (ease-out) · hover: terangkat 2px + bayangan naik',
    ];
    catatan.forEach((c2, i) => {
      bulat(x, sx + 26, sy + 748 + i * 20 - 4, 2.6, hex(t['--accent']));
      tulis(x, c2, 11, { x: sx + 36, y: sy + 748 + i * 20, warna: hex(t['--text-muted']) });
    });
  } else {
    // kerangka laptop
    const pw = 1480, ph = 900, px = 120, py = 250;
    lapis(x, () => { x.fillStyle = '#0d0f11'; rr.call(x, px, py, pw, ph, 30); x.fill(); }, { blur: 60, warna: hex('#000', 0.45), geserY: 26 });
    x.fillStyle = '#14181b'; rr.call(x, px + 10, py + 10, pw - 20, ph - 20, 24); x.fill();
    x.save(); rr.call(x, px + 18, py + 18, pw - 36, ph - 36, 18); x.clip();
    x.translate(px + 18, py + 18); const s = (pw - 36) / 1080; x.scale(s, s);
    layarKasir(x, t);
    x.restore();
    // kaki laptop
    x.fillStyle = hex(t['--surface-2']); rr.call(x, px - 60, py + ph - 6, pw + 120, 24, 12); x.fill();
  }
  fs.mkdirSync(KELUAR, { recursive: true });
  fs.writeFileSync(path.join(KELUAR, berkas), c.toBuffer('image/png'));
  console.log('papan dibuat:', berkas);
}

/* ================================= CLI ================================= */
(async () => {
  await muatFoto();
  const minta = process.argv[2] || 'semua';
  const daftar = [
    { kunci: 'bara', tema: 'bara', layar: 'katalog', berkas: 'papan-1-bara-panggang.png', nama: 'Bara Panggang', ket: 'Hitam pekat + emas · judul HURUF BESAR · tombol pil berpanah', rujukan: 'Dibuat dari gambar kiriman pemilik: "Grill & Co. — Flame Grilled Perfection"' },
    { kunci: 'hangat', tema: 'hangat', layar: 'katalog', berkas: 'papan-2-hangat-kedai.png', nama: 'Hangat Kedai', ket: 'Krem & coklat · huruf serif ramah · sudut lebih membulat', rujukan: 'Rujukan: P15 Brew & Bliss Coffee House, P22 toko kue' },
    { kunci: 'kasir', tema: 'terang', layar: 'kasir', berkas: 'papan-3-kasir-terang.png', nama: 'Kasir (mode Terang Bersih)', ket: 'Menu kiri · keranjang kanan · pajak & service terpisah', rujukan: 'Rujukan pola: P04 Cashier POS, P17 Jaegar Resto, P32 Pakecho POS' },
    { kunci: 'kasirgelap', tema: 'gelap', layar: 'kasir', berkas: 'papan-4-kasir-gelap.png', nama: 'Kasir (mode Gelap Dapur)', ket: 'Sama persis susunannya — hanya tema yang berganti', rujukan: 'Membuktikan: ganti tema tidak mengubah susunan maupun fungsi' },
    { kunci: 'terang', tema: 'terang', layar: 'katalog', berkas: 'papan-5-katalog-terang.png', nama: 'Katalog Pelanggan (tema bawaan)', ket: 'Tampilan bawaan Terang Bersih — yang pertama dilihat pelanggan Kedai Oasis', rujukan: 'Pola P08, P14, P15, P16 (kartu menu: foto, label kecil, nama, harga, tombol bulat +)' },
  ];
  for (const d of daftar) {
    if (minta === 'semua' || minta === d.kunci) await papan(d);
  }
})();
