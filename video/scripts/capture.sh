#!/usr/bin/env bash
# Capture screenshots of SkinCare Store web build via agent-browser.
set -u
OUT="D:/dev/tokoskincare/video/public/screenshots"
mkdir -p "$OUT"

# Click a semantics node whose trimmed text equals $1 (prefers role=button/tab/link)
click_text() {
  agent-browser eval "(() => {
    const nodes = [...document.querySelectorAll('flt-semantics')];
    const norm = s => (s || '').replace(/\\s+/g, ' ').trim();
    const wanted = '$1';
    const exact = nodes.filter(n => norm(n.innerText) === wanted);
    const pool = exact.length ? exact : nodes.filter(n => norm(n.innerText).includes(wanted));
    const btn = pool.find(n => ['button','tab','link'].includes(n.getAttribute('role'))) || pool[0];
    if (btn) { btn.click(); return 'OK:$1'; }
    const have = nodes.map(n => norm(n.innerText)).filter(Boolean).slice(0, 40).join(' / ');
    return 'MISS:$1 || have=' + have;
  })()" 2>&1
}

echo "=== OPEN ==="
agent-browser open "http://127.0.0.1:8137/" 2>&1
agent-browser set viewport 1600 900 2>&1
sleep 8
agent-browser eval "(() => { const p=document.querySelector('flt-semantics-placeholder'); if(p){p.click(); return 'a11y-on';} return 'already'; })()" 2>&1
sleep 3

echo "=== 00 LOGIN ==="
agent-browser screenshot "$OUT/00-login.png" 2>&1

echo "=== FILL EMAIL ==="
agent-browser click 'input[aria-label="contoh@email.com"]' 2>&1
sleep 1
agent-browser keyboard type "rina@mail.com" 2>&1
sleep 1

echo "=== FILL PASSWORD ==="
agent-browser click 'input[aria-label="Minimal 6 karakter"]' 2>&1
sleep 1
agent-browser keyboard type "123456" 2>&1
sleep 1

echo "=== CLICK MASUK ==="
click_text "Masuk"
sleep 8

echo "=== 01 BERANDA ==="
agent-browser screenshot "$OUT/01-beranda.png" 2>&1

echo "=== NAV PRODUK ==="
click_text "Produk"
sleep 5
agent-browser screenshot "$OUT/02-produk.png" 2>&1

echo "=== CLICK PRODUCT ==="
click_text "Glow Cleanser"
sleep 5
agent-browser screenshot "$OUT/03-detail.png" 2>&1

echo "=== BELI SEKARANG -> CHECKOUT ==="
click_text "Beli Sekarang"
sleep 5
agent-browser screenshot "$OUT/04-checkout.png" 2>&1

echo "=== NAV KERANJANG ==="
click_text "Keranjang"
sleep 5
agent-browser screenshot "$OUT/05-keranjang.png" 2>&1

echo "=== NAV AKUN ==="
click_text "Akun"
sleep 5
agent-browser screenshot "$OUT/06-akun.png" 2>&1

echo "=== PROFIL KULIT ==="
click_text "Profil Kulit"
sleep 5
agent-browser screenshot "$OUT/07-profil-kulit.png" 2>&1

echo "=== DONE ==="
ls -la "$OUT"
agent-browser close 2>&1
