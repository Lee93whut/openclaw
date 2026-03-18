#!/bin/bash
# OpenCLAW 存储管理器
# - 定期检查存储空间，超出阈值时清理本地文件
# - 清理前确保内容已保存到 git（远程已存在）
# - 需要时自动从 git 拉取

VAULT="/root/openclaw-vault"
MAX_SIZE_MB=${1:-100}  # 默认 100MB
LOG_FILE="$VAULT/storage-manager.log"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# 验证 git 连接正常
check_git() {
    cd "$VAULT"
    if git ls-remote --exit-code origin main >/dev/null 2>&1; then
        log "✓ git 远程连接正常"
        return 0
    else
        log "✗ git 远程连接失败"
        return 1
    fi
}

# 确保本地变更已推送到远程
sync_to_git() {
    cd "$VAULT"

    LOCAL=$(git rev-parse HEAD)
    REMOTE=$(git rev-parse origin/main 2>/dev/null)

    if [ "$LOCAL" != "$REMOTE" ]; then
        log "本地有未推送的变更，正在推送..."
        if git push origin main 2>&1 >> "$LOG_FILE"; then
            log "✓ 推送成功"
            return 0
        else
            log "✗ 推送失败，取消清理"
            return 1
        fi
    fi

    log "✓ 本地与远程已同步"
    return 0
}

# 检查远程是否存在某文件/目录
remote_exists() {
    local path="$1"
    cd "$VAULT"
    # 检查远程是否有该路径
    git ls-tree -r origin/main --name-only | grep -q "^${path}$"
}

# 检查并清理存储
clean_storage() {
    # 1. 验证 git 连接
    if ! check_git; then
        echo "✗ git 连接失败，取消清理"
        return 1
    fi

    # 2. 确保本地变更已推送到远程
    if ! sync_to_git; then
        echo "✗ 无法同步到远程，取消清理"
        return 1
    fi

    local current_size=$(du -sm "$VAULT" 2>/dev/null | cut -f1)
    log "当前存储: ${current_size}MB, 阈值: ${MAX_SIZE_MB}MB"

    if [ "$current_size" -gt "$MAX_SIZE_MB" ]; then
        log "超过阈值，开始清理..."
        echo "⚠ 超过阈值 ${MAX_SIZE_MB}MB，开始清理..."

        local cleaned=0
        local skipped=0

        # 清理项目详细内容
        if [ -d "$VAULT/projects" ]; then
            for project_dir in "$VAULT/projects"/*; do
                if [ -d "$project_dir" ]; then
                    project_name=$(basename "$project_dir")

                    # 清理各角色目录
                    for role in entry pm product researcher architect developer qa writer; do
                        role_path="projects/$project_name/$role"
                        if [ -d "$project_dir/$role" ]; then
                            if remote_exists "$role_path"; then
                                rm -rf "$project_dir/$role"
                                log "✓ 已清理: $role_path (远程存在)"
                                ((cleaned++))
                            else
                                log "✗ 跳过: $role_path (远程不存在)"
                                ((skipped++))
                            fi
                        fi
                    done

                    # 清理 shared 目录
                    shared_path="projects/$project_name/shared"
                    if [ -d "$project_dir/shared" ]; then
                        if remote_exists "$shared_path"; then
                            find "$project_dir/shared" -type f -delete 2>/dev/null
                            log "✓ 已清理: $shared_path/* (远程存在)"
                            ((cleaned++))
                        else
                            log "✗ 跳过: $shared_path (远程不存在)"
                            ((skipped++))
                        fi
                    fi
                fi
            done
        fi

        # 清理 agent 经验库
        for role in entry pm product researcher architect developer qa writer; do
            agent_path="agents/$role"
            if [ -d "$VAULT/agents/$role" ]; then
                if remote_exists "$agent_path"; then
                    # 只保留前 50 行
                    if [ -f "$VAULT/agents/$role/experience.md" ]; then
                        head -50 "$VAULT/agents/$role/experience.md" > "$VAULT/agents/$role/experience.md.tmp"
                        mv "$VAULT/agents/$role/experience.md.tmp" "$VAULT/agents/$role/experience.md"
                        log "✓ 已截断: $agent_path/experience.md (远程存在)"
                        ((cleaned++))
                    fi
                    rm -f "$VAULT/agents/$role/AGENTS.md" 2>/dev/null
                else
                    log "✗ 跳过: $agent_path (远程不存在)"
                    ((skipped++))
                fi
            fi
        done

        # 清理 global
        if [ -d "$VAULT/global" ]; then
            if remote_exists "global"; then
                find "$VAULT/global" -type f -delete 2>/dev/null
                log "✓ 已清理: global/* (远程存在)"
                ((cleaned++))
            else
                log "✗ 跳过: global (远程不存在)"
                ((skipped++))
            fi
        fi

        # 提交并推送清理结果
        cd "$VAULT"
        git add -A >/dev/null 2>&1
        CHANGED=$(git status --porcelain | wc -l)
        if [ "$CHANGED" -gt 0 ]; then
            git commit -m "clean: $(date '+%Y-%m-%d %H:%M') local storage" >/dev/null 2>&1
            if git push origin main 2>&1 >> "$LOG_FILE"; then
                log "✓ 清理结果已推送"
            else
                log "✗ 清理结果推送失败"
            fi
        fi

        local new_size=$(du -sm "$VAULT" 2>/dev/null | cut -f1)
        echo "✓ 清理完成: 清理 $cleaned 项, 跳过 $skipped 项, 当前存储: ${new_size}MB"
        log "清理完成: 清理 $cleaned 项, 跳过 $skipped 项, 当前存储: ${new_size}MB"
    else
        log "存储空间充足，无需清理"
        echo "✓ 存储空间充足 (${current_size}MB < ${MAX_SIZE_MB}MB)"
    fi
}

# 按需拉取项目内容
pull_project() {
    local project_name="$1"
    if [ -z "$project_name" ]; then
        echo "用法: $0 <阈值MB> pull <项目名>"
        return 1
    fi

    if ! check_git; then
        echo "✗ git 连接失败"
        return 1
    fi

    log "按需拉取项目: $project_name"

    cd "$VAULT"
    git config core.sparseCheckout true
    echo "projects/$project_name" > "$VAULT/.git/info/sparse-checkout"
    echo "agents" >> "$VAULT/.git/info/sparse-checkout"
    echo "global" >> "$VAULT/.git/info/sparse-checkout"
    echo "INDEX.md" >> "$VAULT/.git/info/sparse-checkout"

    git checkout main -- . 2>/dev/null
    git pull origin main 2>/dev/null

    if [ -d "projects/$project_name" ]; then
        log "项目 $project_name 已拉取"
        echo "✓ 项目 $project_name 已拉取"
    else
        log "项目 $project_name 不存在"
        echo "✗ 项目 $project_name 不存在"
    fi
}

# 恢复所有内容
pull_all() {
    if ! check_git; then
        echo "✗ git 连接失败"
        return 1
    fi

    cd "$VAULT"
    git config core.sparseCheckout false
    rm -f "$VAULT/.git/info/sparse-checkout"
    git checkout main
    git pull origin main

    echo "✓ 已恢复所有内容"
    log "已恢复所有内容"
}

# 显示存储状态
status() {
    local current_size=$(du -sh "$VAULT" 2>/dev/null | cut -f1)
    local file_count=$(find "$VAULT" -type f 2>/dev/null | wc -l)

    echo "=== 存储状态 ==="
    echo "当前大小: $current_size"
    echo "文件数量: $file_count"
    echo "阈值: ${MAX_SIZE_MB}MB"
    echo ""
    echo "=== 项目列表 ==="
    ls -1 "$VAULT/projects" 2>/dev/null || echo "无项目"
    echo ""
    echo "=== 最近提交 ==="
    cd "$VAULT" && git log --oneline -3 2>/dev/null
    echo ""
    echo "=== Git 状态 ==="
    cd "$VAULT"
    LOCAL=$(git rev-parse HEAD 2>/dev/null)
    REMOTE=$(git rev-parse origin/main 2>/dev/null)
    if [ "$LOCAL" = "$REMOTE" ]; then
        echo "✓ 本地与远程已同步"
    else
        echo "⚠ 本地有未推送的变更"
    fi
}

# 主命令
case "${2:-status}" in
    clean)
        clean_storage
        ;;
    pull)
        pull_project "$3"
        ;;
    pull-all)
        pull_all
        ;;
    status)
        status
        ;;
    *)
        echo "用法: $0 <阈值MB> [clean|pull <项目名>|pull-all|status]"
        echo ""
        echo "示例:"
        echo "  $0 100 status          # 查看状态"
        echo "  $0 100 clean           # 超过阈值时清理（仅清理远程已存在的文件）"
        echo "  $0 100 pull myproject  # 按需拉取指定项目"
        echo "  $0 100 pull-all        # 恢复所有内容"
        ;;
esac