#!/bin/bash
# OpenCLAW 自动同步守护进程
# 监听 OpenCLAW 工作区变化，实时同步到 Obsidian Vault

VAULT="/root/openclaw-vault"
WORKSPACE="/root/.openclaw/workspaces/lili"
PID_FILE="/root/openclaw-vault/sync-daemon.pid"
LOG_FILE="/root/openclaw-vault/sync-daemon.log"

# 同步函数
do_sync() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] 检测到变化，开始同步..." >> "$LOG_FILE"

    # 同步全局信息
    if [ -d "$WORKSPACE/_global" ]; then
        rsync -av --delete "$WORKSPACE/_global/" "$VAULT/global/" 2>/dev/null
    fi

    # 同步各角色经验库
    for role in entry pm product researcher architect developer qa writer; do
        mkdir -p "$VAULT/agents/$role"
        if [ -f "$WORKSPACE/agents/$role/experience.md" ]; then
            cp "$WORKSPACE/agents/$role/experience.md" "$VAULT/agents/$role/" 2>/dev/null
        fi
        if [ -f "$WORKSPACE/agents/$role/AGENTS.md" ]; then
            cp "$WORKSPACE/agents/$role/AGENTS.md" "$VAULT/agents/$role/" 2>/dev/null
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
                fi

                # 同步各角色产出
                for role in entry pm product researcher architect developer qa writer; do
                    if [ -d "$project_dir/agents/$role" ]; then
                        mkdir -p "$VAULT/projects/$project_name/$role"
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
    git add -A >/dev/null 2>&1

    CHANGED=$(git status --porcelain | wc -l)
    if [ "$CHANGED" -gt 0 ]; then
        git commit -m "sync: $(date '+%Y-%m-%d %H:%M')" >/dev/null 2>&1
        git push origin main 2>&1 >> "$LOG_FILE" && echo "[$(date '+%Y-%m-%d %H:%M:%S')] ✓ 已同步并推送 $CHANGED 个文件" >> "$LOG_FILE" || echo "[$(date '+%Y-%m-%d %H:%M:%S')] ✗ 推送失败" >> "$LOG_FILE"
    else
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] 无变更" >> "$LOG_FILE"
    fi
}

# 防止重复启动
if [ -f "$PID_FILE" ]; then
    OLD_PID=$(cat "$PID_FILE")
    if kill -0 "$OLD_PID" 2>/dev/null; then
        echo "守护进程已在运行 (PID: $OLD_PID)"
        exit 1
    fi
    rm -f "$PID_FILE"
fi

# 保存 PID
echo $$ > "$PID_FILE"

echo "[$(date '+%Y-%m-%d %H:%M:%S')] OpenCLAW 同步守护进程启动" > "$LOG_FILE"
echo "监听目录: $WORKSPACE"

# 监听文件变化（递归监听，监控创建、修改、删除事件）
inotifywait -m -r -e create,modify,delete,move "$WORKSPACE" --format '%w%f' 2>/dev/null | while read file; do
    # 过滤临时文件和 git 文件
    if [[ ! "$file" =~ /\.(git|swp|swo|tmp)$ ]]; then
        # 防抖：等待 2 秒再同步，避免频繁触发
        sleep 2
        do_sync
    fi
done
