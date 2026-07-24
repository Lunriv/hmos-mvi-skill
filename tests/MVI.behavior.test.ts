import { MVI } from '../assets/framework/core/MVI'

class TestUiState {
  value: number = 0
}

class TestDomainState {}
class TestRuntimeState {}

class TestState extends MVI.State<TestUiState, TestDomainState, TestRuntimeState> {
  constructor() { super(TestUiState, TestDomainState, TestRuntimeState) }
}

class TestViewModel extends MVI.ViewModel<TestState> {
  constructor() { super(TestState) }
}

class SetValueIntent extends MVI.Intent<TestState> {
  private readonly value: number

  constructor(value: number) {
    super('Set test value')
    this.value = value
  }

  public handle(): MVI.Plan<TestState> {
    return [MVI.reduce<TestState>({ ui: { value: this.value } })]
  }
}

class ReturnIntentEffect extends MVI.Effect<TestState> {
  private readonly intent: MVI.Intent<TestState>

  constructor(intent: MVI.Intent<TestState>) {
    super('Return test Intent')
    this.intent = intent
  }

  public execute(): MVI.Intent<TestState> { return this.intent }
}

class DelayedReturnIntentEffect extends MVI.Effect<TestState> {
  private readonly intent: MVI.Intent<TestState>

  constructor(intent: MVI.Intent<TestState>) {
    super('Return test Intent after delay')
    this.intent = intent
  }

  public execute(): Promise<MVI.Intent<TestState>> {
    return new Promise<MVI.Intent<TestState>>((resolve): void => {
      setTimeout((): void => resolve(this.intent), 0)
    })
  }
}

class SideIntent extends MVI.Intent<TestState> {
  constructor() { super('Test side') }

  public handle(): MVI.Plan<TestState> {
    return [MVI.side<TestState>(new ReturnIntentEffect(new SetValueIntent(1)))]
  }
}

class ForkIntent extends MVI.Intent<TestState> {
  constructor() { super('Test fork') }

  public handle(): MVI.Plan<TestState> {
    return [MVI.fork<TestState>(new DelayedReturnIntentEffect(new SetValueIntent(2)))]
  }
}

class ChainIntent extends MVI.Intent<TestState> {
  constructor() { super('Test chain') }

  public handle(): MVI.Plan<TestState> {
    return [MVI.chain<TestState>(new ReturnIntentEffect(new SetValueIntent(3)))]
  }
}

function assertEqual(actual: number, expected: number, message: string): void {
  if (actual !== expected) {
    throw new Error(`${message}: expected=${expected}, actual=${actual}`)
  }
}

async function waitForValue(viewModel: TestViewModel, expected: number): Promise<void> {
  for (let attempt = 0; attempt < 40; attempt++) {
    if (viewModel.ui.value === expected) { return }
    await new Promise<void>((resolve): void => {
      setTimeout(resolve, 5)
    })
  }
  assertEqual(viewModel.ui.value, expected, 'Timed out waiting for async dispatch result')
}

async function verifyBehavior(): Promise<void> {
  const reduceViewModel = new TestViewModel()
  reduceViewModel.dispatch(new SetValueIntent(7))
  await waitForValue(reduceViewModel, 7)

  const sideViewModel = new TestViewModel()
  sideViewModel.dispatch(new SideIntent())
  await new Promise<void>((resolve): void => {
    setTimeout(resolve, 5)
  })
  assertEqual(sideViewModel.ui.value, 0, 'side must ignore a returned Intent')

  const forkViewModel = new TestViewModel()
  forkViewModel.dispatch(new ForkIntent())
  await waitForValue(forkViewModel, 2)

  const chainViewModel = new TestViewModel()
  chainViewModel.dispatch(new ChainIntent())
  await waitForValue(chainViewModel, 3)
}

void verifyBehavior().then((): void => console.info('MVI Core behavior tests passed'))
