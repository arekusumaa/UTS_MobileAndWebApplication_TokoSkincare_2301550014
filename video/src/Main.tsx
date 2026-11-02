import React from "react";
import { AbsoluteFill, Audio, Sequence, staticFile, useCurrentFrame } from "remotion";
import { C } from "./theme";
import { SCENES, TOTAL_FRAMES } from "./durations";
import { Background } from "./components/ui";
import { Opening } from "./scenes/Opening";
import { Masalah } from "./scenes/Masalah";
import { Target } from "./scenes/Target";
import { Scope } from "./scenes/Scope";
import { Closing } from "./scenes/Closing";

const STARTS: number[] = [];
{
  let acc = 0;
  for (const s of SCENES) {
    STARTS.push(acc);
    acc += s.frames;
  }
}

const renderScene = (id: string, total: number) => {
  switch (id) {
    case "scene1-opening":
      return <Opening total={total} />;
    case "scene2-masalah":
      return <Masalah total={total} />;
    case "scene3-target":
      return <Target total={total} />;
    case "scene4-scope":
      return <Scope total={total} />;
    case "scene5-closing":
      return <Closing total={total} />;
    default:
      return null;
  }
};

const ProgressBar: React.FC = () => {
  const frame = useCurrentFrame();
  const pct = Math.min(1, frame / Math.max(1, TOTAL_FRAMES - 1));
  return (
    <div
      style={{
        position: "absolute",
        left: 0,
        bottom: 0,
        width: "100%",
        height: 6,
        background: "rgba(217,87,120,0.12)",
      }}
    >
      <div
        style={{
          height: "100%",
          width: `${pct * 100}%`,
          background: C.primary,
        }}
      />
    </div>
  );
};

export const UTSExplainer: React.FC = () => (
  <AbsoluteFill style={{ backgroundColor: "#FFFFFF" }}>
    <Background />

    {SCENES.map((s, i) => (
      <Sequence
        key={s.id}
        from={STARTS[i]}
        durationInFrames={s.frames}
        name={s.id}
        layout="none"
      >
        <Audio src={staticFile(`audio/${s.file}`)} />
        {renderScene(s.id, s.frames)}
      </Sequence>
    ))}

    <ProgressBar />
  </AbsoluteFill>
);
