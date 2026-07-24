# ArkUI State Integration

## Selection

Use the state management generation already established by the target feature. When no local state-management evidence exists, default to V2. Do not pause only to ask the user to choose a generation. If later project evidence proves V2 unavailable, switch to the supported V1 model. API level is evidence for decorator availability, not a minimum requirement for MVI.

Do not mix V1 and V2 decorators on one observation path. In either generation, ArkUI decorators decide how a View observes a field, while `reduce` remains the only boundary allowed to change MVI State.

## V1 Pattern

Use an `@Observed` UI State class. When the target project supports `@Track`, mark every field read by the UI so updates stay property-specific:

```ts
@Observed
class FeatureUiState {
  @Track value: string = ''
  @Track isPending: boolean = false
  revision: number = 0
}
```

An `@Observed` object must enter the V1 observation chain. The owning View keeps the exact object held by ViewModel in `@State`; a child component receives that object through `@ObjectLink`:

```ts
@Entry
@Component
struct FeatureView {
  private readonly viewModel: FeatureViewModel = new FeatureViewModel()
  @State private ui: FeatureUiState = this.viewModel.ui as FeatureUiState

  build() {
    Text(this.ui.value)
  }
}
```

The type assertion bridges the ViewModel's read-only public type to the decorator. It does not authorize the View to assign fields. State changes still originate in an Intent-returned `reduce`.

V1 rules:

- Keep the State root, `ui`, and every observed nested object stable; do not replace them wholesale.
- If any class field uses `@Track`, every field from that class that the UI reads must use `@Track`.
- `@Track` observes one property level. Give nested objects their own supported observation path when their inner fields drive UI.
- If the target does not support `@Track`, remove every `@Track` decorator from that UI State class and use `@Observed` plus the owning `@State` or child `@ObjectLink`. Never leave a partially tracked class. Verify every UI-driving field with the real build and runtime behavior.
- Do not wrap a V1 object with V2 decorators or expose a copied UI object to the View.

## V2 Pattern

Use `@ObservedV2` on the UI State class and `@Trace` on every field read by the View:

```ts
@ObservedV2
class FeatureUiState {
  @Trace value: string = ''
  @Trace isPending: boolean = false
  revision: number = 0
}
```

Create `@ObservedV2` instances with `new`. A V2 View reads the stable `viewModel.ui` reference directly and must not wrap it with V1 `@State`, `@Observed`, or `@ObjectLink`.

V2 rules:

- Add `@Trace` only to fields that drive UI.
- Give nested classes `@ObservedV2` and their UI-driving fields `@Trace` when deep observation is required.
- Use supported collection mutation APIs when the View depends on an in-place collection change.
- Do not copy or replace the object held by ViewModel.

## MVI Integration Boundary

Both generations use the same Plan:

```ts
return [MVI.reduce<FeatureState>({
  ui: {
    value: '',
    revision: (current: number): number => current + 1
  }
})]
```

Use a field updater for an atomic transformation that depends on the current value. Pass the target value directly when it is already known. Platform observability never authorizes a View, Effect, callback, or ViewModel helper to mutate MVI State outside `reduce`.

## Refresh Diagnosis

Check in this order:

1. Confirm whether the target feature uses V1 or V2 and whether every selected decorator is supported by that project.
2. Confirm the UI State class and UI-driving fields use one matching decorator generation.
3. For V1, confirm the owning View holds the same object in `@State`, or the child receives it through `@ObjectLink`.
4. For V2, confirm the View reads the same `viewModel.ui` object rather than a copy.
5. Confirm `MVI.reduce` targets the correct layer and field without replacing the layer object.
6. Confirm nested-object and collection mutations use APIs observable by the selected generation.
7. Run the real target build and reproduce the field update in the target View.
