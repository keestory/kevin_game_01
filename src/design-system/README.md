# Design System Source Adapter

이 폴더는 문서의 규칙을 게임 런타임으로 연결하는 최소 타입과 설정이다.

## 권장 사용 방식

```ts
import tokens from "../../tokens/design-tokens.json";
import { EFFECTS } from "./effects.config";

const fire = EFFECTS.fire;
const fireColor = resolveToken(tokens, fire.visual.mainColorToken);
```

`resolveToken`은 dot path를 안전하게 조회하고, 없는 토큰이면 개발 환경에서 즉시 오류를 발생시켜야 한다.

## 권장 모듈

```text
src/
├── game/
│   ├── state/
│   ├── physics/
│   ├── effects/
│   ├── powerups/
│   ├── feedback/
│   └── audio/
├── ui/
│   ├── hud/
│   ├── gallery/
│   └── settings/
└── design-system/
```

## 레지스트리 예시

```ts
interface EffectBehavior {
  onApply(context: ApplyContext): void;
  onHit(context: HitContext): void;
  onUpdate(context: UpdateContext): void;
  onRemove(context: RemoveContext): void;
}

const registry = new Map<EffectId, EffectBehavior>();
```

렌더러와 게임 규칙을 분리해 Low FX에서도 게임플레이 결과가 같게 유지한다.
