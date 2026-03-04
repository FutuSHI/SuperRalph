# SuperRalph 开发交接文档

> 本文档记录 SuperRalph 从构思到发布的完整开发历程，供后续维护者参考。

---

## 1. 项目背景

### SuperRalph 是什么

SuperRalph 是 **Superpowers**（开发纪律框架）与 **Ralph Loop**（PRD 驱动的自主执行循环）的深度整合体。它作为一个独立的 Claude Code plugin，将两套体系的核心能力融合成一个统一的状态机工作流。

用一句话描述：**一个 plugin 顶两个，装一个就能获得完整的开发纪律 + 自主执行能力。**

### 为什么要做

市面上已有的方案（如 claude5-starter-kit）本质上是"打包安装"——把 Superpowers 和 Ralph Loop 分别安装，然后让用户自己协调两者的使用。这种方案存在几个问题：

1. **状态割裂**：两个插件各自管理状态，没有统一的生命周期
2. **纪律缺失**：Ralph Loop 的自主迭代过程中，Superpowers 的 TDD、验证、审查纪律无法自动注入
3. **用户心智负担**：需要手动判断何时用哪个工具，命令分散在两个插件中
4. **上下文浪费**：两套 CLAUDE.md 消耗宝贵的上下文窗口

### 核心价值

| 维度 | 分别安装 | SuperRalph |
|------|---------|-------------|
| 安装 | 两个插件 + 配置 | 一条命令 |
| 状态 | 各自独立 | 统一状态机 |
| 纪律注入 | 手动协调 | 每次迭代自动注入 |
| 入口命令 | 分散 | 7 个统一命令 |
| Web 项目 | 手动配置 | 自动检测 |

---

## 2. 架构设计

### 状态机架构

SuperRalph 的核心是一个 4 阶段状态机：

```
idle → think → plan → run → finish → idle
                        ↕
                      debug (可在任何阶段触发)
                      cancel (可在 run 阶段触发)
```

每个阶段对应一个 skill 命令：

- **THINK**（`/think`）：交互式头脑风暴，产出设计文档 + PRD
- **PLAN**（`/plan`）：将 PRD 转换为可执行的 `prd.json`
- **RUN**（`/run`）：自主执行循环，逐个实现 user story
- **FINISH**（`/finish`）：验证、总结、合并/PR

`/superRalph` 是全流程编排器，串联四个阶段自动执行。

### 文件结构概览

```
SuperRalph/
├── .claude-plugin/          # 插件元数据
│   ├── plugin.json          #   插件定义（名称、版本、作者）
│   └── marketplace.json     #   marketplace 发布配置
├── skills/                  # 7 个 skill（用户可直接调用的命令）
│   ├── super-ralph/SKILL.md #   /superRalph — 全流程编排
│   ├── think/SKILL.md       #   /think — 头脑风暴 + PRD
│   ├── plan/SKILL.md        #   /plan — PRD → prd.json
│   ├── run/SKILL.md         #   /run — 启动执行循环
│   ├── finish/SKILL.md      #   /finish — 收尾合并
│   ├── debug/SKILL.md       #   /debug — 系统化调试
│   └── cancel/SKILL.md      #   /cancel — 终止循环
├── disciplines/             # 5 个纪律模块（被注入到每次迭代中）
│   ├── tdd.md               #   TDD 红绿重构纪律
│   ├── verification.md      #   验证纪律（无证据不完成）
│   ├── two-stage-review.md  #   两阶段审查纪律
│   ├── debugging.md         #   系统化调试纪律
│   └── web-enhance.md       #   Web 项目增强（条件加载）
├── scripts/
│   └── ralph.sh             # bash-loop 执行引擎
├── hooks/
│   ├── hooks.json           # hook 注册配置
│   ├── session-start.sh     # 会话启动时显示活跃状态
│   └── stop-hook.sh         # hook-loop 的迭代控制器
├── templates/
│   ├── CLAUDE.md.template   # 每次迭代的指令模板（含纪律占位符）
│   ├── prd.json.example     # prd.json 示例文件
│   └── progress.txt.template # 进度日志模板
├── CLAUDE.md                # 插件级指令（命令路由表）
├── README.md                # 用户面文档
└── .gitignore               # 忽略运行时状态和用户文件
```

### 两种执行模式

#### bash-loop（主力模式）

由 `scripts/ralph.sh` 驱动。每次迭代：

1. 从 `CLAUDE.md.template` 构建指令文件
2. 将 5 个纪律模块的内容注入到占位符位置
3. 检测 Web 项目类型，条件注入 web-enhance 纪律
4. 调用 `claude --dangerously-skip-permissions --print` 执行一次迭代
5. 检查输出中的 `<promise>COMPLETE</promise>` 信号
6. 未完成则继续下一轮迭代

**优势**：每轮迭代有完整的上下文窗口，story 之间零污染，可无人值守运行。

#### hook-loop（轻量模式）

由 `hooks/stop-hook.sh` 驱动。利用 Claude Code 的 Stop hook 机制：

1. Claude 完成一个 story 后准备退出
2. stop-hook 拦截退出信号
3. 检查 `superralph-state.json` 是否仍在 run 阶段
4. 如果还有未完成的 story，注入下一轮迭代的 prompt，阻止退出
5. 直到所有 story 完成或达到最大迭代次数

**优势**：无需额外终端，实时可见，适合 1-2 个 story 的快速迭代。

### 三层记忆体系

自主执行循环最大的挑战是**跨迭代记忆**。每轮迭代是一个全新的上下文窗口，不知道前面发生了什么。SuperRalph 通过三层文件系统持久化解决这个问题：

| 层 | 文件 | 内容 | 作用 |
|----|------|------|------|
| 任务状态 | `tasks/prd.json` | story 列表 + passes 状态 | 知道做什么、做到哪了 |
| 经验日志 | `tasks/progress.txt` | 每轮迭代的学习和发现 | 避免重复犯错，积累模式 |
| 架构决策 | `docs/plans/*-design.md` | 设计文档 | 保持架构一致性 |

每轮迭代开始时，先读这三个文件，再开始工作。

### 5 个纪律模块如何被注入

纪律模块不是 skill（不能被用户直接调用），而是**被注入到每次迭代的指令中**。注入机制如下：

1. `templates/CLAUDE.md.template` 包含占位符：`{TDD_DISCIPLINE}`、`{VERIFICATION_DISCIPLINE}` 等
2. `ralph.sh` 的 `build_instructions()` 函数用 `replace_placeholder()` 将占位符替换为 discipline 文件的完整内容
3. Web 纪律（`{WEB_DISCIPLINE}`）是条件注入的——只在检测到 Web 项目时才替换，否则删除占位符
4. 最终生成的指令文件包含所有适用纪律的完整文本

这种设计的好处：
- 纪律内容可以独立维护和更新
- 用户不需要手动激活纪律
- Web 纪律按需加载，非 Web 项目零噪音

---

## 3. 开发过程记录

### 需求梳理阶段

使用了 Superpowers 的 **brainstorming skill** 进行需求梳理。通过交互式问答，明确了以下核心需求：

- 深度整合 Superpowers + Ralph Loop，不是简单打包
- 一个 plugin 解决所有问题，零外部依赖
- 状态机驱动的工作流，而非松散的命令集合
- 纪律模块自动注入到自主执行循环中

### 实现阶段

使用了 **subagent-driven-development** 进行实现。项目被分解为 18 个 task，通过 subagent 并行执行完成：

1. 项目脚手架搭建（`.claude-plugin/` 结构）
2. prd.json 示例 + progress 模板 + CLAUDE.md 迭代模板
3. TDD 纪律模块
4. 模板文件更新以匹配规格
5. 验证纪律模块
6. 两阶段审查纪律模块
7. 系统化调试纪律模块
8. Web 增强条件纪律模块
9. hook-loop 引擎（stop hook + session start）
10. bash-loop 执行引擎（含纪律注入）
11. `/superRalph` 全流程编排 skill
12. `/think` 头脑风暴 skill
13. `/plan` PRD 转换 skill
14. `/run` 执行启动 skill
15. `/finish` 收尾合并 skill
16. `/debug` 系统化调试 skill
17. `/cancel` 终止循环 skill
18. 插件级 CLAUDE.md（命令路由）
19. marketplace.json（发布配置）
20. 作者更新 + 安装指令修正 + .gitignore

### 从设计到完成的流程

```
构思（brainstorming）
  → 需求文档（PRD）
  → 架构设计（3 个方案对比）
  → 方案 B（状态机架构）胜出
  → task 分解（18+ tasks）
  → subagent 并行实现
  → 集成测试
  → 文档编写
  → 发布到 GitHub
```

---

## 4. 关键设计决策

### 为什么选择状态机架构（方案 B）

在设计阶段，对比了三种架构方案：

| 方案 | 描述 | 问题 |
|------|------|------|
| A. 线性管道 | 简单的 think → plan → run → finish 管道 | 无法处理中途失败、无法跳转、无法恢复 |
| B. 状态机 | 带明确状态转换的有限状态机 | （胜出） |
| C. 分层架构 | 底层引擎 + 中间层协调 + 上层 skill | 过度工程化，增加复杂度但收益有限 |

**选择方案 B 的理由**：

1. **可恢复性**：状态持久化到文件，进程崩溃后可从上次状态恢复
2. **灵活性**：用户可以从任何阶段开始（已有 PRD 可直接 `/plan`，已有 prd.json 可直接 `/run`）
3. **可调试性**：状态转换明确，可以通过 `superralph-state.json` 看到当前状态
4. **简洁性**：比分层架构少很多代码，但功能一样完整

### 为什么 13 个 Superpowers skill 精简为 6 个核心模块

Superpowers 原有 13 个 skill，但许多是重叠或可合并的。精简原则：

- **Skill（用户可调用的命令）**：保留直接面向用户的操作入口，共 7 个
- **Discipline（被注入的纪律规则）**：提取为独立模块，共 5 个
- 去掉了重复或边界不清的 skill
- 将通用规则（如 TDD、验证）从 skill 中抽离，变成每次迭代自动注入的纪律

**核心 7 个 skill**：superRalph、think、plan、run、finish、debug、cancel

**核心 5 个 discipline**：tdd、verification、two-stage-review、debugging、web-enhance

### 为什么 bash-loop 是默认模式

两种模式对比：

| 维度 | bash-loop | hook-loop |
|------|-----------|-----------|
| 上下文隔离 | 每轮全新窗口 | 共享窗口 |
| 纪律注入 | 完整注入 | 简化版 prompt |
| 适合 story 数 | 3+ | 1-2 |
| 无人值守 | 支持 | 不支持 |
| 上下文溢出风险 | 无 | 多 story 时有风险 |

bash-loop 作为默认推荐，因为大部分真实场景涉及 3 个以上 story。每轮迭代有完整上下文窗口意味着纪律规则可以完整注入，不会因为上下文膨胀而被截断。

### 为什么 discipline 模块独立于 skill

这是一个关键的架构决策。纪律模块**不是 skill**，不能被用户通过 `/tdd` 这样的命令直接调用。原因：

1. **纪律是约束，不是操作**：TDD 不是"一个你执行的动作"，而是"你做任何事时都必须遵循的规则"
2. **自动注入比手动调用更可靠**：如果纪律是 skill，用户可能忘记调用；作为注入模块，每次迭代自动生效
3. **减少命令膨胀**：用户只需要记 7 个命令，而不是 12 个
4. **模板化注入**：通过占位符机制（`{TDD_DISCIPLINE}` → 文件内容替换），纪律可以独立更新，不影响 skill 逻辑

---

## 5. 文件清单和用途

共 24 个文件（含 README.md 和 .gitignore）：

### 插件元数据（2 个）

| 文件 | 用途 |
|------|------|
| `.claude-plugin/plugin.json` | 插件定义：名称 `superralph`、版本 `1.0.0`、作者 `FutuSHI`、MIT 许可 |
| `.claude-plugin/marketplace.json` | Marketplace 发布配置：分类 `productivity`、关键词、skill 目录指向 |

### Skill 命令（7 个）

| 文件 | 命令 | 用途 |
|------|------|------|
| `skills/super-ralph/SKILL.md` | `/superRalph` | 全流程编排器：THINK → PLAN → RUN → FINISH 四阶段自动串联 |
| `skills/think/SKILL.md` | `/think` | 头脑风暴 + 需求分析 + 设计文档 + PRD 生成 |
| `skills/plan/SKILL.md` | `/plan` | 将 PRD markdown 转换为可执行的 `prd.json`（含粒度拆分、依赖排序、验收标准增强） |
| `skills/run/SKILL.md` | `/run` | 启动自主执行循环，选择 bash-loop 或 hook-loop 模式 |
| `skills/finish/SKILL.md` | `/finish` | 最终验证 + 摘要展示 + 4 选项（merge/PR/keep/discard） |
| `skills/debug/SKILL.md` | `/debug` | 系统化 4 阶段调试：根因调查 → 模式分析 → 假设验证 → 实现修复 |
| `skills/cancel/SKILL.md` | `/cancel` | 安全终止执行循环，保留所有已完成工作 |

### 纪律模块（5 个）

| 文件 | 用途 |
|------|------|
| `disciplines/tdd.md` | TDD 红绿重构纪律：先写失败测试，再写最小实现，最后重构。代码先于测试 = 删除重来 |
| `disciplines/verification.md` | 验证纪律：5 步验证门控，无证据不标记完成。禁止 "should work" 等模糊表述 |
| `disciplines/two-stage-review.md` | 两阶段审查：第一阶段检查规格符合性（不多不少），第二阶段检查代码质量 |
| `disciplines/debugging.md` | 系统化调试：4 阶段（根因调查 → 模式分析 → 假设验证 → 实现修复）+ 3 次修复规则 |
| `disciplines/web-enhance.md` | Web 项目增强：条件加载，自动检测 Web 框架，UI story 需浏览器验证 |

### 执行引擎（3 个）

| 文件 | 用途 |
|------|------|
| `scripts/ralph.sh` | bash-loop 执行引擎：参数解析、Web 项目检测、纪律注入（占位符替换）、迭代循环、完成信号检测、归档机制 |
| `hooks/stop-hook.sh` | hook-loop 迭代控制器：拦截 Claude 退出信号，检查 story 完成状态，未完成则注入下一轮 prompt |
| `hooks/session-start.sh` | 会话启动 hook：检测活跃的 SuperRalph 会话并显示状态信息 |

### 配置和模板（4 个）

| 文件 | 用途 |
|------|------|
| `hooks/hooks.json` | Hook 注册配置：将 SessionStart 和 Stop 事件绑定到对应的 shell 脚本 |
| `templates/CLAUDE.md.template` | 每次迭代的指令模板：包含纪律占位符 `{TDD_DISCIPLINE}` 等，由 ralph.sh 在构建时替换 |
| `templates/prd.json.example` | prd.json 格式示例：展示标准的 user story 结构（含 ID、标题、验收标准、passes 状态） |
| `templates/progress.txt.template` | 进度日志模板：包含日期、功能名、设计文档链接、模式积累区域 |

### 项目文件（3 个）

| 文件 | 用途 |
|------|------|
| `CLAUDE.md` | 插件级指令文件：命令路由表 + 何时触发哪个 skill 的规则 + 核心纪律概要 + 状态和模式说明 |
| `README.md` | 用户面文档：安装、快速开始、命令列表、工作原理、模式对比、差异化价值 |
| `.gitignore` | 忽略规则：运行时状态文件、用户项目文件、OS 文件 |

---

## 6. 发布信息

### GitHub 仓库

**地址**：[https://github.com/FutuSHI/SuperRalph](https://github.com/FutuSHI/SuperRalph)

### 安装命令

在 Claude Code 中执行：

```bash
/plugin marketplace add FutuSHI/SuperRalph
/plugin install superralph@superralph
```

无外部依赖，无需额外配置。

### 本地开发

#### 源码路径

克隆仓库后，源码结构即为上文描述的目录结构。

#### 关键路径

| 路径 | 说明 |
|------|------|
| `~/.claude/plugins/superralph/` | 插件安装目录（通过 marketplace 安装后） |
| `.claude/superralph-state.json` | 运行时状态文件（在用户项目目录下生成） |
| `.claude/superralph-instructions.md` | 临时指令文件（由 ralph.sh 生成，进程退出时清理） |
| `tasks/prd.json` | 用户项目的执行计划 |
| `tasks/progress.txt` | 用户项目的进度日志 |
| `.superralph/.last-branch` | 上次运行的分支名（用于归档检测） |

#### 本地开发与测试

1. 克隆仓库：`git clone https://github.com/FutuSHI/SuperRalph.git`
2. 在 Claude Code 中注册本地路径进行测试
3. 修改 skill 或 discipline 文件后，重新启动 Claude Code 会话即可生效
4. `ralph.sh` 每次迭代都会重新读取模板和纪律文件，因此修改 discipline 后无需重启 bash-loop

---

## 7. 后续迭代方向（建议）

### 可以加入的功能

#### Parallel Agents 支持

当前 `/run` 是串行执行 story 的。如果 story 之间没有依赖关系，理论上可以并行执行多个 story：

- 分析 prd.json 中 story 的依赖图
- 无依赖的 story 可以并行分配给多个 subagent
- 需要解决并发 git 操作的冲突问题

#### Worktree 支持

结合 Claude Code 的 worktree 功能，每个 story 可以在独立的 git worktree 中执行，避免分支冲突：

- 每个 story 创建独立 worktree
- 完成后合并回主功能分支
- 适合大型项目的并行开发

#### 自定义 Discipline

允许用户定义自己的纪律模块：

- 在用户项目中创建 `.superralph/disciplines/` 目录
- `ralph.sh` 在构建指令时扫描并注入用户自定义纪律
- 可用于注入团队特定的编码规范、安全检查等

### 可以优化的地方

#### ralph.sh 的错误处理

当前 `ralph.sh` 的错误处理比较简单：

- `set -e` 在管道中可能导致意外退出，考虑改为更精细的错误处理
- Claude 进程超时或异常退出时，应有更好的恢复机制
- 考虑加入重试逻辑：如果某次迭代因为 API 错误（非逻辑错误）失败，自动重试
- 考虑加入日志文件：将每次迭代的输出保存到 `.superralph/logs/` 目录

#### hook-loop 的纪律注入方式

当前 hook-loop 模式中，纪律是通过简化版的 prompt 文本注入的（在 `stop-hook.sh` 中硬编码），而不是像 bash-loop 那样从文件中读取完整内容。这导致：

- hook-loop 和 bash-loop 的纪律内容不同步
- 修改 discipline 文件后，hook-loop 不会自动更新

建议：让 `stop-hook.sh` 也读取 discipline 文件并构建完整的指令，或者使用和 `ralph.sh` 相同的 `build_instructions()` 机制。

#### 迭代报告可视化

- 在 `progress.txt` 中加入结构化数据（如 JSON 片段），方便后续工具解析
- 考虑生成 HTML 格式的迭代报告

### 社区相关

#### 发布到 awesome-claude-skills

- 仓库地址：`awesome-claude-code` 或类似的社区列表
- 提交 PR，附上简短描述和安装命令

#### 提交到 claude-plugins-official

- 如果 Anthropic 推出官方插件目录，考虑提交审核
- 确保遵循官方插件规范

#### 文档国际化

- 当前 README.md 为英文
- 考虑加入中文 README（`README.zh-CN.md`）
- 可能对中文开发者社区推广有帮助

---

## 附录：状态文件格式参考

### .claude/superralph-state.json

```json
{
  "phase": "think|plan|run|finish|idle",
  "feature": "<feature-name>",
  "branchName": "superralph/<feature-name>",
  "designDoc": "docs/plans/YYYY-MM-DD-<feature>-design.md",
  "prdFile": "tasks/prd-<feature>.md",
  "prdJson": "tasks/prd.json",
  "runMode": "bash-loop|hook-loop",
  "iteration": 0,
  "maxIterations": 20,
  "completionPromise": "COMPLETE",
  "startedAt": "<ISO timestamp>",
  "webProject": false
}
```

### tasks/prd.json

```json
{
  "project": "<project name>",
  "branchName": "superralph/<feature-kebab>",
  "description": "<feature description>",
  "designDoc": "<path to design doc>",
  "userStories": [
    {
      "id": "US-001",
      "title": "<title>",
      "description": "As a <user>, I want <feature> so that <benefit>",
      "acceptanceCriteria": ["criterion 1", "criterion 2"],
      "priority": 1,
      "passes": false,
      "notes": ""
    }
  ]
}
```
