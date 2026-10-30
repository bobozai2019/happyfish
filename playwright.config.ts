import { defineConfig } from '@playwright/test'

export default defineConfig({
  testDir: './tests/e2e',
  fullyParallel: false,
  workers: 1,
  reporter: [['list'], ['html', { open: 'never', outputFolder: '.playwright/report' }]],
  outputDir: '.playwright/results',
  use: {
    baseURL: 'http://127.0.0.1:8060',
    browserName: 'chromium',
    channel: 'chrome',
    headless: true,
    trace: 'retain-on-failure',
    screenshot: 'only-on-failure',
    video: 'retain-on-failure'
  },
  projects: [
    {
      name: 'chrome',
      use: {
        browserName: 'chromium',
        channel: 'chrome'
      }
    },
    {
      name: 'edge',
      use: {
        browserName: 'chromium',
        channel: 'msedge'
      }
    }
  ],
  webServer: {
    command: 'python tools/serve_web.py --port 8060',
    url: 'http://127.0.0.1:8060/index.html',
    reuseExistingServer: false,
    timeout: 30_000
  }
})
