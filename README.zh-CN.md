# HarmonyOS MVI

[English](README.md) | 简体中文

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](LICENSE)

一个在 HarmonyOS 工程中构建和维护 MVI 架构的 Skill。它将 Intent、Plan、Effect 的完整反馈闭环与 ArkUI 原生响应式状态管理结合。

它用于新功能初始化、功能扩展、缺陷修复、异步反馈和 UI 刷新排查，并保留工程中能够支持正确实现的既有约定。

## 快速开始

### 30 秒安装

使用 Agent Skills 安装器：

```bash
npx skills add Lunriv/hmos-mvi-skill
```

在交互提示中选择根 `hmos-mvi` Skill，以及需要安装到的智能体运行时。

如果运行时不支持该安装器，可将 [GitHub 仓库](https://github.com/Lunriv/hmos-mvi-skill.git)克隆到其 Skill 发现目录：

```bash
git clone https://github.com/Lunriv/hmos-mvi-skill.git /path/to/skills/hmos-mvi
```

无论采用哪种方式，都需要确保运行时能够发现仓库根目录中的 [`SKILL.md`](SKILL.md)。

### 如何让 Skill 发挥更好

只需提供 HarmonyOS 工程和明确的目标行为。以下信息不是必需条件，但可以帮助 Skill 更准确地工作：

- 目标页面、功能或模块路径；
- 预期输入、状态变化、异步结果和错误行为；
- 需要保留的相关 MVI 实现或工程约定；
- 工程已有的 hvigor 构建、测试或其他验证命令。

还可以按需搭配以下 Skill，补充 HarmonyOS 开发能力：

- [`hmos-arkui-develop-skill`](https://gitcode.com/openharmony-skills/hmos-arkui-develop-skill)：用于 ArkUI 实现、API 依据查询和编译检查；
- [`skill-harmonyos-docs`](https://gitcode.com/Andy88/skill-harmonyos-docs)：用于检索 HarmonyOS API 参考、开发指南和最佳实践。

### 使用

在目标 HarmonyOS 工程中直接调用本 Skill。常用提示词如下：

```text
使用 $hmos-mvi 为当前 HarmonyOS 工程初始化 MVI 架构，并按现有目录和模块约定完成基础闭环。

使用 $hmos-mvi 在当前 HarmonyOS 工程中以 MVI 架构实现 <功能>，补全 State、Intent、Effect 和反馈链。

使用 $hmos-mvi 修复当前 HarmonyOS 工程中的 <缺陷>，定位并修复相关 MVI 链路，同时保持无关行为不变。
```

需要时可继续补充目标路径、预期行为、约束或验证命令。Skill 会读取可用的工程事实，保留兼容的本地约定，实现任务所需的 MVI 闭环，并运行可用的验证。

## 为什么需要完整 MVI 闭环

ArkUI 页面可以正常刷新，但业务状态仍可能绕过架构边界。ArkUI 装饰器决定字段变化后由谁刷新 View，并不决定谁有权修改 State。本 Skill 将两种职责严格分开：

```text
View 或生命周期回调
  -> dispatch(具体 Intent)
  -> Intent.handle(ReadonlyState)
  -> Plan
       |-- reduce -> State 字段级变更 -> @Track/@Trace -> View 刷新
       |-- side   -> 启动 Effect，忽略返回值
       |-- fork   -> 启动 Effect，将返回的 Intent 重新入队
       `-- chain  -> 等待 Effect，在当前 dispatch 中继续返回的 Intent
```

Intent 是唯一读取当前 State 并选择业务分支的层。Effect 只执行一个底层动作，不读取或修改 State。所有 MVI State 变更都必须通过字段级 `reduce` 步骤完成。

## 执行模型

| 步骤 | 是否等待 | 是否使用返回的 Intent | 适用场景 |
| --- | --- | --- | --- |
| `reduce` | 不适用 | 不适用 | 更新 `ui`、`domain` 或 `runtime` 中的字段。 |
| `side` | 否 | 否 | 启动无需反馈的任务，并明确忽略其返回值。 |
| `fork` | 否 | 是 | 启动任务，并通过 ViewModel 队列反馈其结果。 |
| `chain` | 是 | 是 | 在当前根 dispatch 内等待并继续反馈链。 |

所有 `chain` 步骤必须连续位于 Plan 末尾。多个尾部 `chain` 会并发启动并统一等待；如需严格串行，应由第一个 Effect 返回 Intent，再由该 Intent 的 Plan 启动下一段。

## 工作流

| 阶段 | 职责 |
| --- | --- |
| 1. 读取工程事实 | 读取可用的工程结构、导出、相邻功能和约定；有明确 V1 证据时保留 V1，否则默认 V2。 |
| 2. 定义闭环 | 列出输入、分层 State、具体 Intent、Plan、Effect、反馈语义、异步顺序和清理方式。 |
| 3. 实现 | 完成最小正确闭环，不附带无关迁移、重命名或目录重组。 |
| 4. 审查不变量 | 检查职责边界、稳定 State 对象、过期结果过滤、输入门控和生命周期清理。 |
| 5. 验证 | 运行相关 Skill 检查和可用的工程测试或验证命令，并说明缺失的验证覆盖。 |

当新功能没有本地先例时，默认使用带有具体业务名称的结构：

```text
<feature>/
├── state/<Feature>State.ets
├── intent/<Feature>Intent.ets
├── effect/<Feature>Effect.ets
├── viewmodel/<Feature>ViewModel.ets
└── view/<Feature>View.ets
```

只要现有功能的组织方式能够支持正确实现，就保留其既有结构。

## 核心原则

- 在 ViewModel 生命周期内保持 State 根对象及其 `ui`、`domain`、`runtime` 分层对象稳定。
- 现有功能保留其状态管理代际；没有本地证据时默认使用 V2 `@ObservedV2/@Trace`，已有 V1 先例或确认 V2 不可用时，使用 V1 `@Observed/@Track` 配合 `@State` 或 `@ObjectLink`。
- 三个 State 分层中的所有变更都通过 `MVI.reduce` 完成。
- 保持 `Intent.handle` 同步；Intent 读取 State、作出决策并返回最终 Plan。
- 每个 Effect 只承担一个底层动作。Effect 必须实现 `execute()`，不得读取 State、直接 dispatch 或作出业务决策。
- 使用令牌或递增序列拒绝晚于新请求返回的异步结果。
- 高频输入不能在队列中累积时，必须在 dispatch 前同步门控。
- 除非现有工程约定妨碍本次任务的正确行为，否则应予以保留。
- 未经用户明确请求并确认范围与隐私规则，不得引入 MVI Trace、链路记录、回放或可视化。

## 参考资料

| 文件 | 读取时机 |
| --- | --- |
| [`references/architecture-contract.md`](references/architecture-contract.md) | 定义框架职责、dispatch 行为、文件归属或 chain 约束时。 |
| [`references/arkui-state.md`](references/arkui-state.md) | 选择 V1 或 V2 状态观察方案，或排查 UI 刷新失败时。 |
| [`references/async-flow.md`](references/async-flow.md) | 处理 Promise、回调、监听器、并发、过期结果或高频输入时。 |
| [`references/closed-loop-template.md`](references/closed-loop-template.md) | 在没有本地先例时从零构建完整功能。 |
| [`references/trace-extension.md`](references/trace-extension.md) | 仅在用户明确要求 MVI Trace、记录、回放或流程可视化后读取。 |

## Skill 结构

```text
hmos-mvi/
├── SKILL.md                         # Skill 入口与决策工作流
├── agents/openai.yaml               # 智能体展示元数据
├── assets/framework/core/           # 可选框架资源
├── references/                      # 架构、状态、异步、模板与 Trace 契约
├── scripts/                         # 安装、审计与验证命令
└── tests/                           # Core 行为与编译契约测试
```

## 验证

在仓库根目录运行 Skill 契约检查：

```bash
bash scripts/test_hmos_mvi_skill_contract.sh
```

运行内置 Core 行为测试与编译契约测试：

```bash
./scripts/test_mvi_core_behavior.sh
```

该可选资源测试默认使用 DevEco Studio 内置的 TypeScript 编译器，路径为 `/Applications/DevEco-Studio.app/Contents/tools/hvigor/hvigor/node_modules/typescript/lib/tsc.js`。安装或调用本 Skill 不依赖该编译器。

对新生成的功能目录执行只读审计：

```bash
./scripts/audit_hmos_mvi_layout.sh /path/to/new/feature
```

布局审计只报告命名和目录建议，不会阻断现有工程构建。如果存在工程测试或验证命令，应继续运行；如果没有，则明确说明编译和运行时行为尚未验证。

## 许可证

本项目采用 [Apache License 2.0](LICENSE) 许可证。
