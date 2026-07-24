export namespace MVI {
  export interface LayeredState {
    readonly ui: Object
    readonly domain: Object
    readonly runtime: Object
  }

  type FieldUpdater<V> = (current: V) => V
  type Change<V> = V | FieldUpdater<V>
  type LayerChanges<L> = { [F in keyof L]?: Change<L[F]> }
  type EffectResult<S extends LayeredState> = void | Intent<S> | Promise<void | Intent<S>>

  export type Changes<S extends LayeredState> = {
    ui?: LayerChanges<S['ui']>
    domain?: LayerChanges<S['domain']>
    runtime?: LayerChanges<S['runtime']>
  }

  export type ReadonlyState<S extends LayeredState> = {
    readonly ui: Readonly<S['ui']>
    readonly domain: Readonly<S['domain']>
    readonly runtime: Readonly<S['runtime']>
  }

  export enum StepKind {
    REDUCE = 'reduce',
    SIDE_EFFECT = 'side_effect',
    FORK_EFFECT = 'fork_effect',
    CHAIN_EFFECT = 'chain_effect',
  }

  export interface ReduceStep<S extends LayeredState> {
    kind: StepKind.REDUCE
    changes: Changes<S>
  }

  export interface SideEffectStep<S extends LayeredState> {
    kind: StepKind.SIDE_EFFECT
    effect: Effect<S>
  }

  export interface ForkEffectStep<S extends LayeredState> {
    kind: StepKind.FORK_EFFECT
    effect: Effect<S>
  }

  export interface ChainEffectStep<S extends LayeredState> {
    kind: StepKind.CHAIN_EFFECT
    effect: Effect<S>
  }

  export type Step<S extends LayeredState> = ReduceStep<S> | SideEffectStep<S> |
    ForkEffectStep<S> | ChainEffectStep<S>
  export type Plan<S extends LayeredState> = Step<S>[]

  export const reduce = <S extends LayeredState>(changes: Changes<S>): ReduceStep<S> => {
    return { kind: StepKind.REDUCE, changes: changes }
  }

  export const side = <S extends LayeredState>(effect: Effect<S>): SideEffectStep<S> => {
    return { kind: StepKind.SIDE_EFFECT, effect: effect }
  }

  export const fork = <S extends LayeredState>(effect: Effect<S>): ForkEffectStep<S> => {
    return { kind: StepKind.FORK_EFFECT, effect: effect }
  }

  export const chain = <S extends LayeredState>(effect: Effect<S>): ChainEffectStep<S> => {
    return { kind: StepKind.CHAIN_EFFECT, effect: effect }
  }

  export abstract class Intent<S extends LayeredState> {
    readonly description: string
    readonly flowKey: string

    protected constructor(description: string = '', flowKey: string = '') {
      this.description = description
      this.flowKey = flowKey
    }

    public abstract handle(state: ReadonlyState<S>): Plan<S>
  }

  export abstract class Effect<S extends LayeredState> {
    readonly description: string
    readonly flowKey: string

    protected constructor(description: string = '', flowKey: string = '') {
      this.description = description
      this.flowKey = flowKey
    }

    public abstract execute(): EffectResult<S>
  }

  export class State<U extends Chunk, D extends Chunk, R extends Chunk> implements LayeredState {
    readonly ui: U
    readonly domain: D
    readonly runtime: R

    public constructor(UI: Ctor<U>, Domain: Ctor<D>, Runtime: Ctor<R>) {
      this.ui = new UI()
      this.domain = new Domain()
      this.runtime = new Runtime()
    }
  }

  export abstract class ViewModel<S extends LayeredState> {
    private readonly state: S
    private dispatchQueue: Promise<void> = Promise.resolve()

    protected constructor(StateCtor: Ctor<S>) { this.state = new StateCtor() }

    public get ui(): Readonly<S['ui']> { return this.state.ui as Readonly<S['ui']> }
    protected get _domain(): Readonly<S['domain']> { return this.state.domain as Readonly<S['domain']> }
    protected get _runtime(): Readonly<S['runtime']> { return this.state.runtime as Readonly<S['runtime']> }

    /** View and external callbacks submit concrete Intents through this entry point. */
    public dispatch(intent: Intent<S>): void {
      this.dispatchQueue = this.dispatchQueue.then(async (): Promise<void> => {
        await this.processIntent(intent, [], [])
      }).catch((error: Object): void => {
        console.error(`MVI dispatch failed: ${error}`)
      })
    }

    private async processIntent(intent: Intent<S>, intentHistory: string[],
      chainEffectHistory: string[]): Promise<void> {
      const intentKey = this.getFlowKey(intent)
      if (this.containsKey(intentHistory, intentKey)) {
        throw new Error(`Duplicate Intent in chain: ${intentKey}`)
      }
      const plan = intent.handle(this.state as ReadonlyState<S>)
      this.validatePlan(plan, chainEffectHistory)
      const nextIntentHistory = this.appendKey(intentHistory, intentKey)
      const chainTasks = new Array<Promise<void>>()
      for (let i = 0; i < plan.length; i++) {
        const step = plan[i]
        if (step.kind === StepKind.REDUCE) {
          this.reduce(step.changes)
          continue
        }
        if (step.kind === StepKind.SIDE_EFFECT) {
          this.launchSideEffect(step.effect)
          continue
        }
        if (step.kind === StepKind.FORK_EFFECT) {
          void this.executeForkEffect(step.effect)
          continue
        }
        chainTasks.push(this.executeChainEffect(step.effect, nextIntentHistory,
          this.appendKey(chainEffectHistory, this.getFlowKey(step.effect))))
      }
      let chainError: Object | undefined = undefined
      for (let i = 0; i < chainTasks.length; i++) {
        try {
          await chainTasks[i]
        } catch (error) {
          if (chainError == undefined) { chainError = error as Object }
        }
      }
      if (chainError != undefined) { throw chainError }
    }

    private async executeChainEffect(effect: Effect<S>, intentHistory: string[],
      chainEffectHistory: string[]): Promise<void> {
      const nextIntent = await effect.execute()
      if (nextIntent != undefined) {
        await this.processIntent(nextIntent as Intent<S>, intentHistory, chainEffectHistory)
      }
    }

    private launchSideEffect(effect: Effect<S>): void {
      try {
        const result = effect.execute()
        if (result instanceof Promise) {
          result.catch((error: Object): void => console.error(`MVI side effect failed: ${error}`))
        }
      } catch (error) {
        console.error(`MVI side effect failed: ${error}`)
      }
    }

    private async executeForkEffect(effect: Effect<S>): Promise<void> {
      try {
        const nextIntent = await effect.execute()
        if (nextIntent != undefined) { this.dispatch(nextIntent as Intent<S>) }
      } catch (error) {
        console.error(`MVI fork effect failed: ${error}`)
      }
    }

    private validatePlan(plan: Plan<S>, chainEffectHistory: string[]): void {
      let chainStarted = false
      const currentPlanChainKeys = new Array<string>()
      for (let i = 0; i < plan.length; i++) {
        const step = plan[i]
        if (step.kind !== StepKind.CHAIN_EFFECT) {
          if (chainStarted) { throw new Error('chain steps must be contiguous at the end of an Intent Plan') }
          continue
        }
        chainStarted = true
        const effectKey = this.getFlowKey(step.effect)
        if (this.containsKey(chainEffectHistory, effectKey)) {
          throw new Error(`Duplicate ChainEffect in chain: ${effectKey}`)
        }
        if (this.containsKey(currentPlanChainKeys, effectKey)) {
          throw new Error(`Concurrent branches of one Intent reuse ChainEffect: ${effectKey}`)
        }
        currentPlanChainKeys.push(effectKey)
      }
    }

    private reduce(changes: Changes<S>): void {
      const target = this.state as Object as Record<string, Record<string, Object>>
      const source = changes as Object as Record<string, Record<string, Object>>
      const layers = Object.keys(source)
      for (let i = 0; i < layers.length; i++) {
        const targetLayer = target[layers[i]]
        const layerChanges = source[layers[i]]
        const fields = Object.keys(layerChanges)
        for (let j = 0; j < fields.length; j++) {
          const fieldName = fields[j]
          const change = layerChanges[fieldName]
          targetLayer[fieldName] = typeof change === 'function' ?
            (change as FieldUpdater<Object>)(targetLayer[fieldName]) : change
        }
      }
    }

    private getTypeKey(target: Object): string {
      const prototype = Object.getPrototypeOf(target)
      return prototype != undefined && prototype.constructor != undefined && prototype.constructor.name ?
        prototype.constructor.name as string : `${target}`
    }

    private getFlowKey(target: Object): string {
      const key = (target as FlowNode).flowKey
      return key != undefined && key.length > 0 ? key : this.getTypeKey(target)
    }

    private containsKey(keys: string[], key: string): boolean {
      for (let i = 0; i < keys.length; i++) {
        if (keys[i] === key) { return true }
      }
      return false
    }

    private appendKey(keys: string[], key: string): string[] {
      const result = keys.slice()
      result.push(key)
      return result
    }
  }
}

interface FlowNode { readonly flowKey?: string }
type Ctor<T> = new () => T
class Chunk {}
