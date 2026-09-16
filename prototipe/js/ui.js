/* ==========================================================================
   RESTO BAROKAH — mesin contoh tampilan (tanpa pustaka luar, tanpa internet)
   Isi: pemilih 10 tema (dengan pratinjau warna asli dari token), kerapatan,
   keranjang hidup (tambah item, qty, hitung pajak/diskon/kembalian),
   lapis mengambang (modal), toast, dan gerak masuk saat digulir.
   ========================================================================== */
(function () {
  'use strict';

  var KEY_TEMA = 'rb-tema', KEY_RAPAT = 'rb-kerapatan';
  var TEMA = [
    ['terang', 'Terang Bersih', 'bersih & terang — bawaan'],
    ['hangat', 'Hangat Kedai', 'krem & coklat, ramah'],
    ['gelap', 'Gelap Dapur', 'gelap untuk layar dapur'],
    ['kontras', 'Kontras Tinggi', 'hitam-putih, garis tebal'],
    ['bara', 'Bara Panggang', 'hitam + emas (gambar kirimanmu)'],
    ['vintage', 'Vintage Klasik', 'kertas tua, serif, garis ganda'],
    ['alam', 'Alam Hijau', 'hijau daun, membulat lembut'],
    ['tropis', 'Tropis Segar', 'teal laut, ceria'],
    ['pastel', 'Pastel Manis', 'pastel lembut, tebal (clay)'],
    ['etnik', 'Etnik Nusantara', 'ivory, terakota, motif batik']
  ];

  function simpan(k, v) { try { localStorage.setItem(k, v); } catch (e) {} }
  function baca(k) { try { return localStorage.getItem(k); } catch (e) { return null; } }
  function rupiah(n) { return 'Rp ' + Math.round(n).toLocaleString('id-ID'); }
  function namaTema(kode) { for (var i = 0; i < TEMA.length; i++) if (TEMA[i][0] === kode) return TEMA[i][1]; return 'Terang Bersih'; }

  // ---- membaca warna asli sebuah tema dari token (tanpa menulis warna ulang di JS) ----
  var probe = document.createElement('div');
  probe.setAttribute('style', 'position:absolute;left:-9999px;top:0');
  document.documentElement.appendChild(probe);
  function warna(kode) {
    probe.setAttribute('data-theme', kode);
    var s = getComputedStyle(probe);
    return [s.getPropertyValue('--bg').trim() || '#fff',
            s.getPropertyValue('--accent').trim() || '#000',
            s.getPropertyValue('--text').trim() || '#000'];
  }

  // ------------------------------ TEMA --------------------------------------
  function pasangTema(kode) {
    document.documentElement.setAttribute('data-theme', kode);
    var w = warna(kode), rgb = 'background:' + w[1];
    document.querySelectorAll('[data-set-tema]').forEach(function (b) {
      b.setAttribute('aria-pressed', String(b.getAttribute('data-set-tema') === kode));
    });
    document.querySelectorAll('[data-nama-tema]').forEach(function (el) { el.textContent = namaTema(kode); });
    document.querySelectorAll('[data-swatch-tema]').forEach(function (el) { el.setAttribute('style', rgb); });
    simpan(KEY_TEMA, kode);
  }

  function buatPemilih() {
    document.querySelectorAll('[data-pemilih-tema]').forEach(function (wadah) {
      var tombol = TEMA.map(function (t) {
        var w = warna(t[0]);
        return '<button type="button" data-set-tema="' + t[0] + '">' +
          '<span class="sw-3" aria-hidden="true"><i style="background:' + w[0] + '"></i><i style="background:' + w[1] + '"></i><i style="background:' + w[2] + '"></i></span>' +
          '<span><strong>' + t[1] + '</strong><small>' + t[2] + '</small></span></button>';
      }).join('');
      wadah.innerHTML =
        '<details class="picker"><summary class="btn btn-sm" aria-label="Pilih tema">' +
        '<i class="swatch" data-swatch-tema aria-hidden="true"></i> Tema: <span data-nama-tema>Terang Bersih</span></summary>' +
        '<div class="picker-panel" role="group" aria-label="Pilih tema">' + tombol +
        '<a class="picker-all" href="04-tema.html">Lihat 10 tema berdampingan &amp; rapi &rarr;</a></div></details>';
    });
  }

  // ------------------------------ KERAPATAN --------------------------------
  function pasangKerapatan(nama) {
    if (nama !== 'padat' && nama !== 'nyaman') nama = 'padat';
    document.documentElement.setAttribute('data-density', nama);
    document.querySelectorAll('[data-set-rapat]').forEach(function (b) {
      b.setAttribute('aria-pressed', String(b.getAttribute('data-set-rapat') === nama));
    });
    simpan(KEY_RAPAT, nama);
  }

  // ------------------------------ TOAST ------------------------------------
  var toastEl, toastTimer;
  function toast(pesan) {
    if (!toastEl) {
      toastEl = document.createElement('div');
      toastEl.className = 'toast';
      toastEl.setAttribute('role', 'status');
      document.body.appendChild(toastEl);
    }
    toastEl.textContent = pesan;
    toastEl.classList.add('tampil');
    clearTimeout(toastTimer);
    toastTimer = setTimeout(function () { toastEl.classList.remove('tampil'); }, 2200);
  }

  // ------------------------------ LAPIS MENGAMBANG --------------------------
  function bukaLapis(sel) {
    var el = document.querySelector(sel);
    if (!el) return;
    el.classList.add('terbuka');
    el.setAttribute('aria-hidden', 'false');
    document.body.style.overflow = 'hidden';
    var fokus = el.querySelector('input,button,textarea,select');
    if (fokus) setTimeout(function () { fokus.focus(); }, 60);
  }
  function tutupLapis(el) {
    if (typeof el === 'string') el = document.querySelector(el);
    if (!el) return;
    el.classList.remove('terbuka');
    el.setAttribute('aria-hidden', 'true');
    document.body.style.overflow = '';
  }

  // ------------------------------ KERANJANG --------------------------------
  var keranjang = { baris: [], diskon: 0, pb1: 0.10, service: 0.05, metode: 'QRIS', uang: 100000 };

  function cariBaris(nama) {
    for (var i = 0; i < keranjang.baris.length; i++) if (keranjang.baris[i].nama === nama) return keranjang.baris[i];
    return null;
  }
  function tambah(nama, harga, diam) {
    var b = cariBaris(nama);
    if (b) b.qty++; else keranjang.baris.push({ nama: nama, harga: parseInt(harga, 10), qty: 1, catatan: '' });
    gambarKeranjang();
    if (!diam) toast(nama + ' ditambahkan');
  }
  function hitung() {
    var sub = keranjang.baris.reduce(function (a, b) { return a + b.harga * b.qty; }, 0);
    var pb1 = sub * keranjang.pb1, svc = sub * keranjang.service;
    var total = Math.max(0, sub + pb1 + svc - keranjang.diskon);
    return { sub: sub, pb1: pb1, svc: svc, total: total, kembali: keranjang.uang - total };
  }
  function gambarKeranjang() {
    var daftar = document.querySelector('[data-daftar-pesanan]');
    var h = hitung();
    if (daftar) {
      if (!keranjang.baris.length) {
        daftar.innerHTML = '<p class="muted small" style="padding:var(--s-4) 0">Belum ada pesanan. Tekan menu di sebelah kiri.</p>';
      } else {
        daftar.innerHTML = keranjang.baris.map(function (b, i) {
          return '<div class="baris-pesanan">' +
            '<div><strong>' + b.nama + '</strong><div class="small muted">' + rupiah(b.harga) + ' × ' + b.qty + '</div></div>' +
            '<div class="row" style="align-items:center">' +
            '<span class="qty"><button type="button" data-qty="kurang" data-i="' + i + '" aria-label="Kurangi ' + b.nama + '">−</button>' +
            '<span>' + b.qty + '</span>' +
            '<button type="button" data-qty="tambah" data-i="' + i + '" aria-label="Tambah ' + b.nama + '">+</button></span>' +
            '<strong class="num" style="width:92px;text-align:right">' + rupiah(b.harga * b.qty) + '</strong></div></div>';
        }).join('');
      }
    }
    var isi = {
      '[data-subtotal]': h.sub, '[data-pb1]': h.pb1, '[data-service]': h.svc,
      '[data-total]': h.total, '[data-kembalian]': Math.max(0, h.kembali), '[data-uang-nilai]': keranjang.uang,
      '[data-jml-item]': keranjang.baris.reduce(function (a, b) { return a + b.qty; }, 0)
    };
    Object.keys(isi).forEach(function (sel) {
      document.querySelectorAll(sel).forEach(function (el) {
        el.textContent = sel === '[data-jml-item]' ? isi[sel] + ' item' : rupiah(isi[sel]);
      });
    });
    var d = document.querySelector('[data-diskon]');
    if (d) d.textContent = '− ' + rupiah(keranjang.diskon);
    var btn = document.querySelector('[data-bayar]');
    if (btn) {
      btn.disabled = !keranjang.baris.length;
      btn.textContent = 'Bayar Sekarang · ' + rupiah(h.total);
    }
  }

  // ------------------------------ INTERAKSI --------------------------------
  document.addEventListener('click', function (e) {
    var t;

    if ((t = e.target.closest('[data-set-tema]'))) {
      pasangTema(t.getAttribute('data-set-tema'));
      var p = t.closest('details'); if (p) p.open = false;
      if (t.hasAttribute('data-ke-atas')) window.scrollTo({ top: 0, behavior: 'smooth' });
      return;
    }
    if ((t = e.target.closest('[data-set-rapat]'))) { pasangKerapatan(t.getAttribute('data-set-rapat')); return; }
    if ((t = e.target.closest('[data-buka-lapis]'))) { bukaLapis(t.getAttribute('data-buka-lapis')); return; }
    if ((t = e.target.closest('[data-tutup-lapis]'))) { tutupLapis(t.closest('.lapis')); return; }
    if (e.target.classList && e.target.classList.contains('lapis')) { tutupLapis(e.target); return; }

    if ((t = e.target.closest('.tombol-tambah,[data-tambah]'))) {
      var nama = t.getAttribute('data-nama') || (t.closest('[data-nama]') && t.closest('[data-nama]').getAttribute('data-nama'));
      var harga = t.getAttribute('data-harga');
      if (nama && harga) { tambah(nama, harga); return; }
    }
    if ((t = e.target.closest('[data-qty]'))) {
      var i = parseInt(t.getAttribute('data-i'), 10);
      if (!isNaN(i) && keranjang.baris[i]) {
        keranjang.baris[i].qty += t.getAttribute('data-qty') === 'tambah' ? 1 : -1;
        if (keranjang.baris[i].qty <= 0) keranjang.baris.splice(i, 1);
        gambarKeranjang();
      }
      return;
    }
    if ((t = e.target.closest('.qty [data-langkah]'))) {   // stepper di halaman katalog
      var box = t.closest('.qty'), out = box.querySelector('span');
      var n = parseInt(out.textContent, 10) + (t.getAttribute('data-langkah') === 'naik' ? 1 : -1);
      out.textContent = Math.max(1, n);
      return;
    }
    if ((t = e.target.closest('.pay'))) {
      keranjang.metode = t.getAttribute('data-metode') || t.textContent.trim();
      t.parentElement.querySelectorAll('.pay').forEach(function (x) { x.setAttribute('aria-pressed', 'false'); });
      t.setAttribute('aria-pressed', 'true');
      return;
    }
    if ((t = e.target.closest('button[data-uang]'))) {
      keranjang.uang = parseInt(t.getAttribute('data-uang'), 10);
      document.querySelectorAll('button[data-uang]').forEach(function (x) { x.setAttribute('aria-pressed', 'false'); });
      t.setAttribute('aria-pressed', 'true');
      gambarKeranjang();
      return;
    }
    if ((t = e.target.closest('[data-cek-voucher]'))) {
      var inp = document.querySelector('#kode-voucher');
      var kode = ((inp && inp.value) || '').trim().toUpperCase();
      toast(kode ? 'Voucher ' + kode + ' sah · diskon Rp 15.000 · BELUM dipakai' : 'Masukkan kode voucher dulu, contoh: UNDANG-7K2M');
      return;
    }
    if (e.target.closest('[data-pakai-voucher]')) {
      var inp2 = document.querySelector('#kode-voucher');
      var kode2 = ((inp2 && inp2.value) || '').trim().toUpperCase() || 'UNDANG-7K2M';
      keranjang.diskon = 15000;
      gambarKeranjang();
      toast('Voucher ' + kode2 + ' dipakai · potongan Rp 15.000');
      return;
    }
    if (e.target.closest('[data-bayar]')) {
      var h = hitung();
      var set = { '[data-bayar-total]': rupiah(h.total), '[data-bayar-metode]': keranjang.metode, '[data-bayar-kembali]': rupiah(Math.max(0, h.kembali)) };
      Object.keys(set).forEach(function (sel) {
        document.querySelectorAll(sel).forEach(function (el) { el.textContent = set[sel]; });
      });
      bukaLapis('#lapis-bayar');
      return;
    }
    if (e.target.closest('[data-aksi]')) { toast(e.target.closest('[data-aksi]').getAttribute('data-aksi')); return; }
    if ((t = e.target.closest('.tab')) && t.parentElement.classList.contains('tabs')) {
      t.parentElement.querySelectorAll('.tab').forEach(function (x) { x.setAttribute('aria-selected', 'false'); });
      t.setAttribute('aria-selected', 'true');
      return;
    }
    if ((t = e.target.closest('.segmen button')) && t.parentElement.classList.contains('segmen')) {
      t.parentElement.querySelectorAll('button').forEach(function (x) { x.setAttribute('aria-pressed', 'false'); });
      t.setAttribute('aria-pressed', 'true');
      return;
    }
    document.querySelectorAll('details.picker[open]').forEach(function (d) { if (!d.contains(e.target)) d.open = false; });
  });

  document.addEventListener('keydown', function (e) {
    if (e.key === 'Escape') document.querySelectorAll('.lapis.terbuka').forEach(tutupLapis);
  });

  // selisih kas pada modal "Tutup Kas"
  document.addEventListener('input', function (e) {
    if (e.target.matches('[data-kas-fisik]')) {
      var nila = parseInt((e.target.value || '0').replace(/\D/g, ''), 10) || 0;
      var seharusnya = 1250000, selisih = nila - seharusnya;
      var out = document.querySelector('[data-selisih]');
      if (out) {
        out.textContent = (selisih === 0 ? 'Pas — tidak ada selisih' : (selisih > 0 ? 'Lebih ' : 'Kurang ') + rupiah(Math.abs(selisih)));
        out.className = 'chip ' + (selisih === 0 ? 'chip-success' : 'chip-warn');
      }
    }
  });

  // ------------------------------ GERAK MASUK ------------------------------
  function siapkanGerak() {
    var el = document.querySelectorAll('.naik,.bertahap');
    if (!('IntersectionObserver' in window)) {
      el.forEach(function (x) { x.classList.add('tampil'); });
      return;
    }
    var io = new IntersectionObserver(function (masuk) {
      masuk.forEach(function (m) { if (m.isIntersecting) { m.target.classList.add('tampil'); io.unobserve(m.target); } });
    }, { rootMargin: '0px 0px -8% 0px', threshold: .08 });
    el.forEach(function (x) { io.observe(x); });
  }

  // dipakai halaman kasir untuk mengisi contoh pesanan saat dibuka
  window.RB = { tambah: tambah, hitung: hitung, toast: toast, rupiah: rupiah };

  // ------------------------------ SAAT DIBUKA ------------------------------
  document.addEventListener('DOMContentLoaded', function () {
    buatPemilih();
    pasangTema(baca(KEY_TEMA) || document.documentElement.getAttribute('data-theme') || 'terang');
    pasangKerapatan(baca(KEY_RAPAT) || document.documentElement.getAttribute('data-density') || 'padat');
    gambarKeranjang();
    siapkanGerak();
    var jam = document.querySelector('[data-jam]');
    if (jam) {
      var d = new Date();
      jam.textContent = String(d.getHours()).padStart(2, '0') + ':' + String(d.getMinutes()).padStart(2, '0');
    }
  });
})();
