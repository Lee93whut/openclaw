# 架构设计文档 - 测试项目

## 1. 技术选型

### 1.1 测试框架

| 技术 | 选择 | 理由 |
|------|------|------|
| **测试框架** | Jest | 成熟的JavaScript测试框架，支持异步测试 |
| **断言库** | Jest内置 | 简洁的断言语法，无需额外配置 |
| **文件系统** | Node.js fs | 读取和验证 TASKS.md、PRD.md 等文件 |
| **日志记录** | console + 文件 | 记录测试过程和结果 |

### 1.2 验证工具

| 工具 | 用途 |
|------|------|
| **文件解析器** | 解析 TASKS.md、PRD.md 文件内容 |
| **状态比对器** | 比对预期状态与实际状态 |
| **断言验证** | 验证文件内容和状态一致性 |

### 1.3 测试环境

| 组件 | 说明 |
|------|------|
| **测试环境** | OpenClaw 工作流系统 |
| **测试数据** | 真实项目数据（TASKS.md, PRD.md） |
| **验证方式** | 文件读取 + 内容验证 |

---

## 2. 系统架构

### 2.1 测试架构图

```
┌─────────────────────────────────────────────────────────────┐
│                    测试管理层                               │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │ 测试启动器   │  │ 结果收集器   │  │ 报告生成器          │  │
│  └─────────────┘  └─────────────┘  └─────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    测试执行层                               │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │ 分发测试     │  │ 流转测试     │  │ 状态测试            │  │
│  └─────────────┘  └─────────────┘  └─────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    验证层                                   │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │ 文件验证     │  │ 状态验证     │  │ 内容验证            │  │
│  └─────────────┘  └─────────────┘  └─────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    被测系统                                 │
│  ┌───────────────────────────────────────────────────────┐  │
│  │ OpenClaw 工作流系统（任务分发、状态管理、触发器）      │  │
│  └───────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

### 2.2 测试流程

```
测试开始
    │
    ├─→ 读取项目文件
    │       ├─ TASKS.md
    │       └─ PRD.md
    │
    ├─→ 执行测试用例
    │       ├─ 任务分发测试
    │       ├─ 角色流转测试
    │       └─ 状态管理测试
    │
    ├─→ 收集测试结果
    │       ├─ 统计通过/失败
    │       └─ 记录错误信息
    │
    └─→ 生成测试报告
```

---

## 3. 核心模块设计

### 3.1 测试启动器 (test-launcher.js)

```javascript
/**
 * 测试启动器
 */
export class TestLauncher {
    constructor(projectPath) {
        this.projectPath = projectPath;
        this.results = [];
    }

    /**
     * 读取项目文件
     */
    async loadProjectFiles() {
        const tasksMd = await this.readFile('shared/TASKS.md');
        const prdMd = await this.readFile('shared/PRD.md');
        return { tasksMd, prdMd };
    }

    /**
     * 执行测试
     */
    async run() {
        const files = await this.loadProjectFiles();
        // 执行测试用例
        return this.results;
    }
}
```

### 3.2 状态验证器 (state-verifier.js)

```javascript
/**
 * 状态验证器
 */
export class StateVerifier {
    /**
     * 解析 TASKS.md
     */
    parseTasksMd(content) {
        return {
            currentStage: this.extractCurrentStage(content),
            nextRole: this.extractNextRole(content),
            triggerRequired: this.extractTriggerRequired(content),
            tasks: this.extractTasks(content)
        };
    }

    /**
     * 验证任务状态
     */
    verifyTaskStatus(tasks, roleName, expectedStatus) {
        const task = tasks.find(t => t.role === roleName);
        return task && task.status === expectedStatus;
    }

    /**
     * 提取当前阶段
     */
    extractCurrentStage(content) {
        const match = content.match(/当前阶段:\s*(.+)/);
        return match ? match[1].trim() : null;
    }
}
```

### 3.3 结果收集器 (result-collector.js)

```javascript
/**
 * 结果收集器
 */
export class ResultCollector {
    constructor() {
        this.passed = 0;
        this.failed = 0;
        this.results = [];
    }

    record(testId, testName, passed, error = null) {
        this.results.push({ testId, testName, passed, error });
        passed ? this.passed++ : this.failed++;
    }

    getSummary() {
        return {
            total: this.passed + this.failed,
            passed: this.passed,
            failed: this.failed,
            passRate: ((this.passed / (this.passed + this.failed)) * 100).toFixed(2) + '%'
        };
    }
}
```

---

## 4. 测试用例设计

### 4.1 任务分发测试

| 用例ID | 测试项 | 验证内容 |
|--------|--------|----------|
| TD-001 | 任务格式 | TASKS.md 文件格式正确 |
| TD-002 | 任务状态 | 需求分析任务状态为"已完成" |
| TD-003 | 阶段状态 | 当前阶段为"架构设计" |

```javascript
/**
 * 测试用例: 任务分发
 */
export async function testTaskDistribution(projectPath) {
    const content = await readFile(`${projectPath}/shared/TASKS.md`);
    
    // 验证文件存在
    assert(content !== null, 'TASKS.md 文件存在');
    
    // 验证任务格式
    assert(content.includes('| 需求分析 | product |'), '任务格式正确');
    
    // 验证任务状态
    assert(content.includes('| 需求分析 | product | 已完成 |'), '需求分析任务已完成');
}
```

### 4.2 角色流转测试

| 用例ID | 测试项 | 验证内容 |
|--------|--------|----------|
| RT-001 | 流转方向 | product → architect 流转正确 |
| RT-002 | 下一步角色 | 下一步角色为 architect |
| RT-003 | 触发标志 | 需要触发标志正确 |

```javascript
/**
 * 测试用例: 角色流转
 */
export async function testRoleTransition(projectPath) {
    const content = await readFile(`${projectPath}/shared/TASKS.md`);
    
    // 验证下一步角色
    assert(content.includes('下一步角色: architect'), '下一步角色正确');
    
    // 验证当前阶段
    assert(content.includes('当前阶段: 架构设计'), '当前阶段正确');
}
```

### 4.3 状态管理测试

| 用例ID | 测试项 | 验证内容 |
|--------|--------|----------|
| SM-001 | 状态流转 | 任务状态正确流转 |
| SM-002 | 阶段更新 | 当前阶段正确更新 |
| SM-003 | 角色切换 | 下一步角色正确切换 |

```javascript
/**
 * 测试用例: 状态管理
 */
export async function testStateManagement(projectPath) {
    const content = await readFile(`${projectPath}/shared/TASKS.md`);
    const verifier = new StateVerifier();
    const state = verifier.parseTasksMd(content);
    
    // 验证当前阶段
    assert(state.currentStage === '架构设计', '当前阶段为架构设计');
    
    // 验证下一步角色
    assert(state.nextRole === 'architect', '下一步角色为architect');
    
    // 验证任务列表
    assert(state.tasks.length > 0, '任务列表不为空');
}
```

---

## 5. 验证方案

### 5.1 文件验证

```javascript
/**
 * 文件验证
 */
export async function verifyFiles(projectPath) {
    const results = [];
    
    // 验证 TASKS.md 存在
    const tasksExists = await fileExists(`${projectPath}/shared/TASKS.md`);
    results.push({ test: 'TASKS.md存在', passed: tasksExists });
    
    // 验证 PRD.md 存在
    const prdExists = await fileExists(`${projectPath}/shared/PRD.md`);
    results.push({ test: 'PRD.md存在', passed: prdExists });
    
    return results;
}
```

### 5.2 内容验证

```javascript
/**
 * 内容验证
 */
export async function verifyContent(projectPath) {
    const tasksMd = await readFile(`${projectPath}/shared/TASKS.md`);
    const results = [];
    
    // 验证工作流状态部分
    results.push({
        test: '包含工作流状态',
        passed: tasksMd.includes('工作流状态')
    });
    
    // 验证任务列表部分
    results.push({
        test: '包含任务列表',
        passed: tasksMd.includes('任务列表')
    });
    
    // 验证需求分析任务
    results.push({
        test: '需求分析任务已完成',
        passed: tasksMd.includes('| 需求分析 | product | 已完成 |')
    });
    
    return results;
}
```

---

## 6. 测试执行

### 6.1 测试脚本 (run-tests.js)

```javascript
import { TestLauncher } from './test-launcher.js';
import { ResultCollector } from './result-collector.js';
import { testTaskDistribution, testRoleTransition, testStateManagement } from './test-cases.js';

async function main() {
    const projectPath = process.env.PROJECT_PATH || './';
    const launcher = new TestLauncher(projectPath);
    const collector = new ResultCollector();

    console.log('🚀 开始测试工作流系统...\n');

    try {
        // 执行测试用例
        await testTaskDistribution(projectPath, collector);
        await testRoleTransition(projectPath, collector);
        await testStateManagement(projectPath, collector);

        // 输出结果
        const summary = collector.getSummary();
        console.log('\n📊 测试结果:');
        console.log(`- 总用例数: ${summary.total}`);
        console.log(`- 通过数: ${summary.passed}`);
        console.log(`- 失败数: ${summary.failed}`);
        console.log(`- 通过率: ${summary.passRate}`);

    } catch (error) {
        console.error('❌ 测试失败:', error);
    }
}

main();
```

### 6.2 测试命令

```bash
# 运行测试
npm test

# 指定项目路径
PROJECT_PATH=/path/to/project npm test
```

---

## 7. 测试报告

### 7.1 报告格式

```markdown
# 测试报告

## 测试概览
- 测试时间: 2026-03-25
- 项目: fix-test-20260325-202928
- 总用例数: 3
- 通过数: 3
- 失败数: 0
- 通过率: 100.00%

## 测试结果

### 任务分发测试
- ✅ TD-001: 任务格式验证
- ✅ TD-002: 任务状态验证
- ✅ TD-003: 阶段状态验证

### 角色流转测试
- ✅ RT-001: 流转方向验证
- ✅ RT-002: 下一步角色验证
- ✅ RT-003: 触发标志验证

### 状态管理测试
- ✅ SM-001: 状态流转验证
- ✅ SM-002: 阶段更新验证
- ✅ SM-003: 角色切换验证

## 结论
所有测试通过，工作流系统运行正常。
```

---

## 8. 性能指标

### 8.1 测试性能要求

| 指标 | 要求 |
|------|------|
| 单个测试用例执行时间 | < 1秒 |
| 完整测试套件执行时间 | < 10秒 |
| 测试报告生成时间 | < 2秒 |

### 8.2 系统性能验证

| 指标 | 要求 |
|------|------|
| 任务分发响应时间 | < 1秒 |
| 状态更新时间 | < 1秒 |

---

## 9. 项目结构

```
fix-test-20260325-202928/
├── shared/
│   ├── TASKS.md           # 任务清单
│   ├── PRD.md             # 产品需求文档
│   └── ARCHITECTURE.md    # 架构设计文档
└── tests/                 # 测试目录（可选）
    ├── test-launcher.js
    ├── state-verifier.js
    ├── result-collector.js
    └── run-tests.js
```

---

## 10. 工作流说明

### 10.1 工作流程

```
product（需求分析）→ architect（架构设计）
```

### 10.2 阶段说明

| 阶段 | 角色 | 状态 |
|------|------|------|
| 需求分析 | product | ✅ 已完成 |
| 架构设计 | architect | 待开始 → 进行中 |

### 10.3 下一步

架构设计完成后，项目即可结束（下一步角色为"无"）。

---

**架构师**: architect  
**创建日期**: 2026-03-25  
**版本**: v1.0  
**项目**: fix-test-20260325-202928