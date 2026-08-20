import { defineConfig, devices } from '@playwright/test'

export default defineConfig({
  testDir: './specs',
  timeout: 30_000,
  use: { baseURL: process.env.BASE_URL ?? 'http://localhost:5173', trace: 'retain-on-failure', screenshot: 'only-on-failure' },
  reporter: [['html', { open: 'never' }], ['list']],
  webServer: { command: 'cd ../../client && npm run dev -- --host 127.0.0.1', url: 'http://127.0.0.1:5173', reuseExistingServer: true },
  projects: [{ name: 'chromium', use: { ...devices['Desktop Chrome'] } }]
})
