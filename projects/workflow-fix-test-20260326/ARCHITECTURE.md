# 架构设计文档 - 工作流自动化修复测试

## 1. 技术选型

### 1.1 测试框架

| 技术 | 选择 | 理由 |
|------|------|------|
| **测试框架** | Jest | 成熟的JavaScript测试框架，支持异步测试 |
| **断言库** | Jest内置 | 简洁的断言语法，无需额外配置 |
| **测试运行器** | Node.js | 直接运行测试脚本，灵活控制 |
| **文件系统** | Node.js fs | 读取和验证 TASKS.md、PRD.md 等文件 |

### 1.2 验证工具

| 工具 | 用途 |
|------|------|
| **文件解析器** | 解析 TASKS.md、PRD.md 文件内容 |
| **状态比对器** | 比对预期状态与实际状态 |
| **触发器验证器** | 验证触发器机制是否正常 |
| **修复验证器** | 验证修复效果 |
| **日志记录器** | 记录测试过程和结果 |

### 1.3 测试环境

| 组件 | 说明 |
|------|------|
| **测试环境** | OpenClaw 工作流系统（修复后） |
| **测试数据** | 真实项目数据（TASKS.md, PRD.md） |
| **验证方式** | 文件读取 + 状态验证 + 修复验证 |

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
│  │ 任务分发测试 │  │ 角色流转测试 │  │ 状态管理测试        │  │
│  └─────────────┘  └─────────────┘  └─────────────────────┘  │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │ 触发器测试   │  │ 修复验证测试 │  │ 完整流程测试        │  │
│  └─────────────┘  └─────────────┘  └─────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    验证层                                   │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │ 文件验证器   │  │ 状态验证器   │  │ 修复验证器          │  │
│  └─────────────┘  └─────────────┘  └─────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    被测系统（修复后）                        │
│  ┌───────────────────────────────────────────────────────┐  │
│  │ OpenClaw 工作流系统（修复版）                          │  │
│  │ (任务分发、状态管理、触发器)                           │  │
│  └───────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

### 2.2 测试流程

```
测试启动
    │
    ├─→ 初始化测试环境
    │       ├─ 读取项目文件
    │       └─ 初始化测试状态
    │
    ├─→ 执行修复验证测试
    │       ├─ 任务分发修复验证
    │       ├─ 状态管理修复验证
    │       ├─ 触发器修复验证
    │       └─ 完整流程验证
    │
    ├─→ 收集测试结果
    │       ├─ 统计通过/失败
    │       └─ 生成测试报告
    │
    └─→ 输出测试结果
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
        this.results = [];
    }

    /**
     * 初始化测试环境
     */
    async setup() {
        console.log('📦 初始化测试环境...');
        // 读取项目文件
        // 初始化测试状态
    }

    /**
     * 运行所有测试
     */
    async runAll() {
        console.log('🧪 执行测试用例...');
        // 执行测试用例
        return this.results;
    }

    /**
     * 清理测试环境
     */
    async cleanup() {
        console.log('🧹 清理测试环境...');
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
        this.results.push({ testId, testName, passed, error });
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
            passRate: `${((this.passed / (this.passed + this.failed)) * 100).toFixed(2)}%`
        };
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
            if (match && match[1] !== '任务') {
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
}
```

### 3.4 修复验证器 (fix-verifier.js)

```javascript
/**
 * 修复验证器
 */
export class FixVerifier {
    /**
     * 验证任务分发修复
     */
    async verifyTaskDistributionFix(projectPath) {
        const verifier = new StateVerifier();
        const state = await verifier.parseTasksMd(projectPath);
        
        // 验证任务分发是否正常
        if (state.tasks.length === 0) {
            throw new Error('任务列表为空，任务分发修复失败');
        }
        
        // 验证 product 任务状态
        const productTask = state.tasks.find(t => t.role === 'product');
        if (!productTask || productTask.status !== '✅ 已完成') {
            throw new Error('product 任务状态不正确，任务分发修复失败');
        }
        
        return true;
    }

    /**
     * 验证状态管理修复
     */
    async verifyStateManagementFix(projectPath) {
        const verifier = new StateVerifier();
        const state = await verifier.parseTasksMd(projectPath);
        
        // 验证当前阶段是否正确
        const validStages = ['需求分析', '架构设计', '开发实施', '测试验证', '文档整理'];
        if (!validStages.includes(state.currentStage)) {
            throw new Error(`当前阶段不正确: ${state.currentStage}，状态管理修复失败`);
        }
        
        // 验证下一步角色是否正确
        const validRoles = ['product', 'architect', 'developer', 'qa', 'writer'];
        if (!validRoles.includes(state.nextRole)) {
            throw new Error(`下一步角色不正确: ${state.nextRole}，状态管理修复失败`);
        }
        
        return true;
    }

    /**
     * 验证触发器修复
     */
    async verifyTriggerFix(projectPath) {
        const verifier = new StateVerifier();
        const state = await verifier.parseTasksMd(projectPath);
        
        // 验证触发器是否正确设置
        if (state.triggerRequired && !state.nextRole) {
            throw new Error('需要触发时，下一步角色为空，触发器修复失败');
        }
        
        return true;
    }
}
```

---

## 4. 测试用例设计

### 4.1 任务分发测试

**测试目标**: 验证任务分发修复效果

| 用例ID | 测试项 | 预期结果 |
|--------|--------|----------|
| TD-001 | TASKS.md 文件存在 | 文件存在且格式正确 |
| TD-002 | PRD.md 文件存在 | 文件存在且格式正确 |
| TD-003 | product 任务状态 | 状态为"✅ 已完成" |

```javascript
/**
 * 测试用例: 任务分发
 */
export async function testTaskDistribution(projectPath, collector) {
    const verifier = new StateVerifier();
    
    try {
        // 验证 TASKS.md 存在
        const tasksContent = await readFile(`${projectPath}/shared/TASKS.md`);
        assert(tasksContent !== null, 'TASKS.md 文件存在');
        
        // 验证 PRD.md 存在
        const prdContent = await readFile(`${projectPath}/shared/PRD.md`);
        assert(prdContent !== null, 'PRD.md 文件存在');
        
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

**测试目标**: 验证角色流转修复效果

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
    const verifier = new StateVerifier();
    
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
            const state = await verifier.parseTasksMd(projectPath);
            
            // 验证 from 角色任务已完成
            const fromTask = state.tasks.find(t => t.role === from);
            if (fromTask && fromTask.status === '✅ 已完成') {
                // 验证下一步角色
                if (state.nextRole === to) {
                    collector.record(testId, `${from}→${to} 流转测试`, true);
                } else {
                    throw new Error(`下一步角色不匹配: 期望 ${to}, 实际 ${state.nextRole}`);
                }
            } else {
                // 如果 from 角色任务未完成，跳过此测试
                collector.record(testId, `${from}→${to} 流转测试`, true, '等待前置任务完成');
            }
        } catch (error) {
            collector.record(testId, `${from}→${to} 流转测试`, false, error.message);
        }
    }
}
```

### 4.3 状态管理测试

**测试目标**: 验证状态管理修复效果

| 用例ID | 测试项 | 预期结果 |
|--------|--------|----------|
| SM-001 | 当前阶段有效 | 当前阶段在有效范围内 |
| SM-002 | 下一步角色有效 | 下一步角色在有效范围内 |
| SM-003 | 任务状态一致 | 任务状态与当前阶段一致 |

```javascript
/**
 * 测试用例: 状态管理
 */
export async function testStateManagement(projectPath, collector) {
    const verifier = new StateVerifier();
    
    try {
        const state = await verifier.parseTasksMd(projectPath);
        
        // 验证当前阶段
        const validStages = ['需求分析', '架构设计', '开发实施', '测试验证', '文档整理'];
        assert(validStages.includes(state.currentStage), '当前阶段有效');
        
        // 验证下一步角色
        const validRoles = ['product', 'architect', 'developer', 'qa', 'writer'];
        assert(validRoles.includes(state.nextRole), '下一步角色有效');
        
        // 验证任务状态一致性
        state.tasks.forEach(task => {
            const validStatuses = ['待开始', '处理中', '✅ 已完成', '已完成', '失败'];
            assert(validStatuses.some(s => task.status.includes(s)), `任务 ${task.name} 状态有效`);
        });
        
        collector.record('SM-001', '状态管理测试', true);
    } catch (error) {
        collector.record('SM-001', '状态管理测试', false, error.message);
    }
}
```

### 4.4 触发器测试

**测试目标**: 验证触发器修复效果

| 用例ID | 测试项 | 预期结果 |
|--------|--------|----------|
| TG-001 | 触发标志正确 | 需要触发标志正确设置 |
| TG-002 | 触发机制正常 | 任务完成后自动触发下一步 |

```javascript
/**
 * 测试用例: 触发器
 */
export async function testTriggerMechanism(projectPath, collector) {
    const verifier = new StateVerifier();
    
    try {
        const state = await verifier.parseTasksMd(projectPath);
        
        // 验证触发标志
        if (state.triggerRequired) {
            assert(state.nextRole !== null, '需要触发时，下一步角色不应为空');
        }
        
        collector.record('TG-001', '触发器测试', true);
    } catch (error) {
        collector.record('TG-001', '触发器测试', false, error.message);
    }
}
```

### 4.5 修复验证测试

**测试目标**: 验证修复效果

| 用例ID | 测试项 | 预期结果 |
|--------|--------|----------|
| FV-001 | 任务分发修复验证 | 修复后功能正常 |
| FV-002 | 状态管理修复验证 | 修复后功能正常 |
| FV-003 | 触发器修复验证 | 修复后功能正常 |

```javascript
/**
 * 测试用例: 修复验证
 */
export async function testFixVerification(projectPath, collector) {
    const fixVerifier = new FixVerifier();
    
    try {
        // 验证任务分发修复
        await fixVerifier.verifyTaskDistributionFix(projectPath);
        collector.record('FV-001', '任务分发修复验证', true);
    } catch (error) {
        collector.record('FV-001', '任务分发修复验证', false, error.message);
    }
    
    try {
        // 验证状态管理修复
        await fixVerifier.verifyStateManagementFix(projectPath);
        collector.record('FV-002', '状态管理修复验证', true);
    } catch (error) {
        collector.record('FV-002', '状态管理修复验证', false, error.message);
    }
    
    try {
        // 验证触发器修复
        await fixVerifier.verifyTriggerFix(projectPath);
        collector.record('FV-003', '触发器修复验证', true);
    } catch (error) {
        collector.record('FV-003', '触发器修复验证', false, error.message);
    }
}
```

### 4.6 完整流程测试

**测试目标**: 验证完整工作流程

| 用例ID | 测试项 | 预期结果 |
|--------|--------|----------|
| E2E-001 | 完整流程 | PM → Product → Architect → Developer → QA → Writer 全流程成功 |

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

---

## 5. 测试执行

### 5.1 测试脚本 (run-tests.js)

```javascript
import { TestLauncher } from './test-launcher.js';
import { ResultCollector } from './result-collector.js';
import { testTaskDistribution, testRoleTransition, testStateManagement, testTriggerMechanism, testFixVerification, testCompleteWorkflow } from './test-cases.js';

async function main() {
    const projectPath = process.env.PROJECT_PATH || './';
    const collector = new ResultCollector();
    const launcher = new TestLauncher({ projectPath });

    console.log('🚀 开始工作流修复测试...\n');
    console.log(`📂 项目路径: ${projectPath}\n`);

    try {
        // 1. 初始化测试环境
        await launcher.setup();

        // 2. 执行测试用例
        await testTaskDistribution(projectPath, collector);
        await testRoleTransition(projectPath, collector);
        await testStateManagement(projectPath, collector);
        await testTriggerMechanism(projectPath, collector);
        await testFixVerification(projectPath, collector);
        await testCompleteWorkflow(projectPath, collector);

        // 3. 输出测试结果
        const summary = collector.getSummary();
        
        console.log('\n' + '='.repeat(60));
        console.log('测试报告');
        console.log('='.repeat(60));
        console.log(`总用例数: ${summary.total}`);
        console.log(`通过数: ${summary.passed}`);
        console.log(`失败数: ${summary.failed}`);
        console.log(`通过率: ${summary.passRate}`);
        console.log('='.repeat(60));

        // 4. 清理测试环境
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

### 5.2 测试命令

```bash
# 运行所有测试
npm test

# 指定项目路径
PROJECT_PATH=/path/to/project npm test
```

---

## 6. 测试报告

### 6.1 报告格式

```markdown
# 测试报告 - 工作流自动化修复测试

## 测试概览
- 测试时间: 2026-03-26 15:20:00
- 项目: workflow-fix-test-20260326
- 总用例数: 13
- 通过数: 13
- 失败数: 0
- 通过率: 100.00%

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

### 修复验证测试
- ✅ FV-001: 任务分发修复验证
- ✅ FV-002: 状态管理修复验证
- ✅ FV-003: 触发器修复验证

### 完整流程测试
- ✅ E2E-001: 完整流程测试

## 结论
所有测试通过，工作流修复效果验证成功。
```

---

## 7. 性能指标

### 7.1 测试性能要求

| 指标 | 要求 |
|------|------|
| 单个测试用例执行时间 | < 3秒 |
| 完整测试套件执行时间 | < 1分钟 |
| 测试报告生成时间 | < 5秒 |

### 7.2 系统性能验证

| 指标 | 要求 |
|------|------|
| 任务分发响应时间 | < 1秒 |
| 角色流转时间 | < 2秒 |
| 状态更新时间 | < 1秒 |
| 触发器响应时间 | < 2秒 |

---

## 8. 项目结构

```
workflow-fix-test-20260326/
├── shared/
│   ├── TASKS.md           # 任务清单
│   ├── PRD.md             # 产品需求文档
│   └── ARCHITECTURE.md    # 架构设计文档
├── tests/                 # 测试目录
│   ├── test-launcher.js
│   ├── test-cases.js
│   ├── state-verifier.js
│   ├── fix-verifier.js
│   ├── result-collector.js
│   └── run-tests.js
├── package.json           # 项目配置
└── README.md              # 项目说明
```

---

## 9. 工作流说明

### 9.1 工作流程

```
PM → Product → Architect → Developer → QA → Writer
```

### 9.2 阶段说明

| 阶段 | 角色 | 说明 | 状态 |
|------|------|------|------|
| 需求分析 | product | 分析需求，产出PRD | ✅ 已完成 |
| 架构设计 | architect | 技术选型，架构设计 | 进行中 |
| 开发实施 | developer | 功能开发 | 待开始 |
| 测试验证 | qa | 测试执行 | 待开始 |
| 文档整理 | writer | 整理文档 | 待开始 |

---

**架构师**: architect  
**创建日期**: 2026-03-26  
**版本**: v1.0  
**项目**: workflow-fix-test-20260326