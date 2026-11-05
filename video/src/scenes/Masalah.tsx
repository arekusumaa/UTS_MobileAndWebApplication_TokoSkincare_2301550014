import React from "react";
import { C, FONT, pad, shadow } from "../theme";
import { riseIn, useIn } from "../anim";
import { Panel, SceneFrame, Watermark } from "../components/ui";

type Problem = { no: string; title: string; desc: string; at: number };

const PROBLEMS: Problem[] = [
  {
    no: "01",
    title: "Kebingungan memilih produk",
    desc: "Ratusan produk dengan klaim yang saling bertentangan, tanpa panduan yang jelas.",
    at: 0.06,
  },
  {
    no: "02",
    title: "Tidak ada personalisasi",
    desc: "Katalog datar — tipe kulit, concern, dan alergi pembeli tidak dipertimbangkan.",
    at: 0.26,
  },
  {
    no: "03",
    title: "Tidak ada info PAO",
    desc: "Produk aktif seperti vitamin C dan retinol dipakai setelah efektivitasnya hilang.",
    at: 0.47,
  },
  {
    no: "04",
    title: "Risiko alergi",
    desc: "Tidak ada cara sistematis mencatat bahan yang memicu iritasi pada kulit.",
    at: 0.65,
  },
];

const CARD_W = 848;
const CARD_H = 196;
const GAP_X = 32;
const GAP_Y = 30;
const TOP = 292;

const ProblemCard: React.FC<{ p: Problem; total: number; col: number; row: number }> = ({
  p,
  total,
  col,
  row,
}) => {
  const prog = useIn(Math.round(total * p.at), 26);
  return (
    <Panel
      style={{
        position: "absolute",
        left: pad + col * (CARD_W + GAP_X),
        top: TOP + row * (CARD_H + GAP_Y),
        width: CARD_W,
        height: CARD_H,
        padding: "30px 34px",
        display: "flex",
        alignItems: "center",
        gap: 26,
        ...riseIn(prog, 34),
      }}
    >
      <div
        style={{
          width: 66,
          height: 66,
          flexShrink: 0,
          borderRadius: 18,
          background: C.tintStrong,
          border: "1px solid rgba(217,87,120,0.20)",
          display: "flex",
          alignItems: "center",
          justifyContent: "center",
          fontFamily: FONT,
          fontSize: 24,
          fontWeight: 700,
          color: C.primary,
          letterSpacing: 0.5,
        }}
      >
        {p.no}
      </div>
      <div style={{ display: "flex", flexDirection: "column", gap: 10 }}>
        <div
          style={{
            fontFamily: FONT,
            fontSize: 31,
            fontWeight: 700,
            color: C.ink,
            letterSpacing: -0.3,
            lineHeight: 1.2,
          }}
        >
          {p.title}
        </div>
        <div
          style={{
            fontFamily: FONT,
            fontSize: 22,
            fontWeight: 400,
            color: C.inkSoft,
            lineHeight: 1.42,
          }}
        >
          {p.desc}
        </div>
      </div>
    </Panel>
  );
};

const Callout: React.FC<{ total: number }> = ({ total }) => {
  const prog = useIn(Math.round(total * 0.85), 24);
  return (
    <div
      style={{
        position: "absolute",
        left: pad,
        top: 748,
        width: CARD_W * 2 + GAP_X,
        height: 104,
        borderRadius: 20,
        background: C.tint,
        border: "1px solid rgba(217,87,120,0.22)",
        boxShadow: shadow.soft,
        display: "flex",
        alignItems: "center",
        gap: 22,
        padding: "0 34px",
        ...riseIn(prog, 22),
      }}
    >
      <div
        style={{
          width: 44,
          height: 44,
          borderRadius: 22,
          background: C.primary,
          color: "#fff",
          display: "flex",
          alignItems: "center",
          justifyContent: "center",
          fontFamily: FONT,
          fontSize: 26,
          fontWeight: 700,
          flexShrink: 0,
        }}
      >
        !
      </div>
      <div
        style={{
          fontFamily: FONT,
          fontSize: 27,
          fontWeight: 600,
          color: C.primaryDark,
          lineHeight: 1.35,
        }}
      >
        Salah memilih skincare bukan hanya membuang uang — tetapi juga memicu jerawat dan iritasi.
      </div>
    </div>
  );
};

export const Masalah: React.FC<{ total: number }> = ({ total }) => (
  <SceneFrame total={total} kicker="Masalah" title="Empat masalah yang ingin diselesaikan">
    {PROBLEMS.map((p, i) => (
      <ProblemCard key={p.no} p={p} total={total} col={i % 2} row={Math.floor(i / 2)} />
    ))}
    <Callout total={total} />
    <Watermark index={2} count={6} label="Masalah" />
  </SceneFrame>
);
