// Uji integrasi CRUD produk admin: Tambah → Edit → Hapus, diverifikasi
// langsung ke server Firestore memakai token pemilik project.
//
// Jalankan:
//   python -m http.server 8137 --bind 127.0.0.1   (dari build/web)
//   node video/scripts/uji-crud-produk.js
const fs = require("fs");
const os = require("os");
const path = require("path");
const { chromium } = require("playwright-core");
const F = require("./lib/flutter");

const URL = "http://127.0.0.1:8137/";
const OUT = path.join(__dirname, "..", "..", "docs", "minggu-10", "bukti");
const ROOT =
  "https://firestore.googleapis.com/v1/projects/toko-skincare-fec17/" +
  "databases/(default)/documents";
const NAMA_UJI = "Produk Uji CRUD Otomatis";
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
const hasil = [];

function catat(no, kasus, diharapkan, nyata, ok) {
  hasil.push({ no, kasus, diharapkan, nyata, status: ok ? "SESUI" : "TIDAK SESUAI" });
  console.log(`#${no} ${kasus}: ${ok ? "SESUI" : "TIDAK SESUAI"}\n    ${nyata}`);
}

function ownerToken() {
  const p = path.join(os.homedir(), ".config", "configstore", "firebase-tools.json");
  return JSON.parse(fs.readFileSync(p, "utf8")).tokens.access_token;
}

async function fsReq(suffix, method = "GET", body = null) {
  const r = await fetch(`${ROOT}/${suffix}`, {
    method,
    headers: {
      Authorization: "Bearer " + ownerToken(),
      "Content-Type": "application/json",
    },
    body: body ? JSON.stringify(body) : undefined,
  });
  const text = await r.text();
  return { status: r.status, body: text ? JSON.parse(text) : {} };
}

async function cariDokumenUji() {
  const r = await fsReq("products?pageSize=200");
  for (const d of r.body.documents || []) {
    if (d.fields?.nama?.stringValue === NAMA_UJI) return d;
  }
  return null;
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
  await sleep(300);
  await page.keyboard.press("Control+A");
  await page.keyboard.press("Backspace");
  await sleep(120);
  await page.keyboard.type(value, { delay: 30 });
  await sleep(200);
}

async function klik(page, teks) {
  const n =
    (await F.findNodeContains(page, teks, "button")) ||
    (await F.findNodeContains(page, teks, ""));
  if (!n) throw new Error(`tombol "${teks}" tidak ditemukan`);
  await page.mouse.move(n.x, n.y);
  await sleep(80);
  await page.mouse.down();
  await sleep(60);
  await page.mouse.up();
}

async function klikKoordinat(page, x, y) {
  await page.mouse.move(x, y);
  await sleep(90);
  await page.mouse.down();
  await sleep(60);
  await page.mouse.up();
}

async function semuaAria(page) {
  return page.evaluate(() =>
    Array.from(document.querySelectorAll("flt-semantics"))
      .map((el) => el.getAttribute("aria-label") || "")
      .join("\n")
  );
}

// Flutter menggabungkan seluruh baris menjadi satu node button dengan
// aria-label "Edit <nama>...", lalu menaruh tombol "Edit"/"Hapus" bertulisan
// sebagai node button terpisah. Cari baris lewat aria, lalu tombol dengan teks
// persis yang paling dekat secara vertikal.
async function gulirKeProduk(page, nama) {
  for (let i = 0; i < 18; i++) {
    const y = await page.evaluate((n) => {
      for (const el of document.querySelectorAll("flt-semantics")) {
        const a = el.getAttribute("aria-label") || "";
        if (!a.includes(n)) continue;
        if (!/Edit|Hapus/.test((el.innerText || ""))) continue;
        const r = el.getBoundingClientRect();
        if (r.height > 2) return r.y + r.height / 2;
      }
      return null;
    }, nama);
    // Baris terakhir berhenti di y≈844 pada viewport 900; itu masih bisa diklik.
    if (y != null && y > 150 && y < 875) return y;
    await page.mouse.move(800, 500);
    await page.mouse.wheel(0, y == null || y >= 875 ? 320 : -320);
    await sleep(600);
  }
  throw new Error(`produk "${nama}" tidak bisa digulir ke layar`);
}

async function klikAksiBaris(page, awalan, nama) {
  const barisY = await gulirKeProduk(page, nama);
  const n = await page.evaluate(
    ({ awalan, barisY }) => {
      const semua = Array.from(document.querySelectorAll("flt-semantics"));

      let terbaik = null;
      for (const el of semua) {
        if ((el.getAttribute("role") || "") !== "button") continue;
        if ((el.innerText || "").trim() !== awalan) continue;
        if ((el.getAttribute("aria-label") || "").trim()) continue;
        const r = el.getBoundingClientRect();
        if (r.width < 2 || r.height < 2) continue;
        const y = r.y + r.height / 2;
        const jarak = Math.abs(y - barisY);
        if (jarak > 45) continue;
        if (!terbaik || jarak < terbaik.jarak) {
          terbaik = { x: r.x + r.width / 2, y, jarak };
        }
      }
      return terbaik;
    },
    { awalan, barisY }
  );
  if (!n) throw new Error(`tombol ${awalan} "${nama}" tidak ditemukan`);
  await klikKoordinat(page, n.x, n.y);
}

// Tombol Hapus pada dialog konfirmasi tidak punya aria-label, jadi dibedakan
// dari tombol Hapus pada baris produk (yang punya tooltip "Hapus <nama>").
async function klikDialogHapus(page) {
  const n = await page.evaluate(() => {
    const semua = Array.from(document.querySelectorAll("flt-semantics"));
    // Batasi pencarian ke dalam dialog konfirmasi.
    const dialog = semua.find((el) =>
      (el.innerText || "").includes("Yakin ingin menghapus")
    );
    const d = dialog?.getBoundingClientRect();
    for (const el of semua) {
      if ((el.getAttribute("role") || "") !== "button") continue;
      if ((el.innerText || "").trim() !== "Hapus") continue;
      const r = el.getBoundingClientRect();
      if (r.width < 2 || r.height < 2) continue;
      const x = r.x + r.width / 2;
      const y = r.y + r.height / 2;
      if (d && (x < d.x || x > d.x + d.width || y < d.y || y > d.y + d.height)) {
        continue;
      }
      return { x, y };
    }
    return null;
  });
  if (!n) throw new Error("tombol Hapus pada dialog tidak ditemukan");
  await klikKoordinat(page, n.x, n.y);
}

(async () => {
  // Bersihkan sisa uji sebelumnya agar hasil deterministik.
  const lama = await cariDokumenUji();
  if (lama) await fsReq(`products/${lama.name.split("/").pop()}`, "DELETE");

  const browser = await chromium.launch({ headless: true, executablePath: F.CHROME });
  const ctx = await browser.newContext({
    viewport: { width: 1600, height: 900 },
    serviceWorkers: "block",
  });
  const page = await ctx.newPage();
  page.setDefaultTimeout(45000);
  const consoleErrors = [];
  page.on("console", (m) => { if (m.type() === "error") consoleErrors.push(m.text().slice(0, 180)); });

  await page.goto(URL, { waitUntil: "domcontentloaded", timeout: 60000 });
  await page.waitForSelector("flt-semantics-placeholder", { state: "attached", timeout: 180000 });
  await sleep(4000);
  await page.locator("flt-semantics-placeholder").first().dispatchEvent("click");
  await sleep(2500);

  await isi(page, 0, "admin@skincare.id");
  await isi(page, 1, "123456");
  await klik(page, "Masuk");
  await sleep(12000);

  await page.evaluate(() => { window.location.hash = "#/admin/produk"; });
  await sleep(4500);

  // ---------------------------------------------------------------- 1 CREATE
  await klik(page, "Tambah Produk"); // Tombol eksplisit di AppBar
  await sleep(2500);
  await isi(page, 0, NAMA_UJI);
  await isi(page, 1, "77777");
  await isi(page, 2, "13");
  await isi(page, 3, "Niacinamide");
  // Tambahkan kandungan lewat tombol + di samping field.
  await klikKoordinat(page, 1088, 314);
  await sleep(500);
  await isi(page, 4, "Uji manfaat produk");
  await isi(page, 5, "Uji cara pakai produk");
  await klik(page, "Tambah Produk");
  await sleep(6500);

  const dibuat = await cariDokumenUji();
  const createOk = dibuat != null &&
    dibuat.fields.harga?.integerValue === "77777" &&
    dibuat.fields.stok?.integerValue === "13";
  catat(1, "Admin menambah produk lewat form",
    "Dokumen products baru dengan harga 77777 dan stok 13",
    dibuat ? `id=${dibuat.name.split("/").pop()}, harga=${dibuat.fields.harga?.integerValue}, stok=${dibuat.fields.stok?.integerValue}` : "dokumen tidak ditemukan di server",
    createOk);
  await page.screenshot({ path: path.join(OUT, "23-crud-tambah-produk.png") });

  // ------------------------------------------------------------------ 2 READ
  // Nama produk diekspos Flutter Web lewat aria-label, bukan innerText.
  const treeKelola = await semuaAria(page);
  const readOk = treeKelola.includes(NAMA_UJI);
  catat(2, "Produk baru tampil di daftar Kelola Produk",
    "Nama produk uji muncul di daftar setelah snapshot Firestore",
    readOk ? "nama produk uji tampil di halaman Kelola Produk" : "nama produk uji tidak tampil",
    readOk);

  // ------------------------------------------------------------------ 3 EDIT
  await klikAksiBaris(page, "Edit", NAMA_UJI);
  // Transisi ke form Firestore-backed bisa memakan beberapa detik.
  await sleep(7000);
  await isi(page, 1, "88888");
  await klik(page, "Simpan Perubahan");
  await sleep(6500);
  const diedit = await cariDokumenUji();
  const editOk = diedit?.fields.harga?.integerValue === "88888";
  catat(3, "Admin mengedit harga produk",
    "harga berubah menjadi 88888 di server",
    diedit ? `harga di server = ${diedit.fields.harga?.integerValue}` : "dokumen hilang",
    editOk);
  await page.screenshot({ path: path.join(OUT, "24-crud-edit-produk.png") });

  // ---------------------------------------------------------------- 4 DELETE
  await klikAksiBaris(page, "Hapus", NAMA_UJI);
  await sleep(1200);
  await klikDialogHapus(page);
  await sleep(6500);
  const setelahHapus = await cariDokumenUji();
  const hapusOk = setelahHapus == null;
  catat(4, "Admin menghapus produk",
    "dokumen produk uji tidak ada lagi di server",
    hapusOk ? "dokumen tidak ditemukan di server" : "dokumen masih ada",
    hapusOk);

  // ------------------------------------------------- 5 PELANGGAN TIDAK BISA
  await page.evaluate(() => { window.location.hash = "#/akun"; });
  await sleep(1500);
  await klik(page, "Keluar");
  await sleep(6000);
  await isi(page, 0, "rina@mail.com");
  await isi(page, 1, "123456");
  await klik(page, "Masuk");
  await sleep(10000);
  await page.evaluate(() => { window.location.hash = "#/akun"; });
  await sleep(3500);
  const treePelanggan = (await F.dumpTree(page)).join("\n");
  const isolasiOk = !treePelanggan.includes("Dashboard Admin");
  catat(5, "Pelanggan tidak melihat menu Dashboard Admin",
    "menu admin tidak muncul untuk rina@mail.com",
    isolasiOk ? "Dashboard Admin tidak muncul" : "Dashboard Admin masih muncul",
    isolasiOk);

  const sesui = hasil.filter((h) => h.status === "SESUI").length;
  const ringkasan = {
    total: hasil.length,
    sesuai: sesui,
    hasil,
    consoleErrors,
  };
  fs.writeFileSync(
    path.join(OUT, "hasil-uji-crud-produk.json"),
    JSON.stringify(ringkasan, null, 2)
  );
  console.log(`\nRINGKASAN: ${sesui}/${hasil.length} SESUI; console error: ${consoleErrors.length}`);
  await browser.close();
  if (sesui !== hasil.length) process.exitCode = 1;
})().catch((e) => { console.error("GAGAL:", e.message); process.exit(1); });
