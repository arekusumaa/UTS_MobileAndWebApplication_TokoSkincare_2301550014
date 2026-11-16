// Buat gambar bukti isi 5 collection Firestore dari REST API live.
//
// Catatan kejujuran akademik: ini BUKAN screenshot Firebase Console.
// Console membutuhkan sesi login Google pengguna, jadi gambar ini dirakit
// dari respons Firestore REST API yang sama dengan yang dipakai aplikasi.
// Screenshot Console asli tetap diserahkan mahasiswa secara manual.
//
//   node video/scripts/buat-bukti-data.js
const fs = require("fs");
const os = require("os");
const path = require("path");
const { chromium } = require("playwright-core");
const F = require("./lib/flutter");

const ROOT =
  "https://firestore.googleapis.com/v1/projects/toko-skincare-fec17/" +
  "databases/(default)/documents";
const ROOTDIR = path.join(__dirname, "..", "..");
const OUT = path.join(ROOTDIR, "docs", "minggu-10", "bukti");

function ownerToken() {
  const p = path.join(os.homedir(), ".config", "configstore", "firebase-tools.json");
  return JSON.parse(fs.readFileSync(p, "utf8")).tokens.access_token;
}

async function list(coll) {
  const r = await fetch(`${ROOT}/${coll}?pageSize=100`, {
    headers: { Authorization: "Bearer " + ownerToken() },
  });
  const j = await r.json();
  return j.documents || [];
}

const s = (f, k) => (f[k] || {}).stringValue || "";
const i = (f, k) => Number((f[k] || {}).integerValue || 0);
const id = (d) => d.name.split("/").pop();
const esc = (v) => String(v).replace(/[&<>]/g, (c) =>
  ({ "&": "&amp;", "<": "&lt;", ">": "&gt;" }[c]));

(async () => {
  const meta = JSON.parse(fs.readFileSync(
    path.join(ROOTDIR, "docs", "minggu-10", "isi-firestore.json"), "utf8"));
  const orders = await list("orders");
  const profil = await list("skin_profiles");

  const orderRows = orders.map((d) => {
    const f = d.fields || {};
    const items = (f.items || {}).arrayValue?.values || [];
    const isi = items.map((v) => {
      const m = v.mapValue?.fields || {};
      return `${s(m, "productId")} x${i(m, "quantity")}`;
    }).join(", ") || "-";
    return `<tr><td><code>${esc(id(d))}</code></td>
      <td><code>${esc(s(f, "uid").slice(0, 12))}…</code></td>
      <td>${esc(isi)}</td><td>Rp ${i(f, "total").toLocaleString("id-ID")}</td>
      <td><span class="badge">${esc(s(f, "status"))}</span></td></tr>`;
  }).join("");

  const profilRows = profil.map((d) => {
    const f = d.fields || {};
    const arr = (k) => ((f[k] || {}).arrayValue?.values || [])
      .map((v) => v.stringValue || "").join(", ") || "-";
    return `<tr><td><code>${esc(id(d))}</code></td>
      <td>${esc(s(f, "tipeKulit"))}</td><td>${esc(arr("concern"))}</td>
      <td>${esc(arr("alergi"))}</td></tr>`;
  }).join("");

  const kartu = (nama, docs, extra = "") => `
    <div class="card">
      <div class="card-head"><span class="dot"></span>
        <b>${esc(nama)}</b><span class="count">${docs.length} dokumen</span></div>
      <div class="chips">${docs.length
        ? docs.map((x) => `<code>${esc(x)}</code>`).join("")
        : '<span class="muted">sub-collection berisi dokumen items</span>'}</div>
      ${extra}
    </div>`;

  const html = `<!doctype html><html><head><meta charset="utf-8"><style>
    *{box-sizing:border-box}
    body{margin:0;padding:32px 40px;background:#faf7f8;color:#2b2230;
         font-family:Arial,Helvetica,sans-serif}
    h1{margin:0 0 4px;font-size:26px;color:#D95778}
    .sub{font-size:13px;color:#7a6b73;margin-bottom:6px}
    .note{font-size:12px;color:#8a5a68;background:#fff0f4;border:1px solid #f5c9d6;
          padding:10px 14px;border-radius:8px;margin:14px 0 20px}
    .grid{display:grid;grid-template-columns:repeat(2,1fr);gap:16px}
    .card{background:#fff;border:1px solid #ece2e7;border-radius:12px;padding:16px;
          box-shadow:0 1px 3px rgba(0,0,0,.04)}
    .card-head{display:flex;align-items:center;gap:9px;font-size:16px;margin-bottom:12px}
    .dot{width:10px;height:10px;border-radius:50%;background:#D95778;display:inline-block}
    .count{margin-left:auto;font-size:12px;color:#fff;background:#D95778;
           padding:3px 9px;border-radius:20px}
    .chips{display:flex;flex-wrap:wrap;gap:6px}
    code{font-size:11px;background:#f7f1f4;border:1px solid #eee0e7;
         padding:3px 7px;border-radius:5px;color:#5c4552}
    .muted{font-size:12px;color:#9a8b93}
    table{width:100%;border-collapse:collapse;margin-top:20px;font-size:12px;
          background:#fff;border-radius:10px;overflow:hidden}
    th{background:#D95778;color:#fff;text-align:left;padding:9px 12px;font-size:12px}
    td{padding:8px 12px;border-bottom:1px solid #f1e9ed}
    .badge{background:#fff0f4;color:#D95778;padding:2px 8px;border-radius:12px;font-size:11px}
    h2{font-size:16px;margin:26px 0 0;color:#4a3842}
    .foot{margin-top:22px;font-size:11px;color:#9a8b93}
  </style></head><body>
    <h1>Cloud Firestore — Isi Collection</h1>
    <div class="sub">Project <b>toko-skincare-fec17</b> · Database (default) ·
      asia-southeast2 · Paket Spark</div>
    <div class="sub">Diambil ${esc(meta.tanggal)} (UTC) lewat Firestore REST API
      dengan token pemilik project.</div>
    <div class="note"><b>Catatan:</b> gambar ini dirakit dari respons REST API,
      bukan screenshot Firebase Console. Screenshot Console asli dilampirkan
      terpisah oleh mahasiswa (memerlukan login Google).</div>
    <div class="grid">
      ${kartu("users", meta.collections.users)}
      ${kartu("products", meta.collections.products)}
      ${kartu("skin_profiles", meta.collections.skin_profiles)}
      ${kartu("orders", meta.collections.orders)}
      ${kartu("carts", [], '<div class="chips"><code>carts/{uid}/items → P01</code></div>')}
      <div class="card">
        <div class="card-head"><span class="dot"></span><b>Ringkasan</b></div>
        <div class="chips">
          <code>5 collection</code><code>Create + Read</code>
          <code>StreamBuilder .snapshots()</code><code>Security Rules default-deny</code>
        </div>
      </div>
    </div>
    <h2>Dokumen orders</h2>
    <table><thead><tr><th>ID dokumen</th><th>uid</th><th>items</th>
      <th>total</th><th>status</th></tr></thead><tbody>${orderRows}</tbody></table>
    <h2>Dokumen skin_profiles</h2>
    <table><thead><tr><th>ID dokumen</th><th>tipeKulit</th>
      <th>concern</th><th>alergi</th></tr></thead><tbody>${profilRows}</tbody></table>
    <div class="foot">SkinCare Store · Are Kusuma Pratiwi · 23.01.55.0014 ·
      Modul Minggu 10 — Cloud Firestore: Collection, Tambah &amp; Tampilkan Data</div>
  </body></html>`;

  fs.writeFileSync(path.join(OUT, "19-isi-collection.html"), html);
  const browser = await chromium.launch({ headless: true, executablePath: F.CHROME });
  const page = await browser.newPage({ viewport: { width: 1280, height: 1100 },
                                      deviceScaleFactor: 1 });
  await page.setContent(html, { waitUntil: "load" });
  await page.screenshot({ path: path.join(OUT, "19-isi-collection.png"),
                          fullPage: true });
  await browser.close();
  console.log("->", path.join(OUT, "19-isi-collection.png"));
})().catch((e) => { console.error(e); process.exit(1); });
