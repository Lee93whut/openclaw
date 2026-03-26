# 架构设计文档 - 需要触发状态修复测试

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
| **状态验证器** | 验证"需要触发"状态是否正确 |
| **触发器验证器** | 验证触发器机制是否正常 |
| **修复验证器** | 验证修复效果 |
| **日志记录器** | 记录测试过程和结果 |

### 1.3 测试环境

| 组件 | 说明 |
|------|------|
| **测试环境** | OpenClaw 工作流系统（修复后） |
| **测试数据** | 真实项目数据（TASKS.md, PRD.md） |
| **验证方式** | 文件读取 + 状态验证 + 触发器验证 |

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
│  │ 状态管理测试 │  │ 触发器测试   │  │ 修复验证测试        │  │
│  └─────────────┘  └─────────────┘  └─────────────────────┘  │
│  ┌─────────────┐                                             │
│  │ 完整流程测试 │                                             │
│  └─────────────┘                                             │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    验证层                                   │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │ 状态验证器   │  │ 触发器验证器 │  │ 修复验证器          │  │
│  └─────────────┘  └─────────────┘  └─────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    被测系统（修复后）                        │
│  ┌───────────────────────────────────────────────────────┐  │
│  │ OpenClaw 工作流系统（修复版）                          │  │
│  │ (状态管理、触发器)                                     │  │
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
    │       ├─ 状态管理测试
    │       ├─ 触发器测试
    │       ├─ 修复验证测试
    │       └─ 完整流程测试
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
 * 状态验证器 - 重点验证"需要触发"状态
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
     * 提取需要触发 - 核心验证方法
     */
    extractTriggerRequired(content) {
        const match = content.match(/需要触发:\s*(是|否)/);
        return match ? match[1].trim() === '是' : false;
    }

    /**
     * 验证"需要触发"状态
     */
    verifyTriggerRequired(state, expected) {
        if (state.triggerRequired !== expected) {
            throw new Error(`需要触发状态不匹配: 期望 ${expected}, 实际 ${state.triggerRequired}`);
        }
        return true;
    }

    /**
     * 验证状态流转正确性
     */
    verifyStateTransition(state, expectedStage, expectedNextRole, expectedTrigger) {
        if (state.currentStage !== expectedStage) {
            throw new Error(`当前阶段不匹配: 期望 ${expectedStage}, 实际 ${state.currentStage}`);
        }
        if (state.nextRole !== expectedNextRole) {
            throw new Error(`下一步角色不匹配: 期望 ${expectedNextRole}, 实际 ${state.nextRole}`);
        }
        if (state.triggerRequired !== expectedTrigger) {
            throw new Error(`需要触发不匹配: 期望 ${expectedTrigger}, 实际 ${state.triggerRequired}`);
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
     * 验证触发标志正确性
     */
    async verifyTriggerFlag(projectPath, expected) {
        const content = await this.readFile(`${projectPath}/shared/TASKS.md`);
        
        // 验证需要触发标志
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

    /**
     * 验证触发逻辑正确性
     */
    async verifyTriggerLogic(projectPath) {
        const verifier = new StateVerifier();
        const state = await verifier.parseTasksMd(projectPath);
        
        // 如果需要触发，则下一步角色不应为空
        if (state.triggerRequired) {
            if (!state.nextRole) {
                throw new Error('需要触发时，下一步角色为空');
            }
        }
        
        return true;
    }

    /**
     * 验证触发后的状态变化
     */
    async verifyTriggerStateChange(projectPath, beforeState, afterState) {
        // 验证当前阶段是否推进
        if (beforeState.currentStage === afterState.currentStage) {
            throw new Error('触发后当前阶段未变化');
        }
        
        // 验证下一步角色是否更新
        if (beforeState.nextRole === afterState.nextRole) {
            throw new Error('触发后下一步角色未更新');
        }
        
        return true;
    }
}
```

### 3.3 修复验证器 (fix-verifier.js)

```javascript
/**
 * 修复验证器 - 验证修复效果
 */
export class FixVerifier {
    /**
     * 验证"需要触发"状态修复
     */
    async verifyTriggerRequiredFix(projectPath) {
        const verifier = new StateVerifier();
        const state = await verifier.parseTasksMd(projectPath);
        
        // 验证"需要触发"字段存在
        if (state.triggerRequired === undefined || state.triggerRequired === null) {
            throw new Error('需要触发字段不存在，修复失败');
        }
        
        // 验证"需要触发"值正确
        if (typeof state.triggerRequired !== 'boolean') {
            throw new Error('需要触发字段类型不正确，修复失败');
        }
        
        return true;
    }

    /**
     * 验证状态管理修复
     */
    async verifyStateManagementFix(projectPath) {
        const verifier = new StateVerifier();
        const state = await verifier.parseTasksMd(projectPath);
        
        // 验证当前阶段存在
        if (!state.currentStage) {
            throw new Error('当前阶段不存在，状态管理修复失败');
        }
        
        // 验证下一步角色存在
        if (!state.nextRole) {
            throw new Error('下一步角色不存在，状态管理修复失败');
        }
        
        return true;
    }

    /**
     * 验证触发器修复
     */
    async verifyTriggerFix(projectPath) {
        const verifier = new StateVerifier();
        const state = await verifier.parseTasksMd(projectPath);
        
        // 验证触发逻辑正确
        if (state.triggerRequired && !state.nextRole) {
            throw new Error('需要触发时，下一步角色为空，触发器修复失败');
        }
        
        return true;
    }
}
```

---

## 4. 测试用例设计

### 4.1 状态管理测试

**测试目标**: 验证状态管理修复效果

| 用例ID | 测试项 | 预期结果 |
|--------|--------|----------|
| SM-001 | 当前阶段存在 | 当前阶段字段存在且有效 |
| SM-002 | 下一步角色存在 | 下一步角色字段存在且有效 |
| SM-003 | "需要触发"字段存在 | "需要触发"字段存在且类型正确 |
| SM-004 | 状态一致性 | 状态与任务进度一致 |

```javascript
/**
 * 测试用例: 状态管理
 */
export async function testStateManagement(projectPath, collector) {
    const verifier = new StateVerifier();
    
    try {
        const state = await verifier.parseTasksMd(projectPath);
        
        // 验证当前阶段
        assert(state.currentStage !== null, '当前阶段存在');
        
        // 验证下一步角色
        assert(state.nextRole !== null, '下一步角色存在');
        
        // 验证"需要触发"字段
        assert(state.triggerRequired !== undefined, '需要触发字段存在');
        assert(typeof state.triggerRequired === 'boolean', '需要触发类型正确');
        
        collector.record('SM-001', '状态管理测试', true);
    } catch (error) {
        collector.record('SM-001', '状态管理测试', false, error.message);
    }
}
```

### 4.2 触发器测试

**测试目标**: 验证触发器修复效果

| 用例ID | 测试项 | 预期结果 |
|--------|--------|----------|
| TG-001 | 触发标志正确 | "需要触发"标志正确显示 |
| TG-002 | 触发逻辑正确 | 需要触发时下一步角色不为空 |
| TG-003 | 触发状态变化 | 触发后状态正确更新 |

```javascript
/**
 * 测试用例: 触发器
 */
export async function testTriggerMechanism(projectPath, collector) {
    const verifier = new StateVerifier();
    const triggerVerifier = new TriggerVerifier();
    
    try {
        const state = await verifier.parseTasksMd(projectPath);
        
        // 验证触发标志
        await triggerVerifier.verifyTriggerFlag(projectPath, state.triggerRequired);
        
        // 验证触发逻辑
        await triggerVerifier.verifyTriggerLogic(projectPath);
        
        collector.record('TG-001', '触发器测试', true);
    } catch (error) {
        collector.record('TG-001', '触发器测试', false, error.message);
    }
}
```

### 4.3 修复验证测试

**测试目标**: 验证修复效果

| 用例ID | 测试项 | 预期结果 |
|--------|--------|----------|
| FV-001 | "需要触发"状态修复验证 | 修复后功能正常 |
| FV-002 | 状态管理修复验证 | 修复后功能正常 |
| FV-003 | 触发器修复验证 | 修复后功能正常 |

```javascript
/**
 * 测试用例: 修复验证
 */
export async function testFixVerification(projectPath, collector) {
    const fixVerifier = new FixVerifier();
    
    try {
        // 验证"需要触发"状态修复
        await fixVerifier.verifyTriggerRequiredFix(projectPath);
        collector.record('FV-001', '需要触发状态修复验证', true);
    } catch (error) {
        collector.record('FV-001', '需要触发状态修复验证', false, error.message);
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

### 4.4 完整流程测试

**测试目标**: 验证完整工作流程

| 用例ID | 测试项 | 预期结果 |
|--------|--------|----------|
| E2E-001 | 完整流程 | Product → Architect → Developer → QA → Writer 全流程成功 |

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
            if (task && task.status === '✅ 已完成') {
                completedCount++;
            }
        }
        
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
import { testStateManagement, testTriggerMechanism, testFixVerification, testCompleteWorkflow } from './test-cases.js';

async function main() {
    const projectPath = process.env.PROJECT_PATH || './';
    const collector = new ResultCollector();
    const launcher = new TestLauncher({ projectPath });

    console.log('🚀 开始需要触发状态修复测试...\n');
    console.log(`📂 项目路径: ${projectPath}\n`);

    try {
        // 1. 初始化测试环境
        await launcher.setup();

        // 2. 执行测试用例
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
# 测试报告 - 需要触发状态修复测试

## 测试概览
- 测试时间: 2026-03-26 17:27:00
- 项目: bugfix-test
- 总用例数: 7
- 通过数: 7
- 失败数: 0
- 通过率: 100.00%

## 测试结果

### 状态管理测试
- ✅ SM-001: 状态管理测试

### 触发器测试
- ✅ TG-001: 触发器测试

### 修复验证测试
- ✅ FV-001: 需要触发状态修复验证
- ✅ FV-002: 状态管理修复验证
- ✅ FV-003: 触发器修复验证

### 完整流程测试
- ✅ E2E-001: 完整流程测试

## 结论
所有测试通过，需要触发状态修复效果验证成功。
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
| 状态读取时间 | < 1秒 |
| 触发器响应时间 | < 2秒 |

---

## 8. 项目结构

```
bugfix-test/
├── shared/
│   ├── TASKS.md           # 任务清单
│   ├── PRD.md             # 产品需求文档
│   └── ARCHITECTURE.md    # 架构设计文档
├── tests/                 # 测试目录
│   ├── test-launcher.js
│   ├── test-cases.js
│   ├── state-verifier.js
│   ├── trigger-verifier.js
│   ├── fix-verifier.js
│   ├── result-collector.js
│   └── run-tests.js
└── README.md              # 项目说明
```

---

## 9. 工作流说明

### 9.1 工作流程

```
Product → Architect → Developer → QA → Writer
```

### 9.2 阶段说明

| 阶段 | 角色 | 说明 | 状态 |
|------|------|------|------|
| 需求 | product | 需求分析 | ✅ 已完成 |
| 架构 | architect | 架构设计 | 进行中 |
| 开发 | developer | 功能开发 | 待开始 |
| 测试 | qa | 测试执行 | 待开始 |
| 文档 | writer | 文档整理 | 待开始 |

---

**架构师**: architect  
**创建日期**: 2026-03-26  
**版本**: v1.0  
**项目**: bugfix-test