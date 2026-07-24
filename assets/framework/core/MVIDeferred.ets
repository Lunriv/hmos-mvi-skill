/**
 * One-shot async result container that reconnects a callback result to an MVI flow.
 */
export class MVIDeferred<T> {
  public promise: Promise<T>
  public resolve: (value: T) => void = (_value: T): void => {}

  public constructor() {
    this.promise = new Promise<T>((resolve) => { this.resolve = resolve })
  }
}

/**
 * Bridge for repeated external events during a lifecycle. Clear stale consumers on release.
 */
export class MVIBridge<T extends Object> {
  private consumer: (value: T) => void = (_value: T): void => {}

  /** Bind the event consumer for the current lifecycle. */
  public bindConsumer(consumer: (value: T) => void): void { this.consumer = consumer }

  /** Send one external event to the current consumer. */
  public emit(value: T): void { this.consumer(value) }

  /** Disconnect the consumer from the previous lifecycle. */
  public clear(): void { this.consumer = (_value: T): void => {} }
}
