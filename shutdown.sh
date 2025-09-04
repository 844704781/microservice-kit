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

# 检查 Docker 和 Docker Compose 是否安装
check_prerequisites() {
    log_info "检查环境依赖..."
    
    if ! command -v docker &> /dev/null; then
        log_error "Docker 未安装，请先安装 Docker"
        exit 1
    fi
    
    if ! command -v docker-compose &> /dev/null; then
        log_error "Docker Compose 未安装，请先安装 Docker Compose"
        exit 1
    fi
    
    log_success "环境依赖检查通过"
}

# 停止服务
stop_services() {
    log_info "正在停止所有服务..."
    
    # 检查是否有运行中的容器
    local running_containers=$(docker-compose ps -q)
    
    if [ -z "$running_containers" ]; then
        log_warning "没有发现运行中的服务"
        return 0
    fi
    
    # 显示当前运行的服务
    log_info "当前运行的服务:"
    docker-compose ps --format "table"
    
    echo ""
    log_info "开始停止服务..."
    
    # 停止并移除容器
    docker-compose down
    
    if [ $? -eq 0 ]; then
        log_success "所有服务已成功停止"
    else
        log_error "停止服务时发生错误"
        return 1
    fi
}

# 清理资源（可选）
cleanup_resources() {
    local cleanup_mode="$1"
    
    case "$cleanup_mode" in
        "--clean-images")
            log_info "清理相关镜像..."
            docker-compose down --rmi all
            log_success "镜像清理完成"
            ;;
        "--clean-volumes")
            log_info "清理数据卷..."
            docker-compose down --volumes
            log_success "数据卷清理完成"
            ;;
        "--clean-all")
            log_info "清理所有资源（容器、镜像、数据卷、网络）..."
            docker-compose down --rmi all --volumes --remove-orphans
            log_success "所有资源清理完成"
            ;;
        *)
            # 默认只停止容器，不清理其他资源
            ;;
    esac
}

# 显示帮助信息
show_help() {
    echo "Task API 服务停止脚本"
    echo ""
    echo "用法: $0 [选项]"
    echo ""
    echo "选项:"
    echo "  无参数              仅停止容器"
    echo "  --clean-images      停止容器并删除相关镜像"
    echo "  --clean-volumes     停止容器并删除数据卷"
    echo "  --clean-all         停止容器并删除所有相关资源"
    echo "  --help, -h          显示此帮助信息"
    echo ""
    echo "示例:"
    echo "  $0                  # 仅停止服务"
    echo "  $0 --clean-images   # 停止服务并清理镜像"
    echo "  $0 --clean-all      # 停止服务并清理所有资源"
}

# 确认操作（对于清理操作）
confirm_action() {
    local action="$1"
    
    case "$action" in
        "--clean-images"|"--clean-volumes"|"--clean-all")
            log_warning "此操作将删除相关资源，是否继续？ (y/N)"
            read -r response
            case "$response" in
                [yY][eE][sS]|[yY])
                    return 0
                    ;;
                *)
                    log_info "操作已取消"
                    exit 0
                    ;;
            esac
            ;;
    esac
}

# 主函数
main() {
    local cleanup_mode="$1"
    
    # 处理帮助参数
    case "$cleanup_mode" in
        "--help"|"-h")
            show_help
            exit 0
            ;;
    esac
    
    echo "======================================"
    echo "    Task API 服务停止脚本"
    echo "======================================"
    echo ""
    
    # 检查环境
    check_prerequisites
    
    # 确认清理操作
    confirm_action "$cleanup_mode"
    
    # 停止服务
    if stop_services; then
        # 执行清理操作
        cleanup_resources "$cleanup_mode"
        
        echo ""
        log_success "操作完成！"
        
        if [ "$cleanup_mode" = "--clean-all" ]; then
            log_info "所有相关资源已清理，下次启动将重新构建镜像"
        fi
    else
        log_error "停止服务失败"
        exit 1
    fi
}

# 捕获中断信号
trap 'log_warning "操作被中断"; exit 1' INT TERM

# 执行主函数
main "$@"