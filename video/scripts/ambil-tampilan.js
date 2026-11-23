// Ambil screenshot tampilan terbaru dari beberapa halaman utama.
const fs = require("fs");
const path = require("path");
const { chromium } = require("playwright-core");
const F = require("./lib/flutter");

const URL = "http://127.0.0.1:8137/";
const OUT = path.join(__dirname, "..", "..", "docs", "minggu-10", "bukti");
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

async function isi(page, i, v) {
  const b = await page.evaluate(() =>
    Array.from(document.querySelectorAll("input,textarea")).map((e) => {
      const r = e.getBoundingClientRect();
      return { x: r.x + r.width / 2, y: r.y + r.height / 2 };
    })
  );
  await page.mouse.click(b[i].x, b[i].y);
  await sleep(300);
  await page.keyboard.press("Control+A");
  await page.keyboard.press("Backspace");
  await sleep(100);
  await page.keyboard.type(v, { delay: 30 });
  await sleep(200);
}

async function klik(page, teks) {
  const n =
    (await F.findNodeContains(page, teks, "button")) ||
    (await F.findNodeContains(page, teks, ""));
  if (!n) throw new Error(`tombol "${teks}" tidak ditemukan`);
  await page.mouse.click(n.x, n.y);
}

async function ke(page, hash, nama) {
  await page.evaluate((h) => { window.location.hash = h; }, hash);
  await sleep(4500);
  await page.screenshot({ path: path.join(OUT, `tampilan-${nama}.png`) });
  console.log("tersimpan:", `tampilan-${nama}.png`);
}

(async () => {
  const browser = await chromium.launch({ headless: true, executablePath: F.CHROME });
  const ctx = await browser.newContext({
    viewport: { width: 1600, height: 900 },
    serviceWorkers: "block",
  });
  const page = await ctx.newPage();
  page.setDefaultTimeout(45000);

  await page.goto(URL, { waitUntil: "domcontentloaded", timeout: 60000 });
  await page.waitForSelector("flt-semantics-placeholder", { state: "attached", timeout: 180000 });
  await sleep(4000);
  await page.locator("flt-semantics-placeholder").first().dispatchEvent("click");
  await sleep(2500);
  await page.screenshot({ path: path.join(OUT, "tampilan-login.png") });
  console.log("tersimpan: tampilan-login.png");

  await isi(page, 0, "admin@skincare.id");
  await isi(page, 1, "123456");
  await klik(page, "Masuk");
  await sleep(13000);

  await ke(page, "#/beranda", "beranda");
  await ke(page, "#/produk", "daftar-produk");
  await ke(page, "#/akun", "akun");
  await ke(page, "#/admin", "admin-dashboard");
  await ke(page, "#/admin/produk", "admin-produk");

  await browser.close();
})().catch((e) => { console.error("GAGAL:", e.message); process.exit(1); });
