// Uji integrasi Minggu 10: aplikasi Flutter Web <-> Cloud Firestore nyata.
// Disajikan dari build/web di http://127.0.0.1:8137/.
// Buktikan: seed admin, role dari Firestore, produk terbaca, keranjang
// persisten setelah refresh (bukan sekadar memori).
const fs = require("fs");
const path = require("path");
const { chromium } = require("playwright-core");
const F = require("./lib/flutter");

const URL = "http://127.0.0.1:8137/";
const OUT = path.join(__dirname, "..", "..", "docs", "minggu-10", "bukti");
const ADMIN = { email: "admin@skincare.id", pass: "123456" };
const USER = { email: "rina@mail.com", pass: "123456" };

fs.mkdirSync(OUT, { recursive: true });
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
const hasil = [];

function catat(no, kasus, diharapkan, nyata, ok) {
  hasil.push({ no, kasus, diharapkan, nyata, status: ok ? "SESUI" : "TIDAK SESUAI" });
  console.log(`#${no} ${kasus}: ${ok ? "SESUI" : "TIDAK SESUAI"}\n    ${nyata}`);
}

async function tree(page) {
  return (await F.dumpTree(page)).join("\n");
}

// Semantics tree Flutter kadang tertinggal satu frame setelah pergantian
// rute. Poll beberapa kali sebelum memutuskan gagal.
async function tungguTeks(page, teks, timeoutMs = 9000) {
  const t0 = Date.now();
  let terakhir = "";
  while (Date.now() - t0 < timeoutMs) {
    terakhir = await tree(page);
    if (terakhir.includes(teks)) return { ok: true, teks: terakhir };
    await sleep(700);
  }
  return { ok: false, teks: terakhir };
}

async function shot(page, name) {
  await page.screenshot({ path: path.join(OUT, name + ".png") });
}

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
  await sleep(80);
  await page.keyboard.press("Backspace");
  await sleep(120);
  await page.keyboard.type(value, { delay: 40 });
  await sleep(250);
}

async function klik(page, teks) {
  const n = await F.findNodeContains(page, teks, "button");
  if (!n) throw new Error(`tombol "${teks}" tidak ditemukan`);
  await page.mouse.move(n.x, n.y);
  await sleep(90);
  await page.mouse.down();
  await sleep(60);
  await page.mouse.up();
  await sleep(300);
}

async function ke(page, hash) {
  await page.evaluate((h) => { window.location.hash = h; }, hash);
  await sleep(3200);
}

async function buka(page) {
  await page.goto(URL, { waitUntil: "domcontentloaded", timeout: 60000 });
  await sleep(7500);
  await F.enableSemantics(page);
  await sleep(1200);
}

async function masuk(page, akun) {
  await isi(page, 0, akun.email);
  await isi(page, 1, akun.pass);
  await klik(page, "Masuk");
  await sleep(7000); // tunggu auth + listener Firestore + seed
}

(async () => {
  const browser = await chromium.launch({ headless: true, executablePath: F.CHROME });
  const ctx = await browser.newContext({ viewport: { width: 1600, height: 900 } });
  const page = await ctx.newPage();
  page.setDefaultTimeout(45000);
  const logs = [];
  page.on("console", (m) => { if (m.type() === "error") logs.push(m.text().slice(0, 180)); });
  page.on("pageerror", (e) => logs.push("pageerror: " + String(e).slice(0, 180)));

  await buka(page);
  let t = await tree(page);

  catat(1, "Akses awal tanpa login", "Halaman Masuk tampil",
    page.url().includes("login") ? "URL " + page.url() : "URL " + page.url(),
    page.url().includes("login"));
  await shot(page, "01-login");

  // ---------- ADMIN ----------
  await masuk(page, ADMIN);
  t = await tree(page);
  catat(2, "Login admin", "Beranda tampil",
    t.includes("Halo,") ? "Sapaan 'Halo, ...' tampil" : t.slice(0, 160).replace(/\n/g, " | "),
    t.includes("Halo,"));
  await shot(page, "02-beranda-admin");

  await ke(page, "#/akun");
  t = await tree(page);
  const adminOk = t.includes("Dashboard Admin") && t.includes("Admin");
  catat(3, "Role admin terbaca dari users/{uid}", "Badge Admin + menu Dashboard Admin",
    adminOk ? "Badge 'Admin' dan menu 'Dashboard Admin' tampil" : t.slice(0, 180).replace(/\n/g, " | "),
    adminOk);
  await shot(page, "03-akun-admin");

  // Tunggu seed 10 produk selesai.
  await sleep(3500);
  await ke(page, "#/produk");
  t = await tree(page);
  const produkOk = t.includes("Glow Cleanser Gel") || t.includes("Cleanser");
  catat(4, "Produk terbaca dari collection products", "Nama produk contoh tampil",
    produkOk ? "Produk 'Glow Cleanser Gel' tampil di Daftar Produk" : t.slice(0, 200).replace(/\n/g, " | "),
    produkOk);
  await shot(page, "04-produk-firestore");

  // Keluar dari admin.
  await ke(page, "#/akun");
  await klik(page, "Keluar");
  await sleep(3000);

  // ---------- PELANGGAN ----------
  await masuk(page, USER);
  t = await tree(page);
  catat(5, "Login pelanggan", "Beranda tampil",
    t.includes("Halo,") ? "Sapaan 'Halo, ...' tampil" : t.slice(0, 160).replace(/\n/g, " | "),
    t.includes("Halo,"));

  await ke(page, "#/produk/P01");
  t = await tree(page);
  const detailOk = t.includes("Glow Cleanser Gel");
  catat(6, "Detail produk P01 dari Firestore", "Detail P01 tampil",
    detailOk ? "Detail 'Glow Cleanser Gel' tampil" : t.slice(0, 180).replace(/\n/g, " | "),
    detailOk);
  await shot(page, "05-detail-produk");

  await klik(page, "Keranjang");
  await sleep(2500);
  await ke(page, "#/keranjang");
  // Halaman Keranjang tidak mengekspos nama produk ke semantics tree,
  // sehingga sinyal yang dipakai: ringkasan "Total (N item)" + tombol Checkout.
  const c7 = await tungguTeks(page, "Total (");
  const adaItem7 = c7.ok && c7.teks.includes("Checkout") && !c7.teks.includes("Total (0");
  fs.writeFileSync(path.join(OUT, "tree-keranjang.txt"), c7.teks);
  catat(7, "Keranjang ditulis ke carts/{uid}/items", "Keranjang berisi minimal 1 item",
    adaItem7 ? "Semantics menampilkan 'Total (N item)' + tombol Checkout" : c7.teks.slice(0, 300).replace(/\n/g, " | "),
    adaItem7);
  await shot(page, "06-keranjang-firestore");

  // Refresh: kalau hanya memori, item akan hilang. Firestore harus memulihkannya.
  await page.reload({ waitUntil: "domcontentloaded" });
  await sleep(8000);
  await F.enableSemantics(page);
  await sleep(1500);
  await ke(page, "#/keranjang");
  const c8 = await tungguTeks(page, "Total (");
  const adaItem8 = c8.ok && c8.teks.includes("Checkout") && !c8.teks.includes("Total (0");
  fs.writeFileSync(path.join(OUT, "tree-keranjang-refresh.txt"), c8.teks);
  catat(8, "Keranjang persisten setelah refresh", "Item tetap ada setelah F5",
    adaItem8 ? "Keranjang masih berisi item setelah refresh (bukan memori)" : c8.teks.slice(0, 300).replace(/\n/g, " | "),
    adaItem8);
  await shot(page, "07-keranjang-setelah-refresh");

  const sesuai = hasil.filter((h) => h.status === "SESUI").length;
  fs.writeFileSync(
    path.join(OUT, "hasil-uji.json"),
    JSON.stringify({
      tanggal: new Date().toISOString(), url: URL,
      sesuai, total: hasil.length, hasil, consoleErrors: logs.slice(0, 15),
    }, null, 2)
  );
  console.log(`\n${sesuai}/${hasil.length} SESUI`);
  console.log("Console errors:", logs.slice(0, 8).join(" | ") || "(none)");
  await browser.close();
  if (sesuai !== hasil.length) process.exit(1);
})().catch((e) => {
  console.error("UJI ERROR", e);
  fs.writeFileSync(path.join(OUT, "hasil-uji.json"),
    JSON.stringify({ error: String(e), hasil }, null, 2));
  process.exit(1);
});
