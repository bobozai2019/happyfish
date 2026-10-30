import { expect, test, type Page } from '@playwright/test'

const VIEWPORT = { width: 1280, height: 720 }

const CLIPS = {
	p1Hud: { x: 24, y: 20, width: 286, height: 215 },
	goldValue: { x: 24, y: 100, width: 150, height: 38 },
	levelValue: { x: 24, y: 142, width: 160, height: 38 },
	mouseControls: { x: 440, y: 608, width: 400, height: 92 },
	pausePanel: { x: 430, y: 125, width: 420, height: 470 },
	confirmationPanel: { x: 410, y: 270, width: 460, height: 180 },
	lowerPlayfield: { x: 555, y: 455, width: 170, height: 115 },
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

test('E2E-M05 restart resets the round and return destroys it before a fresh start', async ({
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

	const selectionFrame = await canvas.screenshot()
	const selectionHudArea = await page.screenshot({ clip: CLIPS.p1Hud })
	const selectionMouseControls = await page.screenshot({ clip: CLIPS.mouseControls })

	// Start the frozen default: single-player with mouse controls.
	await canvas.click({ position: { x: 640, y: 590 } })
	await expect
		.poll(async () => !(await page.screenshot({ clip: CLIPS.p1Hud })).equals(selectionHudArea), {
			message: 'Start should enter the default single-player mouse battle',
		})
		.toBe(true)
	await waitForAnimationFrames(page, 2)

	const initialGold = await page.screenshot({ clip: CLIPS.goldValue })
	const initialLevel = await page.screenshot({ clip: CLIPS.levelValue })
	const initialMouseControls = await page.screenshot({ clip: CLIPS.mouseControls })
	const initialLowerPlayfield = await page.screenshot({ clip: CLIPS.lowerPlayfield })
	expect(
		initialMouseControls.equals(selectionMouseControls),
		'the battle must reveal the mouse-only HUD controls',
	).toBe(false)

	// Create visible round state: raise the multiplier and fire a shot that spends coins
	// and leaves a projectile/net in the lower playfield before pausing.
	await page.mouse.click(770, 656)
	await expect
		.poll(async () => !(await page.screenshot({ clip: CLIPS.levelValue })).equals(initialLevel), {
			message: 'raising the multiplier should visibly change the round state',
		})
		.toBe(true)
	const changedLevel = await page.screenshot({ clip: CLIPS.levelValue })

	await page.mouse.click(640, 470)
	await expect
		.poll(async () => !(await page.screenshot({ clip: CLIPS.goldValue })).equals(initialGold), {
			message: 'firing should visibly spend round coins',
		})
		.toBe(true)
	const changedGold = await page.screenshot({ clip: CLIPS.goldValue })
	await page.keyboard.press('Escape')
	const battlePauseArea = await page.screenshot({ clip: CLIPS.pausePanel })
	await expect
		.poll(async () => !(await page.screenshot({ clip: CLIPS.pausePanel })).equals(battlePauseArea), {
			message: 'Escape should visibly open the pause overlay',
		})
		.toBe(true)
	const restartPausePanel = await page.screenshot({ clip: CLIPS.pausePanel })

	const confirmationAreaBeforeRestart = await page.screenshot({ clip: CLIPS.confirmationPanel })
	await canvas.click({ position: { x: 640, y: 495 } })
	await expect
		.poll(async () => !(await page.screenshot({ clip: CLIPS.confirmationPanel })).equals(confirmationAreaBeforeRestart), {
			message: 'Restart should open its confirmation panel',
		})
		.toBe(true)

	await canvas.click({ position: { x: 560, y: 347 } })
	await expect
		.poll(async () => ({
			goldReset: (await page.screenshot({ clip: CLIPS.goldValue })).equals(initialGold),
			levelReset: (await page.screenshot({ clip: CLIPS.levelValue })).equals(initialLevel),
			pauseClosed: !(await page.screenshot({ clip: CLIPS.pausePanel })).equals(restartPausePanel),
		}), { message: 'confirmed restart should reset economy and multiplier and resume play' })
		.toEqual({ goldReset: true, levelReset: true, pauseClosed: true })

	expect(changedGold.equals(initialGold), 'the pre-restart coin change must be observable').toBe(false)
	expect(changedLevel.equals(initialLevel), 'the pre-restart multiplier change must be observable').toBe(false)
	expect(
		(await page.screenshot({ clip: CLIPS.mouseControls })).equals(initialMouseControls),
		'restart must preserve single-player mouse controls and their HUD buttons',
	).toBe(true)
	expect(
		(await page.screenshot({ clip: CLIPS.lowerPlayfield })).equals(initialLowerPlayfield),
		'restart must restore the stable lower playfield without inheriting projectile/net visuals',
	).toBe(true)

	// Return requires a second explicit confirmation and must destroy the battle UI.
	const beforeSecondPause = await page.screenshot({ clip: CLIPS.pausePanel })
	await page.keyboard.press('Escape')
	await expect
		.poll(async () => !(await page.screenshot({ clip: CLIPS.pausePanel })).equals(beforeSecondPause), {
			message: 'Escape should reopen the pause overlay after a restart',
		})
		.toBe(true)
	const secondPausePanel = await page.screenshot({ clip: CLIPS.pausePanel })
	const confirmationAreaBeforeReturn = await page.screenshot({ clip: CLIPS.confirmationPanel })
	await canvas.click({ position: { x: 640, y: 570 } })
	await expect
		.poll(async () => !(await page.screenshot({ clip: CLIPS.confirmationPanel })).equals(confirmationAreaBeforeReturn), {
			message: 'Return should visibly replace the pause menu with a confirmation',
		})
		.toBe(true)
	await canvas.click({ position: { x: 560, y: 347 } })

	await expect
		.poll(async () => (await canvas.screenshot()).equals(selectionFrame), {
			message: 'confirmed return should restore the stable mode-selection page',
		})
		.toBe(true)
	expect(
		(await page.screenshot({ clip: CLIPS.p1Hud })).equals(selectionHudArea),
		'return should remove the battle HUD with the destroyed round',
	).toBe(true)
	expect(
		(await page.screenshot({ clip: CLIPS.mouseControls })).equals(selectionMouseControls),
		'return should remove the mouse battle controls',
	).toBe(true)

	// Starting again from the remembered single/mouse selection creates another clean round.
	await canvas.click({ position: { x: 640, y: 590 } })
	await expect
		.poll(async () => ({
			goldFresh: (await page.screenshot({ clip: CLIPS.goldValue })).equals(initialGold),
			levelFresh: (await page.screenshot({ clip: CLIPS.levelValue })).equals(initialLevel),
			mouseHudRestored: (await page.screenshot({ clip: CLIPS.mouseControls })).equals(initialMouseControls),
			pauseAbsent: !(await page.screenshot({ clip: CLIPS.pausePanel })).equals(secondPausePanel),
		}), { message: 'a later Start should create a fresh, running single-player mouse round' })
		.toEqual({ goldFresh: true, levelFresh: true, mouseHudRestored: true, pauseAbsent: true })

	await expectNoScroll(page)
	expect(pageErrors, `uncaught page errors:\n${pageErrors.join('\n')}`).toEqual([])
	expect(consoleErrors, `console errors:\n${consoleErrors.join('\n')}`).toEqual([])
})
