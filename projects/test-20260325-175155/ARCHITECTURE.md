# 架构设计文档 - 工作流系统测试

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
| **日志记录器** | 记录测试过程和结果 |

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
│  │ (Launcher)  │  │ (Collector)  │  │ (Reporter)         │  │
│  └─────────────┘  └─────────────┘  └─────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    测试执行层                               │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │ 分发测试     │  │ 流转测试     │  │ 状态测试            │  │
│  │ (Distribute)│  │ (Transition) │  │ (State)            │  │
│  └─────────────┘  └─────────────┘  └─────────────────────┘  │
│  ┌─────────────┐  ┌─────────────┐                           │
│  │ 触发测试     │  │ 完整流程测试 │                           │
│  │ (Trigger)   │  │ (E2E)       │                           │
│  └─────────────┘  └─────────────┘                           │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    验证层                                   │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │ 文件验证     │  │ 状态验证     │  │ 触发验证            │  │
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

### 2.2 测试流程图

```
测试开始
    │
    ├─→ 初始化测试环境
    │       ├─ 创建测试项目
    │       ├─ 准备测试数据
    │       └─ 设置初始状态
    │
    ├─→ 执行测试用例
    │       ├─ 任务分发测试
    │       ├─ 角色流转测试
    │       ├─ 状态管理测试
    │       ├─ 触发机制测试
    │       └─ 完整流程测试
    │
    ├─→ 收集测试结果
    │       ├─ 统计通过/失败
    │       ├─ 记录错误信息
    │       └─ 生成测试报告
    │
    └─→ 清理测试环境
```

---

## 3. 核心模块设计

### 3.1 测试启动器 (test-launcher.js)

```javascript
/**
 * 测试启动器 - 初始化和运行测试
 */
export class TestLauncher {
    constructor(config) {
        this.projectPath = config.projectPath;
        this.testCases = [];
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
        // 执行所有测试用例
        // 收集测试结果
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
 * 结果收集器 - 收集和统计测试结果
 */
export class ResultCollector {
    constructor() {
        this.results = [];
        this.passed = 0;
        this.failed = 0;
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

### 3.3 报告生成器 (report-generator.js)

```javascript
/**
 * 报告生成器 - 生成测试报告
 */
export class ReportGenerator {
    /**
     * 生成 Markdown 格式报告
     */
    generateMarkdown(results, summary) {
        let report = `# 测试报告\n\n`;
        report += `## 测试概览\n\n`;
        report += `- 总用例数: ${summary.total}\n`;
        report += `- 通过数: ${summary.passed}\n`;
        report += `- 失败数: ${summary.failed}\n`;
        report += `- 通过率: ${summary.passRate}\n\n`;
        report += `## 测试结果\n\n`;
        
        results.forEach(result => {
            const icon = result.passed ? '✅' : '❌';
            report += `- ${icon} ${result.testId}: ${result.testName}\n`;
            if (result.error) {
                report += `  - 错误: ${result.error}\n`;
            }
        });
        
        return report;
    }
}
```

---

## 4. 测试用例设计

### 4.1 任务分发测试

**测试目标**: 验证任务能够成功分发到 product 角色

| 用例ID | 测试项 | 输入 | 预期结果 |
|--------|--------|------|----------|
| TD-001 | 任务格式验证 | 任务分发消息 | TASKS.md 中任务格式正确 |
| TD-002 | 任务状态验证 | 任务分发后 | 任务状态为"待开始" |
| TD-003 | 项目名称验证 | 项目名称 | PRD.md 中项目名称正确 |

```javascript
/**
 * 测试用例: 任务分发
 */
export async function testTaskDistribution(projectPath) {
    // 读取 TASKS.md
    const tasksMd = await readTasksMd(projectPath);
    
    // 验证任务格式
    assert(tasksMd.includes('| 需求分析 | product |'));
    
    // 验证任务状态
    assert(tasksMd.includes('| 需求分析 | product | 已完成 |'));
    
    // 验证下一步角色
    assert(tasksMd.includes('下一步角色: architect'));
}
```

### 4.2 角色流转测试

**测试目标**: 验证各角色之间的自动流转机制

| 用例ID | 测试项 | 前置条件 | 预期结果 |
|--------|--------|----------|----------|
| RT-001 | product→architect | product 完成需求分析 | architect 被触发 |
| RT-002 | architect→developer | architect 完成架构设计 | developer 被触发 |
| RT-003 | developer→qa | developer 完成功能开发 | qa 被触发 |
| RT-004 | qa→writer | qa 完成测试 | writer 被触发 |

```javascript
/**
 * 测试用例: 角色流转
 */
export async function testRoleTransition(projectPath, fromRole, toRole) {
    // 读取 TASKS.md
    const tasksMd = await readTasksMd(projectPath);
    
    // 验证 fromRole 任务已完成
    const fromPattern = new RegExp(`\\| .* \\| ${fromRole} \\| 已完成 \\|`);
    assert(fromPattern.test(tasksMd));
    
    // 验证 toRole 任务已触发
    assert(tasksMd.includes(`下一步角色: ${toRole}`));
    assert(tasksMd.includes('需要触发: 是'));
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
export async function testStateManagement(projectPath) {
    // 读取 TASKS.md
    const tasksMd = await readTasksMd(projectPath);
    
    // 验证当前阶段
    const currentStage = extractCurrentStage(tasksMd);
    assert(['需求分析', '架构设计', '开发阶段', '测试阶段', '文档整理'].includes(currentStage));
    
    // 验证任务状态一致性
    const tasks = parseTasks(tasksMd);
    tasks.forEach(task => {
        assert(['待开始', '处理中', '已完成', '失败'].includes(task.status));
    });
}
```

### 4.4 触发机制测试

**测试目标**: 验证触发器功能正常工作

| 用例ID | 测试项 | 输入 | 预期结果 |
|--------|--------|------|----------|
| TG-001 | 自动触发 | 需要触发=是 | 自动触发下一步 |
| TG-002 | 触发标志 | 任务完成 | 需要触发标志正确 |

```javascript
/**
 * 测试用例: 触发机制
 */
export async function testTriggerMechanism(projectPath) {
    // 读取 TASKS.md
    const tasksMd = await readTasksMd(projectPath);
    
    // 验证需要触发标志
    const triggerRequired = extractTriggerRequired(tasksMd);
    assert(['是', '否'].includes(triggerRequired));
    
    // 验证触发逻辑
    const currentStage = extractCurrentStage(tasksMd);
    const nextRole = extractNextRole(tasksMd);
    assert(nextRole !== null);
}
```

### 4.5 完整流程测试

**测试目标**: 验证完整工作流程

| 用例ID | 测试项 | 测试范围 | 预期结果 |
|--------|--------|----------|----------|
| E2E-001 | 完整流程 | product→architect→developer→qa→writer | 全流程成功 |

```javascript
/**
 * 测试用例: 完整流程
 */
export async function testCompleteWorkflow(projectPath) {
    const roles = ['product', 'architect', 'developer', 'qa', 'writer'];
    
    // 验证每个角色的任务状态
    const tasksMd = await readTasksMd(projectPath);
    const tasks = parseTasks(tasksMd);
    
    // 验证角色流转链
    for (let i = 0; i < roles.length - 1; i++) {
        const currentTask = tasks.find(t => t.role === roles[i]);
        const nextTask = tasks.find(t => t.role === roles[i + 1]);
        
        // 如果当前任务已完成，下一个任务应该已触发
        if (currentTask.status === '已完成') {
            assert(['待开始', '处理中', '已完成'].includes(nextTask.status));
        }
    }
}
```

---

## 5. 验证方案

### 5.1 文件验证器 (file-verifier.js)

```javascript
/**
 * 文件验证器 - 验证文件内容
 */
export class FileVerifier {
    /**
     * 验证文件存在
     */
    static async exists(filePath) {
        try {
            await fs.access(filePath);
            return true;
        } catch {
            return false;
        }
    }

    /**
     * 验证文件内容包含
     */
    static async contains(filePath, content) {
        const fileContent = await fs.readFile(filePath, 'utf-8');
        return fileContent.includes(content);
    }

    /**
     * 验证文件内容匹配
     */
    static async matches(filePath, pattern) {
        const fileContent = await fs.readFile(filePath, 'utf-8');
        return pattern.test(fileContent);
    }
}
```

### 5.2 状态验证器 (state-verifier.js)

```javascript
/**
 * 状态验证器 - 验证任务状态
 */
export class StateVerifier {
    /**
     * 解析 TASKS.md
     */
    static async parseTasksMd(projectPath) {
        const content = await fs.readFile(`${projectPath}/shared/TASKS.md`, 'utf-8');
        
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
    static extractCurrentStage(content) {
        const match = content.match(/当前阶段:\s*(.+)/);
        return match ? match[1].trim() : null;
    }

    /**
     * 提取下一步角色
     */
    static extractNextRole(content) {
        const match = content.match(/下一步角色:\s*(\w+)/);
        return match ? match[1].trim() : null;
    }

    /**
     * 提取需要触发
     */
    static extractTriggerRequired(content) {
        const match = content.match(/需要触发:\s*(是|否)/);
        return match ? match[1].trim() : null;
    }

    /**
     * 提取任务列表
     */
    static extractTasks(content) {
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
}
```

### 5.3 断言库 (assertions.js)

```javascript
/**
 * 自定义断言库
 */
export function assert(condition, message) {
    if (!condition) {
        throw new Error(`断言失败: ${message}`);
    }
}

export function assertEquals(actual, expected, message) {
    if (actual !== expected) {
        throw new Error(`断言失败: 期望 "${expected}"，实际 "${actual}"。${message}`);
    }
}

export function assertContains(content, substring, message) {
    if (!content.includes(substring)) {
        throw new Error(`断言失败: 内容不包含 "${substring}"。${message}`);
    }
}

export function assertMatches(content, pattern, message) {
    if (!pattern.test(content)) {
        throw new Error(`断言失败: 内容不匹配模式 "${pattern}"。${message}`);
    }
}
```

---

## 6. 测试执行流程

### 6.1 测试脚本 (run-tests.js)

```javascript
import { TestLauncher } from './test-launcher.js';
import { ResultCollector } from './result-collector.js';
import { ReportGenerator } from './report-generator.js';
import { testTaskDistribution, testRoleTransition, testStateManagement, testTriggerMechanism, testCompleteWorkflow } from './test-cases.js';

async function main() {
    const collector = new ResultCollector();
    const launcher = new TestLauncher({
        projectPath: process.env.PROJECT_PATH
    });

    try {
        console.log('🚀 开始测试工作流系统...\n');

        // 1. 初始化测试环境
        console.log('📦 初始化测试环境...');
        await launcher.setup();

        // 2. 执行测试用例
        console.log('🧪 执行测试用例...\n');

        // 任务分发测试
        try {
            await testTaskDistribution(launcher.projectPath);
            collector.record('TD-001', '任务分发测试', true);
            console.log('✅ TD-001: 任务分发测试');
        } catch (error) {
            collector.record('TD-001', '任务分发测试', false, error.message);
            console.log('❌ TD-001: 任务分发测试 -', error.message);
        }

        // 角色流转测试
        try {
            await testRoleTransition(launcher.projectPath);
            collector.record('RT-001', '角色流转测试', true);
            console.log('✅ RT-001: 角色流转测试');
        } catch (error) {
            collector.record('RT-001', '角色流转测试', false, error.message);
            console.log('❌ RT-001: 角色流转测试 -', error.message);
        }

        // 状态管理测试
        try {
            await testStateManagement(launcher.projectPath);
            collector.record('SM-001', '状态管理测试', true);
            console.log('✅ SM-001: 状态管理测试');
        } catch (error) {
            collector.record('SM-001', '状态管理测试', false, error.message);
            console.log('❌ SM-001: 状态管理测试 -', error.message);
        }

        // 触发机制测试
        try {
            await testTriggerMechanism(launcher.projectPath);
            collector.record('TG-001', '触发机制测试', true);
            console.log('✅ TG-001: 触发机制测试');
        } catch (error) {
            collector.record('TG-001', '触发机制测试', false, error.message);
            console.log('❌ TG-001: 触发机制测试 -', error.message);
        }

        // 完整流程测试
        try {
            await testCompleteWorkflow(launcher.projectPath);
            collector.record('E2E-001', '完整流程测试', true);
            console.log('✅ E2E-001: 完整流程测试');
        } catch (error) {
            collector.record('E2E-001', '完整流程测试', false, error.message);
            console.log('❌ E2E-001: 完整流程测试 -', error.message);
        }

        // 3. 生成测试报告
        console.log('\n📊 生成测试报告...');
        const summary = collector.getSummary();
        const reporter = new ReportGenerator();
        const report = reporter.generateMarkdown(collector.results, summary);
        
        console.log('\n' + report);

        // 4. 清理测试环境
        console.log('\n🧹 清理测试环境...');
        await launcher.cleanup();

        console.log('\n✨ 测试完成！');

    } catch (error) {
        console.error('❌ 测试失败:', error);
    }
}

main();
```

### 6.2 测试命令

```bash
# 运行所有测试
npm test

# 运行指定测试
npm test -- --grep "任务分发"

# 详细日志模式
npm test -- --verbose

# 生成报告
npm test -- --report
```

---

## 7. 测试报告模板

### 7.1 Markdown 格式

```markdown
# 测试报告 - 工作流系统测试

## 测试概览

- 测试时间: 2026-03-25 18:00:00
- 测试项目: test-20260325-175155
- 总用例数: 5
- 通过数: 5
- 失败数: 0
- 通过率: 100.00%

## 测试结果

### 任务分发测试
- ✅ TD-001: 任务分发测试

### 角色流转测试
- ✅ RT-001: 角色流转测试

### 状态管理测试
- ✅ SM-001: 状态管理测试

### 触发机制测试
- ✅ TG-001: 触发机制测试

### 完整流程测试
- ✅ E2E-001: 完整流程测试

## 失败详情

无

## 测试环境

- OpenClaw 版本: v1.0.0
- Node.js 版本: v22.22.1
- 操作系统: Linux 5.15.0-170-generic

## 建议

- 所有测试通过，工作流系统运行正常
- 建议持续监控工作流性能指标
```

---

## 8. 性能指标

### 8.1 测试性能要求

| 指标 | 要求 |
|------|------|
| 单个测试用例执行时间 | < 3秒 |
| 完整测试套件执行时间 | < 2分钟 |
| 测试报告生成时间 | < 5秒 |

### 8.2 系统性能验证

| 指标 | 要求 |
|------|------|
| 任务分发响应时间 | < 1秒 |
| 角色流转时间 | < 2秒 |
| 状态更新时间 | < 1秒 |
| 触发器响应时间 | < 2秒 |

---

## 9. 异常处理

### 9.1 测试失败处理

| 异常类型 | 处理方式 |
|----------|----------|
| 文件不存在 | 记录错误，标记测试失败 |
| 内容不匹配 | 记录预期值和实际值，继续执行 |
| 格式错误 | 记录错误详情，标记测试失败 |
| 超时 | 设置3秒超时，超时后标记失败 |

### 9.2 清理机制

```javascript
/**
 * 测试清理
 */
async function cleanup() {
    try {
        // 删除测试项目
        await fs.rm(testProjectPath, { recursive: true });
        
        // 清理临时文件
        await fs.rm(tempDir, { recursive: true });
        
        // 重置测试状态
        testState.reset();
        
    } catch (error) {
        console.warn('清理失败:', error.message);
    }
}
```

---

## 10. 项目结构

```
test-20260325-175155/
├── shared/
│   ├── TASKS.md           # 任务清单
│   ├── PRD.md             # 产品需求文档
│   └── ARCHITECTURE.md    # 架构设计文档
├── tests/
│   ├── test-launcher.js   # 测试启动器
│   ├── test-cases.js      # 测试用例
│   ├── file-verifier.js   # 文件验证器
│   ├── state-verifier.js  # 状态验证器
│   ├── assertions.js      # 断言库
│   ├── result-collector.js # 结果收集器
│   ├── report-generator.js # 报告生成器
│   └── run-tests.js       # 测试入口
├── package.json           # 项目配置
└── README.md              # 项目说明
```

---

## 11. 扩展性设计

### 11.1 未来扩展方向

- 支持并行测试执行
- 支持测试报告可视化
- 支持自定义测试用例
- 支持测试数据持久化
- 支持测试覆盖率分析

### 11.2 扩展接口

```javascript
/**
 * 测试用例接口
 */
interface TestCase {
    id: string;
    name: string;
    category: string;
    run(projectPath: string): Promise<boolean>;
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
**创建日期**: 2026-03-25  
**版本**: v1.0