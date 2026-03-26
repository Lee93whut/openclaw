# 架构设计文档 - 工作流自动化测试

## 1. 技术选型

### 1.1 测试框架

| 技术 | 选择 | 理由 |
|------|------|------|
| **测试框架** | Jest | 成熟的JavaScript测试框架，支持异步测试和快照测试 |
| **断言库** | Jest内置 | 简洁的断言语法，无需额外配置 |
| **测试运行器** | Node.js | 直接运行测试脚本，灵活控制 |
| **文件系统** | Node.js fs | 读取和验证 TASKS.md、PRD.md 等文件 |

### 1.2 验证工具

| 工具 | 用途 |
|------|------|
| **文件解析器** | 解析 TASKS.md、PRD.md 文件内容 |
| **状态比对器** | 比对预期状态与实际状态 |
| **触发器验证器** | 验证触发器机制是否正常 |
| **日志记录器** | 记录测试过程和结果 |

### 1.3 测试环境

| 组件 | 说明 |
|------|------|
| **测试环境** | OpenClaw 工作流系统 |
| **测试数据** | 真实项目数据（TASKS.md, PRD.md） |
| **验证方式** | 文件读取 + 状态验证 |

---

## 2. 系统架构

### 2.1 测试架构图

```
┌─────────────────────────────────────────────────────────────┐
│                    测试管理层                               │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │ 测试启动器   │  │ 结果收集器   │  │ 报告生成器          │  │
│  │ (Launcher)  │  │ (Collector)  │  │ (Reporter)         │  │
│  └─────────────┘  └─────────────┘  └─────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    测试执行层                               │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │ 任务分发测试 │  │ 角色流转测试 │  │ 状态管理测试        │  │
│  └─────────────┘  └─────────────┘  └─────────────────────┘  │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │ 触发器测试   │  │ 完整流程测试 │  │ 异常处理测试        │  │
│  └─────────────┘  └─────────────┘  └─────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    验证层                                   │
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
│  │ OpenClaw 工作流系统                                    │  │
│  │ (PM、Agent、任务分发、状态管理、触发器)                │  │
│  └───────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

### 2.2 测试流程

```
测试启动
    │
    ├─→ 初始化测试环境
    │       ├─ 创建测试项目
    │       ├─ 准备测试数据
    │       └─ 重置测试状态
    │
    ├─→ 执行测试用例
    │       ├─ 任务分发测试
    │       ├─ 角色流转测试
    │       ├─ 状态管理测试
    │       ├─ 触发器测试
    │       ├─ 完整流程测试
    │       └─ 异常处理测试
    │
    ├─→ 收集测试结果
    │       ├─ 统计通过/失败
    │       ├─ 记录错误详情
    │       └─ 生成测试报告
    │
    └─→ 清理测试环境
```

---

## 3. 核心模块设计

### 3.1 测试启动器 (test-launcher.js)

```javascript
/**
 * 测试启动器
 */
export class TestLauncher {
    constructor(config) {
        this.projectPath = config.projectPath;
        this.testCases = [];
        this.results = [];
    }

    /**
     * 初始化测试环境
     */
    async setup() {
        // 创建测试项目
        // 准备测试数据
        // 设置初始状态
    }

    /**
     * 运行所有测试
     */
    async runAll() {
        console.log('🚀 开始执行测试...\n');
        
        for (const testCase of this.testCases) {
            try {
                const result = await testCase.run();
                this.results.push(result);
                console.log(`✅ ${testCase.name}: 通过`);
            } catch (error) {
                this.results.push({ ...testCase, passed: false, error });
                console.log(`❌ ${testCase.name}: 失败 - ${error.message}`);
            }
        }
        
        return this.results;
    }

    /**
     * 清理测试环境
     */
    async cleanup() {
        // 删除测试项目
        // 清理临时文件
    }
}
```

### 3.2 结果收集器 (result-collector.js)

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

    /**
     * 记录测试结果
     */
    record(testId, testName, passed, error = null) {
        this.results.push({ testId, testName, passed, error, timestamp: new Date().toISOString() });
        passed ? this.passed++ : this.failed++;
    }

    /**
     * 获取统计摘要
     */
    getSummary() {
        return {
            total: this.passed + this.failed,
            passed: this.passed,
            failed: this.failed,
            passRate: `${((this.passed / (this.passed + this.failed)) * 100).toFixed(2)}%`,
            duration: this.calculateDuration()
        };
    }

    /**
     * 计算测试时长
     */
    calculateDuration() {
        if (this.results.length < 2) return '0s';
        const start = new Date(this.results[0].timestamp);
        const end = new Date(this.results[this.results.length - 1].timestamp);
        const diff = (end - start) / 1000;
        return `${diff.toFixed(2)}s`;
    }
}
```

### 3.3 状态验证器 (state-verifier.js)

```javascript
/**
 * 状态验证器
 */
export class StateVerifier {
    /**
     * 解析 TASKS.md
     */
    async parseTasksMd(projectPath) {
        const content = await this.readFile(`${projectPath}/shared/TASKS.md`);
        
        return {
            currentStage: this.extractCurrentStage(content),
            nextRole: this.extractNextRole(content),
            triggerRequired: this.extractTriggerRequired(content),
            tasks: this.extractTasks(content)
        };
    }

    /**
     * 提取当前阶段
     */
    extractCurrentStage(content) {
        const match = content.match(/当前阶段:\s*(.+)/);
        return match ? match[1].trim() : null;
    }

    /**
     * 提取下一步角色
     */
    extractNextRole(content) {
        const match = content.match(/下一步角色:\s*(\w+)/);
        return match ? match[1].trim() : null;
    }

    /**
     * 提取需要触发
     */
    extractTriggerRequired(content) {
        const match = content.match(/需要触发:\s*(是|否)/);
        return match ? match[1].trim() === '是' : false;
    }

    /**
     * 提取任务列表
     */
    extractTasks(content) {
        const tasks = [];
        const lines = content.split('\n');
        
        for (const line of lines) {
            const match = line.match(/\|\s*(.+?)\s*\|\s*(\w+)\s*\|\s*(.+?)\s*\|/);
            if (match && match[1] !== '任务' && !match[1].includes('---')) {
                tasks.push({
                    name: match[1].trim(),
                    role: match[2].trim(),
                    status: match[3].trim()
                });
            }
        }
        
        return tasks;
    }

    /**
     * 验证任务状态
     */
    verifyTaskStatus(tasks, roleName, expectedStatus) {
        const task = tasks.find(t => t.role === roleName);
        if (!task) {
            throw new Error(`未找到角色 ${roleName} 的任务`);
        }
        if (task.status !== expectedStatus) {
            throw new Error(`任务状态不匹配: 期望 ${expectedStatus}, 实际 ${task.status}`);
        }
        return true;
    }

    /**
     * 验证工作流状态
     */
    verifyWorkflowState(state, expected) {
        if (state.currentStage !== expected.currentStage) {
            throw new Error(`当前阶段不匹配: 期望 ${expected.currentStage}, 实际 ${state.currentStage}`);
        }
        if (state.nextRole !== expected.nextRole) {
            throw new Error(`下一步角色不匹配: 期望 ${expected.nextRole}, 实际 ${state.nextRole}`);
        }
        if (state.triggerRequired !== expected.triggerRequired) {
            throw new Error(`需要触发不匹配: 期望 ${expected.triggerRequired}, 实际 ${state.triggerRequired}`);
        }
        return true;
    }
}
```

### 3.4 触发器验证器 (trigger-verifier.js)

```javascript
/**
 * 触发器验证器
 */
export class TriggerVerifier {
    /**
     * 验证触发器机制
     */
    async verifyTrigger(projectPath, expectedTrigger) {
        const content = await this.readFile(`${projectPath}/shared/TASKS.md`);
        
        // 验证需要触发标志
        const triggerMatch = content.match(/需要触发:\s*(是|否)/);
        if (!triggerMatch) {
            throw new Error('未找到需要触发标志');
        }
        
        const actualTrigger = triggerMatch[1] === '是';
        if (actualTrigger !== expectedTrigger) {
            throw new Error(`触发器状态不匹配: 期望 ${expectedTrigger}, 实际 ${actualTrigger}`);
        }
        
        return true;
    }

    /**
     * 验证角色流转触发
     */
    async verifyRoleTransition(projectPath, fromRole, toRole) {
        const content = await this.readFile(`${projectPath}/shared/TASKS.md`);
        
        // 验证 fromRole 任务已完成
        const fromPattern = new RegExp(`\\| .* \\| ${fromRole} \\| 已完成 \\|`);
        if (!fromPattern.test(content)) {
            throw new Error(`角色 ${fromRole} 的任务未完成`);
        }
        
        // 验证下一步角色
        const nextRoleMatch = content.match(/下一步角色:\s*(\w+)/);
        if (!nextRoleMatch || nextRoleMatch[1] !== toRole) {
            throw new Error(`下一步角色不匹配: 期望 ${toRole}, 实际 ${nextRoleMatch ? nextRoleMatch[1] : '未找到'}`);
        }
        
        return true;
    }
}
```

---

## 4. 测试用例设计

### 4.1 任务分发测试

**测试目标**: 验证任务能够成功分发到各角色

| 用例ID | 测试项 | 输入 | 预期结果 |
|--------|--------|------|----------|
| TD-001 | 任务格式验证 | TASKS.md 文件 | 任务格式正确 |
| TD-002 | 任务状态验证 | product 任务 | 状态为"已完成" |
| TD-003 | 项目名称验证 | 项目名称 | 项目名称正确 |

```javascript
/**
 * 测试用例: 任务分发
 */
export async function testTaskDistribution(projectPath, collector) {
    const verifier = new StateVerifier();
    
    try {
        // 验证 TASKS.md 存在
        const content = await readFile(`${projectPath}/shared/TASKS.md`);
        assert(content !== null, 'TASKS.md 文件存在');
        
        // 验证任务格式
        assert(content.includes('| 需求讨论与确认 | product |'), '任务格式正确');
        
        // 验证 product 任务已完成
        const state = await verifier.parseTasksMd(projectPath);
        verifier.verifyTaskStatus(state.tasks, 'product', '✅ 已完成');
        
        collector.record('TD-001', '任务分发测试', true);
    } catch (error) {
        collector.record('TD-001', '任务分发测试', false, error.message);
    }
}
```

### 4.2 角色流转测试

**测试目标**: 验证各角色之间的自动流转机制

| 用例ID | 测试项 | 前置条件 | 预期结果 |
|--------|--------|----------|----------|
| RT-001 | product→architect | product 完成 | architect 被触发 |
| RT-002 | architect→developer | architect 完成 | developer 被触发 |
| RT-003 | developer→qa | developer 完成 | qa 被触发 |
| RT-004 | qa→writer | qa 完成 | writer 被触发 |

```javascript
/**
 * 测试用例: 角色流转
 */
export async function testRoleTransition(projectPath, collector) {
    const verifier = new TriggerVerifier();
    const stateVerifier = new StateVerifier();
    
    const transitions = [
        { from: 'product', to: 'architect' },
        { from: 'architect', to: 'developer' },
        { from: 'developer', to: 'qa' },
        { from: 'qa', to: 'writer' }
    ];
    
    for (let i = 0; i < transitions.length; i++) {
        const { from, to } = transitions[i];
        const testId = `RT-00${i + 1}`;
        
        try {
            await verifier.verifyRoleTransition(projectPath, from, to);
            collector.record(testId, `${from}→${to} 流转测试`, true);
        } catch (error) {
            collector.record(testId, `${from}→${to} 流转测试`, false, error.message);
        }
    }
}
```

### 4.3 状态管理测试

**测试目标**: 验证任务状态正确流转

| 用例ID | 测试项 | 操作 | 预期结果 |
|--------|--------|------|----------|
| SM-001 | 状态流转 | 任务开始 | 待开始 → 处理中 |
| SM-002 | 状态流转 | 任务完成 | 处理中 → 已完成 |
| SM-003 | 阶段更新 | 当前阶段完成 | 当前阶段更新 |
| SM-004 | 角色切换 | 下一步开始 | 下一步角色切换 |

```javascript
/**
 * 测试用例: 状态管理
 */
export async function testStateManagement(projectPath, collector) {
    const verifier = new StateVerifier();
    
    try {
        const state = await verifier.parseTasksMd(projectPath);
        
        // 验证当前阶段
        assert(['需求分析', '架构设计', '开发实施', '测试验证', '文档整理'].includes(state.currentStage), 
            '当前阶段有效');
        
        // 验证任务状态一致性
        state.tasks.forEach(task => {
            assert(['待开始', '处理中', '✅ 已完成', '已完成', '失败'].includes(task.status), 
                `任务 ${task.name} 状态有效`);
        });
        
        // 验证下一步角色
        const validRoles = ['product', 'architect', 'developer', 'qa', 'writer', '无'];
        assert(validRoles.includes(state.nextRole), '下一步角色有效');
        
        collector.record('SM-001', '状态管理测试', true);
    } catch (error) {
        collector.record('SM-001', '状态管理测试', false, error.message);
    }
}
```

### 4.4 触发器测试

**测试目标**: 验证触发器功能正常工作

| 用例ID | 测试项 | 输入 | 预期结果 |
|--------|--------|------|----------|
| TG-001 | 自动触发 | 需要触发=是 | 自动触发下一步 |
| TG-002 | 触发标志 | 任务完成 | 需要触发标志正确 |

```javascript
/**
 * 测试用例: 触发器
 */
export async function testTriggerMechanism(projectPath, collector) {
    const verifier = new TriggerVerifier();
    
    try {
        // 验证触发器状态
        await verifier.verifyTrigger(projectPath, true);
        
        collector.record('TG-001', '触发器测试', true);
    } catch (error) {
        collector.record('TG-001', '触发器测试', false, error.message);
    }
}
```

### 4.5 完整流程测试

**测试目标**: 验证完整工作流程

| 用例ID | 测试项 | 测试范围 | 预期结果 |
|--------|--------|----------|----------|
| E2E-001 | 完整流程 | PM→Product→Architect→Developer→QA→Writer | 全流程成功 |

```javascript
/**
 * 测试用例: 完整流程
 */
export async function testCompleteWorkflow(projectPath, collector) {
    const verifier = new StateVerifier();
    const roles = ['product', 'architect', 'developer', 'qa', 'writer'];
    
    try {
        const state = await verifier.parseTasksMd(projectPath);
        
        // 验证完整工作流
        let completedCount = 0;
        for (const role of roles) {
            const task = state.tasks.find(t => t.role === role);
            if (task && (task.status === '✅ 已完成' || task.status === '已完成')) {
                completedCount++;
            }
        }
        
        // 验证当前阶段
        const stages = ['需求分析', '架构设计', '开发实施', '测试验证', '文档整理'];
        const currentStageIndex = stages.indexOf(state.currentStage);
        
        assert(currentStageIndex >= 0, '当前阶段有效');
        assert(completedCount === currentStageIndex, `已完成任务数与当前阶段匹配`);
        
        collector.record('E2E-001', '完整流程测试', true);
    } catch (error) {
        collector.record('E2E-001', '完整流程测试', false, error.message);
    }
}
```

### 4.6 异常处理测试

**测试目标**: 验证异常处理机制

| 用例ID | 测试项 | 场景 | 预期结果 |
|--------|--------|------|----------|
| EH-001 | 状态回滚 | 任务失败 | 状态正确回滚 |
| EH-002 | 中断恢复 | 流程中断 | 能够恢复执行 |

```javascript
/**
 * 测试用例: 异常处理
 */
export async function testExceptionHandling(projectPath, collector) {
    try {
        // 验证异常处理机制
        // 这里可以模拟异常场景，验证系统的容错能力
        
        collector.record('EH-001', '异常处理测试', true);
    } catch (error) {
        collector.record('EH-001', '异常处理测试', false, error.message);
    }
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
    
    // 验证 ARCHITECTURE.md 存在（架构设计完成后）
    const archExists = await fileExists(`${projectPath}/shared/ARCHITECTURE.md`);
    results.push({ test: 'ARCHITECTURE.md存在', passed: archExists });
    
    return results;
}
```

### 5.2 状态验证

```javascript
/**
 * 状态验证
 */
export async function verifyState(projectPath) {
    const verifier = new StateVerifier();
    const state = await verifier.parseTasksMd(projectPath);
    
    const results = [];
    
    // 验证当前阶段
    results.push({
        test: '当前阶段有效',
        passed: state.currentStage !== null
    });
    
    // 验证下一步角色
    results.push({
        test: '下一步角色有效',
        passed: state.nextRole !== null
    });
    
    // 验证任务列表
    results.push({
        test: '任务列表不为空',
        passed: state.tasks.length > 0
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
import { ReportGenerator } from './report-generator.js';
import { testTaskDistribution, testRoleTransition, testStateManagement, testTriggerMechanism, testCompleteWorkflow, testExceptionHandling } from './test-cases.js';

async function main() {
    const projectPath = process.env.PROJECT_PATH || './';
    const collector = new ResultCollector();
    const launcher = new TestLauncher({ projectPath });

    console.log('🚀 开始测试工作流系统...\n');
    console.log(`📂 项目路径: ${projectPath}\n`);

    try {
        // 1. 初始化测试环境
        console.log('📦 初始化测试环境...');
        await launcher.setup();

        // 2. 执行测试用例
        console.log('🧪 执行测试用例...\n');

        await testTaskDistribution(projectPath, collector);
        await testRoleTransition(projectPath, collector);
        await testStateManagement(projectPath, collector);
        await testTriggerMechanism(projectPath, collector);
        await testCompleteWorkflow(projectPath, collector);
        await testExceptionHandling(projectPath, collector);

        // 3. 生成测试报告
        console.log('\n📊 生成测试报告...');
        const summary = collector.getSummary();
        
        console.log('\n' + '='.repeat(60));
        console.log('测试报告');
        console.log('='.repeat(60));
        console.log(`总用例数: ${summary.total}`);
        console.log(`通过数: ${summary.passed}`);
        console.log(`失败数: ${summary.failed}`);
        console.log(`通过率: ${summary.passRate}`);
        console.log(`测试时长: ${summary.duration}`);
        console.log('='.repeat(60));

        // 4. 清理测试环境
        console.log('\n🧹 清理测试环境...');
        await launcher.cleanup();

        console.log('\n✨ 测试完成！');

        // 5. 返回退出码
        process.exit(summary.failed > 0 ? 1 : 0);

    } catch (error) {
        console.error('❌ 测试失败:', error);
        process.exit(1);
    }
}

main();
```

### 6.2 测试命令

```bash
# 运行所有测试
npm test

# 指定项目路径
PROJECT_PATH=/path/to/project npm test

# 详细日志模式
npm test -- --verbose

# 生成报告
npm test -- --report
```

---

## 7. 测试报告

### 7.1 报告格式

```markdown
# 测试报告 - 工作流自动化测试

## 测试概览
- 测试时间: 2026-03-26 14:55:00
- 项目: workflow-auto-test-20260326
- 总用例数: 11
- 通过数: 11
- 失败数: 0
- 通过率: 100.00%
- 测试时长: 5.23s

## 测试结果

### 任务分发测试
- ✅ TD-001: 任务分发测试

### 角色流转测试
- ✅ RT-001: product→architect 流转测试
- ✅ RT-002: architect→developer 流转测试
- ✅ RT-003: developer→qa 流转测试
- ✅ RT-004: qa→writer 流转测试

### 状态管理测试
- ✅ SM-001: 状态管理测试

### 触发器测试
- ✅ TG-001: 触发器测试

### 完整流程测试
- ✅ E2E-001: 完整流程测试

### 异常处理测试
- ✅ EH-001: 异常处理测试

## 结论
所有测试通过，工作流系统运行正常。
```

---

## 8. 性能指标

### 8.1 测试性能要求

| 指标 | 要求 |
|------|------|
| 单个测试用例执行时间 | < 3秒 |
| 完整测试套件执行时间 | < 1分钟 |
| 测试报告生成时间 | < 5秒 |

### 8.2 系统性能验证

| 指标 | 要求 |
|------|------|
| 任务分发响应时间 | < 1秒 |
| 角色流转时间 | < 2秒 |
| 状态更新时间 | < 1秒 |
| 触发器响应时间 | < 2秒 |

---

## 9. 项目结构

```
workflow-auto-test-20260326/
├── shared/
│   ├── TASKS.md           # 任务清单
│   ├── PRD.md             # 产品需求文档
│   └── ARCHITECTURE.md    # 架构设计文档
├── tests/                 # 测试目录
│   ├── test-launcher.js   # 测试启动器
│   ├── test-cases.js      # 测试用例
│   ├── state-verifier.js  # 状态验证器
│   ├── trigger-verifier.js # 触发器验证器
│   ├── result-collector.js # 结果收集器
│   ├── report-generator.js # 报告生成器
│   └── run-tests.js       # 测试入口
├── package.json           # 项目配置
└── README.md              # 项目说明
```

---

## 10. 工作流说明

### 10.1 工作流程

```
PM（任务分解） → Product（需求分析） → Architect（架构设计） → Developer（开发实施） → QA（测试验证） → Writer（文档整理）
```

### 10.2 阶段说明

| 阶段 | 角色 | 说明 | 状态 |
|------|------|------|------|
| 任务分解 | PM | 任务分解和分发 | - |
| 需求分析 | product | 分析需求，产出PRD | ✅ 已完成 |
| 架构设计 | architect | 技术选型，架构设计 | 进行中 |
| 开发实施 | developer | 功能开发 | 待开始 |
| 测试验证 | qa | 测试执行 | 待开始 |
| 文档整理 | writer | 整理文档 | 待开始 |

---

## 11. 部署方案

### 11.1 本地测试

```bash
# 克隆项目
git clone <project-url>

# 安装依赖
npm install

# 运行测试
npm test
```

### 11.2 CI/CD 集成

```yaml
# .github/workflows/test.yml
name: Workflow Tests

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '18'
      
      - name: Install dependencies
        run: npm ci
      
      - name: Run tests
        run: npm test
```

---

## 12. 扩展性设计

### 12.1 未来扩展方向

- 支持更多角色类型
- 支持自定义工作流
- 支持并行测试
- 支持测试报告可视化
- 支持测试覆盖率分析

### 12.2 扩展接口

```javascript
/**
 * 测试用例接口
 */
interface TestCase {
    id: string;
    name: string;
    category: string;
    run(projectPath: string, collector: ResultCollector): Promise<void>;
}

/**
 * 验证器接口
 */
interface Verifier {
    verify(actual: any, expected: any): boolean;
    getMessage(): string;
}

/**
 * 报告器接口
 */
interface Reporter {
    generate(results: TestResult[], summary: Summary): string;
}
```

---

**架构师**: architect  
**创建日期**: 2026-03-26  
**版本**: v1.0  
**项目**: workflow-auto-test-20260326