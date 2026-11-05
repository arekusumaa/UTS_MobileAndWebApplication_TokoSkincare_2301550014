// Shared helpers for driving the Flutter web app through the semantics tree.
const CHROME =
  "D:/dev/tokoskincare/video/node_modules/.remotion/chrome-headless-shell/win64/chrome-headless-shell-win64/chrome-headless-shell.exe";

async function enableSemantics(page) {
  await page.waitForSelector("flt-semantics-placeholder", { timeout: 45000 });
  await page.locator("flt-semantics-placeholder").first().dispatchEvent("click");
  await page.waitForTimeout(1200);
}

/** Return the smallest visible semantics node matching text (and optional role). */
async function findNode(page, text, role = "") {
  return page.evaluate(
    ({ text, role }) => {
      const nodes = Array.from(document.querySelectorAll("flt-semantics"));
      let best = null;
      for (const n of nodes) {
        const t = (n.innerText || "").trim();
        const r = n.getAttribute("role") || "";
        if (role && r !== role) continue;
        if (t !== text) continue;
        const rect = n.getBoundingClientRect();
        if (rect.width < 2 || rect.height < 2) continue;
        const area = rect.width * rect.height;
        if (!best || area < best.area) {
          best = {
            x: rect.x + rect.width / 2,
            y: rect.y + rect.height / 2,
            area,
            w: rect.width,
            h: rect.height,
          };
        }
      }
      return best;
    },
    { text, role }
  );
}

/** Return the smallest visible node whose text *contains* needle. */
async function findNodeContains(page, needle, role = "") {
  return page.evaluate(
    ({ needle, role }) => {
      const nodes = Array.from(document.querySelectorAll("flt-semantics"));
      let best = null;
      for (const n of nodes) {
        const t = (n.innerText || "").trim();
        const r = n.getAttribute("role") || "";
        if (role && r !== role) continue;
        if (!t.includes(needle)) continue;
        const rect = n.getBoundingClientRect();
        if (rect.width < 2 || rect.height < 2) continue;
        const area = rect.width * rect.height;
        if (!best || area < best.area) {
          best = {
            x: rect.x + rect.width / 2,
            y: rect.y + rect.height / 2,
            area,
            w: rect.width,
            h: rect.height,
            text: t.slice(0, 80),
          };
        }
      }
      return best;
    },
    { needle, role }
  );
}

async function clickNode(page, text, role = "") {
  const n = await findNode(page, text, role);
  if (!n) throw new Error(`node not found: "${text}" role="${role}"`);
  await page.mouse.move(n.x, n.y);
  await page.waitForTimeout(90);
  await page.mouse.down();
  await page.waitForTimeout(60);
  await page.mouse.up();
  return n;
}

async function clickContains(page, needle, role = "") {
  const n = await findNodeContains(page, needle, role);
  if (!n) throw new Error(`node containing not found: "${needle}" role="${role}"`);
  await page.mouse.move(n.x, n.y);
  await page.waitForTimeout(90);
  await page.mouse.down();
  await page.waitForTimeout(60);
  await page.mouse.up();
  return n;
}

/** Click a text field then type real keystrokes. */
async function typeInto(page, label, value, opts = {}) {
  const clear = opts.clear !== false;
  const n = await findNode(page, label);
  if (!n) throw new Error(`field not found: "${label}"`);
  await page.mouse.move(n.x, n.y);
  await page.waitForTimeout(80);
  await page.mouse.down();
  await page.waitForTimeout(50);
  await page.mouse.up();
  await page.waitForTimeout(500);

  if (clear) {
    await page.keyboard.press("Control+A");
    await page.waitForTimeout(120);
    await page.keyboard.press("Backspace");
    await page.waitForTimeout(120);
  }
  await page.keyboard.type(value, { delay: 55 });
  await page.waitForTimeout(300);
}

async function dumpTree(page) {
  return page.evaluate(() => {
    const nodes = Array.from(document.querySelectorAll("flt-semantics"));
    const out = [];
    for (const n of nodes) {
      const t = (n.innerText || "").trim().replace(/\n/g, " | ");
      const r = n.getAttribute("role") || "";
      const rect = n.getBoundingClientRect();
      if (!t) continue;
      if (rect.width < 2 || rect.height < 2) continue;
      out.push(`${r || "-"} :: ${t.slice(0, 70)}`);
    }
    return out;
  });
}

module.exports = {
  CHROME,
  enableSemantics,
  findNode,
  findNodeContains,
  clickNode,
  clickContains,
  typeInto,
  dumpTree,
};
