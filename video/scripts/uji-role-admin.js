// Diagnosa: cek peran yang benar-benar tampil setelah login admin.
const fs = require("fs");
const path = require("path");
const { chromium } = require("playwright-core");
const F = require("./lib/flutter");

const URL = "http://127.0.0.1:8137/";
const OUT = path.join(__dirname, "..", "..", "docs", "minggu-10", "bukti");
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

async function isi(page, index, value) {
  const boxes = await page.evaluate(() =>
    Array.from(document.querySelectorAll("input, textarea")).map((e) => {
      const r = e.getBoundingClientRect();
      return { x: r.x + r.width / 2, y: r.y + r.height / 2 };
    })
  );
  if (!boxes[index]) throw new Error(`input #${index} tidak ada`);
  await page.mouse.click(boxes[index].x, boxes[index].y);
  await sleep(350);
  await page.keyboard.press("Control+A");
  await page.keyboard.press("Backspace");
  await sleep(120);
  await page.keyboard.type(value, { delay: 40 });
  await sleep(250);
}

async function klik(page, teks) {
  const n =
    (await F.findNodeContains(page, teks, "button")) ||
    (await F.findNodeContains(page, teks, ""));
  if (!n) throw new Error(`tombol "${teks}" tidak ditemukan`);
  await page.mouse.move(n.x, n.y);
  await sleep(90);
  await page.mouse.down();
  await sleep(60);
  await page.mouse.up();
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
  await page.waitForSelector("flt-semantics-placeholder", {
    state: "attached",
    timeout: 180000,
  });
  await sleep(4000);
  await page.locator("flt-semantics-placeholder").first().dispatchEvent("click");
  await sleep(2500);

  await isi(page, 0, "admin@skincare.id");
  await isi(page, 1, "123456");
  await klik(page, "Masuk");
  await sleep(15000);

  console.log("URL setelah login:", page.url());
  const beranda = (await F.dumpTree(page)).join("\n");
  fs.writeFileSync(path.join(OUT, "probe-admin-beranda.txt"), beranda);

  await page.evaluate(() => { window.location.hash = "#/akun"; });
  await sleep(5000);
  const akun = (await F.dumpTree(page)).join("\n");
  fs.writeFileSync(path.join(OUT, "probe-admin-akun.txt"), akun);
  await page.screenshot({ path: path.join(OUT, "22-role-admin-tampil.png") });

  const baris = (t) => t.split("\n").filter((l) => /Admin|Pelanggan|Kelola|admin@/i.test(l));
  console.log("=== BERANDA (role) ===");
  console.log(baris(beranda).join("\n") || "(kosong)");
  console.log("=== AKUN (role) ===");
  console.log(baris(akun).join("\n") || "(kosong)");
  await browser.close();
})().catch((e) => { console.error("GAGAL:", e.message); process.exit(1); });
