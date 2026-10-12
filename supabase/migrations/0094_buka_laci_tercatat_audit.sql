-- 0094 — Jejak audit "buka laci tanpa transaksi" (PMB1-F-010 · kartu B-F-02)
--
-- Cacat (temuan PMB1-F-010, hakim H-F-02): PRD M3 baris 99, TECH_SPEC baris 396, dan
-- KEAMANAN §… menjanjikan jejak audit untuk "buka laci tanpa transaksi", tetapi repo
-- tidak punya aksi audit/RPC/kolom apa pun untuk itu (grep "buka laci"/"buka_laci" → 0).
-- Satu-satunya perintah laci di aplikasi hanyalah byte ESC/POS saat cetak struk tunai —
-- tidak pernah tercatat siapa membuka laci dan kapan. Kontrol anti-fraud dijanjikan tiga
-- dokumen fondasi tanpa wujud.
--
-- Perbaikan: RPC `catat_buka_laci` — SATU pintu tercatat untuk membuka laci kas.
-- Klien TIDAK boleh mengirim perintah kick laci sebelum RPC ini sukses: helper
-- `aplikasi/src/lib/laci.ts` memanggil RPC lebih dulu dan hanya menerbitkan byte
-- ESC/POS setelah peladen mencatat jejaknya ("laci hanya terbuka bila tercatat").
--
-- Latar peladen saja yang menulis catatan_audit (tabelnya revoke semua; RLS hanya-baca),
-- pelaku diambil dari auth.uid() — tidak bisa dikarang klien (aturan AUD-3).

create or replace function public.catat_buka_laci(
  p_konteks text default 'manual',
  p_alasan text default null
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_uid uuid;
  v_peran text;
  v_penyewa uuid;
  v_konteks text;
  v_alasan text;
begin
  v_uid := auth.uid();
  v_peran := public.peran_saya();

  if v_uid is null or v_peran is null then
    return jsonb_build_object(
      'berhasil', false,
      'kode', 'MASUK_WAJIB',
      'pesan', 'Buka laci hanya bisa dilakukan staf yang sedang masuk, dan wajib tercatat.'
    );
  end if;

  -- Laci kas adalah urusan kasir (dan atasan yang mengawasi). Dapur/pelayan tidak
  -- punya kebutuhan membuka laci; janji PRD M3 menyebutnya kontrol anti-fraud.
  if v_peran not in ('owner_pusat', 'admin_cabang', 'kasir') then
    return jsonb_build_object(
      'berhasil', false,
      'kode', 'PERAN_TIDAK_BOLEH',
      'pesan', 'Peran ini tidak berhak membuka laci kas.'
    );
  end if;

  v_konteks := coalesce(nullif(btrim(p_konteks), ''), 'manual');
  v_alasan := nullif(btrim(coalesce(p_alasan, '')), '');
  -- Buka laci TANPA transaksi wajib menyebut alasan — jejak tanpa alasan tidak
  -- berguna saat audit. Konteks 'cetak_struk_tunai' (laci ikut struk) bebas alasan.
  if v_konteks = 'manual' and v_alasan is null then
    return jsonb_build_object(
      'berhasil', false,
      'kode', 'ALASAN_WAJIB',
      'pesan', 'Buka laci tanpa transaksi wajib menyebut alasan.'
    );
  end if;

  select p.penyewa_id into v_penyewa from public.pengguna p where p.id = v_uid;
  if v_penyewa is null then
    return jsonb_build_object(
      'berhasil', false,
      'kode', 'PENYEWA_TIDAK_JELAS',
      'pesan', 'Penyewa pemanggil tidak dikenal.'
    );
  end if;

  insert into public.catatan_audit (
    penyewa_id, pelaku_id, aksi, entitas, entitas_id, nilai_baru, waktu
  ) values (
    v_penyewa,
    v_uid,
    'buka_laci',
    'laci_kas',
    null,
    jsonb_build_object('konteks', v_konteks, 'alasan', v_alasan),
    now()
  );

  return jsonb_build_object(
    'berhasil', true,
    'kode', 'TERCATAT',
    'pesan', 'Buka laci tercatat di jejak audit.'
  );
end;
$$;

comment on function public.catat_buka_laci(text, text) is
  'PMB1-F-010: satu-satunya pintu sah membuka laci kas — mencatat aksi "buka_laci" ke catatan_audit SEBELUM perangkat mengirim perintah kick ke printer (helper laci.ts). Buka tanpa transaksi wajib beralasan.';

-- anon DIBERI execute supaya keadaan "belum masuk" dijawab pesan jujur MASUK_WAJIB
-- (fail-closed tetap di dalam fungsi), bukan galat permission yang membingungkan —
-- pola sama dengan verifikasi_pin_perangkat (0091).
revoke all on function public.catat_buka_laci(text, text) from public;
grant execute on function public.catat_buka_laci(text, text) to anon, authenticated, service_role;
