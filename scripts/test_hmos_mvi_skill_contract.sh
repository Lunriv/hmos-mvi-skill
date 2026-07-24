#!/usr/bin/env bash
set -Eeu

skill_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
failed=false

require_text() {
  local file="$1"
  local text="$2"
  if grep -Fq "$text" "$file"; then
    echo "OK       $file contains: $text"
  else
    echo "MISSING  $file does not contain: $text" >&2
    failed=true
  fi
}

forbid_text() {
  local file="$1"
  local text="$2"
  if grep -Fq "$text" "$file"; then
    echo "FORBIDDEN $file contains: $text" >&2
    failed=true
  else
    echo "OK       $file does not contain: $text"
  fi
}

require_text "$skill_root/SKILL.md" 'state/<Feature>State.ets'
require_text "$skill_root/SKILL.md" 'intent/<Feature>Intent.ets'
require_text "$skill_root/SKILL.md" 'effect/<Feature>Effect.ets'
require_text "$skill_root/SKILL.md" 'directly dispatches a concrete Intent'
require_text "$skill_root/SKILL.md" 'audit_hmos_mvi_layout.sh'
require_text "$skill_root/SKILL.md" 'references/closed-loop-template.md'
require_text "$skill_root/SKILL.md" 'references/trace-extension.md'
require_text "$skill_root/SKILL.md" 'references/arkui-state.md'
require_text "$skill_root/SKILL.md" 'test_mvi_core_behavior.sh'
require_text "$skill_root/SKILL.md" 'The current task takes priority over an ideal architecture'
require_text "$skill_root/SKILL.md" 'A difference is not automatically a conflict'
require_text "$skill_root/SKILL.md" 'Do not use the task to migrate architecture'
require_text "$skill_root/SKILL.md" 'Ask only when the goal cannot be completed correctly within existing conventions'
require_text "$skill_root/SKILL.md" 'New initialization without a local precedent places State, Intent, and Effect in `<Feature>Mvi.ets`'
require_text "$skill_root/SKILL.md" 'New initialization without a local precedent places feature State in `Model.ets`'
require_text "$skill_root/SKILL.md" 'New initialization without a local precedent routes View input through `viewModel.onClick()` before dispatch'
require_text "$skill_root/SKILL.md" 'If the current task does not require a Core change'
require_text "$skill_root/SKILL.md" 'Ask only when existing Core semantics prevent a correct result'
require_text "$skill_root/SKILL.md" 'Run fixed-asset verification and fixed-Core behavior tests only'
require_text "$skill_root/SKILL.md" 'Effect must implement `execute()`; Core provides no empty default implementation'
require_text "$skill_root/SKILL.md" 'semantic promise'
require_text "$skill_root/SKILL.md" 'Every added or modified declaration and code block'
require_text "$skill_root/SKILL.md" 'Do not violate file semantics to reduce file count, shorten import paths, or reuse code'
require_text "$skill_root/SKILL.md" 'Do not impose a universal file suffix, directory, namespace, or declaration-type matrix'
require_text "$skill_root/SKILL.md" 'constrain only declarations added or modified by the current task'
require_text "$skill_root/SKILL.md" "Use the target feature's established state management generation"
require_text "$skill_root/SKILL.md" 'When no local state-management evidence exists, default to V2.'
require_text "$skill_root/SKILL.md" 'Available project build or test commands improve verification but are not required'
require_text "$skill_root/SKILL.md" '`@Observed` + `@Track`'
require_text "$skill_root/SKILL.md" '`@ObservedV2` + `@Trace`'
forbid_text "$skill_root/SKILL.md" 'Report incompatibility below API 12 and do not generate a V1 fallback.'
forbid_text "$skill_root/SKILL.md" 'Ask only when project files, adjacent code, and the build configuration cannot establish a safe choice.'
forbid_text "$skill_root/SKILL.md" 'Finish with the real hvigor build command for the target module.'
require_text "$skill_root/references/architecture-contract.md" '## File Semantic Ownership'
require_text "$skill_root/references/architecture-contract.md" 'If a declaration cannot directly belong to that responsibility, do not write it in that file'
require_text "$skill_root/references/arkui-state.md" '## V1 Pattern'
require_text "$skill_root/references/arkui-state.md" 'When no local state-management evidence exists, default to V2.'
require_text "$skill_root/references/arkui-state.md" '@Observed'
require_text "$skill_root/references/arkui-state.md" '@Track'
require_text "$skill_root/references/arkui-state.md" '@State'
require_text "$skill_root/references/arkui-state.md" '@ObjectLink'
require_text "$skill_root/references/arkui-state.md" 'remove every `@Track` decorator from that UI State class'
require_text "$skill_root/references/arkui-state.md" '## V2 Pattern'
require_text "$skill_root/references/arkui-state.md" '@ObservedV2'
require_text "$skill_root/references/arkui-state.md" '@Trace'
require_text "$skill_root/assets/framework/core/MVI.ts" 'export abstract class Effect'
require_text "$skill_root/assets/framework/core/MVI.ts" 'public abstract execute()'
forbid_text "$skill_root/SKILL.md" 'View only calls public ViewModel entry points'
forbid_text "$skill_root/SKILL.md" 'stop and report a conflict'
forbid_text "$skill_root/assets/framework/core/MVI.ts" 'MVITrace'
forbid_text "$skill_root/assets/framework/core/MVI.ts" 'export class ChainEffect'
forbid_text "$skill_root/assets/framework/core/MVI.ts" 'export class SideEffect'
forbid_text "$skill_root/scripts/install_hmos_mvi.sh" 'MVITracePort'
require_text "$skill_root/references/closed-loop-template.md" '`Feature` is a structural marker to replace'
require_text "$skill_root/references/closed-loop-template.md" 'interface FeaturePort'
require_text "$skill_root/references/closed-loop-template.md" 'class FeatureUiState'
require_text "$skill_root/references/closed-loop-template.md" 'class FeatureDomainState'
require_text "$skill_root/references/closed-loop-template.md" 'class FeatureRuntimeState'
require_text "$skill_root/references/closed-loop-template.md" 'class FeatureState'
require_text "$skill_root/references/closed-loop-template.md" 'class FeatureInputIntent'
require_text "$skill_root/references/closed-loop-template.md" 'class InvokeFeaturePortEffect'
require_text "$skill_root/references/closed-loop-template.md" 'class FeatureResultIntent'
require_text "$skill_root/references/closed-loop-template.md" 'class FeatureViewModel'
require_text "$skill_root/references/closed-loop-template.md" 'struct FeatureView'
require_text "$skill_root/references/closed-loop-template.md" 'public async execute()'
require_text "$skill_root/references/closed-loop-template.md" 'MVI.fork<FeatureState>'
require_text "$skill_root/references/closed-loop-template.md" 'state.runtime.sequence !== this.sequence'
require_text "$skill_root/references/closed-loop-template.md" 'this.viewModel.dispatch(new FeatureInputIntent(input))'
require_text "$skill_root/references/closed-loop-template.md" '### V1 State'
require_text "$skill_root/references/closed-loop-template.md" '### V2 State'
require_text "$skill_root/references/closed-loop-template.md" '### V1 View'
require_text "$skill_root/references/closed-loop-template.md" '### V2 View'
require_text "$skill_root/references/closed-loop-template.md" '@Observed'
require_text "$skill_root/references/closed-loop-template.md" '@Track'
require_text "$skill_root/references/closed-loop-template.md" 'remove all three `@Track` decorators'
require_text "$skill_root/references/closed-loop-template.md" '@Component'
require_text "$skill_root/references/closed-loop-template.md" '@ObservedV2'
require_text "$skill_root/references/closed-loop-template.md" '@Trace'
require_text "$skill_root/references/closed-loop-template.md" '@ComponentV2'
require_text "$skill_root/README.md" 'npx skills add Lunriv/hmos-mvi-skill'
require_text "$skill_root/README.md" 'git clone https://github.com/Lunriv/hmos-mvi-skill.git'
require_text "$skill_root/README.md" '### Get Better Results'
require_text "$skill_root/README.md" 'Only the HarmonyOS project and target behavior are required.'
require_text "$skill_root/README.md" 'https://gitcode.com/openharmony-skills/hmos-arkui-develop-skill'
require_text "$skill_root/README.md" 'https://gitcode.com/Andy88/skill-harmonyos-docs'
require_text "$skill_root/README.md" 'License-Apache%202.0'
require_text "$skill_root/README.md" '[Apache License 2.0](LICENSE)'
require_text "$skill_root/README.md" 'Use $hmos-mvi to initialize MVI architecture in the current HarmonyOS project.'
require_text "$skill_root/README.md" 'Use $hmos-mvi to implement <feature> in the current HarmonyOS project with MVI.'
require_text "$skill_root/README.md" 'Use $hmos-mvi to fix <bug> in the current HarmonyOS project.'
require_text "$skill_root/README.zh-CN.md" 'npx skills add Lunriv/hmos-mvi-skill'
require_text "$skill_root/README.zh-CN.md" 'git clone https://github.com/Lunriv/hmos-mvi-skill.git'
require_text "$skill_root/README.zh-CN.md" 'https://gitcode.com/openharmony-skills/hmos-arkui-develop-skill'
require_text "$skill_root/README.zh-CN.md" 'https://gitcode.com/Andy88/skill-harmonyos-docs'
require_text "$skill_root/README.zh-CN.md" 'License-Apache%202.0'
require_text "$skill_root/README.zh-CN.md" '[Apache License 2.0](LICENSE)'
require_text "$skill_root/LICENSE" 'Apache License'
require_text "$skill_root/LICENSE" 'Version 2.0, January 2004'
require_text "$skill_root/LICENSE" 'Copyright 2026 Lunriv'
if [[ $(grep -Fc '$hmos-mvi' "$skill_root/README.md") -lt 3 ||
  $(grep -Fc '$hmos-mvi' "$skill_root/README.zh-CN.md") -lt 3 ]]; then
  echo 'MISSING  Each README must contain three $hmos-mvi usage prompts' >&2
  failed=true
else
  echo 'OK       Both READMEs contain three $hmos-mvi usage prompts'
fi
forbid_text "$skill_root/README.md" 'Use API 12 or later'
forbid_text "$skill_root/README.md" '### Prerequisites'
forbid_text "$skill_root/README.md" 'Identify the target module, its real hvigor build command'
forbid_text "$skill_root/README.md" 'Build command: <hvigor-command>'
forbid_text "$skill_root/README.md" 'real hvigor build'
forbid_text "$skill_root/README.zh-CN.md" 'hvigor-command'

if [[ -e "$skill_root/references/closed-loop-example.md" ]]; then
  echo 'FORBIDDEN A concrete closed-loop example file remains' >&2
  failed=true
else
  echo 'OK       No concrete closed-loop example file remains'
fi

if [[ -e "$skill_root/references/arkui-v2-state.md" ]]; then
  echo 'FORBIDDEN The V2-only state reference remains' >&2
  failed=true
else
  echo 'OK       The state reference covers both V1 and V2'
fi

if [[ -e "$skill_root/assets/framework/core/MVITracePort.ts" ]]; then
  echo 'FORBIDDEN The default Core contains MVITracePort.ts' >&2
  failed=true
else
  echo 'OK       The default Core does not contain MVITracePort.ts'
fi

if rg -l '[\p{Han}]' "$skill_root" -g '!README.md' -g '!README.zh-CN.md'; then
  echo 'FORBIDDEN Non-README skill files contain Han characters' >&2
  failed=true
else
  echo 'OK       Non-README skill files contain no Han characters'
fi

if $failed; then
  exit 1
fi
echo 'Skill contract verification passed'
