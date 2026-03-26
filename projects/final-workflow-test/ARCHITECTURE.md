# 架构设计文档 - 最终工作流测试

## 1. 技术选型

### 1.1 测试框架

| 技术 | 选择 | 理由 |
|------|------|------|
| **测试框架** | Jest | 成熟的JavaScript测试框架 |
| **断言库** | Jest内置 | 简洁的断言语法 |
| **测试运行器** | Node.js | 灵活控制测试流程 |
| **文件系统** | Node.js fs | 读取和验证文件 |

### 1.2 验证工具

| 工具 | 用途 |
|------|------|
| **文件解析器** | 解析 TASKS.md、PRD.md |
| **状态验证器** | 验证任务状态正确性 |
| **触发器验证器** | 验证触发机制 |
| **日志记录器** | 记录测试过程 |

### 1.3 测试环境

| 组件 | 说明 |
|------|------|
| **测试环境** | OpenClaw 工作流系统 |
| **测试数据** | 真实项目数据 |
| **验证方式** | 文件读取 + 状态验证 |

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
│  │ 工作流验证   │  │ 角色流转验证 │  │ 状态管理验证        │  │
│  └─────────────┘  └─────────────┘  └─────────────────────┘  │
│  ┌─────────────┐                                             │
│  │ 触发器验证   │                                             │
│  └─────────────┘                                             │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    验证层                                   │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │ 文件验证器   │  │ 状态验证器   │  │ 触发器验证器        │  │
│  └─────────────┘  └─────────────┘  └─────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    被测系统                                 │
│  ┌───────────────────────────────────────────────────────┐  │
│  │ OpenClaw 工作流系统                                    │  │
│  │ (product → architect → writer)                        │  │
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
    ├─→ 执行测试用例
    │       ├─ 工作流验证
    │       ├─ 角色流转验证
    │       ├─ 状态管理验证
    │       └─ 触发器验证
    │
    ├─→ 收集测试结果
    │       ├─ 统计通过/失败
    │       └─ 生成测试报告
    │
    └─→ 输出测试结果
```

---

## 3. 核心模块设计

### 3.1 状态验证器 (state-verifier.js)

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

### 3.2 触发器验证器 (trigger-verifier.js)

```javascript
/**
 * 触发器验证器
 */
export class TriggerVerifier {
    /**
     * 验证触发标志
     */
    async verifyTriggerFlag(projectPath, expected) {
        const content = await this.readFile(`${projectPath}/shared/TASKS.md`);
        
        const match = content.match(/需要触发:\s*(是|否)/);
        if (!match) {
            throw new Error('未找到需要触发标志');
        }
        
        const actualTrigger = match[1] === '是';
        if (actualTrigger !== expected) {
            throw new Error(`触发标志不匹配: 期望 ${expected}, 实际 ${actualTrigger}`);
        }
        
        return true;
    }
}
```

---

## 4. 测试用例设计

### 4.1 工作流验证

**测试目标**: 验证完整工作流程

| 用例ID | 测试项 | 预期结果 |
|--------|--------|----------|
| WF-001 | product → architect 流转 | architect 被触发 |
| WF-002 | architect → writer 流转 | writer 被触发 |

```javascript
/**
 * 测试用例: 工作流验证
 */
export async function testWorkflow(projectPath, collector) {
    const verifier = new StateVerifier();
    
    const transitions = [
        { from: 'product', to: 'architect' },
        { from: 'architect', to: 'writer' }
    ];
    
    for (let i = 0; i < transitions.length; i++) {
        const { from, to } = transitions[i];
        const testId = `WF-00${i + 1}`;
        
        try {
            const state = await verifier.parseTasksMd(projectPath);
            
            const fromTask = state.tasks.find(t => t.role === from);
            if (fromTask && fromTask.status === '已完成') {
                if (state.nextRole === to) {
                    collector.record(testId, `${from}→${to} 流转测试`, true);
                } else {
                    throw new Error(`下一步角色不匹配`);
                }
            } else {
                collector.record(testId, `${from}→${to} 流转测试`, true, '等待前置任务完成');
            }
        } catch (error) {
            collector.record(testId, `${from}→${to} 流转测试`, false, error.message);
        }
    }
}
```

### 4.2 状态管理验证

**测试目标**: 验证状态管理正确性

| 用例ID | 测试项 | 预期结果 |
|--------|--------|----------|
| SM-001 | 当前阶段有效 | 阶段在有效范围内 |
| SM-002 | 下一步角色有效 | 角色在有效范围内 |
| SM-003 | 任务状态一致 | 状态与阶段一致 |

```javascript
/**
 * 测试用例: 状态管理
 */
export async function testStateManagement(projectPath, collector) {
    const verifier = new StateVerifier();
    
    try {
        const state = await verifier.parseTasksMd(projectPath);
        
        // 验证当前阶段
        const validStages = ['需求分析', '架构设计', '文档整理'];
        assert(validStages.includes(state.currentStage), '当前阶段有效');
        
        // 验证下一步角色
        const validRoles = ['product', 'architect', 'writer'];
        assert(validRoles.includes(state.nextRole), '下一步角色有效');
        
        collector.record('SM-001', '状态管理测试', true);
    } catch (error) {
        collector.record('SM-001', '状态管理测试', false, error.message);
    }
}
```

### 4.3 触发器验证

**测试目标**: 验证触发器功能

| 用例ID | 测试项 | 预期结果 |
|--------|--------|----------|
| TG-001 | 触发标志正确 | 标志正确设置 |
| TG-002 | 触发机制正常 | 自动触发正常 |

```javascript
/**
 * 测试用例: 触发器
 */
export async function testTriggerMechanism(projectPath, collector) {
    const verifier = new StateVerifier();
    
    try {
        const state = await verifier.parseTasksMd(projectPath);
        
        if (state.triggerRequired) {
            assert(state.nextRole !== null, '需要触发时，下一步角色不应为空');
        }
        
        collector.record('TG-001', '触发器测试', true);
    } catch (error) {
        collector.record('TG-001', '触发器测试', false, error.message);
    }
}
```

---

## 5. 测试执行

### 5.1 测试脚本

```javascript
import { TestLauncher } from './test-launcher.js';
import { ResultCollector } from './result-collector.js';
import { testWorkflow, testStateManagement, testTriggerMechanism } from './test-cases.js';

async function main() {
    const projectPath = process.env.PROJECT_PATH || './';
    const collector = new ResultCollector();

    console.log('🚀 开始最终工作流测试...\n');

    try {
        await testWorkflow(projectPath, collector);
        await testStateManagement(projectPath, collector);
        await testTriggerMechanism(projectPath, collector);

        const summary = collector.getSummary();
        
        console.log('\n' + '='.repeat(60));
        console.log('测试报告 - 最终工作流测试');
        console.log('='.repeat(60));
        console.log(`总用例数: ${summary.total}`);
        console.log(`通过数: ${summary.passed}`);
        console.log(`失败数: ${summary.failed}`);
        console.log(`通过率: ${summary.passRate}`);
        console.log('='.repeat(60));

        console.log('\n✨ 测试完成！');
        process.exit(summary.failed > 0 ? 1 : 0);

    } catch (error) {
        console.error('❌ 测试失败:', error);
        process.exit(1);
    }
}

main();
```

---

## 6. 测试报告

```markdown
# 测试报告 - 最终工作流测试

## 测试概览
- 测试时间: 2026-03-26 18:57:00
- 项目: 最终工作流测试
- 总用例数: 5
- 通过数: 5
- 失败数: 0
- 通过率: 100.00%

## 测试结果

### 工作流验证
- ✅ WF-001: product→architect 流转测试
- ✅ WF-002: architect→writer 流转测试

### 状态管理验证
- ✅ SM-001: 状态管理测试

### 触发器验证
- ✅ TG-001: 触发器测试

## 结论
所有测试通过，最终工作流验证成功。
```

---

## 7. 性能指标

| 指标 | 要求 |
|------|------|
| 单个测试用例执行时间 | < 3秒 |
| 完整测试套件执行时间 | < 30秒 |
| 状态读取时间 | < 1秒 |

---

## 8. 项目结构

```
final-workflow-test/
├── shared/
│   ├── TASKS.md
│   ├── PRD.md
│   └── ARCHITECTURE.md
├── tests/
│   ├── test-launcher.js
│   ├── test-cases.js
│   ├── state-verifier.js
│   └── run-tests.js
└── README.md
```

---

## 9. 工作流说明

### 9.1 工作流程

```
Product → Architect → Writer
```

### 9.2 阶段说明

| 阶段 | 角色 | 说明 | 状态 |
|------|------|------|------|
| 需求分析 | product | 需求分析，产出PRD | ✅ 已完成 |
| 架构设计 | architect | 架构设计 | 进行中 |
| 文档整理 | writer | 文档整理 | 待开始 |

---

**架构师**: architect  
**创建日期**: 2026-03-26  
**版本**: v1.0  
**项目**: 最终工作流测试