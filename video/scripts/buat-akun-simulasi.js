// Sekali jalan: membuat akun simulasi admin agar halaman admin tetap terjangkau.
// Jalankan setelah build/web disajikan di http://127.0.0.1:8137/.
const { chromium } = require("playwright-core");
const F = require("./lib/flutter");

const URL = "http://127.0.0.1:8137/";
const NAMA = "Admin Simulasi";
const EMAIL = "admin@skincare.id";
const PASSWORD = "123456";
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

(async () => {
  const browser = await chromium.launch({ headless: true, executablePath: F.CHROME });
  const page = await browser.newPage({ viewport: { width: 1600, height: 900 } });
  await page.goto(URL, { waitUntil: "domcontentloaded", timeout: 60000 });
  await sleep(7000);
  await F.enableSemantics(page);
  await sleep(1200);

  const tree = (await F.dumpTree(page)).join("\n");
  if (!tree.includes("Masuk")) throw new Error("Halaman Masuk tidak tampil");

  await F.clickContains(page, "Daftar", "button");
  await sleep(1500);

  const boxes = await page.evaluate(() =>
    Array.from(document.querySelectorAll("input, textarea")).map((e) => {
      const r = e.getBoundingClientRect();
      return { x: r.x + r.width / 2, y: r.y + r.height / 2 };
    })
  );
  const isi = [NAMA, EMAIL, PASSWORD, PASSWORD];
  for (let i = 0; i < 4; i++) {
    await page.mouse.click(boxes[i].x, boxes[i].y);
    await sleep(350);
    await page.keyboard.type(isi[i], { delay: 45 });
    await sleep(250);
  }
  await F.clickContains(page, "Daftar", "button");
  await sleep(7000);

  const akhir = (await F.dumpTree(page)).join("\n");
  const berhasil = akhir.includes("Halo,") || page.url().includes("/beranda");
  console.log(berhasil
    ? `BERHASIL: akun ${EMAIL} terdaftar di Firebase Authentication.`
    : `GAGAL: ${akhir.slice(0, 300).replace(/\n/g, " | ")}`);
  await page.screenshot({ path: "out/m9/setup-akun-admin.png" });
  await browser.close();
})().catch((e) => {
  console.error("ERROR", e);
  process.exit(1);
});
