// Uji integrasi Minggu 9: daftar / masuk / keluar / refresh / pesan kesalahan.
// Dijalankan pada build/web yang disajikan di http://127.0.0.1:8137/.
// Hasil ditulis ke out/m9/hasil-uji.json untuk dipindah ke tabel uji di docs.
const fs = require("fs");
const path = require("path");
const { chromium } = require("playwright-core");
const F = require("./lib/flutter");

const URL = "http://127.0.0.1:8137/";
const OUT = path.join(__dirname, "..", "out", "m9");
const USE_PROXY = process.argv.includes("--proxy");
const DEMO_EMAIL = "rina@mail.com";
const DEMO_PASSWORD = "123456";

fs.mkdirSync(OUT, { recursive: true });

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
const hasil = [];

async function inputBoxes(page) {
  return page.evaluate(() =>
    Array.from(document.querySelectorAll("input, textarea")).map((e) => {
      const r = e.getBoundingClientRect();
      return { x: r.x + r.width / 2, y: r.y + r.height / 2, value: e.value };
    })
  );
}

async function fillField(page, index, value) {
  const boxes = await inputBoxes(page);
  if (!boxes[index]) throw new Error(`no input at index ${index} (have ${boxes.length})`);
  await page.mouse.click(boxes[index].x, boxes[index].y);
  await sleep(380);
  await page.keyboard.press("Control+A");
  await sleep(90);
  await page.keyboard.press("Backspace");
  await sleep(140);
  await page.keyboard.type(value, { delay: 45 });
  await sleep(300);
}

async function treeText(page) {
  return (await F.dumpTree(page)).join("\n");
}

async function shot(page, name) {
  await page.screenshot({ path: path.join(OUT, name + ".png") });
}

function catat(no, kasus, input, diharapkan, nyata, status) {
  hasil.push({ no, kasus, input, diharapkan, nyata, status });
  console.log(`\n#${no} ${kasus}\n  input     : ${input}\n  diharapkan: ${diharapkan}\n  nyata     : ${nyata}\n  status    : ${status}`);
}

async function klik(page, teks, role = "button") {
  const n = await F.findNodeContains(page, teks, role);
  if (!n) throw new Error(`tombol "${teks}" tidak ditemukan`);
  await page.mouse.move(n.x, n.y);
  await sleep(90);
  await page.mouse.down();
  await sleep(60);
  await page.mouse.up();
}

async function tungguPesan(page, timeoutMs = 14000) {
  const t0 = Date.now();
  while (Date.now() - t0 < timeoutMs) {
    const t = await treeText(page);
    if (t.includes("wajib diisi") || t.includes("belum benar") ||
        t.includes("salah") || t.includes("terdaftar") ||
        t.includes("diaktifkan") || t.includes("Terjadi kesalahan") ||
        t.includes("Periksa koneksi") || t.includes("lemah")) {
      return t;
    }
    if (t.includes("Halo,")) return t;
    await sleep(600);
  }
  return treeText(page);
}

(async () => {
  const args = USE_PROXY
    ? ["--proxy-server=http://127.0.0.1:57020", "--proxy-bypass-list=127.0.0.1;localhost"]
    : [];
  const browser = await chromium.launch({ headless: true, executablePath: F.CHROME, args });
  const ctx = await browser.newContext({ viewport: { width: 1600, height: 900 } });
  const page = await ctx.newPage();
  page.setDefaultTimeout(40000);
  const logs = [];
  page.on("console", (m) => { if (m.type() === "error") logs.push(m.text().slice(0, 200)); });
  page.on("pageerror", (e) => logs.push("pageerror: " + String(e).slice(0, 200)));

  const buka = async () => {
    await page.goto(URL, { waitUntil: "domcontentloaded", timeout: 60000 });
    await sleep(7000);
    await F.enableSemantics(page);
    await sleep(1500);
  };

  await buka();
  let t = await treeText(page);
  catat(0, "Akses awal tanpa login", "Buka /", "Halaman Masuk tampil (halaman utama terlindungi)",
    (page.url().includes("/login") && t.includes("Masuk")) ? "URL #/login, form Masuk tampil" : "URL " + page.url(),
    (page.url().includes("/login") && t.includes("Masuk")) ? "SESUI" : "TIDAK SESUAI");
  await shot(page, "00-login-awal");

  // --- Kasus 4: kolom kosong ---
  await klik(page, "Masuk");
  await sleep(1200);
  t = await treeText(page);
  const kosong = t.includes("Email wajib diisi") && t.includes("Password wajib diisi");
  catat(4, "Kolom kosong", "—", "Kedua kolom menampilkan pesan",
    kosong ? "Email wajib diisi + Password wajib diisi" : t.slice(0, 180).replace(/\n/g, " | "),
    kosong ? "SESUI" : "TIDAK SESUAI");
  await shot(page, "04-kolom-kosong");

  // --- Kasus 3: email tidak valid ---
  await fillField(page, 0, "bukan-email");
  await fillField(page, 1, DEMO_PASSWORD);
  await klik(page, "Masuk");
  await sleep(1000);
  t = await treeText(page);
  const invalid = t.includes("Format email belum benar");
  catat(3, "Email tidak valid", "bukan-email / 123456", "Format email belum benar",
    invalid ? "Format email belum benar" : t.slice(0, 180).replace(/\n/g, " | "),
    invalid ? "SESUI" : "TIDAK SESUAI");
  await shot(page, "03-email-tidak-valid");

  // --- Daftar akun simulasi (prasyarat kasus 1 & 5) ---
  console.log("\n[setup] membuka halaman Daftar...");
  await klik(page, "Daftar");
  await sleep(1400);
  t = await treeText(page);
  console.log("  halaman daftar:", t.includes("Buat Akun Baru") ? "OK" : "GAGAL");
  await fillField(page, 0, "Rina Simulasi");
  await fillField(page, 1, DEMO_EMAIL);
  await fillField(page, 2, DEMO_PASSWORD);
  await fillField(page, 3, DEMO_PASSWORD);
  await shot(page, "setup-form-daftar");
  await klik(page, "Daftar");
  t = await tungguPesan(page, 18000);
  const daftarBerhasil = t.includes("Halo,") || page.url().includes("/beranda");
  const sudahAda = t.includes("Email sudah terdaftar. Silakan masuk.");
  // Akun simulasi boleh sudah ada dari percobaan sebelumnya.
  const akunSiap = daftarBerhasil || sudahAda;
  console.log("  daftar:", daftarBerhasil
    ? "BERHASIL (akun baru dibuat)"
    : sudahAda ? "AKUN SUDAH ADA (lanjut uji login)" : "GAGAL -> " + t.slice(0, 260).replace(/\n/g, " | "));
  await shot(page, "setup-hasil-daftar");

  // Bila pendaftaran tadi berhasil, kita masih dalam sesi login; keluar dulu.
  if (daftarBerhasil) {
    await sleep(1200);
    await klik(page, "Keluar");
    await sleep(2500);
  } else {
    // Pendaftaran ditolak karena email sudah ada -> kembali ke halaman Masuk.
    await klik(page, "Masuk");
    await sleep(1800);
  }

  if (akunSiap) {
    // --- Kasus 1: login benar ---
    await fillField(page, 0, DEMO_EMAIL);
    await fillField(page, 1, DEMO_PASSWORD);
    await klik(page, "Masuk");
    t = await tungguPesan(page, 16000);
    const masuk = t.includes("Halo,") || page.url().includes("/beranda");
    catat(1, "Login benar", `${DEMO_EMAIL} / ${DEMO_PASSWORD}`, "Halaman Utama (Beranda) tampil",
      masuk ? "Beranda tampil, sapaan 'Halo, Rina Simulasi!'" : t.slice(0, 200).replace(/\n/g, " | "),
      masuk ? "SESUI" : "TIDAK SESUAI");
    await shot(page, "01-login-benar");

    // --- Sesi bertahan setelah refresh ---
    await page.reload({ waitUntil: "domcontentloaded" });
    await sleep(7000);
    await F.enableSemantics(page);
    await sleep(1500);
    t = await treeText(page);
    const sesi = t.includes("Halo,") && !page.url().includes("/login");
    catat(6, "Sesi setelah refresh", "F5 pada Beranda", "Tetap masuk di Halaman Utama",
      sesi ? "Beranda tetap tampil, URL " + page.url().split("#").pop() : "Kembali ke " + page.url(),
      sesi ? "SESUI" : "TIDAK SESUAI");
    await shot(page, "06-sesi-refresh");

    // --- Kasus 2: password salah ---
    await klik(page, "Keluar");
    await sleep(2500);
    await fillField(page, 0, DEMO_EMAIL);
    await fillField(page, 1, "salah123");
    await klik(page, "Masuk");
    t = await tungguPesan(page, 16000);
    const salah = t.includes("Email atau password salah");
    catat(2, "Password salah", `${DEMO_EMAIL} / salah123`, "Email atau password salah",
      salah ? "Email atau password salah" : t.slice(0, 220).replace(/\n/g, " | "),
      salah ? "SESUI" : "TIDAK SESUAI");
    await shot(page, "02-password-salah");

    // --- Kasus 5: daftar dengan email terpakai ---
    await klik(page, "Daftar");
    await sleep(1400);
    await fillField(page, 0, "Rina Lagi");
    await fillField(page, 1, DEMO_EMAIL);
    await fillField(page, 2, DEMO_PASSWORD);
    await fillField(page, 3, DEMO_PASSWORD);
    await klik(page, "Daftar");
    t = await tungguPesan(page, 16000);
    const duplikat = t.includes("Email sudah terdaftar. Silakan masuk.");
    catat(5, "Daftar dengan email terpakai", `Rina Lagi / ${DEMO_EMAIL} / ${DEMO_PASSWORD}`,
      "Email sudah terdaftar. Silakan masuk.",
      duplikat ? "Email sudah terdaftar. Silakan masuk." : t.slice(0, 220).replace(/\n/g, " | "),
      duplikat ? "SESUI" : "TIDAK SESUAI");
    await shot(page, "05-email-terpakai");

    // --- Tombol Keluar ---
    await klik(page, "Masuk");
    await sleep(1200);
    await fillField(page, 0, DEMO_EMAIL);
    await fillField(page, 1, DEMO_PASSWORD);
    await klik(page, "Masuk");
    await sleep(5000);
    await klik(page, "Keluar");
    await sleep(2500);
    t = await treeText(page);
    const keluar = page.url().includes("/login") && t.includes("SkinCare Store");
    catat(7, "Tombol Keluar", "Klik ikon Keluar di app bar Beranda", "Kembali ke Halaman Masuk",
      keluar ? "Kembali ke #/login tanpa Navigator" : "URL " + page.url(),
      keluar ? "SESUI" : "TIDAK SESUAI");
    await shot(page, "07-setelah-keluar");

    // --- Kasus 8: role admin masih terbaca ---
    await fillField(page, 0, "admin@skincare.id");
    await fillField(page, 1, DEMO_PASSWORD);
    await klik(page, "Masuk");
    await sleep(6000);
    await page.evaluate(() => { window.location.hash = "#/akun"; });
    await sleep(2500);
    t = await treeText(page);
    const admin = t.includes("Dashboard Admin") && t.includes("Admin");
    catat(8, "Akun admin tetap terjangkau", "admin@skincare.id / 123456",
      "Menu Dashboard Admin tampil di halaman Akun",
      admin ? "Halaman Akun menampilkan badge Admin dan menu Dashboard Admin"
            : t.slice(0, 220).replace(/\n/g, " | "),
      admin ? "SESUI" : "TIDAK SESUAI");
    await shot(page, "08-akun-admin");
  } else {
    catat(1, "Login benar", "—", "Halaman Utama tampil", "Tidak dapat diuji: pendaftaran gagal", "TERHALANG");
    catat(2, "Password salah", "—", "Email atau password salah", "Tidak dapat diuji: pendaftaran gagal", "TERHALANG");
    catat(5, "Daftar email terpakai", "—", "Email sudah terdaftar. Silakan masuk.", "Tidak dapat diuji: pendaftaran gagal", "TERHALANG");
    catat(6, "Sesi setelah refresh", "—", "Tetap masuk", "Tidak dapat diuji: pendaftaran gagal", "TERHALANG");
    catat(7, "Tombol Keluar", "—", "Kembali ke Halaman Masuk", "Tidak dapat diuji: pendaftaran gagal", "TERHALANG");
  }

  console.log("\n=== CONSOLE ERRORS ===");
  console.log(logs.slice(0, 12).join("\n") || "(none)");
  fs.writeFileSync(
    path.join(OUT, "hasil-uji.json"),
    JSON.stringify({ tanggal: new Date().toISOString(), url: URL, hasil }, null, 2)
  );
  console.log("\nHasil tersimpan di out/m9/hasil-uji.json");
  await browser.close();
})().catch((e) => {
  console.error("UJI ERROR", e);
  fs.writeFileSync(path.join(OUT, "hasil-uji.json"), JSON.stringify({ error: String(e), hasil }, null, 2));
  process.exit(1);
});
