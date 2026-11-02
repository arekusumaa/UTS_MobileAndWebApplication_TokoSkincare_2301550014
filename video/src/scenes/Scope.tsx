import React from "react";
import { Img, staticFile } from "remotion";
import { C, FONT, pad, shadow } from "../theme";
import { riseIn, useIn } from "../anim";
import { Chip, Panel, SceneFrame, Watermark } from "../components/ui";

const SHOTS: { src: string; label: string }[] = [
  { src: "screenshots/login.png", label: "Login" },
  { src: "screenshots/beranda.png", label: "Beranda" },
  { src: "screenshots/produk.png", label: "Daftar Produk" },
  { src: "screenshots/profil-kulit.png", label: "Profil Kulit" },
];

const PAGES_CUSTOMER = [
  "Login",
  "Register",
  "Beranda",
  "Daftar Produk",
  "Detail Produk",
  "Keranjang",
  "Checkout",
  "Status Pesanan",
  "Riwayat Pesanan",
  "Profil Kulit",
  "Akun",
];

const PAGES_ADMIN = ["Dashboard", "Kelola Produk", "Form Produk", "Kelola Pesanan"];

const MUST = [
  "Profil kulit",
  "Rekomendasi produk",
  "Katalog + filter",
  "Keranjang + checkout",
  "Status pesanan",
];

const WONT = ["Pembayaran nyata", "Notifikasi push", "Unggah foto produk"];

const SHOT_W = 372;
const SHOT_H = 209;
const SHOT_GAP = 24;
const STRIP_TOP = 252;

const smallChip: React.CSSProperties = { padding: "7px 14px", borderRadius: 10 };

const Shot: React.FC<{ src: string; label: string; delay: number; index: number }> = ({
  src,
  label,
  delay,
  index,
}) => {
  const p = useIn(delay, 24);
  return (
    <div
      style={{
        position: "absolute",
        left: pad + 84 + index * (SHOT_W + SHOT_GAP),
        top: STRIP_TOP,
        width: SHOT_W,
        ...riseIn(p, 26),
      }}
    >
      <div
        style={{
          width: SHOT_W,
          height: SHOT_H,
          borderRadius: 14,
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
          marginTop: 10,
          fontFamily: FONT,
          fontSize: 17,
          fontWeight: 600,
          color: C.inkMuted,
          letterSpacing: 0.3,
          textAlign: "center",
        }}
      >
        {label}
      </div>
    </div>
  );
};

const PagesPanel: React.FC<{ total: number }> = ({ total }) => {
  const p = useIn(Math.round(total * 0.18), 26);
  return (
    <Panel
      style={{
        position: "absolute",
        left: pad,
        top: 520,
        width: 1010,
        height: 330,
        padding: "26px 30px",
        display: "flex",
        flexDirection: "column",
        ...riseIn(p, 24),
      }}
    >
      <div style={{ display: "flex", alignItems: "baseline", gap: 12 }}>
        <div style={{ fontFamily: FONT, fontSize: 23, fontWeight: 700, color: C.ink }}>
          Halaman pelanggan
        </div>
        <div style={{ fontFamily: FONT, fontSize: 20, fontWeight: 700, color: C.primary }}>11</div>
      </div>
      <div style={{ height: 14 }} />
      <div style={{ display: "flex", flexWrap: "wrap", gap: 8 }}>
        {PAGES_CUSTOMER.map((x) => (
          <Chip key={x} size={17} tone="pink" style={smallChip}>
            {x}
          </Chip>
        ))}
      </div>

      <div style={{ height: 16 }} />
      <div style={{ height: 1, background: C.line }} />
      <div style={{ height: 16 }} />

      <div style={{ display: "flex", alignItems: "baseline", gap: 12 }}>
        <div style={{ fontFamily: FONT, fontSize: 23, fontWeight: 700, color: C.ink }}>
          Halaman admin
        </div>
        <div style={{ fontFamily: FONT, fontSize: 20, fontWeight: 700, color: C.primary }}>4</div>
      </div>
      <div style={{ height: 14 }} />
      <div style={{ display: "flex", flexWrap: "wrap", gap: 8 }}>
        {PAGES_ADMIN.map((x) => (
          <Chip key={x} size={17} tone="slate" style={smallChip}>
            {x}
          </Chip>
        ))}
      </div>
    </Panel>
  );
};

const PriorityPanel: React.FC<{ total: number }> = ({ total }) => {
  const p = useIn(Math.round(total * 0.30), 26);
  return (
    <Panel
      style={{
        position: "absolute",
        left: 1136,
        top: 520,
        width: 688,
        height: 330,
        padding: "26px 30px",
        display: "flex",
        flexDirection: "column",
        ...riseIn(p, 24),
      }}
    >
      <div style={{ display: "flex", alignItems: "baseline", gap: 12 }}>
        <div style={{ fontFamily: FONT, fontSize: 23, fontWeight: 700, color: C.ink }}>
          Prioritas Must
        </div>
        <div style={{ fontFamily: FONT, fontSize: 20, fontWeight: 700, color: C.success }}>5</div>
      </div>
      <div style={{ height: 14 }} />
      <div style={{ display: "flex", flexWrap: "wrap", gap: 8 }}>
        {MUST.map((x) => (
          <Chip key={x} size={17} tone="green" style={smallChip}>
            ✓ {x}
          </Chip>
        ))}
      </div>

      <div style={{ height: 16 }} />
      <div style={{ height: 1, background: C.line }} />
      <div style={{ height: 16 }} />

      <div style={{ fontFamily: FONT, fontSize: 23, fontWeight: 700, color: C.ink }}>
        Sengaja tidak termasuk
      </div>
      <div style={{ height: 14 }} />
      <div style={{ display: "flex", flexWrap: "wrap", gap: 8 }}>
        {WONT.map((x) => (
          <Chip key={x} size={17} tone="slate" style={smallChip}>
            {x}
          </Chip>
        ))}
      </div>
    </Panel>
  );
};

const Note: React.FC<{ total: number }> = ({ total }) => {
  const p = useIn(Math.round(total * 0.9), 22);
  return (
    <div
      style={{
        position: "absolute",
        left: pad,
        top: 884,
        width: 1728,
        textAlign: "center",
        fontFamily: FONT,
        fontSize: 21,
        fontWeight: 500,
        color: C.inkMuted,
        ...riseIn(p, 14),
      }}
    >
      Seluruh data masih berupa data simulasi di memori — Firebase menyusul pada fase berikutnya.
    </div>
  );
};

export const Scope: React.FC<{ total: number }> = ({ total }) => (
  <SceneFrame total={total} kicker="Scope" title="15 halaman, 5 fitur Must">
    {SHOTS.map((s, i) => (
      <Shot
        key={s.src}
        src={s.src}
        label={s.label}
        delay={Math.round(total * (0.03 + i * 0.02))}
        index={i}
      />
    ))}
    <PagesPanel total={total} />
    <PriorityPanel total={total} />
    <Note total={total} />
    <Watermark index={4} count={5} label="Scope" />
  </SceneFrame>
);
