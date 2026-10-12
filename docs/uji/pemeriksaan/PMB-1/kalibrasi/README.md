# Kalibrasi PMB-1 — cara kunci jawaban disimpan

Prinsip protokol (`docs/uji/PROTOKOL_AUDIT_INDEPENDEN.md` §7): **kunci jawaban tidak pernah terbaca di repo**. Karena PMB berjalan
lintas banyak sesi (kunci di `/tmp` sesi pembuatnya akan hilang), kunci disimpan **terenkripsi** di sini dan hanya bisa dibuka dengan
kata sandi yang dipegang **Lee** (disampaikan sekali di percakapan saat bahan dibuat; tidak ditulis di repo):

- `KUNCI-TAHAP-<n>.enc` — kunci jawaban, AES-256-CBC (PBKDF2 200.000 iterasi), base64.
- `KUNCI-TAHAP-<n>.sha256` — sidik jari plaintext kunci: membuktikan kunci tidak diubah setelah bahan dibuat.

Membuka (hanya Perencana setelah kartu F-<kalibrasi> masuk, dengan sandi dari Lee):

```bash
openssl enc -d -aes-256-cbc -pbkdf2 -iter 200000 -a -in docs/uji/pemeriksaan/PMB-1/kalibrasi/KUNCI-TAHAP-1.enc -pass pass:<SANDI-DARI-LEE> | tee /tmp/KUNCI-TAHAP-1.md | sha256sum
# sidik jari harus sama dengan isi KUNCI-TAHAP-1.sha256
```

Bila sandi hilang: kunci tidak bisa dibuka → bahan kalibrasi tahap itu dianggap hangus dan Perencana membuat bahan baru (bertanggal
baru; bahan lama tidak dihapus, sesuai protokol §7 butir 4). Pemeriksa & Hakim **dilarang** membuka/meminta kunci.
