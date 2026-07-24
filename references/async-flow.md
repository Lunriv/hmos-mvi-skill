# Async Flow and Feedback

## Step Selection

| Requirement | Step | Result |
| --- | --- | --- |
| Trigger an action without waiting or accepting a returned Intent | `side` | Promise errors are logged; return values are ignored |
| Do not wait, but return a result to MVI | `fork` | A returned Intent re-enters the ViewModel queue |
| Later handling must wait for this result | `chain` | A returned Intent continues inside the current root dispatch |

First ask whether the current dispatch must wait, then whether a returned Intent must feed back. Do not choose a Step from the Effect name, sync or async implementation, or result type.

## Out-of-Order Results

An Effect that may return after a newer request must carry the token or increasing sequence captured at launch. The result Intent reads `state.runtime` to determine whether it is still current:

```ts
if (state.runtime.sequence !== this.sequence) {
  return []
}
return [MVI.reduce<FeatureState>({ ui: { value: this.value } })]
```

The token rejects stale results. It does not cancel a request or prevent input from entering the queue.

## High-Frequency Input Gate

Input that cannot queue must be checked synchronously before dispatch. The gate and MVI State have different responsibilities: the gate controls whether input enters the queue, while State describes the current business state.

```ts
class InputDispatchGate {
  private isLocked: boolean = false

  public tryLock(): boolean {
    if (this.isLocked) { return false }
    this.isLocked = true
    return true
  }

  public unlock(): void { this.isLocked = false }
}
```

Call `tryLock()` before dispatch. The input Intent's Plan uses a technical Effect whose only action is `unlock()`. New input cannot accumulate while that Intent is queued. If the input policy retains the latest value, let the gate retain the latest snapshot and decide whether to resubmit on release; do not put that policy in an Effect business decision.

## Callback Bridges

- `MVIDeferred<T>` accepts one result. Create a new instance for every task and never reuse it.
- `MVIBridge<T>` accepts repeated external events during a page lifecycle. Bind the consumer at initialization and call `clear()` on release.
- Split a callback-based multi-stage capability into a listener-registration Effect, an action-trigger Effect, and a result Intent. Do not wait for and decide the entire business chain in one Effect.

## Errors and Concurrency

- A chain error ends the current root dispatch; later independent dispatches still run.
- A side Promise error is logged and does not become State. Use fork or chain with a result Intent when the UI must show an error.
- A fork error does not block the queue. Package expected technical results in one result Intent and let that Intent decide the business meaning.
- Multiple trailing chain steps start concurrently. For strict ordering, let the first Effect return an Intent whose Plan starts the next segment.
