#!/usr/bin/env bash
set -Eeu

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
skill_root="$(cd "$script_dir/.." && pwd)"
typescript_compiler="/Applications/DevEco-Studio.app/Contents/tools/hvigor/hvigor/node_modules/typescript/lib/tsc.js"
test_output_root="${TMPDIR:-/tmp}/hmos-mvi-core-test"
compile_fail_output="$test_output_root/missing-execute.log"

if [[ ! -f "$typescript_compiler" ]]; then
  echo "TypeScript compiler not found: $typescript_compiler" >&2
  exit 1
fi

node "$typescript_compiler" \
  "$skill_root/assets/framework/core/MVI.ts" \
  "$skill_root/tests/MVI.behavior.test.ts" \
  --target ES2020 \
  --module commonjs \
  --rootDir "$skill_root" \
  --outDir "$test_output_root" \
  --skipLibCheck \
  --noEmitOnError

node "$test_output_root/tests/MVI.behavior.test.js"

if node "$typescript_compiler" \
  "$skill_root/assets/framework/core/MVI.ts" \
  "$skill_root/tests/MVI.missing-execute.compile-fail.ts" \
  --target ES2020 \
  --module commonjs \
  --rootDir "$skill_root" \
  --outDir "$test_output_root/missing-execute" \
  --skipLibCheck \
  --noEmitOnError >"$compile_fail_output" 2>&1; then
  echo 'An Effect without execute() must not compile' >&2
  exit 1
fi

if ! grep -Eq "TS2515|does not implement inherited abstract member 'execute'" "$compile_fail_output"; then
  echo 'The Effect did not fail compilation because execute() was missing' >&2
  cat "$compile_fail_output" >&2
  exit 1
fi

echo 'Effect execute() compile-contract test passed'
