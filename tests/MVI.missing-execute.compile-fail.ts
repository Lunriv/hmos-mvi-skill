import { MVI } from '../assets/framework/core/MVI'

class CompileFailUiState {}
class CompileFailDomainState {}
class CompileFailRuntimeState {}

class CompileFailState extends MVI.State<CompileFailUiState, CompileFailDomainState,
  CompileFailRuntimeState> {
  constructor() { super(CompileFailUiState, CompileFailDomainState, CompileFailRuntimeState) }
}

class MissingExecuteEffect extends MVI.Effect<CompileFailState> {
  constructor() { super('Missing execution entry point') }
}

void new MissingExecuteEffect()
