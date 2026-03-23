# A2A协议调研报告

**日期**: 2026-03-23
**调研人**: Architect Agent
**项目**: A2A协议调研测试

---

## 概述

**A2A (Agent-to-Agent)** 是由 Google 贡献给 Linux Foundation 的开源协议，旨在解决 AI Agent 之间的通信和互操作性问题。

- **版本**: 1.0.0
- **开源协议**: Apache 2.0
- **官网**: https://a2a-protocol.org
- **GitHub**: https://github.com/a2aproject/A2A

---

## 核心目标

| 目标 | 说明 |
|------|------|
| **互操作性** | 连接不同框架、不同厂商构建的Agent |
| **协作** | 让多个Agent能协同完成复杂任务 |
| **发现** | 动态发现和理解其他Agent的能力 |
| **灵活性** | 支持同步/流式/异步多种交互模式 |
| **安全性** | 企业级安全通信 |
| **异步优先** | 原生支持长时间任务和人机交互 |

---

## 架构设计

三层架构模型：

```
┌─────────────────────────────────────────┐
│  Layer 3: Protocol Bindings             │
│  (JSON-RPC, gRPC, HTTP/REST)            │
├─────────────────────────────────────────┤
│  Layer 2: Abstract Operations           │
│  (Send Message, Get Task, Subscribe...) │
├─────────────────────────────────────────┤
│  Layer 1: Canonical Data Model          │
│  (Task, Message, AgentCard, Part...)    │
└─────────────────────────────────────────┘
```

---

## 核心概念

| 概念 | 说明 |
|------|------|
| **A2A Client** | 发起请求的应用或Agent |
| **A2A Server** | 处理任务的Agent（Remote Agent） |
| **Agent Card** | JSON元数据文档，描述Agent能力、技能、端点、认证要求 |
| **Task** | 工作单元，有生命周期状态 |
| **Message** | 通信单元，包含role(user/agent)和一个或多个Part |
| **Part** | 最小内容单元（文本、文件引用、结构化JSON） |
| **Artifact** | Agent生成的输出（文档、图片、结构化数据） |
| **Context** | 可选标识符，逻辑分组相关任务和消息 |

---

## 核心操作

### 消息操作
- `Send Message` - 发送消息，返回Task或直接返回Message
- `Send Streaming Message` - 发送消息并流式接收更新

### 任务管理
- `Get Task` - 获取任务当前状态
- `List Tasks` - 列出任务（支持过滤和分页）
- `Cancel Task` - 取消任务
- `Subscribe to Task` - 订阅任务更新流

### 推送通知
- `Create/Get/List/Delete Push Notification Config`

### 发现
- `Get Extended Agent Card` - 获取认证后的详细Agent Card

---

## Task生命周期

```
pending → working → [input_required / auth_required] → completed / failed / canceled / rejected
```

---

## 通信模式

| 模式 | 说明 | 适用场景 |
|------|------|---------|
| **同步** | 发送请求，等待响应 | 简单交互 |
| **流式 (SSE)** | 实时增量更新 | 实时仪表盘、进度监控 |
| **异步推送** | 服务端主动推送 | 长时间任务、事件驱动架构 |

---

## 协议绑定

- **JSON-RPC 2.0** over HTTP(S) - 默认
- **gRPC** - 高性能场景
- **HTTP/REST** - 简单集成

---

## 安全特性

- 支持标准Web安全实践
- Agent Card声明认证方案
- 不暴露内部状态、内存或工具实现
- 保持Agent"黑盒"特性，保护IP

---

## A2A vs MCP

| 维度 | A2A | MCP |
|------|-----|-----|
| **定位** | Agent间协作 | Agent与工具连接 |
| **关系** | 互补关系 | 互补关系 |
| **场景** | 多Agent系统编排 | 扩展Agent能力边界 |

**可以组合使用**：Agent通过MCP访问工具，通过A2A与其他Agent协作。

---

## SDK支持

- **Python**: `pip install a2a-sdk`
- **Go**: `go get github.com/a2aproject/a2a-go`
- **JavaScript**: `npm install @a2a-js/sdk`
- **Java**: Maven
- **.NET**: NuGet `dotnet add package A2A`

---

## 设计亮点

1. **Opaque Execution** - Agent协作不需要共享内部思想、计划或工具实现
2. **Async First** - 原生支持长时间任务和人机交互
3. **Enterprise Ready** - 考虑认证、授权、追踪、监控
4. **标准化** - 复用HTTP、JSON-RPC 2.0、SSE等成熟标准

---

## 学习资源

- 官方短课程: https://goo.gle/dlai-a2a (Google Cloud & IBM Research合作)
- 官方文档: https://a2a-protocol.org
- 示例代码: https://github.com/a2aproject/a2a-samples
- 规范文档: https://a2a-protocol.org/latest/specification/

---

## 应用场景建议

A2A协议适合用于：
- 多Agent系统架构设计
- 企业级Agent编排平台
- 跨框架Agent互操作场景
- 需要长时间任务和人机协作的Agent工作流

---

## 与 OpenClaw 的关系

OpenClaw 已实现类似的 Agent-to-Agent 通信能力：
- `sessions_send` - Agent间消息发送
- `sessions_spawn` - 创建子Agent执行任务
- `subagents` - 管理子Agent

A2A 协议可以作为 OpenClaw 与其他 Agent 框架互操作的标准接口。

---

**报告完成时间**: 2026-03-23 14:07