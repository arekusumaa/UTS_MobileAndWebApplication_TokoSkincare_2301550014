// Record the live prototype demo: login -> beranda -> produk -> detail -> keranjang
// -> checkout (validation) -> status pesanan.
//
// Usage:
//   node scripts/demo-record.js            (dry run, screenshots only)
//   node scripts/demo-record.js --video    (record webm to out/demo/raw)
const path = require("path");
const fs = require("fs");
const { chromium } = require("playwright-core");
const F = require("./lib/flutter");

const URL = "http://127.0.0.1:8137/";
const OUT = path.join(__dirname, "..", "out", "demo");
const REC = path.join(OUT, "raw");
const WANT_VIDEO = process.argv.includes("--video");
const S = WANT_VIDEO ? 2.2 : 1;

fs.mkdirSync(OUT, { recursive: true });
fs.mkdirSync(REC, { recursive: true });

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
/** Scene-level pause, stretched when recording. */
const wait = (ms) => sleep(Math.round(ms * S));

async function inputBoxes(page) {
  return page.evaluate(() =>
    Array.from(document.querySelectorAll("input, textarea")).map((e) => {
      const r = e.getBoundingClientRect();
      return {
        x: r.x + r.width / 2,
        y: r.y + r.height / 2,
        type: e.getAttribute("type") || "text",
        aria: e.getAttribute("aria-label") || "",
        value: e.value,
      };
    })
  );
}

async function fillField(page, index, value, delay = 60) {
  const boxes = await inputBoxes(page);
  if (!boxes[index]) throw new Error(`no input at index ${index} (have ${boxes.length})`);
  await page.mouse.click(boxes[index].x, boxes[index].y);
  await sleep(420);
  await page.keyboard.press("Control+A");
  await sleep(90);
  await page.keyboard.press("Backspace");
  await sleep(160);
  await page.keyboard.type(value, { delay });
  await sleep(320);
}

(async () => {
  const browser = await chromium.launch({ headless: true, executablePath: F.CHROME });
  const ctx = await browser.newContext({
    viewport: { width: 1600, height: 900 },
    ...(WANT_VIDEO ? { recordVideo: { dir: REC, size: { width: 1600, height: 900 } } } : {}),
  });
  const page = await ctx.newPage();
  page.setDefaultTimeout(30000);

  let n = 0;
  const shot = async (name) => {
    n += 1;
    await page.screenshot({ path: `${OUT}/s${String(n).padStart(2, "0")}-${name}.png` });
    console.log(`  [shot] ${name} @${Date.now()}`);
  };
  const marks = [];
  const mark = (label) => {
    marks.push({ label, t: Date.now() });
    console.log(`  [mark] ${label}`);
  };

  mark("start");
  console.log("1. open app");
  await page.goto(URL, { waitUntil: "load", timeout: 60000 });
  await sleep(6500);
  await F.enableSemantics(page);
  await sleep(1200);
  await wait(1600);
  await shot("login");
  mark("login");

  console.log("2. login as customer");
  await fillField(page, 0, "rina@mail.com", 85);
  await wait(500);
  await fillField(page, 1, "123456", 130);
  await wait(900);
  await shot("login-filled");
  mark("login-filled");
  await F.clickNode(page, "Masuk", "button");
  await sleep(3200);
  await shot("beranda");
  mark("beranda");

  console.log("3. scroll beranda");
  await page.mouse.move(800, 500);
  await wait(900);
  await page.mouse.wheel(0, 380);
  await wait(2200);
  await shot("beranda-scrolled");
  await page.mouse.wheel(0, -380);
  await wait(1200);

  console.log("4. go to Produk");
  await F.clickContains(page, "Produk Tab 2 of 4", "button");
  await sleep(2600);
  await shot("produk");
  mark("produk");
  await wait(1800);

  console.log("5. open product detail");
  const card = await F.findNodeContains(page, "Glow Cleanser Gel");
  if (!card) throw new Error("product card not found");
  await page.mouse.click(card.x, card.y);
  await sleep(2800);
  await shot("detail");
  mark("detail");
  await wait(3200);

  console.log("6. add to cart");
  await F.clickNode(page, "Keranjang");
  await sleep(900);
  await shot("detail-added");
  mark("snackbar");
  await wait(1400);

  console.log("7. open keranjang via SnackBar action");
  await F.clickNode(page, "Lihat");
  await sleep(2400);
  await shot("keranjang");
  mark("keranjang");
  await wait(2400);

  console.log("8. checkout");
  await F.clickNode(page, "Checkout");
  await sleep(2400);
  await shot("checkout");
  mark("checkout");
  await wait(2200);

  console.log("9. submit empty -> validation errors");
  await F.clickNode(page, "Buat Pesanan");
  await sleep(2000);
  await shot("checkout-errors");
  mark("errors");
  await wait(3200);

  console.log("10. fill invalid values");
  await fillField(page, 0, "Rina Pratiwi", 80);
  await fillField(page, 1, "abc", 170);
  await fillField(page, 2, "Jl. Mawar", 85);
  await sleep(1600);
  await shot("checkout-invalid");
  mark("invalid");
  await wait(2600);

  console.log("11. fix values");
  await fillField(page, 1, "081234567890", 80);
  await wait(400);
  await fillField(page, 2, "Jl. Mawar No. 12, Jakarta Selatan", 45);
  await sleep(1200);
  await shot("checkout-valid");
  mark("valid");
  await wait(1800);

  console.log("12. submit valid");
  await F.clickNode(page, "Buat Pesanan");
  await sleep(1800);
  await shot("checkout-success");
  mark("success");
  await sleep(2600);
  await shot("status");
  mark("status");
  await wait(3400);

  mark("end");
  const video = page.video();
  await ctx.close();
  await browser.close();

  if (WANT_VIDEO && video) {
    const p = await video.path();
    console.log("VIDEO_PATH=" + p);
  }

  // Relative timings (seconds from start) for narration sync.
  const t0 = marks[0].t;
  console.log("\nTIMELINE");
  for (const m of marks) console.log(`${((m.t - t0) / 1000).toFixed(2)}s  ${m.label}`);
  console.log("DONE");
})().catch((e) => {
  console.error("FAILED:", e.message);
  process.exit(1);
});
