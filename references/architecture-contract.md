# Architecture Contract

## State and Dispatch

Each ViewModel creates and permanently owns one State tree. The root and its `ui/domain/runtime` layer objects are never replaced. `dispatch` appends a root Intent to that ViewModel's private Promise queue. A failure ends that dispatch but does not block later queue entries.

Intent synchronously returns a `Plan` from `handle(ReadonlyState)`. A Plan describes the current business branch rather than a fixed layer pipeline:

```text
Input source -> View or lifecycle callback -> dispatch(concrete Intent) -> serial queue
  -> Intent.handle(ReadonlyState) -> Plan interpreter
       |-- reduce -> field updates -> @Trace -> View refresh
       |-- side   -> launch Effect, do not wait, ignore return value
       |-- fork   -> launch Effect, do not wait, dispatch returned Intent
       `-- chain  -> wait for Effect, continue returned Intent in current dispatch
```

## Responsibilities

### Intent

- It is the only location allowed to read current MVI State, make business decisions, and select Plan branches.
- It composes a Plan but performs no low-level capability action directly.
- It does not write State or directly invoke another Intent's `handle`.
- It may place the same low-level Effect in different Step kinds, but Intent always returns the final Plan.

### Effect

- It performs one low-level action and does not read or write MVI State.
- It does not hold a ViewModel, call dispatch, or make business decisions.
- Name it after the real low-level action, not a flow phase, result state, or wait mode.
- A new Effect extends `MVI.Effect` and implements the single execution entry point `execute()`. `side/fork/chain` are call semantics, not Effect subclasses.
- Set only forwards a target value; Toggle only flips a binary value; Switch only rotates fixed alternatives.
- Use `finally` only for technical cleanup such as resource release, never to introduce business decisions.

An Effect may package a low-level return value and technical error in the same result Intent. That Intent reads State to decide success, UI updates, and any next action.

### ViewModel and View

For new initialization, ViewModel owns State, dependencies, and lifecycle resources and exposes inherited `dispatch`. View directly dispatches concrete Intents from clicks, input, and lifecycle events. It does not mutate MVI State. A V2 View reads stable `viewModel.ui`; a V1 owning View keeps that same object in `@State`, while a V1 child receives it through `@ObjectLink`. Do not wrap each View input in a ViewModel method that only forwards to `dispatch`; the ViewModel may dispatch feedback from external callbacks and lifecycle internals.

For an existing feature, preserve its View/ViewModel input convention when that convention does not prevent correctness. If a correct implementation requires changing the interaction contract, explain the behavior and impact and ask first.

## File Semantic Ownership

The target project's path, file name, existing declarations, module exports, and adjacent implementations jointly express a file's responsibility. A universal suffix or directory from this skill does not determine that responsibility on its own. Before writing:

1. Derive the responsibility from the path, file name, existing declarations, exports, and adjacent implementation.
2. Check the ownership of every class, interface, type, enum, function, constant, and code block.
3. If a declaration cannot directly belong to that responsibility, do not write it in that file.
4. Use an existing semantically matching file, or create a file named for the real responsibility when no suitable destination exists.
5. Ask when ambiguity in an existing boundary affects the current implementation. Only report unrelated historical mixing; do not clean it up through the current task.

This principle applies to every file but does not impose one organization format. The namespace or declaration boundary of one Intent file is evidence only for that project. Never generalize it into a suffix, namespace, or declaration matrix for other files or projects.

## Existing Project Boundaries

- The current goal takes priority over an ideal structure. Use expert judgment for the smallest correct change, not to expand refactoring scope.
- Differences in naming, directories, namespaces, dependency injection, and encapsulation are implementation differences, not automatic conflicts.
- An existing Core that differs from fixed assets is also an implementation difference. Use its real dispatch semantics and do not treat asset equality as a gate for an unrelated task.
- Do not migrate architecture, split files, or normalize naming while fixing a bug.
- Escalate an existing convention only when it prevents a correct result for the current goal.
- Report MVI issues outside the current scope without modifying them.

## Chain Constraints

- Keep every `chain` step contiguous at the end of a Plan.
- Multiple trailing `chain` steps start concurrently and are awaited together; do not interpret them as sequential steps.
- A call chain must not repeat the same Intent or ChainEffect. Concurrent branches in one Plan must not repeat the same ChainEffect.
- When nodes of the same class represent distinct branches, pass distinct `flowKey` values instead of fabricating different class names.
- An error in any chain branch ends the current root dispatch. Concurrent branches already started are not automatically cancelled.

## State Layers

| Layer | Content | Reactive by default |
| --- | --- | --- |
| `ui` | Display and interaction state observed through the project's V1 or V2 state model | Yes |
| `domain` | External capability objects, long-lived dependencies, domain context | No |
| `runtime` | Tokens, sequences, and flow-control state | No |

All MVI State changes in all three layers use `reduce`. Layering is not permission to bypass the reducer boundary.
