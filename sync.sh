#!/bin/bash
# OpenClaw 产出物同步脚本
# 用法: ./sync.sh [--push]

VAULT="/root/openclaw-vault"
WORKSPACE="/root/.openclaw/workspaces/lili"
PUSH=${1:-"--push"}

echo "=== $(date '+%Y-%m-%d %H:%M:%S') 开始同步 ==="

# 同步全局信息
if [ -d "$WORKSPACE/_global" ]; then
    rsync -av --delete "$WORKSPACE/_global/" "$VAULT/global/"
    echo "✓ 同步全局信息"
fi

# 同步各角色经验库
for role in entry pm product researcher architect developer qa writer; do
    mkdir -p "$VAULT/agents/$role"
    if [ -f "$WORKSPACE/agents/$role/experience.md" ]; then
        cp "$WORKSPACE/agents/$role/experience.md" "$VAULT/agents/$role/"
        echo "✓ 同步 $role 经验库"
    fi
    # 同步 AGENTS.md 如果存在
    if [ -f "$WORKSPACE/agents/$role/AGENTS.md" ]; then
        cp "$WORKSPACE/agents/$role/AGENTS.md" "$VAULT/agents/$role/"
    fi
done

# 同步项目产出
if [ -d "$WORKSPACE/projects" ]; then
    for project_dir in "$WORKSPACE/projects"/*; do
        if [ -d "$project_dir" ]; then
            project_name=$(basename "$project_dir")
            mkdir -p "$VAULT/projects/$project_name"

            # 同步 shared 目录
            if [ -d "$project_dir/shared" ]; then
                rsync -av --delete "$project_dir/shared/" "$VAULT/projects/$project_name/" 2>/dev/null
                echo "✓ 同步项目: $project_name"
            fi

            # 同步各角色产出
            for role in entry pm product researcher architect developer qa writer; do
                if [ -d "$project_dir/agents/$role" ]; then
                    mkdir -p "$VAULT/projects/$project_name/$role"
                    # 同步 markdown 文件
                    find "$project_dir/agents/$role" -name "*.md" -exec cp {} "$VAULT/projects/$project_name/$role/" \; 2>/dev/null
                fi
            done
        fi
    done
fi

# 更新索引文件
cat > "$VAULT/INDEX.md" << INDEXEOF
# OpenClaw 产出物索引

> 最后更新: $(date '+%Y-%m-%d %H:%M:%S')

## 全局信息
- [[global/PROJECTS]] - 项目列表
- [[global/OVERVIEW]] - 全局概览
- [[global/RESOURCES]] - 全局资源

## 各角色经验库
INDEXEOF

for role in entry pm product researcher architect developer qa writer; do
    if [ -f "$VAULT/agents/$role/experience.md" ]; then
        echo "- [[agents/$role/experience|$role]]" >> "$VAULT/INDEX.md"
    fi
done

echo "" >> "$VAULT/INDEX.md"
echo "## 项目产出" >> "$VAULT/INDEX.md"
for project_dir in "$VAULT/projects"/*; do
    if [ -d "$project_dir" ]; then
        project_name=$(basename "$project_dir")
        echo "- [[projects/$project_name|$project_name]]" >> "$VAULT/INDEX.md"
    fi
done

# Git 操作
cd "$VAULT"
git add -A

CHANGED=$(git status --porcelain | wc -l)
if [ "$CHANGED" -eq 0 ]; then
    echo "无变更需要提交"
else
    git commit -m "sync: $(date '+%Y-%m-%d %H:%M')"
    echo "✓ 已提交 $CHANGED 个文件"

    # 推送到远程
    if [ "$PUSH" = "--push" ]; then
        git push origin main 2>&1 && echo "✓ 已推送到远程" || echo "✗ 推送失败，请检查网络或认证"
    fi
fi

echo "=== 同步完成 ==="