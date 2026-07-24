---
name: hmos-mvi
description: Use when Codex needs to add, extend, or fix HarmonyOS ArkTS MVI features, especially for complete Intent/Plan/Effect feedback, async ordering, stale-result races, or UI refresh failures across ArkUI state management generations.
---

# HarmonyOS MVI

## Core Principle

Always work as one HMOS MVI expert: use MVI knowledge to complete the current goal while respecting existing implementation choices that do not prevent correctness. Intent reads State and returns a Plan; the dispatcher interprets the Plan; Effect performs one low-level action; State changes only through field-level `reduce` steps.

## Unified Expert Decision Chain

1. Establish the current goal and authorized scope, then read the target feature, adjacent implementations, existing Core, and project conventions.
2. Use MVI expertise to produce the smallest correct solution for the goal. The current task takes priority over an ideal architecture.
3. A difference is not automatically a conflict. Preserve naming, directories, namespaces, dependency injection, and View/ViewModel interaction patterns when they do not prevent a correct result. Do not ask or correct them merely because they differ from the expert default.
4. When initialization has no local precedent, apply this skill's expert defaults and fully design State, Intent, Effect, feedback, lifecycle, and tests.
5. When fixing a bug or changing an existing feature, modify only the chain required by the goal. Do not use the task to migrate architecture, split files, normalize naming, or rewrite unrelated MVI code.
6. Ask only when the goal cannot be completed correctly within existing conventions. Explain the current implementation, obstacle, options, behavioral differences, and affected scope, then wait for the user's choice.
7. Report MVI risks outside the current scope without expanding the changes.

## Workflow

```text
MVI implementation progress:
- [ ] Read the target feature, MVI directories, module exports, and any clear V1 or V2 precedent; default to V2 when none exists
- [ ] Identify existing Core semantics; install the fixed Core without MVI Trace only when required and absent
- [ ] Derive State / Intent / Effect / ViewModel file names from the target module
- [ ] List inputs, State, Intent, Plan, Effect, feedback, and cleanup
- [ ] Implement the complete loop
- [ ] Check responsibilities, async ordering, and stale-result filtering
- [ ] Run relevant available validation and report any unverified build or runtime risk
```

### 1. Read Project Facts

Read available root and target-module configuration, module exports, adjacent ArkTS implementations, and adjacent MVI feature directories. Use the target feature's established state management generation when it is clear. Preserve V1 `@Observed` + `@Track` or V2 `@ObservedV2` + `@Trace` when either already has a local feature precedent. When no local state-management evidence exists, default to V2. Do not pause only to ask which generation to use, and do not impose a universal API-level floor. If later project evidence proves V2 unavailable, switch to the supported V1 observation model.

Available project build or test commands improve verification but are not required to implement the MVI flow. Their absence must not stop implementation; report the missing validation coverage at completion.

Search for an existing `MVI.ts` and understand its `reduce/side/fork/chain` dispatch semantics. If the current task does not require a Core change, do not stop, replace it, or demand migration merely because it differs from the fixed Core. Use the existing contract to complete the goal. Ask only when existing Core semantics prevent a correct result. Install the fixed Core only when the goal requires a compatible Core and none exists; never splice fixed assets into a different kernel.

### 2. Read References as Needed

- For framework, responsibility, or dispatch boundaries, read [references/architecture-contract.md](references/architecture-contract.md) completely.
- For State design, state-management selection, or UI refresh failures, read [references/arkui-state.md](references/arkui-state.md) completely.
- For Promises, callbacks, listeners, concurrency, or high-frequency input, read [references/async-flow.md](references/async-flow.md) completely.
- For a feature built from scratch, read [references/closed-loop-template.md](references/closed-loop-template.md) completely.
- Only when the user explicitly requests MVI Trace, chain recording, debug replay, or flow visualization, read [references/trace-extension.md](references/trace-extension.md) completely.

### 3. Install the Fixed Core Only When Needed

Install only when the current goal requires a Core and the project does not provide one. Treat the directory containing this `SKILL.md` as `skill_root`, assign the confirmed target MVI directory to `target_mvi_dir`, and run a dry run first:

```bash
"$skill_root/scripts/install_hmos_mvi.sh" --dry-run "$target_mvi_dir"
"$skill_root/scripts/install_hmos_mvi.sh" "$target_mvi_dir"
```

The script installs only the dispatcher under `core/` and does not include MVI Trace. Without explicit user authorization, never declare, install, import, or register any MVI Trace capability.

### 4. Define the Loop and Required Files Before Coding

When the target scope has no MVI precedent, or the user explicitly requests reinitialization, use this expert default structure. Derive `<Feature>` from the existing business name of the target page or module:

```text
<feature>/
  state/<Feature>State.ets
  intent/<Feature>Intent.ets
  effect/<Feature>Effect.ets
  viewmodel/<Feature>ViewModel.ets
  view/<Feature>View.ets
```

- For new initialization, declare the concrete `<Feature>State` and its `UI/Domain/Runtime` layers in `state/<Feature>State.ets`.
- For new initialization, declare concrete action classes such as `<Action>Intent` in `intent/<Feature>Intent.ets`. A single Intent file may use namespaces when supported by the local feature style.
- For new initialization, declare concrete low-level action classes such as `<Operation>Effect` in `effect/<Feature>Effect.ets`.
- Without a local precedent, new initialization must not degrade to `Mvi.ets`, `Model.ets`, `VM.ets`, or a generic `State.ets`.
- For an existing feature, preserve its naming and file organization. Do not rename, move, or split files merely because they differ from this default.
- Ask when a new initialization has no known business name, or when an existing feature has multiple naming precedents with no clear priority.

### File Semantic Ownership

Before writing a file, use its path, name, existing declarations, module exports, and adjacent implementations to state its semantic promise in one sentence. Every added or modified declaration and code block must directly serve that responsibility. If it does not belong, place it in an existing semantically matching file or create a file named for its real responsibility.

Do not violate file semantics to reduce file count, shorten import paths, or reuse code. Do not impose a universal file suffix, directory, namespace, or declaration-type matrix. Determine ownership from target-project evidence and the current feature semantics.

For new initialization and new files, review every declaration file by file. In existing projects, do not clean up historical mixing; constrain only declarations added or modified by the current task. If multiple reasonable interpretations of an existing boundary would change the feature implementation, follow the unified expert decision chain and ask.

After implementation, the newly generated feature directory may receive a read-only audit:

```bash
"$skill_root/scripts/audit_hmos_mvi_layout.sh" "$generated_feature_dir"
```

The script reports suggestions only. It does not modify files, scan other module directories, or gate builds for existing projects.

Before coding, answer at least the following questions:

| Area | Required decision |
| --- | --- |
| Input | Does it originate in the View, lifecycle, or an external callback? Can it be frequent or repeated? |
| State | Does the target feature establish V1? Otherwise use V2. What belongs in `ui/domain/runtime`? Which UI fields require `@Track` or `@Trace`? |
| Intent | Which State fields does it read, what decisions does it make, and which Plan branches can it return? |
| Effect | Which single low-level action does it perform, and which raw result Intent can it return? |
| Feedback | Should the result use `side`, `fork`, or `chain`, and why? |
| Async | Does the flow require a token/sequence, `MVIDeferred`, `MVIBridge`, or an entry gate? |
| Cleanup | When are listeners, bridges, controllers, or other lifecycle resources disconnected? |

### 5. Implement and Verify

In the default initialization, keep inherited `ViewModel.dispatch` public. The View reads stable `viewModel.ui` and directly dispatches a concrete Intent. The ViewModel holds only State, dependencies, and lifecycle resources; do not add View input methods that merely forward to `dispatch`. The ViewModel may dispatch Intents produced by lifecycle events or external callbacks.

For an existing feature, preserve its View/ViewModel dispatch convention when it does not prevent a correct result. Ask through the unified expert decision chain only when correctness requires changing that interaction contract.

Intent synchronously returns a Plan. Every new Effect extends `MVI.Effect` and implements `execute()`; the calling Step determines whether execution is awaited.

Run fixed-asset verification and fixed-Core behavior tests only when this task installs or uses the fixed Core:

```bash
"$skill_root/scripts/verify_hmos_mvi.sh" "$target_mvi_dir"
"$skill_root/scripts/test_mvi_core_behavior.sh"
```

When using an existing Core, run the project's corresponding tests when available instead of validating it against fixed assets. Run any relevant project validation command that can be discovered or was supplied by the user. When none is available, complete the skill audits and report that project compilation and runtime behavior remain unverified. Asset verification proves fixed files are intact; it does not prove feature semantics or ArkTS compilation.

## Invariants

These constraints apply to the chain added or modified by the current task. They do not authorize cleanup of historical code outside the scope:

- Keep the State root and its `ui/domain/runtime` layer objects stable for the ViewModel lifetime; never replace them wholesale.
- Match the target project's native observation model. In V1, use an `@Observed` UI class, mark every UI-read field with `@Track` when supported, and keep the same object in the owning View's `@State` or a child View's `@ObjectLink`. In V2, use an `@ObservedV2` UI class and mark every UI-read field with `@Trace`. Do not mix V1 and V2 decorators on the same observation path.
- Route every MVI State change through `reduce`. Platform observability does not authorize bypassing the Plan.
- Intent is the only place that reads current State, makes business decisions, and composes Plan branches. Keep `handle` synchronous.
- Intent must not directly invoke another Intent's `handle`; use an Effect-returned Intent for feedback.
- Effect must not read or write MVI State, hold a ViewModel, dispatch directly, or make business decisions. Name it for the low-level action, not a phase, result, or wait mode.
- Effect must implement `execute()`; Core provides no empty default implementation.
- `side` does not wait and ignores the return value. `fork` does not wait and re-enqueues a returned Intent. `chain` waits and continues within the current dispatch.
- Keep all `chain` steps contiguous at the end of a Plan. Multiple trailing `chain` steps run concurrently, not sequentially.
- Results that can arrive out of order carry a token or sequence. The result Intent validates freshness before reducing State.
- Gate high-frequency input synchronously before dispatch when it cannot queue. Filtering after Intent dequeue is too late.
- Without explicit authorization, never declare MVI Trace in Core, feature State, Intent, Effect, ViewModel, or View.
- When the user explicitly requests Trace, treat it as an independent extension task. Confirm scope, build variants, medium, privacy, and cleanup through `references/trace-extension.md` first.
- Report unrelated invariant violations without changing them. Ask first when the current goal cannot be completed without breaking an existing convention.

## Common Mistakes

| Mistake | Correction |
| --- | --- |
| New initialization without a local precedent places State, Intent, and Effect in `<Feature>Mvi.ets` | Split them into semantically named State, Intent, and Effect files |
| New initialization without a local precedent places feature State in `Model.ets` | Create `<Feature>State.ets` |
| New initialization without a local precedent routes View input through `viewModel.onClick()` before dispatch | Dispatch a concrete Intent directly from the View |
| A V1 project is rejected or migrated only because it does not use `@ObservedV2/@Trace` | Preserve its supported V1 observation model and keep the MVI reduce boundary |
| A local bug fix adopts the default directories and naming as a side refactor | Preserve the existing structure and modify only the target chain |
| Every difference from the expert default is treated as a conflict | Ask only when an existing convention prevents a correct result |
| A new Store or monolithic Reducer is introduced | Use the fixed ViewModel dispatcher and field-level `MVI.reduce` |
| Effect decides the next step from State | Return raw results to a result Intent for the decision |
| MVI Trace is introduced by default | Keep the Core free of Trace and design it separately only after explicit authorization |
| The entire project is scanned and corrected for MVI layout | Audit only the newly generated directory and do not interfere with existing structure |
