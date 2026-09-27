// Drives web_typing_rules_app.dart in a real Chrome with real key events
// (Chrome DevTools Protocol input, which the browser treats like a user's
// keyboard: it produces the same keydown / beforeinput / input events, IME
// deltas and newline action a person typing would).
//
// Usage (with the app served on :8123, see web_typing_rules_app.dart):
//   npm i puppeteer-core            # anywhere; point NODE_PATH at it
//   NODE_PATH=<dir>/node_modules node web_typing_rules_drive.cjs
// Env: CHROME (Chrome binary), URL (default http://localhost:8123).
const puppeteer = require('puppeteer-core');
const assert = require('node:assert/strict');

const chrome =
  process.env.CHROME ||
  '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';
const url = process.env.URL || 'http://localhost:8123';

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

(async () => {
  const browser = await puppeteer.launch({
    executablePath: chrome,
    headless: true,
    args: ['--window-size=900,700'],
  });
  let failed = false;
  try {
    const page = await browser.newPage();
    await page.setViewport({ width: 900, height: 700 });
    page.on('pageerror', (e) => console.log('pageerror:', e.message));
    await page.goto(url, { waitUntil: 'load' });
    await page.waitForFunction(() => typeof window.championDoc === 'function', {
      timeout: 60000,
    });
    await sleep(1500);

    // The document as [kind, text] pairs, after the field's 150 ms throttle.
    const doc = async () => {
      await sleep(400);
      const json = JSON.parse(await page.evaluate(() => window.championDoc()));
      return json.nodes.map((n) => {
        const kind =
          n.type === 'listItem'
            ? n.ordered
              ? 'ol'
              : 'ul'
            : n.type === 'heading'
              ? `h${n.level}`
              : n.type;
        return [kind, n.content?.text ?? ''];
      });
    };
    const key = async (k, times = 1) => {
      for (let i = 0; i < times; i++) {
        await page.keyboard.press(k);
        await sleep(60);
      }
    };
    const type = async (s) => {
      for (const ch of s) {
        // Puppeteer maps "-" to the numpad key; use the main-row Minus key
        // like a person would.
        await page.keyboard.press(ch === '-' ? 'Minus' : ch);
        await sleep(40);
      }
    };
    const step = async (name, expected) => {
      const actual = await doc();
      try {
        assert.deepEqual(actual, expected);
        console.log(`ok   ${name}`);
      } catch (e) {
        failed = true;
        console.log(`FAIL ${name}\n  expected ${JSON.stringify(expected)}\n  actual   ${JSON.stringify(actual)}`);
      }
    };

    // Focus the (empty) editor.
    await page.mouse.click(120, 45);
    await sleep(500);

    await type('- one');
    await step('"- " makes a bullet item', [['ul', 'one']]);

    await key('Enter');
    await type('two');
    await step('Enter at the end of a list item continues the list', [
      ['ul', 'one'],
      ['ul', 'two'],
    ]);

    await key('ArrowLeft', 3);
    await key('Backspace');
    await step('Backspace at the start of a list item makes a paragraph', [
      ['ul', 'one'],
      ['paragraph', 'two'],
    ]);

    await key('Backspace');
    await step('Backspace at the start of a paragraph merges it up', [
      ['ul', 'onetwo'],
    ]);

    await key('ArrowRight', 3);
    await key('Enter');
    await key('Enter');
    await step('Enter on an empty list item leaves the list', [
      ['ul', 'onetwo'],
      ['paragraph', ''],
    ]);

    await type('---');
    await key('Enter');
    await step('"---" then Enter makes a divider', [
      ['ul', 'onetwo'],
      ['divider', ''],
      ['paragraph', ''],
    ]);

    await type('# T');
    await key('Enter');
    await type('body');
    await step('Enter at the end of a heading starts a paragraph', [
      ['ul', 'onetwo'],
      ['divider', ''],
      ['h1', 'T'],
      ['paragraph', 'body'],
    ]);

    await key('Backspace');
    await step('Backspace mid-text deletes one character', [
      ['ul', 'onetwo'],
      ['divider', ''],
      ['h1', 'T'],
      ['paragraph', 'bod'],
    ]);
  } finally {
    await browser.close();
  }
  if (failed) process.exit(1);
  console.log('all real-browser checks passed');
})().catch((e) => {
  console.error(e);
  process.exit(1);
});
