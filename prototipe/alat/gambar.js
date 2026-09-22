/* ============================================================================
   Resto Barokah — Pembuat papan mockup (mockup sheet) presisi piksel
   ----------------------------------------------------------------------------
   Memakai @napi-rs/canvas + HURUF ASLI dari skills/ui-styling/canvas-fonts,
   dan WARNA dari prototipe/css/tokens.css (jadi papan tidak bisa "berbohong").

   Yang digambar: kerangka HP/laptop, kartu menu, hero card, tab kategori,
   tombol pil berpanah, label, harga, tombol bulat +, panel keranjang dengan
   garis putus-putus, bayangan berlapis, glow aksen, dan efek kaca (translucent).

   Cara pakai:  node prototipe/alat/mockup.js papan-semua
   Hasil:       docs/desain/mockup/*.png
   ============================================================================ */
const fs = require('fs');
const path = require('path');
const { createCanvas, GlobalFonts, loadImage } = require('@napi-rs/canvas');

const AKAR = path.resolve(__dirname, '..', '..');
const HURUF = path.join(AKAR, 'skills', 'ui-styling', 'canvas-fonts');
const ASET = path.join(AKAR, 'prototipe', 'aset');
const KELUAR = path.join(AKAR, 'docs', 'desain', 'mockup');

/* ---------------- 1. HURUF ASLI ---------------- */
const DAFTAR_HURUF = {
  'WorkSansReg': 'WorkSans-Regular.ttf', 'WorkSansBold': 'WorkSans-Bold.ttf',
  'OutfitReg': 'Outfit-Regular.ttf', 'OutfitBold': 'Outfit-Bold.ttf',
  'BigShoulders': 'BigShoulders-Bold.ttf', 'InstrumentSans': 'InstrumentSans-Regular.ttf',
  'LoraBold': 'Lora-Bold.ttf', 'ArsenalSC': 'ArsenalSC-Regular.ttf',
  'CrimsonReg': 'CrimsonPro-Regular.ttf', 'CrimsonBold': 'CrimsonPro-Bold.ttf',
  'NationalPark': 'NationalPark-Bold.ttf', 'YoungSerif': 'YoungSerif-Regular.ttf',
  'Bricolage': 'BricolageGrotesque-Bold.ttf', 'InstrumentSerif': 'InstrumentSerif-Regular.ttf',
};
for (const [nama, berkas] of Object.entries(DAFTAR_HURUF)) {
  GlobalFonts.registerFromPath(path.join(HURUF, berkas), nama);
}

/* ---------------- 2. WARNA DARI tokens.css ---------------- */
const KUNCI = ['--bg', '--bg-elev', '--surface', '--surface-2', '--border', '--text', '--text-muted',
  '--accent', '--accent-contrast', '--accent-soft', '--success', '--success-soft',
  '--warn', '--warn-soft', '--danger', '--danger-soft', '--info', '--info-soft',
  '--font-body', '--font-display', '--head-transform', '--head-ls'];

function bacaTema() {
  const css = fs.readFileSync(path.join(AKAR, 'prototipe', 'css', 'tokens.css'), 'utf8');
  const blok = {}; let tema = null;
  for (const baris of css.split('\n')) {
    const m = baris.match(/^\s*(:root|\[data-theme="([a-z]+)"\])/);
    if (m) { tema = m[2] || 'terang'; blok[tema] = blok[tema] || {}; continue; }
    if (!tema) continue;
    for (const [, nama, nilai] of baris.matchAll(/(--[a-z0-9-]+):\s*([^;]+);/g)) blok[tema][nama] = nilai.trim();
  }
  // urai var()
  const urai = (nilai, t, d = 0) => {
    const m = nilai && nilai.match(/^var\((--[a-z0-9-]+)\)$/);
    return m && d < 8 ? urai(t[m[1]] || '#000000', t, d + 1) : (nilai || '#000000').trim();
  };
  const hasil = {};
  for (const [nama, t] of Object.entries(blok)) {
    hasil[nama] = {};
    for (const k of KUNCI) hasil[nama][k] = urai(t[k], t);
  }
  // nama berkas huruf -> keluarga yang terdaftar
  const keluarga = {
    "'WorkSans'": 'WorkSansReg', "'Outfit'": 'OutfitReg', "'Lora'": 'LoraBold',
    "'InstrumentSans'": 'InstrumentSans', "'BigShoulders'": 'BigShoulders', "'ArsenalSC'": 'ArsenalSC',
    "'CrimsonPro'": 'CrimsonReg', "'YoungSerif'": 'YoungSerif', "'NationalPark'": 'NationalPark',
    "'Bricolage'": 'Bricolage', 'system-ui': 'WorkSansReg',
  };
  for (const t of Object.values(hasil)) {
    const d = (t['--font-display'] || '').split(',')[0].trim();
    const b = (t['--font-body'] || '').split(',')[0].trim();
    t.fDisplay = keluarga[d] || (d.includes('Crimson') ? 'CrimsonBold' : 'OutfitBold');
    t.fBody = keluarga[b] || 'WorkSansReg';
  }
  return hasil;
}
const TEMA = bacaTema();

/* ---------------- 3. ALAT GAMBAR ---------------- */
const hex = (h, a) => {
  h = h.trim();
  if (h.startsWith('rgba') || h.startsWith('rgb')) return h;
  h = h.replace('#', '');
  if (h.length === 3) h = h.split('').map(c => c + c).join('');
  const r = parseInt(h.slice(0, 2), 16), g = parseInt(h.slice(2, 4), 16), b = parseInt(h.slice(4, 6), 16);
  return a === undefined ? `rgb(${r},${g},${b})` : `rgba(${r},${g},${b},${a})`;
};

function rr(x, y, w, h, r) {              // lintasan persegi membulat
  const c = this;
  r = Math.min(r, w / 2, h / 2);
  c.beginPath();
  c.moveTo(x + r, y);
  c.arcTo(x + w, y, x + w, y + h, r);
  c.arcTo(x + w, y + h, x, y + h, r);
  c.arcTo(x, y + h, x, y, r);
  c.arcTo(x, y, x + w, y, r);
  c.closePath();
}

function lapis(x, fn, { blur = 0, warna = 'rgba(0,0,0,.35)', geserY = 8, sebar = 0 } = {}) {
  x.save(); x.shadowColor = warna; x.shadowBlur = blur; x.shadowOffsetY = geserY;
  if (sebar) { x.shadowOffsetX = 0; }
  fn(); x.restore();
}

function glow(x, cx, cy, r, warna, kekuatan = 0.5, blur = 60) {
  x.save(); x.filter = `blur(${blur}px)`;
  const g = x.createRadialGradient(cx, cy, 0, cx, cy, r);
  g.addColorStop(0, hex(warna, kekuatan)); g.addColorStop(1, hex(warna, 0));
  x.fillStyle = g; x.beginPath(); x.arc(cx, cy, r, 0, Math.PI * 2); x.fill(); x.restore();
}

function tulis(x, teks, px, opt = {}) {
  x.font = `${opt.tebal === false ? '' : ''}${px}px ${opt.huruf || 'WorkSansReg'}`.trim();
  if (opt.huruf === 'BigShoulders' || opt.besar) x.font = `${px}px ${opt.huruf || 'BigShoulders'}`;
  x.fillStyle = opt.warna || '#000';
  x.textBaseline = opt.dasar || 'alphabetic';
  if (opt.tengah) {
    const w = opt.lebar ? [...teks].reduce((a, c) => a + x.measureText(c).width + opt.lebar, 0) : x.measureText(teks).width;
    opt = { ...opt, x: opt.x - w / 2 };
  }
  if (opt.lebar) {
    // penjarakan huruf manual
    let totalWidth = 0; const lebar = [];
    for (const c of teks) { const w = x.measureText(c).width + opt.lebar; lebar.push(w); totalWidth += w; }
    let cx = opt.x - (opt.tengah ? totalWidth / 2 : 0);
    for (let i = 0; i < teks.length; i++) { x.fillText(teks[i], cx, opt.y); cx += lebar[i]; }
    return totalWidth;
  }
  x.fillText(teks, opt.x, opt.y, opt.max);
  return x.measureText(teks).width;
}

function bungkus(x, teks, maxW, huruf, px) {   // potong jadi beberapa baris
  x.font = `${px}px ${huruf}`;
  const kata = teks.split(' '); const baris = []; let kini = '';
  for (const k of kata) {
    const coba = kini ? kini + ' ' + k : k;
    if (x.measureText(coba).width > maxW && kini) { baris.push(kini); kini = k; } else kini = coba;
  }
  if (kini) baris.push(kini);
  return baris;
}

function lebarTeks(x, teks, px, huruf) {
  x.font = `${px}px ${huruf || 'WorkSansReg'}`;
  return x.measureText(teks).width;
}

function tulisPotong(x, teks, px, opt = {}) {   // potong dengan … bila melebihi lebar
  const huruf = opt.huruf || 'WorkSansReg';
  const maxW = opt.max || 1e9;
  x.font = `${px}px ${huruf}`;
  if (x.measureText(teks).width <= maxW) { tulis(x, teks, px, opt); return; }
  let s2 = teks;
  while (s2.length > 1 && x.measureText(s2 + '…').width > maxW) s2 = s2.slice(0, -1);
  tulis(x, s2 + '…', px, opt);
}

function bulat(x, cx, cy, r, warna) { x.fillStyle = warna; x.beginPath(); x.arc(cx, cy, r, 0, Math.PI * 2); x.fill(); }

function bintang(x, cx, cy, r, warna) {
  x.save(); x.fillStyle = warna; x.beginPath();
  for (let i = 0; i < 5; i++) {
    const a = -Math.PI / 2 + i * 2 * Math.PI / 5, a2 = a + Math.PI / 5;
    x.lineTo(cx + Math.cos(a) * r, cy + Math.sin(a) * r);
    x.lineTo(cx + Math.cos(a2) * r * 0.45, cy + Math.sin(a2) * r * 0.45);
  }
  x.closePath(); x.fill(); x.restore();
}

function foto(x, img, dx, dy, dw, dh, radius) {
  x.save(); rr.call(x, dx, dy, dw, dh, radius); x.clip();
  const rasio = Math.max(dw / img.width, dh / img.height);
  const w = img.width * rasio, h = img.height * rasio;
  x.drawImage(img, dx + (dw - w) / 2, dy + (dh - h) / 2, w, h);
  x.restore();
}

function taburan(x, w, h, warna, jenis = 'garis') {   // hiasan latar halus
  x.save(); x.globalAlpha = 0.07; x.strokeStyle = warna; x.fillStyle = warna;
  if (jenis === 'lingkaran') {
    for (let iy = 0; iy < h + 80; iy += 80) for (let ix = 0; ix < w + 80; ix += 80) {
      x.beginPath(); x.arc(ix, iy, 22, 0, Math.PI * 2); x.stroke();
    }
  } else if (jenis === 'ombak') {
    for (let iy = 0; iy < h + 40; iy += 40) {
      x.beginPath();
      for (let ix = -40; ix < w + 40; ix += 40) x.quadraticCurveTo(ix + 10, iy + 12, ix + 40, iy);
      x.stroke();
    }
  } else if (jenis === 'daun') {
    for (let iy = 0; iy < h + 90; iy += 90) for (let ix = 0; ix < w + 90; ix += 90) {
      x.beginPath(); x.ellipse(ix, iy, 10, 26, Math.PI / 5, 0, Math.PI * 2); x.stroke();
      x.beginPath(); x.moveTo(ix - 6, iy + 18); x.lineTo(ix + 6, iy - 18); x.stroke();
    }
  } else {  // butiran kertas
    for (let i = 0; i < 2600; i++) x.fillRect(Math.random() * w, Math.random() * h, 1.3, 1.3);
  }
  x.restore();
}

module.exports = {
  fs, path, createCanvas, loadImage, AKAR, ASET, KELUAR, TEMA, hex, rr, lapis, glow, tulis,
  bungkus, bulat, bintang, foto, taburan, lebarTeks, tulisPotong,
};
