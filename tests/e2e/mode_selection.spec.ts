import { expect, test, type Page } from '@playwright/test'

const VIEWPORT = { width: 1280, height: 720 }

const CLIPS = {
	singleModeFill: { x: 390, y: 285, width: 16, height: 16 },
	dualModeFill: { x: 670, y: 285, width: 16, height: 16 },
	mouseControlFill: { x: 440, y: 420, width: 16, height: 16 },
	keyboardControlFill: { x: 678, y: 420, width: 16, height: 16 },
	operationArea: { x: 300, y: 365, width: 600, height: 170 },
	leftBattleHud: { x: 24, y: 20, width: 286, height: 190 },
	rightBattleHud: { x: 970, y: 20, width: 286, height: 190 },
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

test('E2E-M01 mode selection defaults to mouse and starts a dual-player battle', async ({
	page,
}) => {
	test.setTimeout(90_000)

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

	// At 1280x720 these solid-fill samples distinguish the selected orange cards
	// from the inactive blue cards without relying on unavailable canvas DOM controls.
	const defaultSingleFill = await page.screenshot({ clip: CLIPS.singleModeFill })
	const defaultDualFill = await page.screenshot({ clip: CLIPS.dualModeFill })
	const defaultMouseFill = await page.screenshot({ clip: CLIPS.mouseControlFill })
	const defaultKeyboardFill = await page.screenshot({ clip: CLIPS.keyboardControlFill })

	expect(
		defaultSingleFill.equals(defaultDualFill),
		'single-player must be visibly selected by default',
	).toBe(false)
	expect(
		defaultMouseFill.equals(defaultKeyboardFill),
		'mouse control must be visibly selected by default',
	).toBe(false)

	const stableSelectionFrame = await canvas.screenshot()
	await waitForAnimationFrames(page, 4)
	const repeatedSelectionFrame = await canvas.screenshot()
	expect(
		repeatedSelectionFrame.equals(stableSelectionFrame),
		'the mode-selection screen must remain visually stable before Start is clicked',
	).toBe(true)

	const operationAreaBeforeDual = await page.screenshot({ clip: CLIPS.operationArea })
	await canvas.click({ position: { x: 780, y: 310 } })

	await expect
		.poll(async () => {
			const current = await page.screenshot({ clip: CLIPS.operationArea })
			return current.equals(operationAreaBeforeDual)
		}, { message: 'dual-player selection should visibly change and hide the control selector' })
		.toBe(false)

	const dualSingleFill = await page.screenshot({ clip: CLIPS.singleModeFill })
	const dualModeFill = await page.screenshot({ clip: CLIPS.dualModeFill })
	const hiddenMouseArea = await page.screenshot({ clip: CLIPS.mouseControlFill })
	const hiddenKeyboardArea = await page.screenshot({ clip: CLIPS.keyboardControlFill })

	expect(
		dualSingleFill.equals(dualModeFill),
		'dual-player must be visibly selected after clicking its card',
	).toBe(false)
	expect(
		hiddenMouseArea.equals(defaultMouseFill),
		'dual-player mode must visually remove the mouse control choice',
	).toBe(false)
	expect(
		hiddenKeyboardArea.equals(defaultKeyboardFill),
		'dual-player mode must visually remove the keyboard control choice',
	).toBe(false)
	await expectNoScroll(page)

	const selectionLeftHudArea = await page.screenshot({ clip: CLIPS.leftBattleHud })
	const selectionRightHudArea = await page.screenshot({ clip: CLIPS.rightBattleHud })
	await canvas.click({ position: { x: 640, y: 465 } })

	await expect
		.poll(async () => {
			const leftHud = await page.screenshot({ clip: CLIPS.leftBattleHud })
			const rightHud = await page.screenshot({ clip: CLIPS.rightBattleHud })
			return {
				leftChanged: !leftHud.equals(selectionLeftHudArea),
				rightChanged: !rightHud.equals(selectionRightHudArea),
			}
		}, { message: 'Start should enter battle with both player HUDs visible' })
		.toEqual({ leftChanged: true, rightChanged: true })

	await expectNoScroll(page)
	expect(pageErrors, `uncaught page errors:\n${pageErrors.join('\n')}`).toEqual([])
	expect(consoleErrors, `console errors:\n${consoleErrors.join('\n')}`).toEqual([])
})
