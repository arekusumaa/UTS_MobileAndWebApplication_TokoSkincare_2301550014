import React from "react";
import { AbsoluteFill, useCurrentFrame } from "remotion";
import { C, FONT } from "../theme";
import { envelope, popIn, riseIn, useIn } from "../anim";
import { Logo } from "../components/ui";

export const Opening: React.FC<{ total: number }> = ({ total }) => {
  const frame = useCurrentFrame();
  const env = envelope(frame, total, 14, 12);

  const pLogo = useIn(2, 26);
  const pTitle = useIn(16, 24);
  const pSub = useIn(26, 24);
  const pRule = useIn(38, 22);
  const pName = useIn(48, 22);
  const pMeta = useIn(58, 22);
  const pCourse = useIn(72, 22);

  return (
    <AbsoluteFill style={{ opacity: env }}>
      <AbsoluteFill
        style={{
          alignItems: "center",
          justifyContent: "center",
          flexDirection: "column",
          fontFamily: FONT,
          paddingBottom: 40,
        }}
      >
        <div style={popIn(pLogo, 0.8)}>
          <Logo size={140} />
        </div>

        <div style={{ height: 42 }} />

        <div
          style={{
            ...riseIn(pTitle, 22),
            fontSize: 96,
            fontWeight: 700,
            letterSpacing: -2.4,
            color: C.ink,
            lineHeight: 1.05,
          }}
        >
          SkinCare Store
        </div>

        <div style={{ height: 20 }} />

        <div
          style={{
            ...riseIn(pSub, 20),
            fontSize: 33,
            fontWeight: 400,
            color: C.inkSoft,
            letterSpacing: 0.2,
          }}
        >
          Toko skincare dengan rekomendasi berbasis profil kulit
        </div>

        <div style={{ height: 44 }} />

        <div
          style={{
            width: 148,
            height: 5,
            borderRadius: 3,
            background: C.primary,
            opacity: pRule,
            transform: `scaleX(${pRule})`,
          }}
        />

        <div style={{ height: 44 }} />

        <div
          style={{
            ...riseIn(pName, 18),
            fontSize: 36,
            fontWeight: 600,
            color: C.ink,
            letterSpacing: 0.2,
          }}
        >
          Are Kusuma Pratiwi
        </div>

        <div style={{ height: 12 }} />

        <div
          style={{
            ...riseIn(pMeta, 16),
            fontSize: 24,
            fontWeight: 400,
            color: C.inkMuted,
            letterSpacing: 0.6,
          }}
        >
          NIM 23.01.55.0014 &nbsp;·&nbsp; Kelas A1
        </div>

        <div style={{ height: 56 }} />

        <div
          style={{
            ...riseIn(pCourse, 14),
            fontSize: 20,
            fontWeight: 500,
            color: C.inkMuted,
            letterSpacing: 2.6,
            textTransform: "uppercase",
          }}
        >
          UTS · Mobile and Web Application Development
        </div>
      </AbsoluteFill>
    </AbsoluteFill>
  );
};
