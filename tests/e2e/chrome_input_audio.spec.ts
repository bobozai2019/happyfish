import { expect, test, type Page } from '@playwright/test'

const VIEWPORT = { width: 1280, height: 720 }

const CLIPS = {
	p1Hud: { x: 24, y: 20, width: 286, height: 215 },
	p2Hud: { x: 970, y: 20, width: 286, height: 215 },
	p1Gold: { x: 24, y: 100, width: 150, height: 38 },
	p2Gold: { x: 1110, y: 100, width: 146, height: 38 },
	p1Cannon: { x: 205, y: 570, width: 102, height: 145 },
	p2Cannon: { x: 973, y: 570, width: 102, height: 145 },
	pausePanel: { x: 430, y: 125, width: 420, height: 470 },
	pauseOperationSlot: { x: 480, y: 245, width: 320, height: 100 },
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

async function waitForStableCanvas(page: Page) {
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
							width: rect.width,
							height: rect.height,
							devicePixelRatio: window.devicePixelRatio,
						})
					}

					const [first] = samples
					return (
						samples.every((sample) => JSON.stringify(sample) === JSON.stringify(first)) &&
						first.devicePixelRatio === 1 &&
						first.backingWidth === expected.width &&
						first.backingHeight === expected.height &&
						first.clientWidth === expected.width &&
						first.clientHeight === expected.height &&
						first.left === 0 &&
						first.top === 0 &&
						first.width === expected.width &&
						first.height === expected.height
					)
				}, VIEWPORT),
			{ message: 'wait for the Godot canvas to settle at 1280x720' },
		)
		.toBe(true)
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

test('E2E-M04 dual-player keyboard isolation, pause, no-scroll, and audio unlock', async ({
	page,
}, testInfo) => {
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

	const userAgent = await page.evaluate(() => navigator.userAgent)
	if (testInfo.project.name === 'edge') {
		expect(userAgent, 'the Edge project must run in Microsoft Edge').toContain('Edg')
	} else {
		expect(userAgent, 'the Chrome project must run in Google Chrome').toContain('Chrome')
		expect(userAgent, 'the Chrome project must not run in Microsoft Edge').not.toContain('Edg')
	}

	const canvas = page.locator('#canvas')
	await expect(canvas).toHaveCount(1)
	await expect(canvas).toBeVisible({ timeout: 60_000 })
	await expect(page.locator('#status-progress')).toBeHidden({ timeout: 60_000 })
	await waitForStableCanvas(page)
	await expectNoScroll(page)

	const selectionP1Hud = await page.screenshot({ clip: CLIPS.p1Hud })
	const selectionP2Hud = await page.screenshot({ clip: CLIPS.p2Hud })
	const selectionP1Cannon = await page.screenshot({ clip: CLIPS.p1Cannon })
	const selectionP2Cannon = await page.screenshot({ clip: CLIPS.p2Cannon })

	await canvas.click({ position: { x: 780, y: 310 } })
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
				message: 'the first mode-selection interaction should leave Web Audio running',
				timeout: 30_000,
			},
		)
		.toContain('running')

	await canvas.click({ position: { x: 640, y: 465 } })
	await expect
		.poll(async () => {
			const p1Hud = await page.screenshot({ clip: CLIPS.p1Hud })
			const p2Hud = await page.screenshot({ clip: CLIPS.p2Hud })
			const p1Cannon = await page.screenshot({ clip: CLIPS.p1Cannon })
			const p2Cannon = await page.screenshot({ clip: CLIPS.p2Cannon })
			return {
				p1HudVisible: !p1Hud.equals(selectionP1Hud),
				p2HudVisible: !p2Hud.equals(selectionP2Hud),
				p1CannonVisible: !p1Cannon.equals(selectionP1Cannon),
				p2CannonVisible: !p2Cannon.equals(selectionP2Cannon),
			}
		}, { message: 'Start should reveal both player HUDs and both bottom cannons' })
		.toEqual({
			p1HudVisible: true,
			p2HudVisible: true,
			p1CannonVisible: true,
			p2CannonVisible: true,
		})
	await waitForAnimationFrames(page, 3)

	// Dual mode must ignore mouse aiming and firing in the battle area.
	const goldBeforeMouse = {
		p1: await page.screenshot({ clip: CLIPS.p1Gold }),
		p2: await page.screenshot({ clip: CLIPS.p2Gold }),
	}
	const cannonsBeforeMouse = {
		p1: await page.screenshot({ clip: CLIPS.p1Cannon }),
		p2: await page.screenshot({ clip: CLIPS.p2Cannon }),
	}
	await page.mouse.click(640, 400)
	await waitForAnimationFrames(page, 4)
	expect((await page.screenshot({ clip: CLIPS.p1Gold })).equals(goldBeforeMouse.p1)).toBe(true)
	expect((await page.screenshot({ clip: CLIPS.p2Gold })).equals(goldBeforeMouse.p2)).toBe(true)
	expect((await page.screenshot({ clip: CLIPS.p1Cannon })).equals(cannonsBeforeMouse.p1)).toBe(true)
	expect((await page.screenshot({ clip: CLIPS.p2Cannon })).equals(cannonsBeforeMouse.p2)).toBe(true)

	const goldBeforeKeys = {
		p1: await page.screenshot({ clip: CLIPS.p1Gold }),
		p2: await page.screenshot({ clip: CLIPS.p2Gold }),
	}
	const cannonsBeforeKeys = {
		p1: await page.screenshot({ clip: CLIPS.p1Cannon }),
		p2: await page.screenshot({ clip: CLIPS.p2Cannon }),
	}

	await page.keyboard.down('a')
	await page.keyboard.down('Space')
	await page.keyboard.down('ArrowRight')
	await page.keyboard.down('Enter')
	try {
		await waitForAnimationFrames(page, 18)
		await expectNoScroll(page)

		expect(
			(await page.screenshot({ clip: CLIPS.p1Cannon })).equals(cannonsBeforeKeys.p1),
			'holding P1 A should visibly rotate the left cannon',
		).toBe(false)
		expect(
			(await page.screenshot({ clip: CLIPS.p2Cannon })).equals(cannonsBeforeKeys.p2),
			'holding P2 ArrowRight should visibly rotate the right cannon',
		).toBe(false)
		expect(
			(await page.screenshot({ clip: CLIPS.p1Gold })).equals(goldBeforeKeys.p1),
			'holding P1 Space should visibly change the left HUD economy',
		).toBe(false)
		expect(
			(await page.screenshot({ clip: CLIPS.p2Gold })).equals(goldBeforeKeys.p2),
			'holding P2 Enter should visibly change the right HUD economy',
		).toBe(false)
	} finally {
		await page.keyboard.up('Enter')
		await page.keyboard.up('ArrowRight')
		await page.keyboard.up('Space')
		await page.keyboard.up('a')
	}
	await expectNoScroll(page)

	const pausePanelBefore = await page.screenshot({ clip: CLIPS.pausePanel })
	await page.keyboard.press('Escape')
	await expect
		.poll(async () => {
			const current = await page.screenshot({ clip: CLIPS.pausePanel })
			return current.equals(pausePanelBefore)
		}, { message: 'Escape should visibly open the pause overlay' })
		.toBe(false)

	// In dual-player pause, the single-player Mouse/Keyboard selector is absent.
	// The local slot remains unchanged even when both players' gameplay keys are pressed.
	const dualPauseOperationSlot = await page.screenshot({ clip: CLIPS.pauseOperationSlot })
	await page.keyboard.press('a')
	await page.keyboard.press('Space')
	await page.keyboard.press('ArrowRight')
	await page.keyboard.press('Enter')
	await waitForAnimationFrames(page, 4)
	expect(
		(await page.screenshot({ clip: CLIPS.pauseOperationSlot })).equals(dualPauseOperationSlot),
		'dual-player pause must have no switchable operation-mode controls',
	).toBe(true)

	await expectNoScroll(page)
	expect(pageErrors, `uncaught page errors:\n${pageErrors.join('\n')}`).toEqual([])
	expect(consoleErrors, `console errors:\n${consoleErrors.join('\n')}`).toEqual([])
})
