# OpenClaw 产出物库

> 云服务器自动同步的中间产出物

## 目录结构

```
├── global/           # 全局项目信息
├── agents/           # 各角色跨项目经验库
│   ├── entry/
│   ├── pm/
│   ├── product/
│   ├── researcher/
│   ├── architect/
│   ├── developer/
│   ├── qa/
│   └── writer/
└── projects/         # 各项目产出物
    └── {项目名}/
        ├── PROJECT.md
        ├── TASKS.md
        └── ...
```

## 使用方式

### 云服务器（自动同步）
- 每 30 分钟自动同步
- 手动触发: `/root/openclaw-vault/sync.sh`

### 本地 Obsidian
1. 克隆仓库: `git clone https://github.com/Lee93whut/openclaw.git`
2. 用 Obsidian 打开该目录
3. 编辑后推送: `git add . && git commit -m "update" && git push`

## 快速导航

- [[INDEX]] - 产出物索引（自动生成）
- [[global/PROJECTS]] - 项目列表
- [[global/OVERVIEW]] - 全局概览