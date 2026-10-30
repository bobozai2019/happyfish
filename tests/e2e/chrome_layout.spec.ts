import { expect, test, type Page } from '@playwright/test'

type Viewport = {
  width: number
  height: number
}

async function waitForStableCanvas(page: Page, viewport: Viewport) {
  await expect
    .poll(
      () =>
        page.evaluate(async (expected) => {
          const samples = []

          for (let index = 0; index < 3; index += 1) {
            await new Promise<void>((resolve) => requestAnimationFrame(() => resolve()))

            const canvas = document.querySelector<HTMLCanvasElement>('#canvas')
            if (!canvas) {
              return false
            }

            const rect = canvas.getBoundingClientRect()
            samples.push({
              backingWidth: canvas.width,
              backingHeight: canvas.height,
              clientWidth: canvas.clientWidth,
              clientHeight: canvas.clientHeight,
              left: rect.left,
              top: rect.top,
              rectWidth: rect.width,
              rectHeight: rect.height,
              devicePixelRatio: window.devicePixelRatio,
            })
          }

          const [first] = samples
          const settled = samples.every(
            (sample) => JSON.stringify(sample) === JSON.stringify(first),
          )

          return (
            settled &&
            first.devicePixelRatio === 1 &&
            first.backingWidth === expected.width &&
            first.backingHeight === expected.height &&
            first.clientWidth === expected.width &&
            first.clientHeight === expected.height &&
            first.left === 0 &&
            first.top === 0 &&
            first.rectWidth === expected.width &&
            first.rectHeight === expected.height
          )
        }, viewport),
      { message: `wait for the Godot canvas to settle at ${viewport.width}x${viewport.height}` },
    )
    .toBe(true)
}

async function expectViewportWithoutScroll(page: Page, viewport: Viewport) {
  await expect
    .poll(() =>
      page.evaluate(() => {
        const scrollingElement = document.scrollingElement

        return {
          innerWidth: window.innerWidth,
          innerHeight: window.innerHeight,
          scrollX: window.scrollX,
          scrollY: window.scrollY,
          scrollWidth: scrollingElement?.scrollWidth ?? 0,
          scrollHeight: scrollingElement?.scrollHeight ?? 0,
          clientWidth: scrollingElement?.clientWidth ?? 0,
          clientHeight: scrollingElement?.clientHeight ?? 0,
        }
      }),
    )
    .toEqual({
      innerWidth: viewport.width,
      innerHeight: viewport.height,
      scrollX: 0,
      scrollY: 0,
      scrollWidth: viewport.width,
      scrollHeight: viewport.height,
      clientWidth: viewport.width,
      clientHeight: viewport.height,
    })
}

test('CHROME-01 Chrome Web startup and responsive layout', async ({ page }) => {
  test.setTimeout(90_000)

  const consoleErrors: string[] = []
  const pageErrors: string[] = []

  page.on('console', (message) => {
    if (message.type() === 'error') {
      consoleErrors.push(message.text())
    }
  })
  page.on('pageerror', (error) => pageErrors.push(error.message))

  await page.setViewportSize({ width: 1280, height: 720 })
  const response = await page.goto('/index.html', { waitUntil: 'domcontentloaded' })

  expect(response, 'navigation should return an HTTP response').not.toBeNull()
  expect(response?.ok(), `startup response was ${response?.status()}`).toBe(true)

  const canvas = page.locator('#canvas')
  await expect(canvas).toHaveCount(1)
  await expect(canvas).toBeVisible()
  await expect(page.locator('#status-progress')).toBeHidden({ timeout: 60_000 })
  await waitForStableCanvas(page, { width: 1280, height: 720 })
  await expectViewportWithoutScroll(page, { width: 1280, height: 720 })
  await page.screenshot({
    path: 'task/happy_fish/验收/screenshots/chrome_playwright_1280x720.png',
  })

  await page.setViewportSize({ width: 1920, height: 1080 })
  await waitForStableCanvas(page, { width: 1920, height: 1080 })
  await expectViewportWithoutScroll(page, { width: 1920, height: 1080 })
  await page.screenshot({
    path: 'task/happy_fish/验收/screenshots/chrome_playwright_1920x1080.png',
  })

  expect(pageErrors, `uncaught page errors:\n${pageErrors.join('\n')}`).toEqual([])
  expect(consoleErrors, `console errors:\n${consoleErrors.join('\n')}`).toEqual([])
})
