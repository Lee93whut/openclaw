# 架构设计文档 - 飞书通知测试

## 1. 技术选型

### 1.1 测试框架

| 技术 | 选择 | 理由 |
|------|------|------|
| **测试框架** | Jest | 成熟的JavaScript测试框架，支持异步测试 |
| **断言库** | Jest内置 | 简洁的断言语法 |
| **HTTP客户端** | axios | 支持Promise，易于处理异步请求 |
| **日志库** | winston | 功能强大的日志记录库 |

### 1.2 飞书集成

| 技术 | 选择 | 理由 |
|------|------|------|
| **通知渠道** | 飞书自定义机器人 | 通过webhook发送消息 |
| **消息格式** | 文本消息 | 简单易用，适合测试场景 |
| **API协议** | HTTPS POST | 飞书webhook标准协议 |

### 1.3 配置管理

| 技术 | 选择 | 理由 |
|------|------|------|
| **配置文件** | JSON | 简单易读，易于维护 |
| **环境变量** | dotenv | 支持敏感信息保护 |
| **配置验证** | Joi | 配置项验证 |

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
│  │ 单条消息测试 │  │ 批量消息测试 │  │ 格式验证测试        │  │
│  └─────────────┘  └─────────────┘  └─────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    核心组件层                               │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │ 消息发送器   │  │ 配置管理器   │  │ 日志记录器          │  │
│  └─────────────┘  └─────────────┘  └─────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    外部系统                                 │
│  ┌───────────────────────────────────────────────────────┐  │
│  │ 飞书机器人 Webhook                                     │  │
│  └───────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

### 2.2 测试流程

```
测试启动
    │
    ├─→ 加载配置
    │       ├─ 读取webhook地址
    │       └─ 初始化日志记录器
    │
    ├─→ 执行测试用例
    │       ├─ 单条消息发送测试
    │       ├─ 批量消息发送测试
    │       └─ 消息格式验证测试
    │
    ├─→ 收集测试结果
    │       ├─ 统计通过/失败
    │       └─ 记录错误日志
    │
    └─→ 生成测试报告
```

---

## 3. 核心模块设计

### 3.1 消息发送器 (feishu-sender.js)

```javascript
/**
 * 飞书消息发送器
 */
export class FeishuSender {
    constructor(webhookUrl) {
        this.webhookUrl = webhookUrl;
    }

    /**
     * 发送文本消息
     */
    async sendTextMessage(content) {
        const payload = {
            msg_type: 'text',
            content: {
                text: content
            }
        };

        try {
            const response = await axios.post(this.webhookUrl, payload);
            return {
                success: response.data.StatusCode === 0,
                data: response.data
            };
        } catch (error) {
            return {
                success: false,
                error: error.message
            };
        }
    }

    /**
     * 批量发送消息
     */
    async sendBatchMessages(messages, interval = 1000) {
        const results = [];
        
        for (const message of messages) {
            const result = await this.sendTextMessage(message);
            results.push(result);
            
            if (messages.indexOf(message) < messages.length - 1) {
                await this.delay(interval);
            }
        }
        
        return results;
    }

    /**
     * 延迟函数
     */
    delay(ms) {
        return new Promise(resolve => setTimeout(resolve, ms));
    }
}
```

### 3.2 配置管理器 (config-manager.js)

```javascript
/**
 * 配置管理器
 */
export class ConfigManager {
    constructor() {
        this.config = {};
    }

    /**
     * 加载配置
     */
    loadConfig(configPath) {
        const configFile = require(configPath);
        this.config = { ...this.config, ...configFile };
        return this;
    }

    /**
     * 加载环境变量
     */
    loadEnv() {
        require('dotenv').config();
        this.config.webhookUrl = process.env.FEISHU_WEBHOOK_URL;
        return this;
    }

    /**
     * 获取配置
     */
    get(key) {
        return this.config[key];
    }

    /**
     * 验证配置
     */
    validate() {
        if (!this.config.webhookUrl) {
            throw new Error('缺少飞书webhook地址配置');
        }
        return true;
    }
}
```

### 3.3 日志记录器 (logger.js)

```javascript
/**
 * 日志记录器
 */
import winston from 'winston';

export const logger = winston.createLogger({
    level: 'info',
    format: winston.format.combine(
        winston.format.timestamp(),
        winston.format.json()
    ),
    transports: [
        new winston.transports.File({ filename: 'logs/error.log', level: 'error' }),
        new winston.transports.File({ filename: 'logs/combined.log' }),
        new winston.transports.Console({
            format: winston.format.simple()
        })
    ]
});
```

---

## 4. 测试用例设计

### 4.1 单条消息发送测试

**测试目标**: 验证单条消息能够成功发送到飞书

| 用例ID | 测试项 | 预期结果 |
|--------|--------|----------|
| SM-001 | 发送文本消息 | 消息成功发送，返回StatusCode=0 |
| SM-002 | 空消息处理 | 正确处理并返回错误 |
| SM-003 | 超长消息处理 | 正确截断或返回错误 |

```javascript
/**
 * 测试用例: 单条消息发送
 */
describe('单条消息发送测试', () => {
    let sender;
    
    beforeAll(() => {
        const config = new ConfigManager().loadEnv();
        sender = new FeishuSender(config.get('webhookUrl'));
    });

    test('SM-001: 发送文本消息', async () => {
        const result = await sender.sendTextMessage('测试消息 - ' + Date.now());
        expect(result.success).toBe(true);
    });

    test('SM-002: 空消息处理', async () => {
        const result = await sender.sendTextMessage('');
        expect(result.success).toBe(false);
    });
});
```

### 4.2 批量消息发送测试

**测试目标**: 验证批量消息能够成功发送

| 用例ID | 测试项 | 预期结果 |
|--------|--------|----------|
| BM-001 | 发送多条消息 | 所有消息成功发送 |
| BM-002 | 消息间隔控制 | 消息按间隔发送 |

```javascript
/**
 * 测试用例: 批量消息发送
 */
describe('批量消息发送测试', () => {
    let sender;
    
    beforeAll(() => {
        const config = new ConfigManager().loadEnv();
        sender = new FeishuSender(config.get('webhookUrl'));
    });

    test('BM-001: 发送多条消息', async () => {
        const messages = [
            '批量测试消息1',
            '批量测试消息2',
            '批量测试消息3'
        ];
        
        const results = await sender.sendBatchMessages(messages);
        expect(results.every(r => r.success)).toBe(true);
    }, 30000);
});
```

### 4.3 消息格式验证测试

**测试目标**: 验证消息格式正确

| 用例ID | 测试项 | 预期结果 |
|--------|--------|----------|
| MF-001 | 文本消息格式 | 格式正确 |
| MF-002 | 特殊字符处理 | 正确处理特殊字符 |

```javascript
/**
 * 测试用例: 消息格式验证
 */
describe('消息格式验证测试', () => {
    let sender;
    
    beforeAll(() => {
        const config = new ConfigManager().loadEnv();
        sender = new FeishuSender(config.get('webhookUrl'));
    });

    test('MF-001: 文本消息格式', async () => {
        const result = await sender.sendTextMessage('格式测试消息');
        expect(result.success).toBe(true);
    });

    test('MF-002: 特殊字符处理', async () => {
        const result = await sender.sendTextMessage('特殊字符: @#$%^&*()');
        expect(result.success).toBe(true);
    });
});
```

---

## 5. 错误处理

### 5.1 错误类型

| 错误类型 | 处理方式 |
|----------|----------|
| 网络错误 | 记录日志，返回错误信息 |
| 配置错误 | 抛出异常，终止测试 |
| 飞书API错误 | 记录错误码，返回错误信息 |

### 5.2 重试机制

```javascript
/**
 * 带重试的消息发送
 */
async sendWithRetry(content, maxRetries = 3) {
    let lastError;
    
    for (let i = 0; i < maxRetries; i++) {
        try {
            const result = await this.sendTextMessage(content);
            if (result.success) {
                return result;
            }
            lastError = result.error;
        } catch (error) {
            lastError = error.message;
            logger.warn(`发送失败，第${i + 1}次重试...`);
        }
        
        await this.delay(1000 * (i + 1));
    }
    
    logger.error(`发送失败，已重试${maxRetries}次`);
    return { success: false, error: lastError };
}
```

---

## 6. 测试执行

### 6.1 测试脚本

```javascript
import { FeishuSender } from './feishu-sender.js';
import { ConfigManager } from './config-manager.js';
import { logger } from './logger.js';

async function runTests() {
    console.log('🚀 开始飞书通知测试...\n');

    try {
        // 加载配置
        const config = new ConfigManager().loadEnv();
        config.validate();
        
        const sender = new FeishuSender(config.get('webhookUrl'));
        
        // 执行测试
        console.log('📋 执行测试用例...');
        
        // 单条消息测试
        const result1 = await sender.sendTextMessage('测试消息1 - ' + Date.now());
        console.log(`  单条消息测试: ${result1.success ? '✅ 通过' : '❌ 失败'}`);
        
        // 批量消息测试
        const results = await sender.sendBatchMessages([
            '批量消息1',
            '批量消息2',
            '批量消息3'
        ]);
        const batchSuccess = results.every(r => r.success);
        console.log(`  批量消息测试: ${batchSuccess ? '✅ 通过' : '❌ 失败'}`);
        
        console.log('\n✨ 测试完成！');
        
    } catch (error) {
        logger.error('测试执行失败:', error);
        console.error('❌ 测试失败:', error.message);
    }
}

runTests();
```

### 6.2 运行命令

```bash
# 安装依赖
npm install

# 运行测试
npm test

# 运行特定测试
npm test -- --testNamePattern="单条消息"
```

---

## 7. 测试报告

### 7.1 报告格式

```markdown
# 测试报告 - 飞书通知测试

## 测试概览
- 测试时间: 2026-03-26 20:17:00
- 项目: 飞书通知测试
- 总用例数: 8
- 通过数: 8
- 失败数: 0
- 通过率: 100.00%

## 测试结果

### 单条消息发送测试
- ✅ SM-001: 发送文本消息
- ✅ SM-002: 空消息处理
- ✅ SM-003: 超长消息处理

### 批量消息发送测试
- ✅ BM-001: 发送多条消息
- ✅ BM-002: 消息间隔控制

### 消息格式验证测试
- ✅ MF-001: 文本消息格式
- ✅ MF-002: 特殊字符处理

## 结论
所有测试通过，飞书通知功能正常。
```

---

## 8. 性能指标

| 指标 | 要求 |
|------|------|
| 单条消息发送时间 | < 3秒 |
| 批量消息发送（10条） | < 15秒 |
| 消息发送成功率 | > 99% |
| 错误处理响应时间 | < 1秒 |

---

## 9. 项目结构

```
feishu-notify-test/
├── shared/
│   ├── TASKS.md
│   ├── PRD.md
│   └── ARCHITECTURE.md
├── src/
│   ├── feishu-sender.js
│   ├── config-manager.js
│   └── logger.js
├── tests/
│   ├── single-message.test.js
│   ├── batch-message.test.js
│   └── format-validation.test.js
├── .env.example
├── package.json
└── README.md
```

---

## 10. 配置说明

### 10.1 环境变量

```bash
# .env.example
FEISHU_WEBHOOK_URL=https://open.feishu.cn/open-apis/bot/v2/hook/your-webhook-id
LOG_LEVEL=info
```

### 10.2 消息模板

```json
{
  "msg_type": "text",
  "content": {
    "text": "消息内容"
  }
}
```

---

## 11. 工作流说明

### 11.1 工作流程

```
product → architect
```

### 11.2 阶段说明

| 阶段 | 角色 | 说明 | 状态 |
|------|------|------|------|
| 需求分析 | product | 需求分析，产出PRD | ✅ 已完成 |
| 架构设计 | architect | 架构设计 | 进行中 |

---

**架构师**: architect  
**创建日期**: 2026-03-26  
**版本**: v1.0  
**项目**: 飞书通知测试