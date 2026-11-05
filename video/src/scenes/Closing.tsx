import React from "react";
import { C, FONT, pad, shadow } from "../theme";
import { riseIn, useIn } from "../anim";
import { Chip, SceneFrame, Watermark } from "../components/ui";

const TECH = ["Flutter", "Dart", "Provider", "GoRouter", "Cloud Firestore"];

const COLLECTIONS: { code: string; name: string; fields: string[] }[] = [
  { code: "US", name: "users", fields: ["uid", "nama", "email", "role"] },
  { code: "PR", name: "products", fields: ["nama", "harga", "stok", "kandunganAktif"] },
  { code: "SK", name: "skin_profiles", fields: ["userId", "tipeKulit", "concern", "alergi"] },
  { code: "OR", name: "orders", fields: ["userId", "items[]", "total", "status"] },
  { code: "CA", name: "carts", fields: ["userId", "items[]", "updatedAt"] },
];

const CARD_W = 326;
const CARD_H = 212;
const CARD_GAP = 24;
const CARD_TOP = 372;

const TechRow: React.FC<{ total: number }> = ({ total }) => {
  const p = useIn(Math.round(total * 0.05), 22);
  return (
    <div
      style={{
        position: "absolute",
        left: pad,
        top: 276,
        display: "flex",
        gap: 10,
        ...riseIn(p, 18),
      }}
    >
      {TECH.map((t) => (
        <Chip key={t} size={19} tone="pink">
          {t}
        </Chip>
      ))}
    </div>
  );
};

const CollectionCard: React.FC<{
  code: string;
  name: string;
  fields: string[];
  delay: number;
  index: number;
}> = ({ code, name, fields, delay, index }) => {
  const p = useIn(delay, 24);
  return (
    <div
      style={{
        position: "absolute",
        left: pad + index * (CARD_W + CARD_GAP),
        top: CARD_TOP,
        width: CARD_W,
        height: CARD_H,
        borderRadius: 18,
        background: C.white,
        border: `1px solid ${C.line}`,
        boxShadow: shadow.card,
        padding: "24px 24px",
        display: "flex",
        flexDirection: "column",
        ...riseIn(p, 26),
      }}
    >
      <div style={{ display: "flex", alignItems: "center", gap: 12 }}>
        <div
          style={{
            width: 40,
            height: 40,
            borderRadius: 11,
            background: C.tintStrong,
            color: C.primary,
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
            fontFamily: FONT,
            fontSize: 15,
            fontWeight: 700,
            letterSpacing: 0.6,
            flexShrink: 0,
          }}
        >
          {code}
        </div>
        <div
          style={{
            fontFamily: "Consolas, 'Courier New', monospace",
            fontSize: 20,
            fontWeight: 700,
            color: C.ink,
            letterSpacing: -0.2,
          }}
        >
          {name}
        </div>
      </div>

      <div style={{ height: 16 }} />
      <div style={{ height: 1, background: C.line }} />
      <div style={{ height: 14 }} />

      <div style={{ display: "flex", flexDirection: "column", gap: 7 }}>
        {fields.map((f) => (
          <div
            key={f}
            style={{
              fontFamily: "Consolas, 'Courier New', monospace",
              fontSize: 16,
              color: C.inkSoft,
              fontWeight: 400,
            }}
          >
            · {f}
          </div>
        ))}
      </div>
    </div>
  );
};

const Thanks: React.FC<{ total: number }> = ({ total }) => {
  const p = useIn(Math.round(total * 0.5), 26);
  return (
    <div
      style={{
        position: "absolute",
        left: pad,
        top: 700,
        width: 1728,
        display: "flex",
        flexDirection: "column",
        alignItems: "center",
        ...riseIn(p, 20),
      }}
    >
      <div style={{ width: 148, height: 5, borderRadius: 3, background: C.primary, opacity: 0.9 }} />
      <div style={{ height: 26 }} />
      <div
        style={{
          fontFamily: FONT,
          fontSize: 68,
          fontWeight: 700,
          color: C.ink,
          letterSpacing: -1.4,
          lineHeight: 1.1,
        }}
      >
        Terima kasih
      </div>
      <div style={{ height: 16 }} />
      <div style={{ fontFamily: FONT, fontSize: 23, color: C.inkMuted, fontWeight: 400 }}>
        Are Kusuma Pratiwi &nbsp;·&nbsp; NIM 23.01.55.0014 &nbsp;·&nbsp; Kelas A1
      </div>
    </div>
  );
};

export const Closing: React.FC<{ total: number }> = ({ total }) => (
  <SceneFrame total={total} kicker="Rencana teknis" title="Bagaimana data akan disimpan">
    <TechRow total={total} />
    {COLLECTIONS.map((c, i) => (
      <CollectionCard
        key={c.name}
        code={c.code}
        name={c.name}
        fields={c.fields}
        delay={Math.round(total * (0.18 + i * 0.07))}
        index={i}
      />
    ))}
    <Thanks total={total} />
    <Watermark index={6} count={6} label="Penutup" />
  </SceneFrame>
);
