# 架构设计文档 - 计算器应用

## 1. 技术选型

### 1.1 前端技术栈

| 技术 | 选择 | 理由 |
|------|------|------|
| **HTML5** | 核心结构 | 语义化标签，良好的可访问性，SEO友好 |
| **CSS3** | 样式设计 | Flexbox/Grid布局，响应式设计，原生CSS变量 |
| **JavaScript (ES6+)** | 交互逻辑 | 原生JS，无框架依赖，轻量高效 |
| **ES Modules** | 模块化 | 代码组织清晰，便于维护和测试 |

### 1.2 开发工具

| 工具 | 用途 |
|------|------|
| **VS Code** | 开发编辑器（推荐） |
| **Live Server** | 本地开发服务器（支持热重载） |
| **ESLint** | JavaScript代码质量检查 |
| **Prettier** | 代码格式化 |

### 1.3 部署方案

| 方案 | 说明 |
|------|------|
| **静态托管** | GitHub Pages / Vercel / Netlify |
| **CDN加速** | 可选，提升全球访问速度 |
| **零运维** | 纯前端应用，无需服务器 |

---

## 2. 系统架构

### 2.1 整体架构图

```
┌─────────────────────────────────────────────────────────────┐
│                        表现层 (UI)                          │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │ 显示区域     │  │ 数字键盘     │  │ 运算符面板          │  │
│  │ (Display)   │  │ (Numpad)    │  │ (Operators)        │  │
│  └─────────────┘  └─────────────┘  └─────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                       业务逻辑层                            │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │ 输入处理器   │  │ 计算引擎     │  │ 状态管理器          │  │
│  │ (Input)     │  │ (Calculator)│  │ (State)            │  │
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
├── index.html              # 应用入口HTML
├── css/
│   ├── normalize.css       # CSS Reset
│   ├── variables.css       # CSS变量定义
│   └── main.css            # 主样式文件
├── js/
│   ├── main.js             # 应用主入口
│   ├── modules/
│   │   ├── calculator.js   # 计算引擎
│   │   ├── input.js        # 输入处理
│   │   ├── display.js      # 显示控制
│   │   └── state.js        # 状态管理
│   └── utils/
│       ├── validators.js   # 输入验证
│       └── formatters.js   # 数字格式化
└── README.md               # 项目说明文档
```

---

## 3. 核心模块设计

### 3.1 计算引擎 (calculator.js)

**职责**: 提供基础的四则运算功能

```javascript
/**
 * 计算引擎模块
 */
export class Calculator {
    /**
     * 加法运算
     */
    static add(a, b) {
        return a + b;
    }

    /**
     * 减法运算
     */
    static subtract(a, b) {
        return a - b;
    }

    /**
     * 乘法运算
     */
    static multiply(a, b) {
        return a * b;
    }

    /**
     * 除法运算
     * @throws {Error} 除数为0时抛出错误
     */
    static divide(a, b) {
        if (b === 0) {
            throw new Error('除数不能为0');
        }
        return a / b;
    }

    /**
     * 执行运算
     */
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

**职责**: 管理应用状态

```javascript
/**
 * 状态管理器
 */
export class StateManager {
    constructor() {
        this.state = {
            currentInput: '0',      // 当前输入值
            previousInput: null,     // 上一个操作数
            operator: null,          // 当前运算符
            waitingForOperand: false // 是否等待新操作数
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

    setCurrentInput(value) {
        this.setState({ currentInput: value });
    }

    setOperator(operator) {
        this.setState({
            operator,
            previousInput: this.state.currentInput,
            waitingForOperand: true
        });
    }
}
```

### 3.3 输入处理器 (input.js)

**职责**: 处理用户输入

```javascript
/**
 * 输入处理器
 */
export class InputHandler {
    constructor(stateManager) {
        this.stateManager = stateManager;
    }

    /**
     * 处理数字输入
     */
    handleDigit(digit) {
        const state = this.stateManager.getState();
        
        if (state.waitingForOperand) {
            this.stateManager.setCurrentInput(digit);
            this.stateManager.setState({ waitingForOperand: false });
        } else {
            const newInput = state.currentInput === '0' 
                ? digit 
                : state.currentInput + digit;
            this.stateManager.setCurrentInput(newInput);
        }
    }

    /**
     * 处理小数点输入
     */
    handleDecimal() {
        const state = this.stateManager.getState();
        
        if (state.waitingForOperand) {
            this.stateManager.setCurrentInput('0.');
            this.stateManager.setState({ waitingForOperand: false });
        } else if (!state.currentInput.includes('.')) {
            this.stateManager.setCurrentInput(state.currentInput + '.');
        }
    }

    /**
     * 处理运算符输入
     */
    handleOperator(operator) {
        this.stateManager.setOperator(operator);
    }

    /**
     * 处理清除操作
     */
    handleClear() {
        this.stateManager.reset();
    }

    /**
     * 处理退格操作
     */
    handleBackspace() {
        const state = this.stateManager.getState();
        const newInput = state.currentInput.length > 1 
            ? state.currentInput.slice(0, -1)
            : '0';
        this.stateManager.setCurrentInput(newInput);
    }
}
```

### 3.4 显示控制器 (display.js)

**职责**: 更新UI显示

```javascript
/**
 * 显示控制器
 */
export class DisplayController {
    constructor(displayElement) {
        this.displayElement = displayElement;
    }

    /**
     * 更新显示内容
     */
    update(value) {
        this.displayElement.textContent = value;
    }

    /**
     * 显示错误信息
     */
    showError(message) {
        this.displayElement.textContent = message;
        this.displayElement.classList.add('error');
        
        setTimeout(() => {
            this.displayElement.classList.remove('error');
        }, 2000);
    }

    /**
     * 清空显示
     */
    clear() {
        this.update('0');
    }
}
```

### 3.5 主入口 (main.js)

**职责**: 初始化应用和事件绑定

```javascript
import { Calculator } from './modules/calculator.js';
import { StateManager } from './modules/state.js';
import { InputHandler } from './modules/input.js';
import { DisplayController } from './modules/display.js';

/**
 * 计算器应用主类
 */
class CalculatorApp {
    constructor() {
        // 初始化组件
        this.stateManager = new StateManager();
        this.inputHandler = new InputHandler(this.stateManager);
        this.displayController = new DisplayController(
            document.querySelector('.display')
        );
        
        // 绑定事件
        this.bindEvents();
        
        // 初始显示
        this.render();
    }

    /**
     * 绑定事件监听器
     */
    bindEvents() {
        // 数字按钮
        document.querySelectorAll('.btn-digit').forEach(btn => {
            btn.addEventListener('click', (e) => {
                this.inputHandler.handleDigit(e.target.dataset.value);
                this.render();
            });
        });

        // 运算符按钮
        document.querySelectorAll('.btn-operator').forEach(btn => {
            btn.addEventListener('click', (e) => {
                this.inputHandler.handleOperator(e.target.dataset.value);
            });
        });

        // 等号按钮
        document.querySelector('.btn-equals').addEventListener('click', () => {
            this.calculate();
        });

        // 清除按钮
        document.querySelector('.btn-clear').addEventListener('click', () => {
            this.inputHandler.handleClear();
            this.render();
        });

        // 键盘支持
        document.addEventListener('keydown', (e) => {
            this.handleKeyboard(e);
        });
    }

    /**
     * 执行计算
     */
    calculate() {
        const state = this.stateManager.getState();
        
        if (state.previousInput === null || state.operator === null) {
            return;
        }

        try {
            const a = parseFloat(state.previousInput);
            const b = parseFloat(state.currentInput);
            const result = Calculator.calculate(a, b, state.operator);
            
            this.stateManager.setState({
                currentInput: String(result),
                previousInput: null,
                operator: null,
                waitingForOperand: true
            });
            
            this.render();
        } catch (error) {
            this.displayController.showError(error.message);
            this.inputHandler.handleClear();
        }
    }

    /**
     * 处理键盘输入
     */
    handleKeyboard(e) {
        const key = e.key;
        
        if (/[0-9]/.test(key)) {
            this.inputHandler.handleDigit(key);
            this.render();
        } else if (key === '.') {
            this.inputHandler.handleDecimal();
            this.render();
        } else if (['+', '-', '*', '/'].includes(key)) {
            const operatorMap = { '+': '+', '-': '-', '*': '×', '/': '÷' };
            this.inputHandler.handleOperator(operatorMap[key]);
        } else if (key === 'Enter' || key === '=') {
            this.calculate();
        } else if (key === 'Escape' || key === 'c' || key === 'C') {
            this.inputHandler.handleClear();
            this.render();
        }
    }

    /**
     * 渲染显示
     */
    render() {
        const state = this.stateManager.getState();
        this.displayController.update(state.currentInput);
    }
}

// 启动应用
document.addEventListener('DOMContentLoaded', () => {
    new CalculatorApp();
});
```

---

## 4. 数据流设计

### 4.1 用户操作流程

```
用户点击按钮
    │
    ▼
事件监听器捕获
    │
    ├─→ 数字按钮 → InputHandler.handleDigit() → StateManager 更新 → Display 更新
    │
    ├─→ 运算符按钮 → InputHandler.handleOperator() → StateManager 存储
    │
    ├─→ 等号按钮 → Calculator.calculate() → 计算结果 → StateManager 更新 → Display 更新
    │
    └─→ 清除按钮 → InputHandler.handleClear() → StateManager 重置 → Display 更新
```

### 4.2 状态流转

```
初始状态
├─ currentInput: '0'
├─ previousInput: null
├─ operator: null
└─ waitingForOperand: false

输入数字 '5'
├─ currentInput: '5'
├─ previousInput: null
├─ operator: null
└─ waitingForOperand: false

点击 '+'
├─ currentInput: '5'
├─ previousInput: '5'
├─ operator: '+'
└─ waitingForOperand: true

输入数字 '3'
├─ currentInput: '3'
├─ previousInput: '5'
├─ operator: '+'
└─ waitingForOperand: false

点击 '='
├─ currentInput: '8'
├─ previousInput: null
├─ operator: null
└─ waitingForOperand: true
```

---

## 5. 接口设计

### 5.1 计算引擎 API

| 方法 | 参数 | 返回值 | 说明 |
|------|------|--------|------|
| `add(a, b)` | number, number | number | 加法运算 |
| `subtract(a, b)` | number, number | number | 减法运算 |
| `multiply(a, b)` | number, number | number | 乘法运算 |
| `divide(a, b)` | number, number | number | 除法运算（除数为0抛出错误）|
| `calculate(a, b, operator)` | number, number, string | number | 通用计算方法 |

### 5.2 状态管理 API

| 方法 | 参数 | 返回值 | 说明 |
|------|------|--------|------|
| `getState()` | 无 | Object | 获取当前状态快照 |
| `setState(newState)` | Object | void | 更新状态 |
| `reset()` | 无 | void | 重置为初始状态 |
| `setCurrentInput(value)` | string | void | 设置当前输入值 |
| `setOperator(operator)` | string | void | 设置运算符 |

### 5.3 输入处理 API

| 方法 | 参数 | 返回值 | 说明 |
|------|------|--------|------|
| `handleDigit(digit)` | string | void | 处理数字输入 |
| `handleDecimal()` | 无 | void | 处理小数点输入 |
| `handleOperator(operator)` | string | void | 处理运算符输入 |
| `handleClear()` | 无 | void | 处理清除操作 |
| `handleBackspace()` | 无 | void | 处理退格操作 |

---

## 6. UI设计

### 6.1 布局结构

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

### 6.2 CSS变量定义

```css
:root {
    /* 颜色变量 */
    --color-primary: #4A90E2;
    --color-secondary: #F5F5F5;
    --color-text: #333333;
    --color-error: #E74C3C;
    
    /* 按钮尺寸 */
    --button-size: 60px;
    --button-gap: 10px;
    
    /* 字体 */
    --font-family: 'Segoe UI', Arial, sans-serif;
    --font-size-display: 48px;
    --font-size-button: 24px;
}
```

### 6.3 响应式断点

| 设备 | 断点 | 布局特点 |
|------|------|----------|
| 移动端 | < 768px | 按钮自适应，最小 44px × 44px |
| 平板 | 768px - 1024px | 居中，固定宽度 400px |
| 桌面 | > 1024px | 居中，最大宽度 400px |

---

## 7. 测试策略

### 7.1 单元测试

| 测试模块 | 测试内容 |
|----------|----------|
| Calculator | 四则运算正确性、除零错误处理、边界值 |
| StateManager | 状态更新、重置、状态一致性 |
| InputHandler | 数字输入、运算符处理、边界情况 |
| DisplayController | 显示更新、错误提示 |

### 7.2 集成测试

| 测试场景 | 测试内容 |
|----------|----------|
| 完整计算流程 | 输入 → 计算 → 显示结果 |
| 连续运算 | 多次运算的连续操作 |
| 错误处理 | 除零、非法输入的处理 |

### 7.3 E2E测试

| 测试场景 | 测试步骤 |
|----------|----------|
| 加法运算 | 输入5 + 3 =，验证显示8 |
| 除零错误 | 输入5 ÷ 0 =，验证显示错误 |
| 清除功能 | 输入数字，点击C，验证清空 |

---

## 8. 性能优化

### 8.1 性能指标

| 指标 | 要求 |
|------|------|
| 页面加载时间 | < 2秒 |
| 计算响应时间 | < 100ms |
| 按钮点击响应 | < 50ms |

### 8.2 优化策略

- **单文件部署**: 可选将HTML、CSS、JS合并为单文件
- **最小化请求**: 减少HTTP请求数量
- **事件委托**: 使用事件委托减少监听器数量

---

## 9. 安全考虑

| 风险 | 缓解措施 |
|------|----------|
| XSS攻击 | 无用户输入存储，风险极低 |
| 代码注入 | 无eval使用，安全 |
| 数值溢出 | 使用 `Number.isFinite()` 检查结果 |
| 精度问题 | 使用 `toFixed()` 或 `toPrecision()` 处理浮点数 |

---

## 10. 部署方案

### 10.1 部署流程

```
本地开发 → Git提交 → GitHub Actions构建 → 自动部署到GitHub Pages
```

### 10.2 GitHub Pages 配置

```yaml
name: Deploy to GitHub Pages

on:
  push:
    branches: [ main ]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Deploy
        uses: peaceiris/actions-gh-pages@v3
        with:
          github_token: ${{ secrets.GITHUB_TOKEN }}
          publish_dir: ./
```

---

## 11. 扩展性设计

### 11.1 未来扩展方向

- **科学计算**: 支持三角函数、对数、幂运算
- **历史记录**: 保存计算历史
- **主题切换**: 深色/浅色主题
- **多语言支持**: 国际化

### 11.2 扩展接口

```javascript
/**
 * 计算器插件接口
 */
interface CalculatorPlugin {
    name: string;
    init(calculator: CalculatorApp): void;
    destroy(): void;
}
```

---

## 12. 开发计划

### 12.1 开发阶段

| 阶段 | 内容 | 时间 |
|------|------|------|
| Phase 1 | 项目初始化、目录结构 | 0.5天 |
| Phase 2 | 核心模块开发 | 1天 |
| Phase 3 | UI实现 | 0.5天 |
| Phase 4 | 事件绑定和集成 | 0.5天 |
| Phase 5 | 单元测试 | 0.5天 |
| Phase 6 | 集成测试和优化 | 0.5天 |
| Phase 7 | 部署和文档 | 0.5天 |

### 12.2 交付物

- [ ] 源代码（HTML、CSS、JavaScript）
- [ ] 单元测试代码
- [ ] README.md 文档
- [ ] 在线演示地址

---

**架构师**: architect  
**创建日期**: 2026-03-25  
**版本**: v1.0  
**项目**: auto-test-20260325-211808