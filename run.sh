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

# Maven settings.xml 路径
SETTINGS_XML_SOURCE=~/.m2/settings.xml
SETTINGS_XML_DEST="./task-api/settings.xml"

# 清理函数
cleanup() {
    log_warning "检测到服务异常，正在清理所有容器..."
    docker-compose down
    log_info "清理完成"
    exit 1
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

# 启动服务
start_services() {
    log_info "正在启动所有服务..."
    
    # 先清理可能存在的容器
    docker-compose down > /dev/null 2>&1

    # 复制 settings.xml (如果存在)
    if [ -f "$SETTINGS_XML_SOURCE" ]; then
        log_info "检测到 $SETTINGS_XML_SOURCE 存在，正在复制到 $SETTINGS_XML_DEST..."
        cp "$SETTINGS_XML_SOURCE" "$SETTINGS_XML_DEST"
        if [ $? -eq 0 ]; then
            log_success "settings.xml 复制成功"
        else
            log_error "settings.xml 复制失败"
            exit 1
        fi
    else
        log_warning "$SETTINGS_XML_SOURCE 不存在，将使用默认 Maven 仓库配置。"
    fi
    
    # 启动服务
    docker-compose up --build -d
    
    if [ $? -eq 0 ]; then
        log_success "服务启动成功"
    else
        log_error "服务启动失败"
        exit 1
    fi
}

# 等待服务就绪
wait_for_services() {
    log_info "等待服务就绪..."
    
    local max_attempts=30
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        log_info "第 $attempt 次检查服务状态..."
        
        # 检查容器是否都在运行
        local running_containers=$(docker-compose ps --services --filter "status=running" | wc -l)
        local total_containers=$(docker-compose ps --services | wc -l)
        
        if [ "$running_containers" -eq "$total_containers" ] && [ "$total_containers" -gt 0 ]; then
            # 尝试访问健康检查接口
            if curl -s http://localhost:8080/health > /dev/null 2>&1; then
                log_success "所有服务已就绪"
                return 0
            fi
        fi
        
        sleep 5
        attempt=$((attempt + 1))
    done
    
    log_error "服务启动超时"
    return 1
}

# 健康检查
health_check() {
    log_info "执行健康检查..."
    
    # 调用健康检查接口
    local health_response=$(curl -s http://localhost:8080/health)
    
    if [ $? -ne 0 ]; then
        log_error "无法访问健康检查接口"
        return 1
    fi
    
    log_info "健康检查响应: $health_response"
    
    # 检查响应中是否包含失败的模块
    if echo "$health_response" | grep -q '"data":"fail"'; then
        log_error "检测到服务模块异常"
        
        # 显示具体的失败模块
        echo "$health_response" | grep -o '"module":"[^"]*"[^}]*"data":"fail"' | while read -r line; do
            module=$(echo "$line" | grep -o '"module":"[^"]*"' | cut -d'"' -f4)
            log_error "模块 $module 状态异常"
        done
        
        return 1
    fi
    
    # 检查是否所有模块都成功
    local success_count=$(echo "$health_response" | grep -o '"data":"success"' | wc -l)
    
    if [ "$success_count" -ge 2 ]; then
        log_success "所有服务模块健康检查通过"
        
        # 显示具体的成功模块
        echo "$health_response" | grep -o '"module":"[^"]*"[^}]*"data":"success"' | while read -r line; do
            module=$(echo "$line" | grep -o '"module":"[^"]*"' | cut -d'"' -f4)
            log_success "模块 $module 运行正常"
        done
        
        return 0
    else
        log_error "健康检查未通过，成功模块数量不足"
        return 1
    fi
}

# 显示服务信息
show_service_info() {
    log_info "服务信息:"
    echo "  - Task API: http://localhost:8080"
    echo "  - Python Processor: http://localhost:8001"
    echo "  - Node.js Processor: http://localhost:8002"
    echo ""
    echo "健康检查接口: http://localhost:8080/health"
    echo ""
    echo "停止服务: docker-compose down"
    echo "查看日志: docker-compose logs -f"
}

# 主函数
main() {
    echo "======================================"
    echo "    Task API 一键启动脚本"
    echo "======================================"
    echo ""
    
    # 检查环境
    check_prerequisites
    
    # 启动服务
    start_services
    
    # 等待服务就绪
    if ! wait_for_services; then
        cleanup
    fi
    
    # 健康检查
    if ! health_check; then
        cleanup
    fi
    
    # 显示服务信息
    echo ""
    log_success "所有服务启动成功！"
    echo ""
    show_service_info
}

# 捕获中断信号
trap cleanup INT TERM

# 执行主函数
main "$@"