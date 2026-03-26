# 架构设计文档 - 计算器应用

## 1. 技术选型

### 1.1 前端技术栈

| 技术 | 选择 | 理由 |
|------|------|------|
| **HTML5** | 核心结构 | 语义化标签，良好的可访问性 |
| **CSS3** | 样式设计 | Flexbox/Grid布局，响应式设计 |
| **JavaScript (ES6+)** | 交互逻辑 | 原生JS，无需框架依赖 |
| **ES Modules** | 模块化 | 代码组织清晰，易于维护 |

### 1.2 开发工具

| 工具 | 用途 |
|------|------|
| **VS Code** | 开发编辑器 |
| **Live Server** | 本地开发服务器 |
| **ESLint** | 代码质量检查 |

### 1.3 部署方案

| 方案 | 说明 |
|------|------|
| **静态托管** | GitHub Pages / Vercel / Netlify |
| **CDN加速** | 可选，提升访问速度 |
| **零运维** | 纯前端应用 |

---

## 2. 系统架构

### 2.1 整体架构图

```
┌─────────────────────────────────────────────────────────────┐
│                        表现层 (UI)                          │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │ 显示区域     │  │ 数字键盘     │  │ 运算符面板          │  │
│  └─────────────┘  └─────────────┘  └─────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                       业务逻辑层                            │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │ 输入处理器   │  │ 计算引擎     │  │ 状态管理器          │  │
│  └─────────────┘  └─────────────┘  └─────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                        数据层                               │
│  ┌───────────────────────────────────────────────────────┐  │
│  │ 应用状态: currentInput, previousInput, operator       │  │
│  └───────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

### 2.2 模块划分

```
calculator/
├── index.html              # 应用入口
├── css/
│   ├── normalize.css       # CSS Reset
│   ├── variables.css       # CSS变量
│   └── main.css            # 主样式
├── js/
│   ├── main.js             # 主入口
│   ├── modules/
│   │   ├── calculator.js   # 计算引擎
│   │   ├── input.js        # 输入处理
│   │   ├── display.js      # 显示控制
│   │   └── state.js        # 状态管理
│   └── utils/
│       ├── validators.js   # 输入验证
│       └── formatters.js   # 数字格式化
└── README.md
```

---

## 3. 核心模块设计

### 3.1 计算引擎 (calculator.js)

```javascript
/**
 * 计算引擎模块
 */
export class Calculator {
    static add(a, b) {
        return a + b;
    }

    static subtract(a, b) {
        return a - b;
    }

    static multiply(a, b) {
        return a * b;
    }

    static divide(a, b) {
        if (b === 0) {
            throw new Error('除数不能为0');
        }
        return a / b;
    }

    static calculate(a, b, operator) {
        switch (operator) {
            case '+': return this.add(a, b);
            case '-': return this.subtract(a, b);
            case '×': return this.multiply(a, b);
            case '÷': return this.divide(a, b);
            default: throw new Error(`未知运算符: ${operator}`);
        }
    }
}
```

### 3.2 状态管理器 (state.js)

```javascript
/**
 * 状态管理器
 */
export class StateManager {
    constructor() {
        this.state = {
            currentInput: '0',
            previousInput: null,
            operator: null,
            waitingForOperand: false
        };
    }

    getState() {
        return { ...this.state };
    }

    setState(newState) {
        this.state = { ...this.state, ...newState };
    }

    reset() {
        this.state = {
            currentInput: '0',
            previousInput: null,
            operator: null,
            waitingForOperand: false
        };
    }
}
```

### 3.3 输入处理器 (input.js)

```javascript
/**
 * 输入处理器
 */
export class InputHandler {
    constructor(stateManager) {
        this.stateManager = stateManager;
    }

    handleDigit(digit) {
        const state = this.stateManager.getState();
        
        if (state.waitingForOperand) {
            this.stateManager.setState({ 
                currentInput: digit,
                waitingForOperand: false 
            });
        } else {
            const newInput = state.currentInput === '0' 
                ? digit 
                : state.currentInput + digit;
            this.stateManager.setState({ currentInput: newInput });
        }
    }

    handleOperator(operator) {
        const state = this.stateManager.getState();
        this.stateManager.setState({
            operator,
            previousInput: state.currentInput,
            waitingForOperand: true
        });
    }

    handleClear() {
        this.stateManager.reset();
    }
}
```

### 3.4 显示控制器 (display.js)

```javascript
/**
 * 显示控制器
 */
export class DisplayController {
    constructor(displayElement) {
        this.displayElement = displayElement;
    }

    update(value) {
        this.displayElement.textContent = value;
    }

    showError(message) {
        this.displayElement.textContent = message;
        this.displayElement.classList.add('error');
        setTimeout(() => {
            this.displayElement.classList.remove('error');
        }, 2000);
    }
}
```

---

## 4. 接口设计

### 4.1 计算引擎 API

| 方法 | 参数 | 返回值 | 说明 |
|------|------|--------|------|
| `add(a, b)` | number, number | number | 加法运算 |
| `subtract(a, b)` | number, number | number | 减法运算 |
| `multiply(a, b)` | number, number | number | 乘法运算 |
| `divide(a, b)` | number, number | number | 除法运算 |
| `calculate(a, b, op)` | number, number, string | number | 通用计算 |

### 4.2 状态管理 API

| 方法 | 参数 | 返回值 | 说明 |
|------|------|--------|------|
| `getState()` | 无 | Object | 获取状态 |
| `setState(obj)` | Object | void | 更新状态 |
| `reset()` | 无 | void | 重置状态 |

---

## 5. UI设计

### 5.1 布局结构

```
┌────────────────────────────────┐
│         [显示区域]              │
│           0.00                 │
├────────────────────────────────┤
│  C     ←     ÷     ×          │
│  7     8     9      -          │
│  4     5     6      +          │
│  1     2     3     =           │
│  0           .     =           │
└────────────────────────────────┘
```

### 5.2 CSS变量

```css
:root {
    --color-primary: #4A90E2;
    --color-secondary: #F5F5F5;
    --color-text: #333333;
    --color-error: #E74C3C;
    --button-size: 60px;
    --font-size-display: 48px;
}
```

### 5.3 响应式断点

| 设备 | 断点 | 布局特点 |
|------|------|----------|
| 移动端 | < 768px | 按钮自适应，最小 44px × 44px |
| 平板 | 768px - 1024px | 居中，固定宽度 400px |
| 桌面 | > 1024px | 居中，最大宽度 400px |

---

## 6. 测试策略

### 6.1 单元测试

| 测试模块 | 测试内容 |
|----------|----------|
| Calculator | 四则运算正确性、除零错误 |
| StateManager | 状态更新、重置 |
| InputHandler | 数字输入、运算符处理 |

### 6.2 集成测试

| 测试场景 | 测试内容 |
|----------|----------|
| 计算流程 | 输入 → 计算 → 显示 |
| 错误处理 | 除零错误处理 |

---

## 7. 性能指标

| 指标 | 要求 |
|------|------|
| 页面加载时间 | < 2秒 |
| 计算响应时间 | < 100ms |
| 按钮点击响应 | < 50ms |

---

## 8. 项目结构

```
workflow-auto-test-20260325-175114/
├── shared/
│   ├── TASKS.md
│   ├── PRD.md
│   └── ARCHITECTURE.md
├── index.html
├── css/
├── js/
└── README.md
```

---

## 9. 工作流说明

### 9.1 工作流程

```
entry → pm → product → architect → developer → qa → writer
```

### 9.2 阶段说明

| 阶段 | 角色 | 说明 | 状态 |
|------|------|------|------|
| 入口处理 | entry | 入口处理 | 待开始 |
| 项目管理 | pm | 项目管理 | 待开始 |
| 需求分析 | product | 需求分析 | ✅ 已完成 |
| 架构设计 | architect | 架构设计 | 进行中 |
| 功能开发 | developer | 功能开发 | 待开始 |
| 测试执行 | qa | 测试执行 | 待开始 |
| 文档整理 | writer | 文档整理 | 待开始 |

---

**架构师**: architect  
**创建日期**: 2026-03-26  
**版本**: v1.0  
**项目**: workflow-auto-test-20260325-175114