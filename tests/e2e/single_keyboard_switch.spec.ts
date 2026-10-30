import { expect, test, type Page } from '@playwright/test'

const VIEWPORT = { width: 1280, height: 720 }

const CLIPS = {
	modeControlRow: { x: 390, y: 385, width: 500, height: 72 },
	p1Hud: { x: 24, y: 20, width: 286, height: 215 },
	goldValue: { x: 24, y: 100, width: 150, height: 38 },
	levelValue: { x: 24, y: 142, width: 160, height: 38 },
	centralCannon: { x: 606, y: 566, width: 68, height: 116 },
	mouseControls: { x: 440, y: 608, width: 400, height: 92 },
	pausePanel: { x: 430, y: 125, width: 420, height: 470 },
	pauseControlRow: { x: 480, y: 288, width: 320, height: 54 },
} as const

async function waitForAnimationFrames(page: Page, count = 3) {
	await page.evaluate(
		async (frameCount) => {
			for (let index = 0; index < frameCount; index += 1) {
				await new Promise<void>((resolve) => requestAnimationFrame(() => resolve()))
			}
		},
		count,
	)
}

async function pressForFrames(page: Page, key: string, frameCount: number) {
	await page.keyboard.down(key)
	try {
		await waitForAnimationFrames(page, frameCount)
	} finally {
		await page.keyboard.up(key)
	}
}

async function expectNoScroll(page: Page) {
	await expect
		.poll(() =>
			page.evaluate(() => {
				const scrollingElement = document.scrollingElement
				return {
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
			scrollX: 0,
			scrollY: 0,
			scrollWidth: VIEWPORT.width,
			scrollHeight: VIEWPORT.height,
			clientWidth: VIEWPORT.width,
			clientHeight: VIEWPORT.height,
		})
}

test('E2E-M03 single-player keyboard controls and pause-time control switching', async ({
	page,
}) => {
	test.setTimeout(120_000)

	const consoleErrors: string[] = []
	const pageErrors: string[] = []

	page.on('console', (message) => {
		if (message.type() === 'error') {
			consoleErrors.push(message.text())
		}
	})
	page.on('pageerror', (error) => pageErrors.push(error.message))

	await page.setViewportSize(VIEWPORT)
	const response = await page.goto('/index.html', { waitUntil: 'domcontentloaded' })

	expect(response, 'navigation should return an HTTP response').not.toBeNull()
	expect(response?.ok(), `startup response was ${response?.status()}`).toBe(true)

	const canvas = page.locator('#canvas')
	await expect(canvas).toHaveCount(1)
	await expect(canvas).toBeVisible({ timeout: 60_000 })
	await expect(page.locator('#status-progress')).toBeHidden({ timeout: 60_000 })
	await expect
		.poll(() => canvas.evaluate((element) => ({ width: element.clientWidth, height: element.clientHeight })))
		.toEqual(VIEWPORT)
	await expectNoScroll(page)
	await waitForAnimationFrames(page)

	const mouseSelected = await page.screenshot({ clip: CLIPS.modeControlRow })
	await canvas.click({ position: { x: 755, y: 418 } })
	await expect
		.poll(async () => {
			const current = await page.screenshot({ clip: CLIPS.modeControlRow })
			return current.equals(mouseSelected)
		}, { message: 'selecting Keyboard should visibly update the single-player control choice' })
		.toBe(false)

	const selectionHud = await page.screenshot({ clip: CLIPS.p1Hud })
	await canvas.click({ position: { x: 640, y: 590 } })
	await expect
		.poll(async () => {
			const current = await page.screenshot({ clip: CLIPS.p1Hud })
			return current.equals(selectionHud)
		}, { message: 'Start should enter a single-player keyboard battle' })
		.toBe(false)
	await expectNoScroll(page)

	const cannonBeforeAim = await page.screenshot({ clip: CLIPS.centralCannon })
	await pressForFrames(page, 'a', 18)
	const cannonAfterA = await page.screenshot({ clip: CLIPS.centralCannon })
	expect(cannonAfterA.equals(cannonBeforeAim), 'A should visibly rotate the P1 cannon').toBe(false)

	await pressForFrames(page, 'd', 36)
	const cannonAfterD = await page.screenshot({ clip: CLIPS.centralCannon })
	expect(cannonAfterD.equals(cannonAfterA), 'D should visibly rotate the P1 cannon').toBe(false)

	const initialLevel = await page.screenshot({ clip: CLIPS.levelValue })
	await pressForFrames(page, 'w', 3)
	const raisedLevel = await page.screenshot({ clip: CLIPS.levelValue })
	expect(raisedLevel.equals(initialLevel), 'W should visibly raise the cannon multiplier').toBe(false)

	await pressForFrames(page, 's', 3)
	const restoredLevel = await page.screenshot({ clip: CLIPS.levelValue })
	expect(restoredLevel.equals(initialLevel), 'S should visibly restore the cannon multiplier').toBe(true)

	const goldBeforeSpace = await page.screenshot({ clip: CLIPS.goldValue })
	await pressForFrames(page, 'Space', 3)
	await expect
		.poll(async () => {
			const current = await page.screenshot({ clip: CLIPS.goldValue })
			return current.equals(goldBeforeSpace)
		}, { message: 'Space should produce visible firing economy feedback' })
		.toBe(false)
	await expectNoScroll(page)

	// Keep keyboard inputs physically held across the switch. The router must clear its
	// internal held state when pausing/changing control, even before browser key-up events.
	await page.keyboard.down('a')
	await page.keyboard.down('Space')
	await waitForAnimationFrames(page, 2)
	const beforePausePanel = await page.screenshot({ clip: CLIPS.pausePanel })
	await page.keyboard.press('Escape')
	await expect
		.poll(async () => {
			const current = await page.screenshot({ clip: CLIPS.pausePanel })
			return current.equals(beforePausePanel)
		}, { message: 'Escape should visibly open the pause overlay' })
		.toBe(false)

	const keyboardPauseControls = await page.screenshot({ clip: CLIPS.pauseControlRow })
	await canvas.click({ position: { x: 560, y: 315 } })
	await expect
		.poll(async () => {
			const current = await page.screenshot({ clip: CLIPS.pauseControlRow })
			return current.equals(keyboardPauseControls)
		}, { message: 'pause-time Mouse selection should visibly replace Keyboard selection' })
		.toBe(false)

	await canvas.click({ position: { x: 640, y: 420 } })
	await waitForAnimationFrames(page, 3)
	const mouseModeControls = await page.screenshot({ clip: CLIPS.mouseControls })
	const heldClearGold = await page.screenshot({ clip: CLIPS.goldValue })
	const heldClearCannon = await page.screenshot({ clip: CLIPS.centralCannon })
	await waitForAnimationFrames(page, 24)
	expect(
		(await page.screenshot({ clip: CLIPS.goldValue })).equals(heldClearGold),
		'held Space must not keep firing after switching to mouse',
	).toBe(true)
	expect(
		(await page.screenshot({ clip: CLIPS.centralCannon })).equals(heldClearCannon),
		'held A must not keep rotating after switching to mouse',
	).toBe(true)

	await page.mouse.move(360, 360)
	await waitForAnimationFrames(page, 2)
	const mouseAimedCannon = await page.screenshot({ clip: CLIPS.centralCannon })
	expect(mouseAimedCannon.equals(heldClearCannon), 'mouse movement should immediately aim after switching').toBe(false)

	const goldBeforeMouseFire = await page.screenshot({ clip: CLIPS.goldValue })
	await page.mouse.click(360, 360)
	await expect
		.poll(async () => {
			const current = await page.screenshot({ clip: CLIPS.goldValue })
			return current.equals(goldBeforeMouseFire)
		}, { message: 'battle click should immediately fire after switching to mouse' })
		.toBe(false)
	await page.keyboard.up('Space')
	await page.keyboard.up('a')

	await page.keyboard.press('Escape')
	await waitForAnimationFrames(page, 2)
	await canvas.click({ position: { x: 720, y: 315 } })
	await canvas.click({ position: { x: 640, y: 420 } })
	await waitForAnimationFrames(page, 3)

	const keyboardModeControls = await page.screenshot({ clip: CLIPS.mouseControls })
	expect(
		keyboardModeControls.equals(mouseModeControls),
		'switching back to keyboard should visibly hide the mouse-only HUD controls',
	).toBe(false)

	// The previous mouse shot has left the playfield by now; a keyboard-mode battle click
	// must not change the firing economy because mouse gameplay input is disconnected.
	await waitForAnimationFrames(page, 90)
	const goldBeforeIgnoredClick = await page.screenshot({ clip: CLIPS.goldValue })
	await page.mouse.click(920, 420)
	await waitForAnimationFrames(page, 4)
	const goldAfterIgnoredClick = await page.screenshot({ clip: CLIPS.goldValue })
	expect(
		goldAfterIgnoredClick.equals(goldBeforeIgnoredClick),
		'battle-area click must not fire after switching back to keyboard',
	).toBe(true)

	await expectNoScroll(page)
	expect(pageErrors, `uncaught page errors:\n${pageErrors.join('\n')}`).toEqual([])
	expect(consoleErrors, `console errors:\n${consoleErrors.join('\n')}`).toEqual([])
})
