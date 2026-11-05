import React from "react";
import { Img, staticFile } from "remotion";
import { C, FONT, pad, shadow } from "../theme";
import { riseIn, useIn } from "../anim";
import { SceneFrame, Watermark } from "../components/ui";

/* ── User Flow ── */
const FLOW_STEPS = ["Login", "Beranda", "Profil Kulit", "Daftar Produk", "Detail", "Keranjang", "Checkout", "Status"];

const FLOW_LABEL_TOP = 250;
const FLOW_Y = 312;
const FLOW_NODE_W = 158;
const FLOW_NODE_H = 56;
const FLOW_GAP = 34;
const FLOW_TOTAL_W = FLOW_STEPS.length * FLOW_NODE_W + (FLOW_STEPS.length - 1) * FLOW_GAP;
const FLOW_START_X = (1920 - FLOW_TOTAL_W) / 2;

const FlowNode: React.FC<{ label: string; index: number; total: number }> = ({ label, index, total }) => {
  const p = useIn(Math.round(total * (0.06 + index * 0.032)), 18);
  const isLast = index === FLOW_STEPS.length - 1;
  const left = FLOW_START_X + index * (FLOW_NODE_W + FLOW_GAP);
  return (
    <>
      <div
        style={{
          position: "absolute",
          left,
          top: FLOW_Y,
          width: FLOW_NODE_W,
          height: FLOW_NODE_H,
          borderRadius: 13,
          background: isLast ? C.successBg : C.white,
          border: `1.5px solid ${isLast ? "rgba(46,158,107,0.40)" : C.line}`,
          boxShadow: shadow.soft,
          display: "flex",
          alignItems: "center",
          justifyContent: "center",
          fontFamily: FONT,
          fontSize: 18,
          fontWeight: 600,
          color: isLast ? C.success : C.ink,
          ...riseIn(p, 16),
        }}
      >
        {label}
      </div>
      {!isLast && (
        <div
          style={{
            position: "absolute",
            left: left + FLOW_NODE_W,
            top: FLOW_Y + FLOW_NODE_H / 2 - 14,
            width: FLOW_GAP,
            textAlign: "center",
            fontFamily: FONT,
            fontSize: 20,
            fontWeight: 700,
            color: C.primary,
            opacity: p,
          }}
        >
          →
        </div>
      )}
    </>
  );
};

/* ── Sitemap ── */
const SITE_CUSTOMER = [
  "Login", "Register", "Beranda", "Daftar Produk", "Detail Produk", "Keranjang",
  "Checkout", "Status Pesanan", "Riwayat Pesanan", "Profil Kulit", "Akun",
];
const SITE_ADMIN = ["Dashboard", "Kelola Produk", "Form Produk", "Kelola Pesanan"];

const SITE_LABEL_TOP = 402;
const SITE_TOP = 462;
const SITE_NODE_W = 152;
const SITE_NODE_H = 44;
const SITE_GAP_X = 12;
const SITE_GAP_Y = 12;
const SITE_PER_ROW = 6;
const SITE_LEFT = pad;

const chipBase: React.CSSProperties = {
  width: SITE_NODE_W,
  height: SITE_NODE_H,
  borderRadius: 10,
  display: "flex",
  alignItems: "center",
  justifyContent: "center",
  fontFamily: FONT,
  fontSize: 15,
  fontWeight: 600,
};

const CustomerChip: React.FC<{ label: string; left: number; top: number; delay: number }> = ({
  label,
  left,
  top,
  delay,
}) => {
  const p = useIn(delay, 14);
  return (
    <div
      style={{
        ...chipBase,
        position: "absolute",
        left,
        top,
        background: C.tint,
        border: "1px solid rgba(217,87,120,0.22)",
        color: C.primaryDark,
        ...riseIn(p, 12),
      }}
    >
      {label}
    </div>
  );
};

const AdminChip: React.FC<{ label: string; delay: number }> = ({ label, delay }) => {
  const p = useIn(delay, 14);
  return (
    <div
      style={{
        ...chipBase,
        background: C.slateBg,
        border: "1px solid #E3E5E9",
        color: C.slate,
        ...riseIn(p, 12),
      }}
    >
      {label}
    </div>
  );
};

/* ── Wireframe thumbnails ── */
const WIRES = [
  { src: "screenshots/login.png", label: "Login" },
  { src: "screenshots/beranda.png", label: "Beranda" },
  { src: "screenshots/produk.png", label: "Daftar Produk" },
  { src: "screenshots/profil-kulit.png", label: "Profil Kulit" },
];

const WIRE_W = 296;
const WIRE_H = 167;
const WIRE_GAP = 24;
const WIRE_LABEL_TOP = 690;
const WIRE_TOP = 726;
const WIRE_START_X = (1920 - (WIRES.length * WIRE_W + (WIRES.length - 1) * WIRE_GAP)) / 2;

const WireShot: React.FC<{ src: string; label: string; index: number; total: number }> = ({
  src,
  label,
  index,
  total,
}) => {
  const p = useIn(Math.round(total * (0.60 + index * 0.035)), 18);
  return (
    <div
      style={{
        position: "absolute",
        left: WIRE_START_X + index * (WIRE_W + WIRE_GAP),
        top: WIRE_TOP,
        ...riseIn(p, 20),
      }}
    >
      <div
        style={{
          width: WIRE_W,
          height: WIRE_H,
          borderRadius: 12,
          overflow: "hidden",
          border: `1px solid ${C.line}`,
          background: C.white,
          boxShadow: shadow.card,
        }}
      >
        <Img src={staticFile(src)} style={{ width: "100%", height: "100%", objectFit: "cover" }} />
      </div>
      <div
        style={{
          marginTop: 9,
          fontFamily: FONT,
          fontSize: 15,
          fontWeight: 600,
          color: C.inkMuted,
          textAlign: "center",
        }}
      >
        {label}
      </div>
    </div>
  );
};

/* ── Section label ── */
const SectionLabel: React.FC<{
  children: React.ReactNode;
  top: number;
  total: number;
  delayPct: number;
}> = ({ children, top, total, delayPct }) => {
  const p = useIn(Math.round(total * delayPct), 16);
  return (
    <div
      style={{
        position: "absolute",
        left: pad,
        top,
        display: "flex",
        alignItems: "center",
        gap: 10,
        ...riseIn(p, 12),
      }}
    >
      <div style={{ width: 6, height: 21, borderRadius: 3, background: C.primary }} />
      <div style={{ fontFamily: FONT, fontSize: 20, fontWeight: 700, color: C.ink }}>{children}</div>
    </div>
  );
};

const FigmaBadge: React.FC<{ total: number }> = ({ total }) => {
  const p = useIn(Math.round(total * 0.84), 16);
  return (
    <div
      style={{
        position: "absolute",
        right: pad,
        top: 78,
        display: "flex",
        alignItems: "center",
        gap: 8,
        fontFamily: FONT,
        fontSize: 16,
        fontWeight: 600,
        color: C.primaryDark,
        background: C.tintStrong,
        border: "1px solid rgba(217,87,120,0.24)",
        borderRadius: 999,
        padding: "8px 18px",
        ...riseIn(p, 12),
      }}
    >
      Figma · 5 frame Must
    </div>
  );
};

const AdminLabel: React.FC<{ total: number }> = ({ total }) => {
  const p = useIn(Math.round(total * 0.42), 16);
  return (
    <div
      style={{
        display: "flex",
        alignItems: "center",
        gap: 9,
        marginBottom: 9,
        opacity: p,
      }}
    >
      <div style={{ width: 8, height: 8, borderRadius: 3, background: C.slate }} />
      <div style={{ fontFamily: FONT, fontSize: 16, fontWeight: 700, color: C.slate, letterSpacing: 0.4 }}>
        Admin · 4 halaman
      </div>
    </div>
  );
};

const ADMIN_TOP = SITE_TOP + Math.ceil(SITE_CUSTOMER.length / SITE_PER_ROW) * (SITE_NODE_H + SITE_GAP_Y) + 22;

export const Rancangan: React.FC<{ total: number }> = ({ total }) => (
  <SceneFrame total={total} kicker="Rancangan" title="User flow, sitemap & wireframe">
    {/* ── User Flow ── */}
    <SectionLabel top={FLOW_LABEL_TOP} total={total} delayPct={0.03}>
      User Flow
    </SectionLabel>
    {FLOW_STEPS.map((label, i) => (
      <FlowNode key={label} label={label} index={i} total={total} />
    ))}

    {/* ── Sitemap ── */}
    <SectionLabel top={SITE_LABEL_TOP} total={total} delayPct={0.16}>
      Sitemap — 11 halaman pelanggan + 4 halaman admin
    </SectionLabel>
    {SITE_CUSTOMER.map((label, i) => (
      <CustomerChip
        key={label}
        label={label}
        left={SITE_LEFT + (i % SITE_PER_ROW) * (SITE_NODE_W + SITE_GAP_X)}
        top={SITE_TOP + Math.floor(i / SITE_PER_ROW) * (SITE_NODE_H + SITE_GAP_Y)}
        delay={Math.round(total * (0.22 + i * 0.013))}
      />
    ))}

    {/* ── Admin row ── */}
    <div style={{ position: "absolute", left: SITE_LEFT, top: ADMIN_TOP }}>
      <AdminLabel total={total} />
      <div style={{ display: "flex", gap: SITE_GAP_X }}>
        {SITE_ADMIN.map((label, i) => (
          <AdminChip key={label} label={label} delay={Math.round(total * (0.46 + i * 0.015))} />
        ))}
      </div>
    </div>

    {/* ── Wireframe ── */}
    <SectionLabel top={WIRE_LABEL_TOP} total={total} delayPct={0.56}>
      Wireframe Figma → implementasi Flutter
    </SectionLabel>
    {WIRES.map((w, i) => (
      <WireShot key={w.src} src={w.src} label={w.label} index={i} total={total} />
    ))}

    <FigmaBadge total={total} />
    <Watermark index={5} count={6} label="Rancangan" />
  </SceneFrame>
);
