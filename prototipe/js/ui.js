/* Resto Barokah — prototipe desain (tanpa pustaka luar, tanpa internet)
   Tugasnya sedikit saja: ganti tema, ganti kerapatan, tombol +/-, dan contoh "Cek Voucher". */

(function () {
  var KEY_TEMA = 'rb-tema';
  var KEY_RAPAT = 'rb-kerapatan';

  function simpan(k, v) { try { localStorage.setItem(k, v); } catch (e) {} }
  function baca(k) { try { return localStorage.getItem(k); } catch (e) { return null; } }

  // ---------- TEMA ----------
  function pasangTema(nama) {
    document.documentElement.setAttribute('data-theme', nama);
    document.querySelectorAll('[data-set-tema]').forEach(function (b) {
      b.setAttribute('aria-pressed', String(b.getAttribute('data-set-tema') === nama));
    });
    simpan(KEY_TEMA, nama);
  }

  // ---------- KERAPATAN (Mode Kasir padat vs Mode Katalog) ----------
  function pasangKerapatan(nama) {
    document.documentElement.setAttribute('data-density', nama);
    document.querySelectorAll('[data-set-rapat]').forEach(function (b) {
      b.setAttribute('aria-pressed', String(b.getAttribute('data-set-rapat') === nama));
    });
    var label = document.querySelector('[data-label-rapat]');
    if (label) label.textContent = nama === 'padat' ? 'Mode Kasir (padat)' : 'Mode Katalog (berfoto)';
    simpan(KEY_RAPAT, nama);
  }

  document.addEventListener('click', function (e) {
    var t = e.target.closest('[data-set-tema]');
    if (t) { pasangTema(t.getAttribute('data-set-tema')); return; }

    var r = e.target.closest('[data-set-rapat]');
    if (r) { pasangKerapatan(r.getAttribute('data-set-rapat')); return; }

    // Tombol + / - pada keranjang dan jumlah porsi
    var q = e.target.closest('[data-qty]');
    if (q) {
      var box = q.closest('.qty');
      var out = box.querySelector('span');
      var n = parseInt(out.textContent, 10) + (q.getAttribute('data-qty') === 'plus' ? 1 : -1);
      if (n < 0) n = 0;
      out.textContent = n;
      var line = q.closest('.cart-line');
      if (line && n === 0) line.style.opacity = .45;
      return;
    }

    // Tab kategori
    var tab = e.target.closest('.tab');
    if (tab && tab.parentElement.classList.contains('tabs')) {
      tab.parentElement.querySelectorAll('.tab').forEach(function (x) { x.setAttribute('aria-selected', 'false'); });
      tab.setAttribute('aria-selected', 'true');
      return;
    }

    // Pilihan metode bayar
    var pay = e.target.closest('.pay');
    if (pay) {
      pay.parentElement.querySelectorAll('.pay').forEach(function (x) { x.setAttribute('aria-pressed', 'false'); });
      pay.setAttribute('aria-pressed', 'true');
      var hint = document.querySelector('[data-hint-bayar]');
      if (hint) hint.textContent = 'Metode dipilih: ' + pay.textContent.trim();
      return;
    }

    // Contoh "Cek Voucher" — hanya membaca, tidak memakai voucher
    var cek = e.target.closest('[data-cek-voucher]');
    if (cek) {
      var input = document.querySelector('#kode-voucher');
      var hasil = document.querySelector('[data-hasil-voucher]');
      var kode = (input && input.value || '').trim().toUpperCase();
      if (!hasil) return;
      if (!kode) { hasil.textContent = 'Masukkan kode voucher dulu, contoh: UNDANG-7K2M.'; hasil.className = 'chip chip-warn mt-8'; return; }
      hasil.textContent = 'Voucher ' + kode + ' sah · Diskon Rp 15.000 · berlaku sampai 30 Sep · BELUM dipakai (aman)';
      hasil.className = 'chip chip-success mt-8';
      return;
    }
  });

  // ---------- SAAT HALAMAN DIBUKA ----------
  document.addEventListener('DOMContentLoaded', function () {
    pasangTema(baca(KEY_TEMA) || 'terang');
    pasangKerapatan(baca(KEY_RAPAT) || 'padat');
    var jam = document.querySelector('[data-jam]');
    if (jam) {
      var d = new Date();
      jam.textContent = String(d.getHours()).padStart(2, '0') + ':' + String(d.getMinutes()).padStart(2, '0');
    }
  });
})();
