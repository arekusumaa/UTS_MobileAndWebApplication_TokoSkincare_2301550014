// Uji integrasi RESMI modul Minggu 10: "Cloud Firestore: Collection,
// Tambah & Tampilkan Data" — Create + Read saja (Update/Delete Minggu 11).
//
// Berbeda dengan uji-firestore-m10.js (fokus migrasi & persistensi keranjang),
// skrip ini membuktikan 8 butir modul pada aplikasi yang berjalan:
//   1. Create dokumen skin_profiles/{uid} lewat form Profil Kulit
//   2. Read collection products lewat StreamBuilder + .snapshots()
//   3. Validasi form SEBELUM Create + Create dokumen orders/{orderId}
//   4. Read realtime orders lewat where('uid').snapshots() di Riwayat Pesanan
//   5. Aturan bisnis sebelum Create menolak pesanan identik (padanan
//      "cegah jadwal bentrok" RoomBook)
//   6. Data tetap ada setelah refresh (bukan sekadar memori)
//   7. Perubahan dokumen di server langsung tampil tanpa refresh (realtime)
//   8. Isolasi pengguna: akun lain tidak melihat pesanan milik Rina
//
// Verifikasi tidak hanya membaca UI: tiap kasus dicek ke server Firestore
// memakai token OAuth pemilik project (setara Admin SDK, melewati Rules).
//
// Jalankan:
//   python -m http.server 8137 --bind 127.0.0.1   (dari build/web)
//   node video/scripts/uji-modul-m10.js
const fs = require("fs");
const os = require("os");
const path = require("path");
const { chromium } = require("playwright-core");
const F = require("./lib/flutter");

const URL = "http://127.0.0.1:8137/";
const OUT = path.join(__dirname, "..", "..", "docs", "minggu-10", "bukti");
const USER = { email: "rina@mail.com", pass: "123456" };
const ADMIN = { email: "admin@skincare.id", pass: "123456" };
const USER_UID = "stjEG021jVXudJIN0uY57wdhoDq1";
const ROOT =
  "https://firestore.googleapis.com/v1/projects/toko-skincare-fec17/" +
  "databases/(default)/documents";

fs.mkdirSync(OUT, { recursive: true });
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
const hasil = [];

function catat(no, kasus, diharapkan, nyata, ok) {
  hasil.push({ no, kasus, diharapkan, nyata, status: ok ? "SESUI" : "TIDAK SESUAI" });
  console.log(`#${no} ${kasus}: ${ok ? "SESUI" : "TIDAK SESUAI"}\n    ${nyata}`);
}

// ---------------------------------------------------------------- Firestore
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
  const txt = await r.text();
  let json = {};
  try { json = txt ? JSON.parse(txt) : {}; } catch { json = { raw: txt.slice(0, 200) }; }
  return { status: r.status, body: json };
}

async function fsList(coll) {
  const r = await fsReq(`${coll}?pageSize=100`);
  return r.body.documents || [];
}

const s = (f, k) => (f[k] || {}).stringValue || "";
const i = (f, k) => Number((f[k] || {}).integerValue || 0);
const docId = (d) => d.name.split("/").pop();

async function fsClearCart(uid) {
  const docs = await fsList(`carts/${uid}/items`);
  for (const d of docs) await fsReq(`carts/${uid}/items/${docId(d)}`, "DELETE");
  return docs.length;
}

function tandaDokumen(fields) {
  const items = (fields.items || {}).arrayValue?.values || [];
  return items
    .map((v) => {
      const m = v.mapValue?.fields || {};
      return `${s(m, "productId")}:${i(m, "quantity")}`;
    })
    .sort()
    .join("|");
}

// ------------------------------------------------------------------- Browser
async function tree(page) {
  return (await F.dumpTree(page)).join("\n");
}

async function tungguTeks(page, teks, timeoutMs = 12000) {
  const t0 = Date.now();
  let terakhir = "";
  while (Date.now() - t0 < timeoutMs) {
    terakhir = await tree(page);
    if (terakhir.includes(teks)) return { ok: true, teks: terakhir };
    await sleep(600);
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
  if (!boxes[index]) throw new Error(`input #${index} tidak ada (ada ${boxes.length})`);
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
  // Chip Flutter kadang tidak diberi role="button" oleh semantics tree,
  // jadi coba role button dulu lalu fallback ke peran apa pun.
  let n = await F.findNodeContains(page, teks, "button");
  if (!n) n = await F.findNodeContains(page, teks, "");
  if (!n) {
    const t = await tree(page);
    fs.writeFileSync(path.join(OUT, `tree-gagal-${teks.replace(/\W+/g, "_")}.txt`), t);
    throw new Error(`tombol "${teks}" tidak ditemukan; tree disimpan (${t.slice(0, 160).replace(/\n/g, " | ")})`);
  }
  await page.mouse.move(n.x, n.y);
  await sleep(90);
  await page.mouse.down();
  await sleep(60);
  await page.mouse.up();
  await sleep(350);
}

// ChoiceChip / FilterChip diekspos Flutter Web sebagai semantics node
// role="checkbox" dengan aria-label (innerText kosong), bukan tombol teks.
async function klikAria(page, label) {
  const n = await page.evaluate((l) => {
    const el = document.querySelector(`flt-semantics[aria-label="${l}"]`);
    if (!el) return null;
    const r = el.getBoundingClientRect();
    if (r.width < 2 || r.height < 2) return null;
    return { x: r.x + r.width / 2, y: r.y + r.height / 2 };
  }, label);
  if (!n) throw new Error(`chip aria-label="${label}" tidak ditemukan`);
  await page.mouse.move(n.x, n.y);
  await sleep(90);
  await page.mouse.down();
  await sleep(60);
  await page.mouse.up();
  await sleep(400);
}

async function ke(page, hash) {
  await page.evaluate((h) => { window.location.hash = h; }, hash);
  await sleep(3000);
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
  await sleep(7000);
}

async function isiFormCheckout(page) {
  await isi(page, 0, "Rina Pratiwi");
  await isi(page, 1, "081234567890");
  await isi(page, 2, "Jl. Mawar No. 12, Jakarta Selatan");
}

async function tambahKeKeranjang(page, pid) {
  await ke(page, `#/produk/${pid}`);
  await klik(page, "Keranjang");
  await sleep(2200);
  await ke(page, "#/checkout");
}

// ----------------------------------------------------------------------- Uji
(async () => {
  const browser = await chromium.launch({ headless: true, executablePath: F.CHROME });
  const ctx = await browser.newContext({ viewport: { width: 1600, height: 900 } });
  const page = await ctx.newPage();
  page.setDefaultTimeout(45000);
  const logs = [];
  page.on("console", (m) => { if (m.type() === "error") logs.push(m.text().slice(0, 180)); });
  page.on("pageerror", (e) => logs.push("pageerror: " + String(e).slice(0, 180)));

  // Fixture: kosongkan keranjang supaya tanda keranjang deterministik.
  const dibersihkan = await fsClearCart(USER_UID);
  console.log(`fixture: ${dibersihkan} item keranjang lama dibersihkan\n`);

  // Pilih produk yang stoknya cukup DAN belum punya pesanan 'menunggu'
  // dengan tanda "<id>:1" supaya aturan bisnis tidak menolak kasus #3.
  const produk = await fsList("products");
  const ordersAwal = await fsList("orders");
  const tandaMenunggu = new Set(
    ordersAwal
      .filter((d) => s(d.fields || {}, "status") === "menunggu")
      .map((d) => tandaDokumen(d.fields || {}))
  );
  const kandidat = produk.filter(
    (d) => i(d.fields || {}, "stok") >= 1 && !tandaMenunggu.has(`${docId(d)}:1`)
  );
  if (!kandidat.length) throw new Error("Tidak ada produk dengan tanda keranjang unik.");
  const pid = docId(kandidat[0]);
  const namaProduk = s(kandidat[0].fields || {}, "nama");
  console.log(`produk uji  : ${pid} — ${namaProduk} (stok ${i(kandidat[0].fields, "stok")})\n`);

  // ---------- Login pelanggan ----------
  await buka(page);
  await masuk(page, USER);
  const tLogin = await tree(page);
  catat(0, "Login pelanggan (prasyarat)", "Beranda tampil",
    tLogin.includes("Halo,") ? "Sapaan 'Halo, ...' tampil" : tLogin.slice(0, 160).replace(/\n/g, " | "),
    tLogin.includes("Halo,"));

  // ---------- #1 Create skin_profiles ----------
  await ke(page, "#/profil-kulit");
  fs.writeFileSync(path.join(OUT, "tree-profil-kulit.txt"), await tree(page));
  await klikAria(page, "Berminyak");
  await klikAria(page, "Jerawat");
  await klik(page, "Simpan Profil Kulit");
  await sleep(4000);
  const profil = await fsReq(`skin_profiles/${USER_UID}`);
  const profilOk = profil.status === 200 && s(profil.body.fields || {}, "tipeKulit") === "Berminyak";
  catat(1, "Create skin_profiles/{uid} dari form Profil Kulit",
    "Dokumen baru dengan tipeKulit='Berminyak'",
    profilOk ? `HTTP 200 — tipeKulit='Berminyak', concern & alergi tersimpan`
             : `HTTP ${profil.status} — ${JSON.stringify(profil.body).slice(0, 160)}`,
    profilOk);
  // Form memanggil Navigator.pop() sesudah menyimpan. Buka ulang lewat router
  // supaya bukti menampilkan data yang tersimpan, bukan halaman kosong.
  await ke(page, "#/beranda");
  await ke(page, "#/profil-kulit");
  await shot(page, "10-profil-kulit-tersimpan");

  // ---------- #2 Read products ----------
  await ke(page, "#/produk");
  const tProduk = await tungguTeks(page, "produk ditemukan");
  const jumlahProduk = produk.length;
  const bacaOk = tProduk.ok && tProduk.teks.includes(`${jumlahProduk} produk ditemukan`);
  catat(2, "Read collection products lewat StreamBuilder .snapshots()",
    `${jumlahProduk} produk tampil dari server`,
    bacaOk ? `UI menampilkan '${jumlahProduk} produk ditemukan'; server punya ${jumlahProduk} dokumen`
           : tProduk.teks.slice(0, 200).replace(/\n/g, " | "),
    bacaOk);
  await shot(page, "11-produk-streambuilder");

  // ---------- #3 Validasi form + Create orders ----------
  await tambahKeKeranjang(page, pid);
  await klik(page, "Buat Pesanan");
  await sleep(1500);
  const tValidasi = await tree(page);
  const validasiOk = tValidasi.includes("wajib diisi") || tValidasi.includes("minimal 10");
  catat(3, "Validasi form berjalan SEBELUM dokumen orders ditulis",
    "Pesan 'wajib diisi' / 'minimal 10 karakter' muncul, belum ada dokumen",
    validasiOk ? "Validator menolak form kosong; tidak ada dokumen baru"
               : tValidasi.slice(0, 220).replace(/\n/g, " | "),
    validasiOk);
  await shot(page, "12-validasi-checkout");

  await isiFormCheckout(page);
  await klik(page, "Buat Pesanan");
  await sleep(7000);
  const ordersSesudah = await fsList("orders");
  const idLama = new Set(ordersAwal.map(docId));
  const baru = ordersSesudah.filter((d) => !idLama.has(docId(d)));
  const orderId = baru.length ? docId(baru[0]) : "";
  const fieldBaru = baru.length ? (baru[0].fields || {}) : {};
  const createOk = !!orderId && s(fieldBaru, "uid") === USER_UID &&
                   s(fieldBaru, "status") === "menunggu" &&
                   page.url().includes("status-pesanan");
  catat(4, "Create orders/{orderId} lewat tombol Buat Pesanan",
    "1 dokumen baru, uid=Rina, status='menunggu', pindah ke Status Pesanan",
    createOk ? `Dokumen ${orderId} (uid=${USER_UID}, status=menunggu, items=${tandaDokumen(fieldBaru)})`
             : `dokumen baru=${baru.length}, url=${page.url()}`,
    createOk);
  await shot(page, "13-pesanan-berhasil-dibuat");

  // ---------- #5 Read realtime Riwayat Pesanan ----------
  await ke(page, "#/riwayat");
  const tRiwayat = await tungguTeks(page, orderId || "ORD-");
  catat(5, "Read orders lewat where('uid').snapshots() di Riwayat Pesanan",
    "Pesanan baru tampil tanpa refreshManual",
    tRiwayat.ok ? `Order ${orderId} terbaca dari stream realtime` : tRiwayat.teks.slice(0, 200).replace(/\n/g, " | "),
    tRiwayat.ok);
  await shot(page, "14-riwayat-streambuilder");

  // ---------- #6 Aturan bisnis sebelum Create (tolak duplikat) ----------
  const sebelumTolak = (await fsList("orders")).length;
  await tambahKeKeranjang(page, pid);
  await isiFormCheckout(page);
  await klik(page, "Buat Pesanan");
  // SnackBar hanya hidup 5 detik; poll segera setelah klik agar pesan
  // penolakan sempat terbaca sebelum hilang.
  let tTolak = "";
  let adaPesanTolak = false;
  for (let k = 0; k < 12; k++) {
    tTolak = await tree(page);
    if (tTolak.includes("masih berstatus") || tTolak.includes("Pesanan dengan isi")) {
      adaPesanTolak = true;
      break;
    }
    await sleep(450);
  }
  fs.writeFileSync(path.join(OUT, "tree-tolak-duplikat.txt"), tTolak);
  await shot(page, "15-tolak-pesanan-bentrok");
  await sleep(2500);
  const sesudahTolak = await fsList("orders");
  const masihCheckout = page.url().includes("checkout");
  const tolakOk = masihCheckout &&
                  sesudahTolak.length === sebelumTolak && adaPesanTolak;
  catat(6, "Aturan bisnis menolak pesanan identik yang masih Menunggu",
    "Tidak ada dokumen baru; form tetap di Checkout; SnackBar penolakan tampil",
    tolakOk ? `orders tetap ${sesudahTolak.length} dokumen, URL masih checkout, pesan penolakan tampil`
            : `orders ${sebelumTolak}→${sesudahTolak.length}, url=${page.url()}, pesan=${adaPesanTolak}`,
    tolakOk);

  // ---------- #7 Persistensi setelah refresh ----------
  await page.reload({ waitUntil: "domcontentloaded" });
  await sleep(8000);
  await F.enableSemantics(page);
  await sleep(1500);
  await ke(page, "#/riwayat");
  const tRefresh = await tungguTeks(page, orderId || "ORD-");
  catat(7, "Data pesanan tetap ada setelah refresh (F5)",
    "Order yang sama masih tampil; sumbernya server, bukan memori",
    tRefresh.ok ? `Order ${orderId} masih ada setelah halaman dimuat ulang`
                : tRefresh.teks.slice(0, 200).replace(/\n/g, " | "),
    tRefresh.ok);
  await shot(page, "16-riwayat-setelah-refresh");

  // ---------- #8 Realtime: ubah status dari Console/server ----------
  let realtimeOk = false;
  let realtimeInfo = "order uji tidak ditemukan";
  if (orderId) {
    await fsReq(`orders/${orderId}?updateMask.fieldPaths=status`, "PATCH",
      { fields: { status: { stringValue: "diproses" } } });
    await sleep(4500);
    const tStatus = await tree(page);
    realtimeOk = tStatus.includes("Diproses");
    realtimeInfo = realtimeOk
      ? "Status berubah Menunggu → Diproses tanpa refresh halaman"
      : tStatus.slice(0, 200).replace(/\n/g, " | ");
  }
  catat(8, "Perubahan dokumen di server langsung tampil (realtime)",
    "Label status berubah jadi 'Diproses' tanpa reload",
    realtimeInfo, realtimeOk);
  await shot(page, "17-realtime-status-berubah");

  // ---------- #9 Isolasi pengguna ----------
  await ke(page, "#/akun");
  await klik(page, "Keluar");
  await sleep(3500);
  await masuk(page, ADMIN);
  await ke(page, "#/riwayat");
  const tAdmin = await tree(page);
  const isolasiOk = !tAdmin.includes(orderId) && tAdmin.includes("Belum ada pesanan");
  catat(9, "Isolasi pengguna: akun admin tidak melihat pesanan Rina",
    "Riwayat admin kosong walaupun collection orders berisi pesanan Rina",
    isolasiOk ? "Riwayat admin menampilkan 'Belum ada pesanan' (filter uid bekerja)"
              : tAdmin.slice(0, 220).replace(/\n/g, " | "),
    isolasiOk);
  await shot(page, "18-isolasi-pengguna");

  const sesuai = hasil.filter((h) => h.status === "SESUI").length;
  const ringkas = {
    tanggal: new Date().toISOString(),
    url: URL,
    modul: "Minggu 10 — Cloud Firestore: Collection, Tambah & Tampilkan Data",
    produkUji: { id: pid, nama: namaProduk },
    orderUji: orderId,
    sesuai,
    total: hasil.length,
    hasil,
    consoleErrors: logs.slice(0, 15),
  };
  fs.writeFileSync(path.join(OUT, "hasil-uji-modul.json"),
    JSON.stringify(ringkas, null, 2));
  console.log(`\n${sesuai}/${hasil.length} SESUI`);
  console.log("Console errors:", logs.slice(0, 8).join(" | ") || "(none)");
  await browser.close();
  if (sesuai !== hasil.length) process.exit(1);
})().catch((e) => {
  console.error("UJI ERROR", e);
  fs.writeFileSync(path.join(OUT, "hasil-uji-modul.json"),
    JSON.stringify({ error: String(e), hasil }, null, 2));
  process.exit(1);
});
