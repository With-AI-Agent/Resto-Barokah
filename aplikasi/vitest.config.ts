import { defineConfig } from 'vitest/config'

export default defineConfig({
  test: {
    environment: 'node',
    // CSS diolah sungguhan (bukan dibuang) supaya uji bisa MENGUKUR kaskade
    // berkas gaya nyata — lihat src/gaya/kerapatan-css.test.ts.
    css: true,
    include: ['src/**/*.test.{ts,tsx}', 'alat/**/*.test.{ts,tsx}'],
  },
})
