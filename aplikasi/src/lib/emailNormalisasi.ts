/**
 * emailNormalisasi.ts — Utilitas normalisasi alamat email & saringan anti-email sekali-pakai (ART-5 & ART-10).
 *
 * Mengapa diperlukan (PRD M10 & TECH_SPEC §9 ART-5):
 *   1. Mencegah satu orang menimbun voucher dengan variasi alias Gmail (titik & tanda `+`).
 *      Di Gmail/Googlemail: `b.u.d.i.santoso@gmail.com` dan `budisantoso+promo@gmail.com`
 *      mengarah ke kotak masuk yang sama (`budisantoso@gmail.com`).
 *   2. Mencegah penggunaan email sementara/sekali-pakai (disposable/burner email) seperti
 *      10minutemail, tempmail, guerrillamail, mailinator, dsb.
 *   3. Memastikan kepatuhan UU PDP (data kontak yang sah & dapat dipertanggungjawabkan).
 */

export interface HasilValidasiEmail {
  sah: boolean
  pesan?: string
  email_asli: string
  email_normalisasi?: string
  domain?: string
  adalah_sekali_pakai?: boolean
}

// Daftar domain email sementara/sekali-pakai yang dikenal
export const DOMAIN_SEKALI_PAKAI = new Set([
  '10minutemail.com',
  '10minutemail.net',
  '10minutemail.org',
  'burnermail.io',
  'crazymailing.com',
  'dispostable.com',
  'disposablemail.com',
  'emailondeck.com',
  'fakeinbox.com',
  'fakemail.net',
  'fakemailgenerator.com',
  'generator.email',
  'getairmail.com',
  'grr.la',
  'guerrillamail.biz',
  'guerrillamail.com',
  'guerrillamail.de',
  'guerrillamail.net',
  'guerrillamail.org',
  'guerrillamailblock.com',
  'inboxkitten.com',
  'mailcatch.com',
  'maildrop.cc',
  'mailinator.com',
  'mohmal.com',
  'mytemp.email',
  'nada.ltd',
  'sharklasers.com',
  'spam4.me',
  'temp-mail.org',
  'tempail.com',
  'tempmail.com',
  'tempmail.net',
  'throwawaymail.com',
  'trashmail.com',
  'trashmail.net',
  'trashmail.org',
  'yopmail.com',
  'yopmail.net',
])

/**
 * Memeriksa apakah domain yang diberikan terdaftar sebagai penyedia email sekali-pakai.
 */
export function apakahEmailSekaliPakai(emailAtauDomain: string): boolean {
  if (!emailAtauDomain) return false
  const input = emailAtauDomain.trim().toLowerCase()
  const domain = input.includes('@') ? input.split('@').pop() || '' : input
  return DOMAIN_SEKALI_PAKAI.has(domain)
}

/**
 * Menghapus titik dan tag `+` dari bagian lokal alamat Gmail.
 */
export function bersihkanGmail(bagianLokal: string): string {
  if (!bagianLokal) return ''
  // 1. Ambil bagian sebelum karakter `+` (abaikan alias sub-addressing)
  const tanpaTag = bagianLokal.split('+')[0] || ''
  // 2. Hapus seluruh tanda titik (.)
  return tanpaTag.replace(/\./g, '')
}

/**
 * Melakukan validasi format, mendeteksi domain sekali-pakai, serta melakukan normalisasi email.
 *
 * Aturan normalisasi:
 * - Domain `gmail.com` dan `googlemail.com`: bagian lokal dibersihkan dari titik dan tag `+`,
 *   domain disatukan ke `gmail.com`.
 * - Domain lain: teks diubah ke huruf kecil (lowercase) dan spasi dihapus (trim).
 */
export function normalisasiEmail(input: string): HasilValidasiEmail {
  const emailMentah = (input ?? '').trim()

  if (!emailMentah) {
    return {
      sah: false,
      pesan: 'Alamat email tidak boleh kosong.',
      email_asli: '',
    }
  }

  // Pola regex email standar: satu '@', bagian lokal sah, domain dengan titik dan minimal 2 huruf TLD
  const polaEmail =
    /^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)+$/
  if (!polaEmail.test(emailMentah)) {
    return {
      sah: false,
      pesan: 'Format alamat email tidak sah.',
      email_asli: emailMentah,
    }
  }

  const bagian = emailMentah.split('@')
  if (bagian.length !== 2) {
    return {
      sah: false,
      pesan: 'Format alamat email tidak sah.',
      email_asli: emailMentah,
    }
  }

  let [lokal, domain] = bagian
  lokal = lokal.toLowerCase()
  domain = domain.toLowerCase()

  // Saringan 1: Anti email sekali-pakai
  if (DOMAIN_SEKALI_PAKAI.has(domain)) {
    return {
      sah: false,
      adalah_sekali_pakai: true,
      pesan:
        'Email sementara atau sekali-pakai tidak diizinkan. Mohon gunakan email pribadi aktif.',
      email_asli: emailMentah,
      domain,
    }
  }

  // Saringan 2: Normalisasi Gmail / Googlemail
  if (domain === 'gmail.com' || domain === 'googlemail.com') {
    domain = 'gmail.com'
    lokal = bersihkanGmail(lokal)
    if (!lokal) {
      return {
        sah: false,
        pesan: 'Bagian nama email Gmail tidak sah.',
        email_asli: emailMentah,
      }
    }
  }

  const hasilNormalisasi = `${lokal}@${domain}`

  return {
    sah: true,
    email_asli: emailMentah,
    email_normalisasi: hasilNormalisasi,
    domain,
    adalah_sekali_pakai: false,
  }
}
