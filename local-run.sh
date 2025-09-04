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

# 清理函数
cleanup() {
    log_warning "检测到服务异常，正在清理所有进程..."
    
    # 停止所有服务
    if [ -f "$PIDFILE_PYTHON" ]; then
        PID=$(cat "$PIDFILE_PYTHON")
        if kill -0 "$PID" 2>/dev/null; then
            kill "$PID"
            log_info "已停止 Python 处理器 (PID: $PID)"
        fi
        rm -f "$PIDFILE_PYTHON"
    fi
    
    if [ -f "$PIDFILE_NODEJS" ]; then
        PID=$(cat "$PIDFILE_NODEJS")
        if kill -0 "$PID" 2>/dev/null; then
            kill "$PID"
            log_info "已停止 Node.js 处理器 (PID: $PID)"
        fi
        rm -f "$PIDFILE_NODEJS"
    fi
    
    if [ -f "$PIDFILE_TASKAPI" ]; then
        PID=$(cat "$PIDFILE_TASKAPI")
        if kill -0 "$PID" 2>/dev/null; then
            kill "$PID"
            log_info "已停止 Task API (PID: $PID)"
        fi
        rm -f "$PIDFILE_TASKAPI"
    fi
    
    log_info "清理完成"
    exit 1
}

# 设置信号处理
trap cleanup SIGINT SIGTERM

# 检查环境依赖
check_prerequisites() {
    log_info "检查环境依赖..."
    
    # 检查 Java 17
    if ! command -v java &> /dev/null; then
        log_error "Java 未安装，请先安装 Java 17"
        exit 1
    fi
    
    JAVA_VERSION=$(java -version 2>&1 | head -n 1 | cut -d'"' -f2 | cut -d'.' -f1)
    if [ "$JAVA_VERSION" != "17" ]; then
        log_warning "当前 Java 版本: $JAVA_VERSION，推荐使用 Java 17"
        log_info "建议使用: jabba use openjdk@1.17.0"
    fi
    
    # 检查 Python
    if ! command -v python3 &> /dev/null; then
        log_error "Python3 未安装，请先安装 Python 3.8+"
        exit 1
    fi
    
    # 检查 Node.js
    if ! command -v node &> /dev/null; then
        log_error "Node.js 未安装，请先安装 Node.js 18.20.5+"
        exit 1
    fi
    
    # 检查 npm
    if ! command -v npm &> /dev/null; then
        log_error "npm 未安装，请先安装 npm"
        exit 1
    fi
    
    log_success "环境依赖检查通过"
}

# 启动 Python 处理器
start_python_processor() {
    log_info "启动 Python 处理器..."
    
    cd python-processor || {
        log_error "无法进入 python-processor 目录"
        exit 1
    }
    
    # 检查虚拟环境
    if [ ! -d ".venv" ]; then
        log_warning "虚拟环境不存在，正在创建..."
        python3 -m venv .venv
        source .venv/bin/activate
        pip install -r requirements.txt
    else
        source .venv/bin/activate
    fi
    
    # 启动服务
    nohup python main.py > ../python-processor.log 2>&1 &
    echo $! > "../$PIDFILE_PYTHON"
    
    cd ..
    log_success "Python 处理器已启动 (PID: $(cat $PIDFILE_PYTHON))"
}

# 启动 Node.js 处理器
start_nodejs_processor() {
    log_info "启动 Node.js 处理器..."
    
    cd nodejs-processor || {
        log_error "无法进入 nodejs-processor 目录"
        exit 1
    }
    
    # 检查依赖
    if [ ! -d "node_modules" ]; then
        log_info "安装 Node.js 依赖..."
        npm install
    fi
    
    # 启动服务
    nohup npm start > ../nodejs-processor.log 2>&1 &
    echo $! > "../$PIDFILE_NODEJS"
    
    cd ..
    log_success "Node.js 处理器已启动 (PID: $(cat $PIDFILE_NODEJS))"
}

# 启动 Task API
start_task_api() {
    log_info "启动 Task API..."
    
    cd task-api || {
        log_error "无法进入 task-api 目录"
        exit 1
    }
    
    # 启动服务
    nohup ./mvnw spring-boot:run > ../task-api.log 2>&1 &
    echo $! > "../$PIDFILE_TASKAPI"
    
    cd ..
    log_success "Task API 已启动 (PID: $(cat $PIDFILE_TASKAPI))"
}

# 等待服务就绪
wait_for_services() {
    log_info "等待服务就绪..."
    
    local max_attempts=30
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        log_info "第 $attempt 次检查服务状态..."
        
        # 检查 Python 处理器
        if curl -s -f http://localhost:8001/health > /dev/null 2>&1; then
            PYTHON_READY=true
        else
            PYTHON_READY=false
        fi
        
        # 检查 Node.js 处理器
        if curl -s -f http://localhost:8002/health > /dev/null 2>&1; then
            NODEJS_READY=true
        else
            NODEJS_READY=false
        fi
        
        # 检查 Task API
        if curl -s -f http://localhost:8080/health > /dev/null 2>&1; then
            TASKAPI_READY=true
        else
            TASKAPI_READY=false
        fi
        
        if [ "$PYTHON_READY" = true ] && [ "$NODEJS_READY" = true ] && [ "$TASKAPI_READY" = true ]; then
            log_success "所有服务已就绪"
            return 0
        fi
        
        sleep 5
        ((attempt++))
    done
    
    log_error "服务启动超时，请检查日志文件"
    cleanup
}

# 健康检查
health_check() {
    log_info "执行健康检查..."
    
    # 聚合健康检查
    HEALTH_RESPONSE=$(curl -s http://localhost:8080/health)
    if [ $? -eq 0 ]; then
        log_info "健康检查响应: $HEALTH_RESPONSE"
        
        # 检查响应中是否包含成功标识
        if echo "$HEALTH_RESPONSE" | grep -q '"code":0'; then
            log_success "所有服务模块健康检查通过"
            
            # 解析并显示各模块状态
            if echo "$HEALTH_RESPONSE" | grep -q '"module":"python".*"data":"success"'; then
                log_success "模块 python 运行正常"
            fi
            
            if echo "$HEALTH_RESPONSE" | grep -q '"module":"nodejs".*"data":"success"'; then
                log_success "模块 nodejs 运行正常"
            fi
        else
            log_warning "部分服务模块可能存在问题"
        fi
    else
        log_error "健康检查失败"
        cleanup
    fi
}

# 显示服务信息
show_service_info() {
    echo
    log_success "所有服务启动成功！"
    echo
    log_info "服务信息:"
    echo "  - Task API: http://localhost:8080"
    echo "  - Python Processor: http://localhost:8001"
    echo "  - Node.js Processor: http://localhost:8002"
    echo
    echo "健康检查接口: http://localhost:8080/health"
    echo
    echo "日志文件:"
    echo "  - Task API: task-api.log"
    echo "  - Python Processor: python-processor.log"
    echo "  - Node.js Processor: nodejs-processor.log"
    echo
    echo "停止服务: ./local-shutdown.sh"
    echo "查看日志: tail -f *.log"
}

# 主函数
main() {
    echo "======================================"
    echo "    Task API 本地一键启动脚本"
    echo "======================================"
    echo
    
    check_prerequisites
    
    log_info "正在启动所有服务..."
    
    # 按顺序启动服务
    start_python_processor
    sleep 3
    
    start_nodejs_processor
    sleep 3
    
    start_task_api
    
    wait_for_services
    health_check
    show_service_info
    
    # 保持脚本运行
    log_info "按 Ctrl+C 停止所有服务"
    while true; do
        sleep 10
    done
}

# 执行主函数
main "$@"