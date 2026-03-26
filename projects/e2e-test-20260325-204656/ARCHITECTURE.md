# 架构设计文档 - 待办事项应用

## 1. 技术选型

### 1.1 前端技术栈

| 技术 | 选择 | 理由 |
|------|------|------|
| **HTML5** | 核心结构 | 语义化标签，良好的可访问性 |
| **CSS3** | 样式设计 | Flexbox/Grid布局，响应式设计 |
| **JavaScript (ES6+)** | 交互逻辑 | 原生JS，无需框架依赖 |
| **ES Modules** | 模块化 | 代码组织清晰，易于维护 |

### 1.2 数据存储

| 技术 | 选择 | 理由 |
|------|------|------|
| **LocalStorage** | 本地存储 | 浏览器原生支持，数据持久化 |
| **JSON** | 数据格式 | 简单易用，与JS无缝集成 |

### 1.3 开发工具

| 工具 | 用途 |
|------|------|
| **VS Code** | 开发编辑器 |
| **Live Server** | 本地开发服务器 |
| **ESLint** | 代码质量检查 |

### 1.4 部署方案

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
│  │ 任务列表     │  │ 任务表单     │  │ 筛选面板            │  │
│  └─────────────┘  └─────────────┘  └─────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                       业务逻辑层                            │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │ 任务管理器   │  │ 筛选处理器   │  │ 事件处理器          │  │
│  └─────────────┘  └─────────────┘  └─────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                        数据层                               │
│  ┌───────────────────────────────────────────────────────┐  │
│  │ 存储管理器 (StorageManager)                            │  │
│  │ - LocalStorage 操作封装                                │  │
│  │ - 数据序列化/反序列化                                   │  │
│  └───────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

### 2.2 模块划分

```
todo-app/
├── index.html              # 应用入口
├── css/
│   ├── normalize.css       # CSS Reset
│   ├── variables.css       # CSS变量
│   └── main.css            # 主样式
├── js/
│   ├── main.js             # 主入口
│   ├── modules/
│   │   ├── task-manager.js # 任务管理器
│   │   ├── storage.js      # 存储管理器
│   │   ├── filter.js       # 筛选处理器
│   │   └── renderer.js     # 渲染器
│   └── utils/
│       ├── validators.js   # 输入验证
│       ├── formatters.js   # 格式化工具
│       └── helpers.js      # 辅助函数
└── README.md
```

---

## 3. 核心模块设计

### 3.1 任务管理器 (task-manager.js)

```javascript
/**
 * 任务管理器
 */
export class TaskManager {
    constructor(storageManager) {
        this.storageManager = storageManager;
        this.tasks = this.loadTasks();
    }

    /**
     * 加载所有任务
     */
    loadTasks() {
        return this.storageManager.get('tasks') || [];
    }

    /**
     * 保存所有任务
     */
    saveTasks() {
        this.storageManager.set('tasks', this.tasks);
    }

    /**
     * 创建新任务
     */
    createTask(title, description = '', tags = []) {
        const task = {
            id: Date.now().toString(),
            title,
            description,
            tags,
            completed: false,
            createdAt: new Date().toISOString(),
            updatedAt: new Date().toISOString()
        };
        
        this.tasks.push(task);
        this.saveTasks();
        
        return task;
    }

    /**
     * 更新任务
     */
    updateTask(id, updates) {
        const index = this.tasks.findIndex(t => t.id === id);
        if (index === -1) {
            throw new Error('任务不存在');
        }
        
        this.tasks[index] = {
            ...this.tasks[index],
            ...updates,
            updatedAt: new Date().toISOString()
        };
        
        this.saveTasks();
        return this.tasks[index];
    }

    /**
     * 删除任务
     */
    deleteTask(id) {
        const index = this.tasks.findIndex(t => t.id === id);
        if (index === -1) {
            throw new Error('任务不存在');
        }
        
        this.tasks.splice(index, 1);
        this.saveTasks();
        
        return true;
    }

    /**
     * 切换任务完成状态
     */
    toggleTask(id) {
        const task = this.tasks.find(t => t.id === id);
        if (!task) {
            throw new Error('任务不存在');
        }
        
        return this.updateTask(id, { completed: !task.completed });
    }

    /**
     * 获取任务列表
     */
    getTasks(filter = 'all') {
        switch (filter) {
            case 'active':
                return this.tasks.filter(t => !t.completed);
            case 'completed':
                return this.tasks.filter(t => t.completed);
            default:
                return this.tasks;
        }
    }

    /**
     * 按标签筛选任务
     */
    getTasksByTag(tag) {
        return this.tasks.filter(t => t.tags.includes(tag));
    }
}
```

### 3.2 存储管理器 (storage.js)

```javascript
/**
 * 存储管理器
 */
export class StorageManager {
    constructor(prefix = 'todo_app_') {
        this.prefix = prefix;
    }

    /**
     * 获取数据
     */
    get(key) {
        try {
            const data = localStorage.getItem(this.prefix + key);
            return data ? JSON.parse(data) : null;
        } catch (error) {
            console.error('读取存储失败:', error);
            return null;
        }
    }

    /**
     * 设置数据
     */
    set(key, value) {
        try {
            localStorage.setItem(this.prefix + key, JSON.stringify(value));
            return true;
        } catch (error) {
            console.error('写入存储失败:', error);
            return false;
        }
    }

    /**
     * 删除数据
     */
    remove(key) {
        try {
            localStorage.removeItem(this.prefix + key);
            return true;
        } catch (error) {
            console.error('删除存储失败:', error);
            return false;
        }
    }

    /**
     * 清空所有数据
     */
    clear() {
        try {
            Object.keys(localStorage)
                .filter(key => key.startsWith(this.prefix))
                .forEach(key => localStorage.removeItem(key));
            return true;
        } catch (error) {
            console.error('清空存储失败:', error);
            return false;
        }
    }
}
```

### 3.3 筛选处理器 (filter.js)

```javascript
/**
 * 筛选处理器
 */
export class FilterHandler {
    constructor() {
        this.currentFilter = 'all';
        this.currentTag = null;
    }

    /**
     * 设置筛选条件
     */
    setFilter(filter) {
        this.currentFilter = filter;
        this.currentTag = null;
    }

    /**
     * 设置标签筛选
     */
    setTagFilter(tag) {
        this.currentTag = tag;
    }

    /**
     * 获取当前筛选条件
     */
    getFilter() {
        return {
            status: this.currentFilter,
            tag: this.currentTag
        };
    }

    /**
     * 应用筛选
     */
    applyFilter(tasks) {
        let filtered = tasks;

        // 状态筛选
        if (this.currentFilter === 'active') {
            filtered = filtered.filter(t => !t.completed);
        } else if (this.currentFilter === 'completed') {
            filtered = filtered.filter(t => t.completed);
        }

        // 标签筛选
        if (this.currentTag) {
            filtered = filtered.filter(t => t.tags.includes(this.currentTag));
        }

        return filtered;
    }
}
```

### 3.4 渲染器 (renderer.js)

```javascript
/**
 * 渲染器
 */
export class Renderer {
    constructor(container) {
        this.container = container;
    }

    /**
     * 渲染任务列表
     */
    renderTasks(tasks) {
        this.container.innerHTML = '';
        
        if (tasks.length === 0) {
            this.renderEmptyState();
            return;
        }

        const fragment = document.createDocumentFragment();
        
        tasks.forEach(task => {
            const taskElement = this.createTaskElement(task);
            fragment.appendChild(taskElement);
        });
        
        this.container.appendChild(fragment);
    }

    /**
     * 创建任务元素
     */
    createTaskElement(task) {
        const li = document.createElement('li');
        li.className = `task-item ${task.completed ? 'completed' : ''}`;
        li.dataset.id = task.id;
        
        li.innerHTML = `
            <div class="task-checkbox">
                <input type="checkbox" ${task.completed ? 'checked' : ''}>
            </div>
            <div class="task-content">
                <h3 class="task-title">${this.escapeHtml(task.title)}</h3>
                ${task.description ? `<p class="task-description">${this.escapeHtml(task.description)}</p>` : ''}
                ${task.tags.length > 0 ? this.renderTags(task.tags) : ''}
            </div>
            <div class="task-actions">
                <button class="btn-edit">编辑</button>
                <button class="btn-delete">删除</button>
            </div>
        `;
        
        return li;
    }

    /**
     * 渲染标签
     */
    renderTags(tags) {
        return `<div class="task-tags">
            ${tags.map(tag => `<span class="tag">${this.escapeHtml(tag)}</span>`).join('')}
        </div>`;
    }

    /**
     * 渲染空状态
     */
    renderEmptyState() {
        this.container.innerHTML = `
            <div class="empty-state">
                <p>暂无任务</p>
                <p>点击"添加任务"创建新任务</p>
            </div>
        `;
    }

    /**
     * HTML转义
     */
    escapeHtml(text) {
        const div = document.createElement('div');
        div.textContent = text;
        return div.innerHTML;
    }
}
```

---

## 4. 数据模型

### 4.1 任务数据结构

```javascript
/**
 * 任务对象
 */
const Task = {
    id: String,           // 唯一标识 (时间戳)
    title: String,        // 任务标题
    description: String,  // 任务描述
    tags: Array,          // 标签列表
    completed: Boolean,   // 完成状态
    createdAt: String,    // 创建时间 (ISO 8601)
    updatedAt: String     // 更新时间 (ISO 8601)
};
```

### 4.2 筛选选项

```javascript
/**
 * 筛选选项
 */
const FilterOptions = {
    status: 'all' | 'active' | 'completed',
    tag: String | null
};
```

---

## 5. UI设计

### 5.1 布局结构

```
┌────────────────────────────────────────┐
│              [应用标题]                 │
│              待办事项                   │
├────────────────────────────────────────┤
│  [输入框] [添加按钮]                    │
├────────────────────────────────────────┤
│  [全部] [待办] [已完成]                 │
├────────────────────────────────────────┤
│  □ 任务1                [编辑] [删除]   │
│  □ 任务2 #工作          [编辑] [删除]   │
│  ✓ 任务3 (已完成)       [编辑] [删除]   │
│  □ 任务4 #个人          [编辑] [删除]   │
└────────────────────────────────────────┘
```

### 5.2 CSS变量

```css
:root {
    --color-primary: #4A90E2;
    --color-secondary: #F5F5F5;
    --color-success: #52C41A;
    --color-text: #333333;
    --color-text-light: #999999;
    --color-border: #E8E8E8;
    --font-size-base: 14px;
    --font-size-title: 18px;
    --border-radius: 4px;
}
```

### 5.3 响应式断点

| 设备 | 断点 | 布局特点 |
|------|------|----------|
| 移动端 | < 768px | 单列布局，按钮全宽 |
| 平板 | 768px - 1024px | 居中，最大宽度 600px |
| 桌面 | > 1024px | 居中，最大宽度 800px |

---

## 6. 测试策略

### 6.1 单元测试

| 测试模块 | 测试内容 |
|----------|----------|
| TaskManager | 任务CRUD操作、状态切换 |
| StorageManager | 存储读写、异常处理 |
| FilterHandler | 筛选逻辑 |

### 6.2 集成测试

| 测试场景 | 测试内容 |
|----------|----------|
| 任务创建流程 | 输入 → 存储 → 显示 |
| 任务编辑流程 | 编辑 → 更新 → 显示 |
| 数据持久化 | 刷新后数据保持 |

---

## 7. 性能指标

| 指标 | 要求 |
|------|------|
| 页面加载时间 | < 2秒 |
| 任务操作响应时间 | < 100ms |
| 渲染100条任务时间 | < 200ms |
| 本地存储读写时间 | < 50ms |

---

## 8. 项目结构

```
e2e-test-20260325-204656/
├── shared/
│   ├── TASKS.md
│   ├── PRD.md
│   └── ARCHITECTURE.md
├── index.html
├── css/
│   ├── normalize.css
│   ├── variables.css
│   └── main.css
├── js/
│   ├── main.js
│   ├── modules/
│   │   ├── task-manager.js
│   │   ├── storage.js
│   │   ├── filter.js
│   │   └── renderer.js
│   └── utils/
│       ├── validators.js
│       ├── formatters.js
│       └── helpers.js
└── README.md
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
| 需求分析 | product | 需求分析，产出PRD | ✅ 已完成 |
| 架构设计 | architect | 架构设计 | 进行中 |
| 开发实施 | developer | 功能开发 | 待开始 |
| 测试验证 | qa | 测试执行 | 待开始 |
| 文档整理 | writer | 文档整理 | 待开始 |

---

**架构师**: architect  
**创建日期**: 2026-03-26  
**版本**: v1.0  
**项目**: e2e-test-20260325-204656