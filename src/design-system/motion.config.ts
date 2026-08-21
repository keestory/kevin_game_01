export const HIT_FEEDBACK = {
  normal: {
    hitStopMs: 22,
    shakePx: 2,
    zoomPunch: 1,
    flashAlpha: 0,
    squashX: 0.82,
    squashY: 1.18,
  },
  heavy: {
    hitStopMs: 36,
    shakePx: 4,
    zoomPunch: 1.01,
    flashAlpha: 0.06,
    squashX: 0.78,
    squashY: 1.22,
  },
  critical: {
    hitStopMs: 48,
    shakePx: 7,
    zoomPunch: 1.02,
    flashAlpha: 0.1,
    squashX: 0.74,
    squashY: 1.26,
  },
  boss: {
    hitStopMs: 78,
    shakePx: 11,
    zoomPunch: 1.03,
    flashAlpha: 0.16,
    squashX: 0.7,
    squashY: 1.3,
  },
} as const;

export const ACCESSIBILITY_MULTIPLIERS = {
  reduceMotion: {
    shake: 0.3,
    zoomPunch: 0,
    trailLength: 0.5,
    parallax: 0.25,
    backgroundDrift: 0.4,
  },
  photosensitivitySafe: {
    fullScreenFlash: 0,
    electricPulse: 0.4,
    explosionCoreAlpha: 0.55,
    chromaticAberration: 0,
  },
} as const;

export const COMBO_STAGES = [
  { id: "base", min: 0, trailMultiplier: 1, impactMultiplier: 1 },
  { id: "heat", min: 10, trailMultiplier: 1.1, impactMultiplier: 1.05 },
  { id: "overdrive", min: 20, trailMultiplier: 1.18, impactMultiplier: 1.1 },
  { id: "frenzy", min: 50, trailMultiplier: 1.25, impactMultiplier: 1.15 },
] as const;
