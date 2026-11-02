import { Easing, interpolate, useCurrentFrame } from "remotion";

/** 0 -> 1 progress starting at `delay` frames, easing out cubic. */
export function useIn(delay: number, dur = 22): number {
  const frame = useCurrentFrame();
  return interpolate(frame - delay, [0, dur], [0, 1], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
    easing: Easing.out(Easing.cubic),
  });
}

/** Rise + fade entry. */
export function riseIn(p: number, distance = 26) {
  return {
    opacity: p,
    transform: `translateY(${(1 - p) * distance}px)`,
  } as const;
}

/** Scale + fade entry (for logo / badges). */
export function popIn(p: number, from = 0.86) {
  return {
    opacity: p,
    transform: `scale(${from + (1 - from) * p})`,
  } as const;
}

/** Grow a bar from the left. */
export function growX(p: number) {
  return {
    transform: `scaleX(${p})`,
    transformOrigin: "left center",
  } as const;
}

/** Scene envelope: fade in at start, fade out at end. */
export function envelope(frame: number, total: number, inDur = 12, outDur = 14): number {
  const a = interpolate(frame, [0, inDur], [0, 1], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
  });
  const b = interpolate(frame, [total - outDur, total], [1, 0], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
  });
  return Math.min(a, b);
}

/** Fraction of the scene, 0..1. */
export function useProgress(total: number): number {
  const frame = useCurrentFrame();
  return total <= 0 ? 0 : Math.min(1, frame / total);
}
