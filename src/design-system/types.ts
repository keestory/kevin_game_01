export type ElementType =
  | "neutral"
  | "fire"
  | "electric"
  | "explosion"
  | "ice"
  | "arcane";

export type TrajectoryType = "none" | "piercing" | "homing";
export type MultiplierType = "none" | "multiball" | "damageBoost";
export type UtilityType = "laser" | "shield" | "slowTime";

export type EffectId =
  | "fire"
  | "electric"
  | "piercing"
  | "explosion"
  | "multiball"
  | "ice"
  | "homing"
  | "laser"
  | "shield"
  | "slowTime";

export type EffectSlot = "element" | "trajectory" | "multiplier" | "utility";
export type EffectQuality = "high" | "medium" | "low";

export interface AccessibilitySettings {
  reduceMotion: boolean;
  photosensitivitySafe: boolean;
  colorAssist: boolean;
  highContrastBall: boolean;
  aggregateDamageNumbers: boolean;
}

export interface PerformanceSettings {
  quality: EffectQuality;
  fpsCap: 30 | 60;
  backgroundMotion: boolean;
  autoQuality: boolean;
}

export interface EffectVisualConfig {
  mainColorToken: string;
  coreColorToken: string;
  icon: string;
  pattern: "flame" | "zigzag" | "spear" | "radial" | "orbital" | "crystal" | "target" | "beam" | "hex" | "clock";
  trailPreset: string;
  impactPreset: string;
  residuePreset?: string;
}

export interface EffectConfig {
  id: EffectId;
  displayName: string;
  slot: EffectSlot;
  durationMs?: number;
  maxStacks?: number;
  maxActive?: number;
  replacesSameSlot: boolean;
  visual: EffectVisualConfig;
  gameplay: Record<string, number | boolean | string>;
}

export interface ActiveEffect {
  id: EffectId;
  appliedAtMs: number;
  expiresAtMs?: number;
  stacks: number;
  charges?: number;
}

export interface BallState {
  id: string;
  x: number;
  y: number;
  velocityX: number;
  velocityY: number;
  radius: number;
  element: ElementType;
  trajectory: TrajectoryType;
  multiplier: MultiplierType;
  effects: ActiveEffect[];
}

export interface BrickState {
  id: string;
  x: number;
  y: number;
  width: number;
  height: number;
  hp: number;
  maxHp: number;
  tags: string[];
  statuses: ActiveEffect[];
}

export interface HitContext {
  nowMs: number;
  ballId: string;
  brickId: string;
  contactX: number;
  contactY: number;
  normalX: number;
  normalY: number;
  speed: number;
  combo: number;
}
