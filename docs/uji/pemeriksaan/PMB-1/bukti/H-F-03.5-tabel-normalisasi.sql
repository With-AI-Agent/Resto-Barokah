-- Tabel HAKIM H-F-03.5 (2026-10-02) — apa yang sebenarnya TERSIMPAN untuk tiap penulisan nomor sesudah migrasi 0095.
-- BERKAS INI SENGAJA BERAKHIR GAGAL: runner hanya mencetak baris pertama pesan galat, jadi tabel dikirim lewat
-- `uji.harap(false, ...)` di ujung. Yang dibaca adalah isi pesannya, bukan kata GAGAL.
-- Memanggil fungsi asli public.normalisasi_telepon_pelanggan (0095) — fungsi yang sama dengan yang dipakai pemicu.
-- Dua nomor dianggap SATU identitas oleh kunci unik hanya bila nilai tersimpannya SAMA.
-- Kontrol: baris 1-4 (dasar, +62, 62, tanpa nol) memang menyatu menjadi 081234567890; baris 11-12 untuk telepon
-- rumah dan baris 18-19 (kode area 0622 yang diawali 62) juga menyatu — bukti fungsi bekerja untuk bentuk yang dicakupnya.
select uji.harap(false, 'NORMALISASI ' || (
  select string_agg('[' || v || ' => ' || coalesce(public.normalisasi_telepon_pelanggan(v), 'NULL') || ']', ' ' order by ord)
    from unnest(array[
      '0812-3456-7890','+62 812-3456-7890','62 812 3456 7890','812 3456 7890',
      '+62 (0)812-3456-7890','+62 0812 3456 7890','620812 3456 7890','0062 812 3456 7890','0062-0812-3456-7890','00812 3456 7890',
      '021-5790-1234','+62 21 5790 1234','+62 (0)21 5790 1234','0062 21 5790 1234','21 5790 1234',
      '1','22','0622-123456','+62 622 123456'
    ]) with ordinality as t(v, ord)
));
