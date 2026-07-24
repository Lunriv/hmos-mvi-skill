# HarmonyOS MVI

**English** | [简体中文](README.zh-CN.md)

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](LICENSE)

A skill for building and maintaining MVI architecture in HarmonyOS projects. It combines a complete Intent, Plan, and Effect feedback loop with ArkUI's native reactive state management.

It supports new feature initialization, extension, bug fixing, async feedback, and UI refresh diagnosis while preserving compatible project conventions.

## Quick Start

### Install in 30 Seconds

Install with the Agent Skills installer:

```bash
npx skills add Lunriv/hmos-mvi-skill
```

In the interactive prompt, select the root `hmos-mvi` skill and the agent runtimes where you want to install it.

For runtimes that do not support the installer, clone the [GitHub repository](https://github.com/Lunriv/hmos-mvi-skill.git) into the runtime's skill discovery directory:

```bash
git clone https://github.com/Lunriv/hmos-mvi-skill.git /path/to/skills/hmos-mvi
```

For either method, make sure the runtime can discover the repository's root [`SKILL.md`](SKILL.md).

### Get Better Results

Only the HarmonyOS project and target behavior are required. The following optional context helps the skill work more precisely:

- the target page, feature, or module path;
- expected inputs, state changes, async results, and error behavior;
- related MVI implementations or project conventions that should be preserved;
- available hvigor build, test, or other project validation commands.

The following optional companion skills provide broader HarmonyOS support:

- [`hmos-arkui-develop-skill`](https://gitcode.com/openharmony-skills/hmos-arkui-develop-skill) for ArkUI implementation, API evidence, and compilation checks;
- [`skill-harmonyos-docs`](https://gitcode.com/Andy88/skill-harmonyos-docs) for HarmonyOS API references, development guides, and best practices.

### Usage

Invoke the skill directly from the target HarmonyOS project. Common prompts are:

```text
Use $hmos-mvi to initialize MVI architecture in the current HarmonyOS project.

Use $hmos-mvi to implement <feature> in the current HarmonyOS project with MVI.

Use $hmos-mvi to fix <bug> in the current HarmonyOS project.
```

Add the target path, expected behavior, constraints, or validation command when they matter. The skill reads available project facts, preserves compatible local conventions, implements the required MVI loop, and runs available validation.

## Why a Closed MVI Loop

An ArkUI page can refresh correctly while still bypassing its business-state boundary. ArkUI decorators determine which field changes refresh the View; they do not determine who may change State. This skill keeps those responsibilities separate:

```text
View or lifecycle callback
  -> dispatch(concrete Intent)
  -> Intent.handle(ReadonlyState)
  -> Plan
       |-- reduce -> field-level State changes -> @Track/@Trace -> View refresh
       |-- side   -> launch Effect, ignore its return value
       |-- fork   -> launch Effect, re-enqueue its returned Intent
       `-- chain  -> await Effect, continue its returned Intent in this dispatch
```

Intent is the only layer that reads current State and selects a business branch. Effect performs one low-level action without reading or mutating State. Every MVI State change passes through a field-level `reduce` step.

## Execution Model

| Step | Waits | Uses a returned Intent | Intended use |
| --- | --- | --- | --- |
| `reduce` | Not applicable | Not applicable | Update fields in `ui`, `domain`, or `runtime`. |
| `side` | No | No | Fire-and-forget work whose return value must be ignored. |
| `fork` | No | Yes | Start work and feed its result back through the ViewModel queue. |
| `chain` | Yes | Yes | Continue feedback inside the current root dispatch. |

All `chain` steps must be contiguous at the end of a Plan. Multiple trailing `chain` steps start concurrently and are awaited together; strict sequencing requires the first Effect to return an Intent whose Plan starts the next segment.

## Workflow

| Stage | Responsibility |
| --- | --- |
| 1. Read project facts | Read available project structure, exports, adjacent features, and conventions; preserve clear V1 evidence and otherwise default to V2. |
| 2. Define the loop | List inputs, layered State, concrete Intents, Plans, Effects, feedback semantics, async ordering, and cleanup. |
| 3. Implement | Complete the smallest correct loop without unrelated migration, renaming, or restructuring. |
| 4. Review invariants | Check ownership boundaries, stable State objects, stale-result filtering, input gates, and lifecycle cleanup. |
| 5. Verify | Run relevant skill checks and any available project test or validation command; report missing coverage. |

For a new feature without a local precedent, the default structure uses business-specific names:

```text
<feature>/
├── state/<Feature>State.ets
├── intent/<Feature>Intent.ets
├── effect/<Feature>Effect.ets
├── viewmodel/<Feature>ViewModel.ets
└── view/<Feature>View.ets
```

Existing features keep their established organization whenever it can support a correct implementation.

## Core Principles

- Keep the State root and its `ui`, `domain`, and `runtime` layer objects stable for the ViewModel lifetime.
- Preserve an existing feature's state generation. When no local evidence exists, default to V2 `@ObservedV2/@Trace`; use V1 `@Observed/@Track` with `@State` or `@ObjectLink` when the feature establishes V1 or V2 proves unavailable.
- Route changes in every State layer through `MVI.reduce`.
- Keep `Intent.handle` synchronous; Intent reads State, makes decisions, and returns the final Plan.
- Give each Effect one low-level action. Effect must implement `execute()` and must not read State, dispatch, or make business decisions.
- Use a token or increasing sequence to reject async results that arrive after a newer request.
- Gate high-frequency input synchronously before dispatch when it must not accumulate in the queue.
- Preserve existing project conventions unless they prevent correct behavior for the current task.
- Do not introduce MVI Trace, recording, replay, or visualization unless the user explicitly requests it and confirms its scope and privacy rules.

## References

| File | Read when |
| --- | --- |
| [`references/architecture-contract.md`](references/architecture-contract.md) | Defining framework responsibilities, dispatch behavior, file ownership, or chain constraints. |
| [`references/arkui-state.md`](references/arkui-state.md) | Selecting V1 or V2 state observation and diagnosing UI refresh failures. |
| [`references/async-flow.md`](references/async-flow.md) | Handling Promises, callbacks, listeners, concurrency, stale results, or high-frequency input. |
| [`references/closed-loop-template.md`](references/closed-loop-template.md) | Building a complete feature from scratch without a local precedent. |
| [`references/trace-extension.md`](references/trace-extension.md) | Only after an explicit request for MVI Trace, recording, replay, or flow visualization. |

## Skill Structure

```text
hmos-mvi/
├── SKILL.md                         # Skill entry point and decision workflow
├── agents/openai.yaml               # Agent display metadata
├── assets/framework/core/           # Optional framework assets
├── references/                      # Architecture, state, async, template, and Trace contracts
├── scripts/                         # Installation, audit, and verification commands
└── tests/                           # Core behavior and compile-contract tests
```

## Validation

Run the skill contract checks from the repository root:

```bash
bash scripts/test_hmos_mvi_skill_contract.sh
```

Run the bundled Core behavior and compile-contract tests:

```bash
./scripts/test_mvi_core_behavior.sh
```

This optional asset test expects the TypeScript compiler bundled with DevEco Studio at `/Applications/DevEco-Studio.app/Contents/tools/hvigor/hvigor/node_modules/typescript/lib/tsc.js`. It is not required to install or invoke the skill.

Audit a newly generated feature directory without modifying it:

```bash
./scripts/audit_hmos_mvi_layout.sh /path/to/new/feature
```

The layout audit reports naming and directory suggestions only. It does not gate an existing project build. Run available project tests or validation commands when present; otherwise report compilation and runtime behavior as unverified.

## License

Licensed under the [Apache License 2.0](LICENSE).
