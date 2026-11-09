// Probe: apakah Firebase initializeApp berhasil dan halaman apa yang tampil.
const { chromium } = require("playwright-core");
const F = require("./lib/flutter");

const URL = "http://127.0.0.1:8137/";

(async () => {
  const browser = await chromium.launch({
    headless: true,
    executablePath: F.CHROME,
    args: ["--no-proxy-server"],
  });
  const page = await browser.newPage({ viewport: { width: 1280, height: 900 } });
  const logs = [];
  page.on("console", (m) => logs.push(`[${m.type()}] ${m.text().slice(0, 200)}`));
  page.on("pageerror", (e) => logs.push(`[pageerror] ${String(e).slice(0, 300)}`));
  page.on("requestfailed", (r) =>
    logs.push(`[requestfailed] ${r.url().slice(0, 120)} :: ${r.failure()?.errorText}`)
  );

  await page.goto(URL, { waitUntil: "domcontentloaded", timeout: 60000 });
  await page.waitForTimeout(9000);
  await F.enableSemantics(page);
  await page.waitForTimeout(2000);

  console.log("=== URL ===", page.url());
  console.log("=== TREE ===");
  console.log((await F.dumpTree(page)).slice(0, 60).join("\n"));
  console.log("=== LOGS ===");
  console.log(logs.slice(0, 30).join("\n") || "(none)");
  await page.screenshot({ path: "out/m9/probe.png" });
  await browser.close();
})().catch((e) => {
  console.error("PROBE ERROR", e);
  process.exit(1);
});
