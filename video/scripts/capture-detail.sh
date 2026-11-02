#!/usr/bin/env bash
# Capture Detail Produk + Checkout using real mouse events at node coordinates.
set -u
OUT="D:/dev/tokoskincare/video/public/screenshots"
mkdir -p "$OUT"

# Find centre coordinates of first semantics node containing text $1, then real-click it.
mouse_click_text() {
  local coords
  coords=$(agent-browser eval "(() => {
    const nodes=[...document.querySelectorAll('flt-semantics')];
    const norm=s=>(s||'').replace(/\\s+/g,' ').trim();
    const W='$1';
    let cands=nodes.filter(n=>norm(n.innerText).includes(W));
    if(!cands.length) return 'MISS';
    const exact=cands.filter(n=>norm(n.innerText)===W);
    const pool=exact.length?exact:cands;
    pool.sort((a,b)=>norm(a.innerText).length-norm(b.innerText).length);
    const n=pool[0];
    const r=n.getBoundingClientRect();
    if(r.width<2||r.height<2) return 'ZERO';
    return Math.round(r.left+r.width/2)+','+Math.round(r.top+r.height/2)+','+Math.round(r.width)+'x'+Math.round(r.height);
  })()" 2>&1 | tr -d '"' | tr -d '\r')
  echo "  coords[$1] = $coords"
  if [[ "$coords" == *,* ]]; then
    local x=${coords%%,*}
    local rest=${coords#*,}
    local y=${rest%%,*}
    agent-browser mouse move "$x" "$y" >/dev/null 2>&1
    sleep 1
    agent-browser mouse down >/dev/null 2>&1
    sleep 1
    agent-browser mouse up >/dev/null 2>&1
    sleep 1
    return 0
  fi
  return 1
}

echo "=== OPEN ==="
agent-browser open "http://127.0.0.1:8137/" 2>&1
agent-browser set viewport 1600 900 2>&1
sleep 8
agent-browser eval "(() => { const p=document.querySelector('flt-semantics-placeholder'); if(p){p.click(); return 'a11y-on';} return 'already'; })()" 2>&1
sleep 3

echo "=== LOGIN ==="
agent-browser click 'input[aria-label="contoh@email.com"]' >/dev/null 2>&1
sleep 1
agent-browser keyboard type "rina@mail.com" >/dev/null 2>&1
sleep 1
agent-browser click 'input[aria-label="Minimal 6 karakter"]' >/dev/null 2>&1
sleep 1
agent-browser keyboard type "123456" >/dev/null 2>&1
sleep 1
mouse_click_text "Masuk"
sleep 8

echo "=== NAV PRODUK ==="
mouse_click_text "Produk"
sleep 6

echo "=== CLICK PRODUCT CARD ==="
mouse_click_text "Glow Cleanser"
sleep 7
agent-browser screenshot "$OUT/03-detail.png" 2>&1

echo "=== BELI SEKARANG ==="
mouse_click_text "Beli Sekarang"
sleep 7
agent-browser screenshot "$OUT/04-checkout.png" 2>&1

echo "=== DONE ==="
ls -la "$OUT"/*.png
agent-browser close 2>&1
