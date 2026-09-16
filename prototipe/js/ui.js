/* Resto Barokah — prototipe desain (tanpa pustaka luar, tanpa internet)
   Isi: ganti tema (10 pilihan) · ganti kerapatan · keranjang +/− ·
        modal mengambang (konfirmasi bayar) · toast (pesan berhasil) ·
        animasi masuk berjenjang · contoh "Cek Voucher" (hanya membaca). */

(function () {
  var KEY_TEMA = 'rb-tema';
  var KEY_RAPAT = 'rb-kerapatan';

  var NAMA_TEMA = {
    terang: 'Terang Bersih', hangat: 'Hangat Kedai', gelap: 'Gelap Dapur', kontras: 'Kontras Tinggi',
    bara: 'Bara Panggang', vintage: 'Vintage Klasik', alam: 'Alam Hijau',
    tropis: 'Tropis Segar', pastel: 'Pastel Manis', etnik: 'Etnik Nusantara'
  };
  var RUPIAH = function (n) { return 'Rp ' + n.toLocaleString('id-ID'); };

  function simpan(k, v) { try { localStorage.setItem(k, v); } catch (e) {} }
  function baca(k) { try { return localStorage.getItem(k); } catch (e) { return null; } }

  /* ---------------- TEMA ---------------- */
  function pasangTema(nama) {
    if (!NAMA_TEMA[nama]) nama = 'terang';
    document.documentElement.setAttribute('data-theme', nama);
    document.querySelectorAll('[data-set-tema]').forEach(function (b) {
      b.setAttribute('aria-pressed', String(b.getAttribute('data-set-tema') === nama));
    });
    document.querySelectorAll('[data-nama-tema]').forEach(function (el) { el.textContent = NAMA_TEMA[nama]; });
    var warna = getComputedStyle(document.documentElement).getPropertyValue('--accent').trim();
    document.querySelectorAll('[data-swatch-tema]').forEach(function (el) { el.style.background = warna || 'var(--accent)'; });
    simpan(KEY_TEMA, nama);
  }

  /* ---------------- KERAPATAN ---------------- */
  function pasangKerapatan(nama) {
    if (nama !== 'padat' && nama !== 'nyaman') nama = 'padat';
    document.documentElement.setAttribute('data-density', nama);
    document.querySelectorAll('[data-set-rapat]').forEach(function (b) {
      b.setAttribute('aria-pressed', String(b.getAttribute('data-set-rapat') === nama));
    });
    var label = document.querySelector('[data-label-rapat]');
    if (label) label.textContent = nama === 'padat' ? 'Mode Kasir (padat)' : 'Mode Katalog (berfoto)';
    simpan(KEY_RAPAT, nama);
  }

  /* ---------------- MODAL & TOAST ---------------- */
  function bukaLapisan(id) {
    var el = document.getElementById(id);
    if (!el) return;
    el.classList.add('buka');
    var fokus = el.querySelector('button, [href], input');
    if (fokus) fokus.focus();
  }
  function tutupLapisan(el) {
    if (typeof el === 'string') el = document.getElementById(el);
    if (el) el.classList.remove('buka');
  }
  function pesanBerhasil(teks) {
    var t = document.getElementById('toast');
    if (!t) return;
    var isi = t.querySelector('[data-toast-teks]');
    if (isi && teks) isi.textContent = teks;
    t.classList.add('tampil');
    clearTimeout(t._waktu);
    t._waktu = setTimeout(function () { t.classList.remove('tampil'); }, 2600);
  }

  /* ---------------- KERANJANG ---------------- */
  function hitungUlang() {
    var baris = document.querySelectorAll('[data-baris-keranjang]');
    if (!baris.length) return;
    var subtotal = 0, jumlah = 0;
    baris.forEach(function (b) {
      var harga = parseInt(b.getAttribute('data-harga'), 10) || 0;
      var q = b.querySelector('.qty span');
      var n = parseInt(q ? q.textContent : '0', 10) || 0;
      var total = harga * n;
      subtotal += total; jumlah += n;
      var out = b.querySelector('[data-total-baris]');
      if (out) out.textContent = RUPIAH(total);
    });
    var pb1 = Math.round(subtotal * 0.1), service = Math.round(subtotal * 0.05), diskon = jumlah ? 15000 : 0;
    var total = subtotal + pb1 + service - diskon;
    var set = function (sel, nilai) { var el = document.querySelector(sel); if (el) el.textContent = nilai; };
    set('[data-subtotal]', RUPIAH(subtotal));
    set('[data-pb1]', RUPIAH(pb1));
    set('[data-service]', RUPIAH(service));
    set('[data-diskon]', '− ' + RUPIAH(diskon));
    set('[data-total]', RUPIAH(total));
    set('[data-tombol-bayar]', 'Bayar Sekarang · ' + RUPIAH(total));
    set('[data-jumlah-item]', jumlah + ' item');
    set('[data-total-ringkas]', RUPIAH(total));
    var uang = document.getElementById('uang-diterima');
    if (uang) uang.placeholder = RUPIAH(subtotal + 20000);
    var kembali = document.querySelector('[data-kembalian]');
    if (kembali) kembali.textContent = RUPIAH(20000);
  }

  /* ---------------- ANIMASI MASUK BERJENJANG ---------------- */
  function animasiMasuk() {
    var target = document.querySelectorAll('[data-muncul]');
    target.forEach(function (el, i) {
      el.style.animationDelay = (i * 55) + 'ms';
      el.classList.add('muncul');
    });
    // grafik batang: tumbuhkan setelah tampil
    setTimeout(function () {
      document.querySelectorAll('.bars .bar > span').forEach(function (s) {
        var h = s.getAttribute('data-tinggi');
        if (h) s.style.height = h;
      });
      document.querySelectorAll('.track > i').forEach(function (s) {
        var w = s.getAttribute('data-lebar');
        if (w) s.style.width = w;
      });
    }, 120);
  }

  /* ---------------- KLIK ---------------- */
  document.addEventListener('click', function (e) {
    var t = e.target.closest('[data-set-tema]');
    if (t) { pasangTema(t.getAttribute('data-set-tema')); var p = t.closest('details'); if (p) p.open = false; return; }

    var r = e.target.closest('[data-set-rapat]');
    if (r) { pasangKerapatan(r.getAttribute('data-set-rapat')); return; }

    var q = e.target.closest('[data-qty]');
    if (q) {
      var kotak = q.closest('.qty'), out = kotak.querySelector('span');
      var n = parseInt(out.textContent, 10) + (q.getAttribute('data-qty') === 'plus' ? 1 : -1);
      if (n < 0) n = 0;
      out.textContent = n;
      var baris = q.closest('[data-baris-keranjang]');
      if (baris) baris.style.opacity = n === 0 ? '.45' : '1';
      hitungUlang();
      return;
    }

    var tab = e.target.closest('.tab');
    if (tab && tab.parentElement && tab.parentElement.classList.contains('tabs')) {
      tab.parentElement.querySelectorAll('.tab').forEach(function (x) { x.setAttribute('aria-selected', 'false'); });
      tab.setAttribute('aria-selected', 'true');
      return;
    }

    var add = e.target.closest('.add-btn, [data-tambah]');
    if (add) {
      e.preventDefault();
      var asal = add.innerHTML;
      add.innerHTML = '✓';
      setTimeout(function () { add.innerHTML = asal; }, 800);
      pesanBerhasil('Ditambahkan ke pesanan · ' + (add.getAttribute('data-nama') || 'menu'));
      return;
    }

    var menu = e.target.closest('.menu-item');
    if (menu && !e.target.closest('[data-tambah]')) {
      pesanBerhasil('Ditambahkan ke keranjang · ' + (menu.getAttribute('data-nama') || ''));
      hitungUlang();
      return;
    }

    var pay = e.target.closest('.pay');
    if (pay) {
      pay.parentElement.querySelectorAll('.pay').forEach(function (x) { x.setAttribute('aria-pressed', 'false'); });
      pay.setAttribute('aria-pressed', 'true');
      var hint = document.querySelector('[data-hint-bayar]');
      if (hint) hint.textContent = 'Metode dipilih: ' + pay.textContent.trim();
      return;
    }

    var buka = e.target.closest('[data-buka-lapisan]');
    if (buka) { e.preventDefault(); bukaLapisan(buka.getAttribute('data-buka-lapisan')); return; }

    if (e.target.closest('[data-tutup-lapisan]')) { tutupLapisan(e.target.closest('.lapisan')); return; }
    if (e.target.classList && e.target.classList.contains('lapisan')) { tutupLapisan(e.target); return; }

    if (e.target.closest('[data-bayar-selesai]')) {
      tutupLapisan('modal-bayar');
      pesanBerhasil('Pembayaran berhasil · struk dikirim');
      return;
    }

    var cek = e.target.closest('[data-cek-voucher]');
    if (cek) {
      var input = document.getElementById('kode-voucher');
      var hasil = document.querySelector('[data-hasil-voucher]');
      var kode = ((input && input.value) || '').trim().toUpperCase();
      if (!hasil) return;
      if (!kode) { hasil.textContent = 'Masukkan kode voucher dulu, contoh: UNDANG-7K2M.'; hasil.className = 'chip chip-warn'; return; }
      hasil.textContent = 'Voucher ' + kode + ' sah · Diskon Rp 15.000 · berlaku sampai 30 Sep · BELUM dipakai (aman)';
      hasil.className = 'chip chip-success';
      return;
    }

    document.querySelectorAll('details.picker[open]').forEach(function (d) { if (!d.contains(e.target)) d.open = false; });
  });

  document.addEventListener('keydown', function (e) {
    if (e.key === 'Escape') document.querySelectorAll('.lapisan.buka').forEach(tutupLapisan);
  });

  document.addEventListener('DOMContentLoaded', function () {
    pasangTema(baca(KEY_TEMA) || 'terang');
    pasangKerapatan(baca(KEY_RAPAT) || 'padat');
    hitungUlang();
    animasiMasuk();
    var jam = document.querySelector('[data-jam]');
    if (jam) { var d = new Date(); jam.textContent = String(d.getHours()).padStart(2, '0') + ':' + String(d.getMinutes()).padStart(2, '0'); }
  });
})();
