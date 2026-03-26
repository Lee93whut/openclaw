# 架构设计文档 - 自动化工作流测试

## 1. 技术选型

### 1.1 测试框架

| 技术 | 选择 | 理由 |
|------|------|------|
| **测试框架** | Jest / Vitest | 成熟的单元测试框架，支持异步测试 |
| **断言库** | 内置断言 | 简单直接，无需额外依赖 |
| **测试运行器** | Node.js 脚本 | 灵活控制测试流程 |
| **日志系统** | console + 文件日志 | 追踪测试过程和结果 |

### 1.2 测试环境

| 组件 | 说明 |
|------|------|
| **测试环境** | OpenClaw 开发环境 |
| **测试数据** | 模拟项目数据（TASKS.md, PRD.md） |
| **验证工具** | 文件读取 + 状态比对 |

### 1.3 测试类型

| 类型 | 说明 |
|------|------|
| **集成测试** | 验证完整工作流程 |
| **状态测试** | 验证任务状态流转 |
| **触发器测试** | 验证自动触发机制 |

---

## 2. 系统架构

### 2.1 测试架构图

```
┌─────────────────────────────────────────────────────────────┐
│                    测试控制中心                              │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │ 测试启动器   │  │ 测试协调器   │  │ 结果报告器          │  │
│  │ (Launcher)  │  │ (Coordinator)│  │ (Reporter)         │  │
│  └─────────────┘  └─────────────┘  └─────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    测试用例层                               │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │ 任务分发测试 │  │ 角色流转测试 │  │ 状态管理测试        │  │
│  └─────────────┘  └─────────────┘  └─────────────────────┘  │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │ 触发器测试   │  │ 异常处理测试 │  │ 完整流程测试        │  │
│  └─────────────┘  └─────────────┘  └─────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    验证引擎层                               │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │ 文件验证器   │  │ 状态验证器   │  │ 触发器验证器        │  │
│  │ (FileCheck)  │  │ (StateCheck) │  │ (TriggerCheck)    │  │
│  └─────────────┘  └─────────────┘  └─────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    被测系统                                 │
│  ┌───────────────────────────────────────────────────────┐  │
│  │ OpenClaw 工作流系统（PM/Agent 通信、状态管理、触发器）│  │
│  └───────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

### 2.2 测试流程

```
测试启动
    │
    ├─→ 初始化测试环境
    │       │
    │       ├─ 创建测试项目
    │       ├─ 准备测试数据
    │       └─ 重置测试状态
    │
    ├─→ 执行测试用例
    │       │
    │       ├─ 阶段1: 任务分发测试
    │       ├─ 阶段2: 角色流转测试
    │       ├─ 阶段3: 状态管理测试
    │       ├─ 阶段4: 触发器测试
    │       └─ 阶段5: 完整流程测试
    │
    ├─→ 收集测试结果
    │       │
    │       ├─ 统计通过/失败
    │       ├─ 记录错误详情
    │       └─ 生成测试报告
    │
    └─→ 清理测试环境
```

---

## 3. 测试模块设计

### 3.1 测试控制中心 (test-controller.js)

```javascript
// 测试主控制模块
export class TestController {
    constructor(config) {
        this.config = config;
        this.testCases = [];
        this.results = [];
    }

    // 初始化测试环境
    async setup() { /* 创建测试项目，准备数据 */ }

    // 运行所有测试
    async runAll() { /* 执行测试用例 */ }

    // 生成测试报告
    async generateReport() { /* 输出测试结果 */ }

    // 清理测试环境
    async cleanup() { /* 删除测试项目，清理数据 */ }
}
```

### 3.2 测试用例模块 (test-cases.js)

```javascript
// 任务分发测试
export async function testTaskDistribution() {
    // 验证 PM 分发任务到 product
    // 检查任务格式、优先级、触发状态
}

// 角色流转测试
export async function testRoleTransition() {
    // 验证 product → architect → developer → qa → writer
    // 检查每个环节的自动触发
}

// 状态管理测试
export async function testStateManagement() {
    // 验证状态流转：待开始 → 处理中 → 已完成
    // 检查当前阶段和下一步角色正确更新
}

// 触发器测试
export async function testTriggerMechanism() {
    // 验证需要触发标志
    // 验证自动触发和手动触发
}
```

### 3.3 验证引擎模块 (verifiers.js)

```javascript
// 文件验证器
export function verifyFileExists(path) { /* 检查文件存在 */ }
export function verifyFileContent(path, expected) { /* 验证文件内容 */ }

// 状态验证器
export function verifyTaskStatus(projectPath, taskName, expectedStatus) {
    // 读取 TASKS.md
    // 解析任务状态
    // 比对预期状态
}

// 触发器验证器
export function verifyTriggerRequired(projectPath, expected) {
    // 验证需要触发标志
}
```

### 3.4 结果报告模块 (reporter.js)

```javascript
// 测试结果报告
export class TestReporter {
    constructor() {
        this.passed = 0;
        this.failed = 0;
        this.errors = [];
    }

    recordPass(testName) { /* 记录通过 */ }
    recordFail(testName, error) { /* 记录失败 */ }

    generateSummary() {
        return {
            total: this.passed + this.failed,
            passed: this.passed,
            failed: this.failed,
            passRate: (this.passed / (this.passed + this.failed) * 100).toFixed(2) + '%'
        };
    }
}
```

---

## 4. 测试用例设计

### 4.1 任务分发测试用例

| 用例ID | 测试项 | 输入 | 预期结果 |
|--------|--------|------|----------|
| TD-01 | PM分发任务 | 项目名称 + 任务描述 | product 收到任务，状态为"待开始" |
| TD-02 | 任务优先级 | 高/中/低优先级 | 优先级正确设置 |
| TD-03 | 任务格式 | 标准格式 | 任务格式符合规范 |

### 4.2 角色流转测试用例

| 用例ID | 测试项 | 前置条件 | 预期结果 |
|--------|--------|----------|----------|
| RT-01 | product→architect | product 完成需求分析 | architect 自动触发 |
| RT-02 | architect→developer | architect 完成架构设计 | developer 自动触发 |
| RT-03 | developer→qa | developer 完成功能开发 | qa 自动触发 |
| RT-04 | qa→writer | qa 完成测试 | writer 自动触发 |

### 4.3 状态管理测试用例

| 用例ID | 测试项 | 操作 | 预期结果 |
|--------|--------|------|----------|
| SM-01 | 状态流转 | 任务开始执行 | 待开始 → 处理中 |
| SM-02 | 状态流转 | 任务执行完成 | 处理中 → 已完成 |
| SM-03 | 阶段切换 | 当前阶段完成 | 当前阶段更新，下一步角色切换 |

### 4.4 触发器测试用例

| 用例ID | 测试项 | 输入 | 预期结果 |
|--------|--------|------|----------|
| TG-01 | 自动触发 | 需要触发=是 | 自动触发下一步 |
| TG-02 | 不触发 | 需要触发=否 | 不自动触发 |
| TG-03 | 手动触发 | 手动触发命令 | 正确触发下一步 |

### 4.5 完整流程测试用例

| 用例ID | 测试项 | 测试范围 | 预期结果 |
|--------|--------|----------|----------|
| E2E-01 | 完整流程 | PM→product→architect→developer→qa→writer | 全流程成功，状态正确 |
| E2E-02 | 中断恢复 | 模拟中断后恢复 | 能够从中断点继续 |

---

## 5. 测试数据设计

### 5.1 测试项目结构

```
test-project-{timestamp}/
├── shared/
│   ├── TASKS.md        # 任务清单
│   ├── PRD.md          # 产品需求文档
│   ├── ARCHITECTURE.md # 架构文档（由 architect 生成）
│   ├── CODE.md         # 代码文档（由 developer 生成）
│   ├── TEST_REPORT.md  # 测试报告（由 qa 生成）
│   └── FINAL_DOC.md    # 最终文档（由 writer 生成）
└── README.md
```

### 5.2 测试数据模板

**TASKS.md 模板:**
```markdown
# 任务清单 - 测试项目

## 工作流状态
当前阶段: {阶段}
下一步角色: {角色}
需要触发: {是/否}

## 任务列表
| 任务 | 负责角色 | 状态 | 需要触发 | 下一步角色 |
|------|----------|------|:--------:|:----------:|
| {任务} | {角色} | {状态} | {是/否} | {下一角色} |
```

**PRD.md 模板:**
```markdown
# PRD - 测试项目

## 项目概述
这是一个测试项目，用于验证工作流自动化。

## 功能需求
1. 验证任务分发
2. 验证角色流转
3. 验证状态管理

## 验收标准
- [ ] 所有测试通过
```

---

## 6. 验证方案

### 6.1 文件验证

```javascript
// 验证文件内容
async function verifyTasksMd(projectPath, expected) {
    const content = await readFile(`${projectPath}/shared/TASKS.md`);

    // 验证当前阶段
    assert(content.includes(`当前阶段: ${expected.currentStage}`));

    // 验证下一步角色
    assert(content.includes(`下一步角色: ${expected.nextRole}`));

    // 验证需要触发
    assert(content.includes(`需要触发: ${expected.triggerRequired}`));

    // 验证任务状态
    for (const task of expected.tasks) {
        assert(content.includes(`| ${task.name} | ${task.role} | ${task.status} |`));
    }
}
```

### 6.2 状态验证

```javascript
// 验证状态流转
async function verifyStateTransition(projectPath, fromRole, toRole) {
    const tasks = await parseTasksMd(projectPath);

    // 验证 fromRole 任务已完成
    const fromTask = tasks.find(t => t.role === fromRole);
    assert(fromTask.status === '已完成');

    // 验证 toRole 任务已触发
    const toTask = tasks.find(t => t.role === toRole);
    assert(toTask.status === '待开始' || toTask.status === '处理中');
}
```

### 6.3 触发器验证

```javascript
// 验证触发器机制
async function verifyTrigger(projectPath, expected) {
    const content = await readFile(`${projectPath}/shared/TASKS.md`);

    // 验证需要触发标志
    const triggerMatch = content.match(/需要触发:\s*(是|否)/);
    assert(triggerMatch[1] === expected);
}
```

---

## 7. 测试执行流程

### 7.1 自动化测试脚本

```javascript
// test-runner.js
import { TestController } from './test-controller.js';
import { testTaskDistribution, testRoleTransition, testStateManagement, testTriggerMechanism } from './test-cases.js';

async function main() {
    const controller = new TestController({
        projectName: `test-project-${Date.now()}`,
        testDir: './test-projects'
    });

    try {
        // 1. 初始化测试环境
        await controller.setup();

        // 2. 执行测试用例
        console.log('开始执行测试...\n');

        await testTaskDistribution(controller);
        await testRoleTransition(controller);
        await testStateManagement(controller);
        await testTriggerMechanism(controller);

        // 3. 生成测试报告
        const report = await controller.generateReport();
        console.log('\n测试完成！');
        console.log(report);

    } catch (error) {
        console.error('测试失败:', error);
    } finally {
        // 4. 清理测试环境
        await controller.cleanup();
    }
}

main();
```

### 7.2 测试执行命令

```bash
# 运行所有测试
npm test

# 运行特定测试
npm test -- --grep "任务分发"

# 查看详细日志
npm test -- --verbose

# 生成测试报告
npm test -- --report
```

---

## 8. 测试报告

### 8.1 报告格式

```markdown
# 自动化工作流测试报告

## 测试概览
- 测试时间: {timestamp}
- 测试项目: {projectName}
- 总用例数: {total}
- 通过数: {passed}
- 失败数: {failed}
- 通过率: {passRate}

## 测试结果

### 任务分发测试
- ✅ TD-01: PM分发任务
- ✅ TD-02: 任务优先级
- ✅ TD-03: 任务格式

### 角色流转测试
- ✅ RT-01: product→architect
- ✅ RT-02: architect→developer
- ✅ RT-03: developer→qa
- ✅ RT-04: qa→writer

### 状态管理测试
- ✅ SM-01: 状态流转（待开始→处理中）
- ✅ SM-02: 状态流转（处理中→已完成）
- ✅ SM-03: 阶段切换

### 触发器测试
- ✅ TG-01: 自动触发
- ✅ TG-02: 不触发
- ✅ TG-03: 手动触发

### 完整流程测试
- ✅ E2E-01: 完整流程
- ⚠️ E2E-02: 中断恢复（跳过）

## 失败详情
（如有失败，列出详细错误信息）

## 建议
（根据测试结果提出改进建议）
```

---

## 9. 异常处理

### 9.1 测试失败处理

| 异常类型 | 处理方式 |
|----------|----------|
| 文件不存在 | 记录错误，继续执行其他测试 |
| 状态不一致 | 记录预期值和实际值，标记失败 |
| 超时 | 设置超时时间，超时后标记失败 |
| 权限错误 | 检查权限，提示用户 |

### 9.2 清理机制

```javascript
// 测试清理
async function cleanup() {
    try {
        // 删除测试项目
        await removeTestProject(testProjectPath);

        // 重置测试状态
        await resetTestState();

        // 清理临时文件
        await cleanTempFiles();
    } catch (error) {
        console.warn('清理失败:', error);
    }
}
```

---

## 10. 性能指标

### 10.1 测试性能要求

| 指标 | 要求 |
|------|------|
| 单个测试用例执行时间 | < 5秒 |
| 完整测试套件执行时间 | < 5分钟 |
| 测试报告生成时间 | < 10秒 |

### 10.2 系统性能验证

| 指标 | 要求 |
|------|------|
| 任务分发响应时间 | < 1秒 |
| 角色流转时间 | < 2秒 |
| 状态更新时间 | < 1秒 |
| 触发器响应时间 | < 2秒 |

---

## 11. 扩展性设计

### 11.1 未来扩展方向

- 支持更多角色类型
- 支持自定义工作流
- 支持并行测试
- 支持测试报告可视化

### 11.2 扩展接口

```javascript
// 自定义测试用例接口
interface TestCase {
    id: string;
    name: string;
    category: string;
    run(): Promise<TestResult>;
}

// 自定义验证器接口
interface Verifier {
    verify(actual: any, expected: any): boolean;
    getMessage(): string;
}
```

---

**架构师**: architect  
**创建日期**: 2026-03-25  
**版本**: v1.0