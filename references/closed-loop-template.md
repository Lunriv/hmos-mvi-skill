# Closed-Loop Structure Template

Use this template only for new initialization without a local precedent. `Feature` is a structural marker to replace, not a business name. Derive the real name from the target project or user input before generation. When an existing feature already defines naming, directories, or encapsulation, preserve that implementation rather than copying this template.

The example uses only technical fields such as `input`, `value`, `sequence`, `error`, and `isPending`. It does not supply business names for pages, data, services, copy, or interactions.

## File Boundaries

```text
feature/
  port/FeaturePort.ets
  state/FeatureState.ets
  intent/FeatureResultIntent.ets
  effect/InvokeFeaturePortEffect.ets
  intent/FeatureInputIntent.ets
  viewmodel/FeatureViewModel.ets
  view/FeatureView.ets
```

The result Intent has its own file so the Effect can return it without creating mutual imports between the input Intent and Effect. Preserve a target project's organization when it avoids that issue differently or already has another established structure.

## Port

`port/FeaturePort.ets`

```ts
export interface FeaturePort {
  invoke(input: string): Promise<string>
}

export class DefaultFeaturePort implements FeaturePort {
  public invoke(input: string): Promise<string> {
    return Promise.resolve(input)
  }
}
```

The default implementation provides only an executable async identity operation. Replace it with the target project's low-level capability for a real feature; do not infer a capability name from this example.

## State

`state/FeatureState.ets`

Choose exactly one UI State declaration. Preserve the feature's existing generation; when no local precedent exists, default to V2. Use V1 when the target feature already establishes it or later project evidence proves V2 unavailable.

### V2 State

```ts
@ObservedV2
export class FeatureUiState {
  @Trace value: string = ''
  @Trace error: string = ''
  @Trace isPending: boolean = false
}
```

### V1 State

```ts
@Observed
export class FeatureUiState {
  @Track value: string = ''
  @Track error: string = ''
  @Track isPending: boolean = false
}
```

When the target V1 project does not support `@Track`, remove all three `@Track` decorators and rely on the `@Observed` class entering the owning View's `@State` or a child View's `@ObjectLink`. Verify each UI-driving field. Do not replace V1 with V2 solely to reuse this template.

The remaining layers are shared by both generations:

```ts
import { MVI } from '../../core/MVI'
import { DefaultFeaturePort, FeaturePort } from '../port/FeaturePort'

export class FeatureDomainState {
  readonly port: FeaturePort = new DefaultFeaturePort()
}

export class FeatureRuntimeState {
  sequence: number = 0
}

export class FeatureState extends MVI.State<FeatureUiState, FeatureDomainState, FeatureRuntimeState> {
  public constructor() {
    super(FeatureUiState, FeatureDomainState, FeatureRuntimeState)
  }
}
```

`@Track` and `@Trace` are ArkUI field-observation decorators. Neither enables MVI chain tracing. Never generate MVI Trace infrastructure without an explicit user request.

## Result Intent

`intent/FeatureResultIntent.ets`

```ts
import { MVI } from '../../core/MVI'
import { FeatureState } from '../state/FeatureState'

export class FeatureResultIntent extends MVI.Intent<FeatureState> {
  private readonly sequence: number
  private readonly value: string
  private readonly error: string

  public constructor(sequence: number, value: string, error: string) {
    super()
    this.sequence = sequence
    this.value = value
    this.error = error
  }

  public handle(state: MVI.ReadonlyState<FeatureState>): MVI.Plan<FeatureState> {
    if (state.runtime.sequence !== this.sequence) {
      return []
    }
    return [MVI.reduce<FeatureState>({
      ui: {
        value: this.error.length === 0 ? this.value : state.ui.value,
        error: this.error,
        isPending: false
      }
    })]
  }
}
```

The sequence check rejects a stale async result. It only decides whether the result may enter State; it does not cancel the low-level call.

## Effect

`effect/InvokeFeaturePortEffect.ets`

```ts
import { MVI } from '../../core/MVI'
import { FeatureResultIntent } from '../intent/FeatureResultIntent'
import { FeaturePort } from '../port/FeaturePort'
import { FeatureState } from '../state/FeatureState'

export class InvokeFeaturePortEffect extends MVI.Effect<FeatureState> {
  private readonly port: FeaturePort
  private readonly input: string
  private readonly sequence: number

  public constructor(port: FeaturePort, input: string, sequence: number) {
    super()
    this.port = port
    this.input = input
    this.sequence = sequence
  }

  public async execute(): Promise<MVI.Intent<FeatureState>> {
    try {
      const value = await this.port.invoke(this.input)
      return new FeatureResultIntent(this.sequence, value, '')
    } catch (error) {
      return new FeatureResultIntent(this.sequence, '', `${error}`)
    }
  }
}
```

The Effect only calls the Port and packages the raw result. It does not read State, dispatch, or decide whether the result remains valid.

## Input Intent

`intent/FeatureInputIntent.ets`

```ts
import { MVI } from '../../core/MVI'
import { InvokeFeaturePortEffect } from '../effect/InvokeFeaturePortEffect'
import { FeatureState } from '../state/FeatureState'

export class FeatureInputIntent extends MVI.Intent<FeatureState> {
  private readonly input: string

  public constructor(input: string) {
    super()
    this.input = input
  }

  public handle(state: MVI.ReadonlyState<FeatureState>): MVI.Plan<FeatureState> {
    const sequence = state.runtime.sequence + 1
    return [
      MVI.reduce<FeatureState>({
        ui: { error: '', isPending: true },
        runtime: { sequence: sequence }
      }),
      MVI.fork<FeatureState>(new InvokeFeaturePortEffect(state.domain.port, this.input, sequence))
    ]
  }
}
```

The input Intent is the only place that reads current State, creates the next sequence, and selects the `reduce + fork` Plan.

## ViewModel

`viewmodel/FeatureViewModel.ets`

```ts
import { MVI } from '../../core/MVI'
import { FeatureState } from '../state/FeatureState'

export class FeatureViewModel extends MVI.ViewModel<FeatureState> {
  public constructor() {
    super(FeatureState)
  }
}
```

The ViewModel reuses public `dispatch` and does not add View input methods that only forward an Intent.

## View

`view/FeatureView.ets`

### V2 View

```ts
import { FeatureInputIntent } from '../intent/FeatureInputIntent'
import { FeatureViewModel } from '../viewmodel/FeatureViewModel'

@Entry
@ComponentV2
struct FeatureView {
  private readonly viewModel: FeatureViewModel = new FeatureViewModel()

  build() {
    Column() {
      TextInput()
        .onChange((input: string): void => {
          this.viewModel.dispatch(new FeatureInputIntent(input))
        })
      if (this.viewModel.ui.isPending) {
        LoadingProgress()
      }
      Text(this.viewModel.ui.value)
      Text(this.viewModel.ui.error)
    }
  }
}
```

### V1 View

```ts
import { FeatureInputIntent } from '../intent/FeatureInputIntent'
import { FeatureUiState } from '../state/FeatureState'
import { FeatureViewModel } from '../viewmodel/FeatureViewModel'

@Entry
@Component
struct FeatureView {
  private readonly viewModel: FeatureViewModel = new FeatureViewModel()
  @State private ui: FeatureUiState = this.viewModel.ui as FeatureUiState

  build() {
    Column() {
      TextInput()
        .onChange((input: string): void => {
          this.viewModel.dispatch(new FeatureInputIntent(input))
        })
      if (this.ui.isPending) {
        LoadingProgress()
      }
      Text(this.ui.value)
      Text(this.ui.error)
    }
  }
}
```

Both Views observe the same `ui` object owned by ViewModel, understand the concrete Intent, and dispatch it directly. The V1 View must treat its `@State` reference as read-only; the type assertion only connects the object to V1 observation. Add a synchronous gate before dispatch when high-frequency input cannot queue; stale-result filtering alone is not sufficient.

## Complete Data Flow

```text
FeatureView.dispatch
  -> FeatureInputIntent.handle
  -> reduce(isPending, error, sequence) + fork(InvokeFeaturePortEffect)
  -> InvokeFeaturePortEffect.execute
  -> FeatureResultIntent.handle
  -> sequence freshness check
  -> reduce(value, error, isPending)
  -> the selected V1 or V2 observation path refreshes FeatureView from the stable ui object
```

Preserve the responsibility boundaries and complete loop during generation, but derive every `Feature` marker, directory level, import path, field type, and low-level implementation from the target scope.
