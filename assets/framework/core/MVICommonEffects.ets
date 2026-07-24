import { MVI } from './MVI'

type LayeredState = MVI.LayeredState

export namespace MVICommonEffects {
  /** Return the caller-provided Intent without reading State or adding business decisions. */
  export class ReturnIntentEffect<S extends LayeredState> extends MVI.Effect<S> {
    private readonly resultIntent: MVI.Intent<S>

    public constructor(resultIntent: MVI.Intent<S>, flowKey: string = '') {
      super('Return the provided Intent', flowKey)
      this.resultIntent = resultIntent
    }

    /** Forward the Intent supplied at construction. */
    public execute(): MVI.Intent<S> { return this.resultIntent }
  }

  /** Wait for a fixed duration, then return the caller-provided Intent. */
  export class DelayIntentEffect<S extends LayeredState> extends MVI.Effect<S> {
    private readonly milliseconds: number
    private readonly resultIntent: MVI.Intent<S>

    public constructor(milliseconds: number, resultIntent: MVI.Intent<S>, flowKey: string = '') {
      super('Return the provided Intent after a delay', flowKey)
      this.milliseconds = milliseconds
      this.resultIntent = resultIntent
    }

    /** Forward the target Intent after the timer completes. */
    public execute(): Promise<MVI.Intent<S>> {
      return new Promise<MVI.Intent<S>>((resolve) => {
        setTimeout((): void => resolve(this.resultIntent), this.milliseconds)
      })
    }
  }

  /** Await a one-shot async result and convert it to an Intent with a stateless factory. */
  export class WaitDeferredEffect<S extends LayeredState, T> extends MVI.Effect<S> {
    private readonly promise: Promise<T>
    private readonly resultIntentFactory: (value: T) => MVI.Intent<S>

    public constructor(promise: Promise<T>, resultIntentFactory: (value: T) => MVI.Intent<S>,
      flowKey: string = '') {
      super('Wait for a one-shot async result', flowKey)
      this.promise = promise
      this.resultIntentFactory = resultIntentFactory
    }

    /** Await the bridged result and return its Intent. */
    public async execute(): Promise<MVI.Intent<S>> {
      return this.resultIntentFactory(await this.promise)
    }
  }
}
