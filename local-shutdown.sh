#!/bin/bash

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 进程ID存储文件
PIDFILE_PYTHON=".python-processor.pid"
PIDFILE_NODEJS=".nodejs-processor.pid"
PIDFILE_TASKAPI=".task-api.pid"

# 显示帮助信息
show_help() {
    echo "用法: $0 [选项]"
    echo
    echo "选项:"
    echo "  --clean-logs     停止服务并清理日志文件"
    echo "  --clean-pids     停止服务并清理PID文件"
    echo "  --clean-all      停止服务并清理所有临时文件"
    echo "  --force          强制停止所有相关进程"
    echo "  --help           显示此帮助信息"
    echo
    echo "示例:"
    echo "  $0                    # 仅停止服务"
    echo "  $0 --clean-logs      # 停止服务并清理日志"
    echo "  $0 --clean-all       # 停止服务并清理所有临时文件"
    echo "  $0 --force           # 强制停止所有相关进程"
}

# 停止单个服务
stop_service() {
    local service_name="$1"
    local pidfile="$2"
    
    if [ -f "$pidfile" ]; then
        local pid=$(cat "$pidfile")
        if kill -0 "$pid" 2>/dev/null; then
            log_info "正在停止 $service_name (PID: $pid)..."
            kill "$pid"
            
            # 等待进程结束
            local count=0
            while kill -0 "$pid" 2>/dev/null && [ $count -lt 10 ]; do
                sleep 1
                ((count++))
            done
            
            if kill -0 "$pid" 2>/dev/null; then
                log_warning "$service_name 未能正常停止，强制终止..."
                kill -9 "$pid" 2>/dev/null
            fi
            
            log_success "$service_name 已停止"
        else
            log_warning "$service_name 进程不存在 (PID: $pid)"
        fi
        
        if [ "$CLEAN_PIDS" = true ] || [ "$CLEAN_ALL" = true ]; then
            rm -f "$pidfile"
            log_info "已清理 $service_name PID 文件"
        fi
    else
        log_info "$service_name 未运行 (无PID文件)"
    fi
}

# 强制停止所有相关进程
force_stop_all() {
    log_warning "强制停止所有相关进程..."
    
    # 查找并停止相关进程
    local pids
    
    # 停止 Python 处理器
    pids=$(pgrep -f "python.*main.py" 2>/dev/null)
    if [ -n "$pids" ]; then
        log_info "强制停止 Python 处理器进程: $pids"
        echo "$pids" | xargs kill -9 2>/dev/null
    fi
    
    # 停止 Node.js 处理器
    pids=$(pgrep -f "node.*main.js" 2>/dev/null)
    if [ -n "$pids" ]; then
        log_info "强制停止 Node.js 处理器进程: $pids"
        echo "$pids" | xargs kill -9 2>/dev/null
    fi
    
    # 停止 Maven Spring Boot 应用
    pids=$(pgrep -f "spring-boot:run" 2>/dev/null)
    if [ -n "$pids" ]; then
        log_info "强制停止 Task API 进程: $pids"
        echo "$pids" | xargs kill -9 2>/dev/null
    fi
    
    # 停止 Java 应用（备用方案）
    pids=$(pgrep -f "java.*spring-boot" 2>/dev/null)
    if [ -n "$pids" ]; then
        log_info "强制停止 Java 应用进程: $pids"
        echo "$pids" | xargs kill -9 2>/dev/null
    fi
    
    log_success "强制停止完成"
}

# 清理日志文件
clean_logs() {
    log_info "清理日志文件..."
    
    local log_files=("task-api.log" "python-processor.log" "nodejs-processor.log")
    
    for log_file in "${log_files[@]}"; do
        if [ -f "$log_file" ]; then
            rm -f "$log_file"
            log_info "已删除 $log_file"
        fi
    done
    
    log_success "日志文件清理完成"
}

# 清理PID文件
clean_pids() {
    log_info "清理PID文件..."
    
    local pid_files=("$PIDFILE_PYTHON" "$PIDFILE_NODEJS" "$PIDFILE_TASKAPI")
    
    for pid_file in "${pid_files[@]}"; do
        if [ -f "$pid_file" ]; then
            rm -f "$pid_file"
            log_info "已删除 $pid_file"
        fi
    done
    
    log_success "PID文件清理完成"
}

# 检查服务状态
check_service_status() {
    log_info "检查服务状态..."
    
    local any_running=false
    
    # 检查各服务端口
    if netstat -tuln 2>/dev/null | grep -q ":8080 "; then
        log_warning "端口 8080 仍被占用 (Task API)"
        any_running=true
    fi
    
    if netstat -tuln 2>/dev/null | grep -q ":8001 "; then
        log_warning "端口 8001 仍被占用 (Python Processor)"
        any_running=true
    fi
    
    if netstat -tuln 2>/dev/null | grep -q ":8002 "; then
        log_warning "端口 8002 仍被占用 (Node.js Processor)"
        any_running=true
    fi
    
    if [ "$any_running" = false ]; then
        log_success "所有服务已完全停止"
    else
        log_warning "部分服务可能仍在运行，建议使用 --force 选项"
    fi
}

# 主函数
main() {
    echo "======================================"
    echo "    Task API 本地一键停止脚本"
    echo "======================================"
    echo
    
    # 解析命令行参数
    CLEAN_LOGS=false
    CLEAN_PIDS=false
    CLEAN_ALL=false
    FORCE_STOP=false
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            --clean-logs)
                CLEAN_LOGS=true
                shift
                ;;
            --clean-pids)
                CLEAN_PIDS=true
                shift
                ;;
            --clean-all)
                CLEAN_ALL=true
                shift
                ;;
            --force)
                FORCE_STOP=true
                shift
                ;;
            --help)
                show_help
                exit 0
                ;;
            *)
                log_error "未知选项: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    if [ "$FORCE_STOP" = true ]; then
        force_stop_all
    else
        log_info "正在停止所有服务..."
        
        # 按相反顺序停止服务
        stop_service "Task API" "$PIDFILE_TASKAPI"
        stop_service "Node.js 处理器" "$PIDFILE_NODEJS"
        stop_service "Python 处理器" "$PIDFILE_PYTHON"
    fi
    
    # 执行清理操作
    if [ "$CLEAN_LOGS" = true ] || [ "$CLEAN_ALL" = true ]; then
        clean_logs
    fi
    
    if [ "$CLEAN_PIDS" = true ] || [ "$CLEAN_ALL" = true ]; then
        clean_pids
    fi
    
    # 检查服务状态
    check_service_status
    
    echo
    log_success "停止操作完成！"
    
    if [ "$CLEAN_ALL" != true ]; then
        echo
        log_info "提示:"
        echo "  - 查看剩余进程: ps aux | grep -E '(python.*main.py|node.*main.js|spring-boot)'"
        echo "  - 清理所有文件: $0 --clean-all"
        echo "  - 强制停止: $0 --force"
    fi
}

# 执行主函数
main "$@"