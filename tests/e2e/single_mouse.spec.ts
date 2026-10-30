import { expect, test, type Page } from '@playwright/test'

const VIEWPORT = { width: 1280, height: 720 }

const CLIPS = {
	p1Hud: { x: 24, y: 20, width: 286, height: 215 },
	p2Hud: { x: 970, y: 20, width: 286, height: 215 },
	centralCannon: { x: 612, y: 570, width: 56, height: 76 },
	goldValue: { x: 24, y: 100, width: 140, height: 38 },
	levelValue: { x: 24, y: 142, width: 150, height: 38 },
	fireButton: { x: 545, y: 616, width: 190, height: 80 },
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

async function waitForRafDuration(page: Page, durationMs: number) {
	await page.evaluate(
		async (duration) => {
			const start = performance.now()
			while (performance.now() - start < duration) {
				await new Promise<void>((resolve) => requestAnimationFrame(() => resolve()))
			}
		},
		durationMs,
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

test('E2E-M02 single-player mouse aim, fire, HUD controls, and audio', async ({ page }) => {
	test.setTimeout(120_000)

	const consoleErrors: string[] = []
	const pageErrors: string[] = []

	page.on('console', (message) => {
		if (message.type() === 'error') {
			consoleErrors.push(message.text())
		}
	})
	page.on('pageerror', (error) => pageErrors.push(error.message))

	await page.addInitScript(() => {
		const contexts: AudioContext[] = []
		Object.defineProperty(globalThis, '__playwrightAudioContexts', {
			configurable: false,
			enumerable: false,
			value: contexts,
			writable: false,
		})

		for (const constructorName of ['AudioContext', 'webkitAudioContext'] as const) {
			const original = (globalThis as typeof globalThis & Record<string, unknown>)[constructorName]
			if (typeof original !== 'function') {
				continue
			}

			const instrumented = new Proxy(original, {
				construct(target, argumentsList, newTarget) {
					const context = Reflect.construct(target, argumentsList, newTarget) as AudioContext
					contexts.push(context)
					return context
				},
			})

			Object.defineProperty(globalThis, constructorName, {
				configurable: true,
				enumerable: false,
				value: instrumented,
				writable: true,
			})
		}
	})

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

	const selectionP1HudArea = await page.screenshot({ clip: CLIPS.p1Hud })
	const selectionCannonArea = await page.screenshot({ clip: CLIPS.centralCannon })

	// The frozen mode-selection contract defaults to single-player mouse control.
	await canvas.click({ position: { x: 640, y: 590 } })

	await expect
		.poll(async () => {
			const current = await page.screenshot({ clip: CLIPS.p1Hud })
			return current.equals(selectionP1HudArea)
		}, { message: 'Start should enter the default single-player battle and reveal the P1 HUD' })
		.toBe(false)
	await waitForAnimationFrames(page)

	const battleP1Hud = await page.screenshot({ clip: CLIPS.p1Hud })
	const battleP2Hud = await page.screenshot({ clip: CLIPS.p2Hud })
	const battleCannon = await page.screenshot({ clip: CLIPS.centralCannon })
	expect(battleP1Hud.equals(battleP2Hud), 'single-player battle must not show a mirrored P2 HUD').toBe(false)
	expect(
		battleCannon.equals(selectionCannonArea),
		'single-player battle must visibly add the central cannon',
	).toBe(false)

	await expect
		.poll(
			() =>
				page.evaluate(() => {
					const contexts = (globalThis as typeof globalThis & {
						__playwrightAudioContexts?: AudioContext[]
					}).__playwrightAudioContexts
					return contexts?.map((context) => context.state) ?? []
				}),
			{
				message: 'the first canvas interaction should leave a Web Audio context running',
				timeout: 30_000,
			},
		)
		.toContain('running')

	await page.mouse.move(350, 300)
	await waitForAnimationFrames(page, 2)
	const aimedLeft = await page.screenshot({ clip: CLIPS.centralCannon })
	await page.mouse.move(930, 300)
	await waitForAnimationFrames(page, 2)
	const aimedRight = await page.screenshot({ clip: CLIPS.centralCannon })
	expect(aimedRight.equals(aimedLeft), 'moving the pointer across the battle should visibly rotate the cannon').toBe(false)

	// The multiplier buttons change only the multiplier display. Gold staying identical
	// proves the GUI click was consumed and did not also trigger a battle shot.
	const initialLevel = await page.screenshot({ clip: CLIPS.levelValue })
	const goldBeforeHudClicks = await page.screenshot({ clip: CLIPS.goldValue })
	await page.mouse.click(770, 656)
	await waitForAnimationFrames(page, 2)
	const raisedLevel = await page.screenshot({ clip: CLIPS.levelValue })
	const goldAfterPlus = await page.screenshot({ clip: CLIPS.goldValue })
	expect(raisedLevel.equals(initialLevel), 'HUD plus must visibly change the cannon multiplier').toBe(false)
	expect(goldAfterPlus.equals(goldBeforeHudClicks), 'HUD plus must not misfire a battle shot').toBe(true)

	await page.mouse.click(495, 656)
	await waitForAnimationFrames(page, 2)
	const restoredLevel = await page.screenshot({ clip: CLIPS.levelValue })
	const goldAfterMinus = await page.screenshot({ clip: CLIPS.goldValue })
	expect(restoredLevel.equals(initialLevel), 'HUD minus must visibly restore the original multiplier').toBe(true)
	expect(goldAfterMinus.equals(goldBeforeHudClicks), 'HUD minus must not misfire a battle shot').toBe(true)

	const goldBeforeBattleClick = await page.screenshot({ clip: CLIPS.goldValue })
	await page.mouse.click(350, 500)
	await expect
		.poll(async () => {
			const current = await page.screenshot({ clip: CLIPS.goldValue })
			return current.equals(goldBeforeBattleClick)
		}, { message: 'a battle-area left click should produce visible firing economy feedback' })
		.toBe(false)

	const battleHoldGoldFrames = [await page.screenshot({ clip: CLIPS.goldValue })]
	await page.mouse.move(350, 500)
	await page.mouse.down()
	try {
		for (let index = 0; index < 4; index += 1) {
			await waitForRafDuration(page, 280)
			battleHoldGoldFrames.push(await page.screenshot({ clip: CLIPS.goldValue }))
		}
	} finally {
		await page.mouse.up()
	}
	const uniqueBattleHoldFrames = new Set(
		battleHoldGoldFrames.map((image) => image.toString('base64')),
	)
	expect(
		uniqueBattleHoldFrames.size,
		'holding the battle-area left button should produce repeated visible firing changes',
	).toBeGreaterThanOrEqual(3)

	const fireButtonBefore = await page.screenshot({ clip: CLIPS.fireButton })
	const hudHoldGoldFrames = [await page.screenshot({ clip: CLIPS.goldValue })]
	await page.mouse.move(640, 656)
	await page.mouse.down()
	try {
		await waitForAnimationFrames(page, 2)
		const fireButtonDown = await page.screenshot({ clip: CLIPS.fireButton })
		expect(fireButtonDown.equals(fireButtonBefore), 'HUD fire must show pressed visual feedback').toBe(false)

		for (let index = 0; index < 3; index += 1) {
			await waitForRafDuration(page, 280)
			hudHoldGoldFrames.push(await page.screenshot({ clip: CLIPS.goldValue }))
		}
	} finally {
		await page.mouse.up()
	}
	const uniqueHudHoldFrames = new Set(hudHoldGoldFrames.map((image) => image.toString('base64')))
	expect(
		uniqueHudHoldFrames.size,
		'holding the HUD fire button should repeatedly produce visible firing changes',
	).toBeGreaterThanOrEqual(2)

	await expectNoScroll(page)
	expect(pageErrors, `uncaught page errors:\n${pageErrors.join('\n')}`).toEqual([])
	expect(consoleErrors, `console errors:\n${consoleErrors.join('\n')}`).toEqual([])
})
