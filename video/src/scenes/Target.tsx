import React from "react";
import { C, FONT, pad, shadow } from "../theme";
import { popIn, riseIn, useIn } from "../anim";
import { Chip, Panel, SceneFrame, Watermark } from "../components/ui";

const ATTRS: { label: string; value: string }[] = [
  { label: "Tipe kulit", value: "Berminyak" },
  { label: "Concern", value: "Jerawat · Pori besar · Kusam" },
  { label: "Alergi", value: "Fragrance" },
  { label: "Budget", value: "Rp 50–100 rb / produk" },
  { label: "Perangkat", value: "Android + Chrome" },
  { label: "Perilaku", value: "Aktif belanja online" },
];

const LEFT_W = 700;
const RIGHT_X = pad + LEFT_W + 40;
const CELL_W = 478;
const CELL_H = 118;
const CELL_GAP = 32;
const ROW_GAP = 24;
const TOP = 300;

const PersonaCard: React.FC<{ total: number }> = ({ total }) => {
  const p = useIn(Math.round(total * 0.04), 26);
  return (
    <Panel
      style={{
        position: "absolute",
        left: pad,
        top: TOP,
        width: LEFT_W,
        height: CELL_H * 3 + ROW_GAP * 2,
        padding: "36px 38px",
        display: "flex",
        flexDirection: "column",
        ...riseIn(p, 30),
      }}
    >
      <div style={{ display: "flex", alignItems: "center", gap: 22 }}>
        <div
          style={{
            width: 92,
            height: 92,
            borderRadius: 46,
            background: `linear-gradient(140deg, ${C.primary} 0%, ${C.primaryDark} 100%)`,
            color: "#fff",
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
            fontFamily: FONT,
            fontSize: 32,
            fontWeight: 700,
            letterSpacing: 1,
            flexShrink: 0,
            ...popIn(p, 0.9),
          }}
        >
          RP
        </div>
        <div style={{ display: "flex", flexDirection: "column", gap: 8 }}>
          <div style={{ fontFamily: FONT, fontSize: 36, fontWeight: 700, color: C.ink, lineHeight: 1.1 }}>
            Rina Pratiwi
          </div>
          <div style={{ fontFamily: FONT, fontSize: 22, color: C.inkMuted, fontWeight: 400 }}>
            21 tahun · Mahasiswa semester 5
          </div>
        </div>
      </div>

      <div style={{ height: 26 }} />
      <div style={{ height: 1, background: C.line }} />
      <div style={{ height: 24 }} />

      <div style={{ display: "flex", gap: 10, flexWrap: "wrap" }}>
        <Chip size={18} tone="pink">
          Persona utama
        </Chip>
        <Chip size={18} tone="slate">
          Pengguna pelanggan
        </Chip>
      </div>

      <div style={{ height: 22 }} />

      <div
        style={{
          fontFamily: FONT,
          fontSize: 23,
          fontStyle: "italic",
          lineHeight: 1.5,
          color: C.inkSoft,
        }}
      >
        “Saya ingin tahu produk mana yang aman untuk kulit berminyak dan tidak memicu alergi saya.”
      </div>
    </Panel>
  );
};

const AttrCell: React.FC<{
  label: string;
  value: string;
  delay: number;
  left: number;
  top: number;
}> = ({ label, value, delay, left, top }) => {
  const p = useIn(delay, 22);
  return (
    <div
      style={{
        position: "absolute",
        left,
        top,
        width: CELL_W,
        height: CELL_H,
        borderRadius: 18,
        background: C.white,
        border: `1px solid ${C.line}`,
        boxShadow: shadow.soft,
        padding: "22px 26px",
        display: "flex",
        flexDirection: "column",
        justifyContent: "center",
        gap: 9,
        ...riseIn(p, 20),
      }}
    >
      <div
        style={{
          fontFamily: FONT,
          fontSize: 17,
          fontWeight: 700,
          letterSpacing: 2,
          textTransform: "uppercase",
          color: C.primary,
        }}
      >
        {label}
      </div>
      <div
        style={{
          fontFamily: FONT,
          fontSize: 25,
          fontWeight: 600,
          color: C.ink,
          lineHeight: 1.28,
        }}
      >
        {value}
      </div>
    </div>
  );
};

const AdminCard: React.FC<{ total: number }> = ({ total }) => {
  const p = useIn(Math.round(total * 0.62), 24);
  return (
    <div
      style={{
        position: "absolute",
        left: pad,
        top: 770,
        width: 1728,
        height: 108,
        borderRadius: 20,
        background: C.tint,
        border: "1px solid rgba(217,87,120,0.20)",
        display: "flex",
        alignItems: "center",
        gap: 24,
        padding: "0 34px",
        ...riseIn(p, 22),
      }}
    >
      <Chip size={19} tone="pink">
        Persona sekunder
      </Chip>
      <div style={{ fontFamily: FONT, fontSize: 28, fontWeight: 700, color: C.ink }}>
        Admin Toko
      </div>
      <div style={{ width: 1, height: 34, background: C.line }} />
      <div style={{ fontFamily: FONT, fontSize: 23, color: C.inkSoft, fontWeight: 400 }}>
        Mengelola katalog produk, memantau stok, dan memperbarui status pesanan masuk.
      </div>
    </div>
  );
};

export const Target: React.FC<{ total: number }> = ({ total }) => (
  <SceneFrame total={total} kicker="Target pengguna" title="Siapa yang memakai aplikasi ini">
    <PersonaCard total={total} />
    {ATTRS.map((a, i) => (
      <AttrCell
        key={a.label}
        label={a.label}
        value={a.value}
        delay={Math.round(total * (0.12 + i * 0.055))}
        left={RIGHT_X + (i % 2) * (CELL_W + CELL_GAP)}
        top={TOP + Math.floor(i / 2) * (CELL_H + ROW_GAP)}
      />
    ))}
    <AdminCard total={total} />
    <Watermark index={3} count={6} label="Target" />
  </SceneFrame>
);
