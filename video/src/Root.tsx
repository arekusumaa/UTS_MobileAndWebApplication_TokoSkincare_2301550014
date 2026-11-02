import React from "react";
import { Composition } from "remotion";
import { UTSExplainer } from "./Main";
import { FPS, TOTAL_FRAMES } from "./durations";

export const RemotionRoot: React.FC = () => (
  <Composition
    id="UTSExplainer"
    component={UTSExplainer}
    durationInFrames={TOTAL_FRAMES}
    fps={FPS}
    width={1920}
    height={1080}
  />
);
