import React from "react";
import { AbsoluteFill, useCurrentFrame } from "remotion";
import { C, FONT, pad, shadow } from "../theme";
import { envelope } from "../anim";

export const Background: React.FC = () => (
  <AbsoluteFill
    style={{
      background: `radial-gradient(1100px 620px at 12% -6%, #FFEDF3 0%, #FFF8FA 42%, #FFFFFF 100%)`,
    }}
  >
    <div
      style={{
        position: "absolute",
        right: -180,
        top: -140,
        width: 620,
        height: 620,
        borderRadius: "50%",
        background: "radial-gradient(circle, rgba(217,87,120,0.13) 0%, rgba(217,87,120,0) 68%)",
      }}
    />
    <div
      style={{
        position: "absolute",
        left: -220,
        bottom: -260,
        width: 700,
        height: 700,
        borderRadius: "50%",
        background: "radial-gradient(circle, rgba(217,87,120,0.09) 0%, rgba(217,87,120,0) 70%)",
      }}
    />
  </AbsoluteFill>
);

export const Logo: React.FC<{ size?: number }> = ({ size = 132 }) => (
  <div
    style={{
      width: size,
      height: size,
      borderRadius: size * 0.27,
      background: `linear-gradient(140deg, ${C.primary} 0%, ${C.primaryDark} 100%)`,
      display: "flex",
      alignItems: "center",
      justifyContent: "center",
      boxShadow: "0 20px 44px rgba(217,87,120,0.34)",
    }}
  >
    <svg width={size * 0.52} height={size * 0.52} viewBox="0 0 48 48" fill="none">
      <path
        d="M24 5c6.2 7.6 11.6 14.4 11.6 21.1A11.6 11.6 0 1 1 12.4 26C12.4 19.4 17.8 12.6 24 5Z"
        fill="white"
        fillOpacity="0.96"
      />
      <path
        d="M24 20.5c2.6 3.2 4.6 5.9 4.6 8.4a4.6 4.6 0 1 1-9.2 0c0-2.5 2-5.2 4.6-8.4Z"
        fill={C.primary}
        fillOpacity="0.9"
      />
    </svg>
  </div>
);

export const Kicker: React.FC<{ children: React.ReactNode; style?: React.CSSProperties }> = ({
  children,
  style,
}) => (
  <div
    style={{
      fontFamily: FONT,
      fontSize: 21,
      fontWeight: 700,
      letterSpacing: 3.4,
      textTransform: "uppercase",
      color: C.primary,
      ...style,
    }}
  >
    {children}
  </div>
);

export const Heading: React.FC<{ children: React.ReactNode; size?: number; style?: React.CSSProperties }> = ({
  children,
  size = 58,
  style,
}) => (
  <div
    style={{
      fontFamily: FONT,
      fontSize: size,
      fontWeight: 700,
      lineHeight: 1.14,
      letterSpacing: -0.8,
      color: C.ink,
      ...style,
    }}
  >
    {children}
  </div>
);

export const Panel: React.FC<{
  children: React.ReactNode;
  style?: React.CSSProperties;
}> = ({ children, style }) => (
  <div
    style={{
      background: C.white,
      border: `1px solid ${C.line}`,
      borderRadius: 22,
      boxShadow: shadow.card,
      ...style,
    }}
  >
    {children}
  </div>
);

export const Chip: React.FC<{
  children: React.ReactNode;
  tone?: "pink" | "slate" | "green" | "warn";
  size?: number;
  style?: React.CSSProperties;
}> = ({ children, tone = "pink", size = 22, style }) => {
  const map = {
    pink: { bg: C.tintStrong, fg: C.primaryDark, bd: "rgba(217,87,120,0.22)" },
    slate: { bg: C.slateBg, fg: C.slate, bd: "#E3E5E9" },
    green: { bg: C.successBg, fg: C.success, bd: "rgba(46,158,107,0.24)" },
    warn: { bg: C.warnBg, fg: C.warn, bd: "rgba(185,118,12,0.26)" },
  }[tone];
  return (
    <div
      style={{
        fontFamily: FONT,
        fontSize: size,
        fontWeight: 600,
        color: map.fg,
        background: map.bg,
        border: `1px solid ${map.bd}`,
        borderRadius: 999,
        padding: "9px 20px",
        whiteSpace: "nowrap",
        ...style,
      }}
    >
      {children}
    </div>
  );
};

/** Standard scene shell: envelope fade + header block. */
export const SceneFrame: React.FC<{
  total: number;
  kicker: string;
  title: string;
  children: React.ReactNode;
  titleWidth?: number;
}> = ({ total, kicker, title, children, titleWidth = 1180 }) => {
  const frame = useCurrentFrame();
  const env = envelope(frame, total);
  return (
    <AbsoluteFill style={{ opacity: env }}>
      <div
        style={{
          position: "absolute",
          left: pad,
          top: 74,
          width: titleWidth,
        }}
      >
        <Kicker>{kicker}</Kicker>
        <div style={{ height: 14 }} />
        <Heading>{title}</Heading>
      </div>
      {children}
    </AbsoluteFill>
  );
};

/** Bottom-left brand watermark + right slide number. */
export const Watermark: React.FC<{ index: number; count: number; label: string }> = ({
  index,
  count,
  label,
}) => (
  <>
    <div
      style={{
        position: "absolute",
        left: pad,
        bottom: 46,
        display: "flex",
        alignItems: "center",
        gap: 12,
        fontFamily: FONT,
        fontSize: 18,
        fontWeight: 600,
        color: C.inkMuted,
      }}
    >
      <div
        style={{
          width: 10,
          height: 10,
          borderRadius: 3,
          background: C.primary,
          opacity: 0.85,
        }}
      />
      SkinCare Store
    </div>
    <div
      style={{
        position: "absolute",
        right: pad,
        bottom: 46,
        display: "flex",
        alignItems: "center",
        gap: 10,
        fontFamily: FONT,
        fontSize: 18,
        fontWeight: 600,
        color: C.inkMuted,
        letterSpacing: 0.4,
      }}
    >
      {label}
      <span style={{ color: C.primary }}>
        {index}/{count}
      </span>
    </div>
  </>
);
