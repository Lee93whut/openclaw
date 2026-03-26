# 架构设计文档 - 计算器应用

## 1. 技术选型

### 1.1 前端技术栈

| 技术 | 选择 | 理由 |
|------|------|------|
| **HTML5** | 核心结构 | 语义化标签，良好的可访问性 |
| **CSS3** | 样式设计 | Flexbox/Grid布局，响应式设计，无需预处理器 |
| **JavaScript (ES6+)** | 交互逻辑 | 原生JS，无需框架依赖，轻量高效 |
| **模块化设计** | ES Modules | 代码组织清晰，便于维护和测试 |

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
| **CDN加速** | 提升全球访问速度 |
| **无需服务器** | 纯前端应用，降低运维成本 |

---

## 2. 系统架构

### 2.1 整体架构图

```
┌─────────────────────────────────────────────────────────────┐
│                        用户界面层                            │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │ 显示区域     │  │ 数字按钮    │  │ 运算符/功能按钮     │  │
│  │ (Display)   │  │ (0-9)      │  │ (+ - × ÷ = C)      │  │
│  └─────────────┘  └─────────────┘  └─────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                       业务逻辑层                             │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │ 事件处理器   │  │ 计算引擎    │  │ 状态管理器          │  │
│  │ (Events)    │  │ (Calculator)│  │ (State)            │  │
│  └─────────────┘  └─────────────┘  └─────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                        数据层                                │
│  ┌───────────────────────────────────────────────────────┐  │
│  │ 计算状态：currentValue, previousValue, operator       │  │
│  └───────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

### 2.2 模块划分

```
calculator/
├── index.html          # 入口HTML
├── styles/
│   └── main.css        # 样式文件
├── scripts/
│   ├── main.js         # 主入口
│   ├── calculator.js   # 计算引擎
│   ├── ui.js           # UI控制器
│   └── state.js        # 状态管理
└── tests/
    └── calculator.test.js  # 单元测试
```

---

## 3. 核心模块设计

### 3.1 计算引擎 (calculator.js)

```javascript
// 核心计算逻辑，无UI依赖
export function add(a, b) { return a + b; }
export function subtract(a, b) { return a - b; }
export function multiply(a, b) { return a * b; }
export function divide(a, b) {
    if (b === 0) throw new Error('除数不能为0');
    return a / b;
}
```

### 3.2 状态管理 (state.js)

```javascript
// 应用状态
const state = {
    currentValue: '0',      // 当前显示值
    previousValue: null,    // 上一个操作数
    operator: null,         // 当前运算符
    waitingForOperand: false // 是否等待新操作数
};

export function getState() { return { ...state }; }
export function setState(newState) { Object.assign(state, newState); }
export function resetState() { /* 重置为初始状态 */ }
```

### 3.3 UI控制器 (ui.js)

```javascript
// UI交互逻辑
export function updateDisplay(value) { /* 更新显示 */ }
export function highlightOperator(op) { /* 高亮当前运算符 */ }
export function showError(message) { /* 显示错误提示 */ }
```

### 3.4 主入口 (main.js)

```javascript
// 事件绑定与模块协调
import * as calculator from './calculator.js';
import * as state from './state.js';
import * as ui from './ui.js';

// 初始化事件监听
document.querySelectorAll('.btn-number').forEach(btn => {
    btn.addEventListener('click', handleNumberClick);
});
// ... 其他事件绑定
```

---

## 4. 数据流设计

### 4.1 用户操作流程

```
用户点击按钮
    │
    ▼
事件处理器捕获
    │
    ▼
判断按钮类型
    ├── 数字 → 更新currentValue → 更新显示
    ├── 运算符 → 存储operator和previousValue
    ├── 等号 → 调用计算引擎 → 更新显示
    └── 清除 → 重置状态 → 清空显示
```

### 4.2 状态流转

```
初始状态
    │ [输入数字]
    ▼
输入第一个操作数
    │ [选择运算符]
    ▼
等待第二个操作数
    │ [输入数字]
    ▼
输入第二个操作数
    │ [点击等号]
    ▼
显示计算结果
    │ [继续运算或清除]
    ▼
循环或重置
```

---

## 5. 接口设计

### 5.1 计算引擎API

| 方法 | 参数 | 返回值 | 说明 |
|------|------|--------|------|
| `add(a, b)` | number, number | number | 加法运算 |
| `subtract(a, b)` | number, number | number | 减法运算 |
| `multiply(a, b)` | number, number | number | 乘法运算 |
| `divide(a, b)` | number, number | number \| Error | 除法运算（除数为0抛出错误）|

### 5.2 状态管理API

| 方法 | 参数 | 返回值 | 说明 |
|------|------|--------|------|
| `getState()` | 无 | object | 获取当前状态快照 |
| `setState(obj)` | object | void | 更新状态 |
| `resetState()` | 无 | void | 重置为初始状态 |

### 5.3 UI控制器API

| 方法 | 参数 | 返回值 | 说明 |
|------|------|--------|------|
| `updateDisplay(value)` | string | void | 更新显示区域 |
| `highlightOperator(op)` | string | void | 高亮当前运算符 |
| `showError(msg)` | string | void | 显示错误信息 |

---

## 6. 响应式设计

### 6.1 布局断点

| 设备 | 断点 | 布局特点 |
|------|------|----------|
| 移动端 | < 768px | 单列，按钮自适应大小 |
| 平板 | 768px - 1024px | 居中显示，固定宽度 |
| 桌面 | > 1024px | 居中显示，最大宽度限制 |

### 6.2 交互适配

- **移动端**：触摸友好，按钮最小 44px × 44px
- **桌面端**：支持键盘输入（数字键、运算符、Enter、Escape）

---

## 7. 性能优化

### 7.1 加载优化

- 使用单HTML文件 + 内联CSS（可选）
- JS模块按需加载
- 无外部依赖，最小化HTTP请求

### 7.2 运行优化

- 计算结果实时更新，无网络请求
- 使用 `requestAnimationFrame` 处理UI更新（如需要）
- 防抖处理连续点击（可选）

---

## 8. 测试策略

### 8.1 单元测试

| 测试范围 | 测试内容 |
|----------|----------|
| 计算引擎 | 四则运算正确性、除零错误处理 |
| 状态管理 | 状态更新、重置功能 |
| UI控制器 | 显示更新、错误提示 |

### 8.2 集成测试

- 完整用户操作流程测试
- 边界条件测试（最大值、最小值、精度问题）

### 8.3 兼容性测试

- Chrome, Firefox, Safari, Edge 最新两个版本
- iOS Safari, Android Chrome

---

## 9. 安全考虑

| 风险 | 缓解措施 |
|------|----------|
| XSS攻击 | 无用户输入存储，无风险 |
| 代码注入 | 无eval使用，安全 |
| 数值溢出 | 使用 Number.isFinite() 检查结果 |

---

## 10. 部署方案

### 10.1 推荐部署流程

```
本地开发 → Git提交 → GitHub Actions自动构建 → 部署到GitHub Pages
```

### 10.2 部署配置

```yaml
# .github/workflows/deploy.yml
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

- 支持更多运算（科学计算、百分比、开方）
- 历史记录功能
- 主题切换（深色/浅色）
- 多语言支持

### 11.2 扩展友好设计

- 计算引擎独立模块，易于添加新运算
- 样式使用CSS变量，方便主题定制
- 状态管理可扩展，支持持久化存储

---

**架构师**: architect  
**创建日期**: 2026-03-25  
**版本**: v1.0