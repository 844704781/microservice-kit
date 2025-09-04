# 项目介绍
## 项目背景
本项目是一个分布式任务管理系统，为用户提供任务的创建、执行和查询功能。

## 系统架构

项目采用微服务架构，由以下三个核心组件构成：

### 1. task-api（主服务）
- **技术栈**：Java + Spring Boot
- **职责**：作为系统入口，对外提供 RESTful API 接口
- **功能**：
  - 任务生命周期管理（创建、调度、监控、查询）
  - 根据任务类型智能路由到相应的处理器
  - 对于 Java 原生任务，直接在本服务内执行
  - 对于其他语言任务，委托给专门的处理器执行

### 2. python-processor（Python 任务处理器）
- **技术栈**：Python
- **适用场景**：视频处理、人工智能、数据爬虫、科学计算等
- **职责**：专门处理需要 Python 生态支持的复杂任务

### 3. nodejs-processor（Node.js 任务处理器）
- **技术栈**：Node.js
- **适用场景**：前端构建、Web 自动化、加解密处理、实时数据处理等
- **职责**：处理需要 JavaScript/Node.js 环境的任务

## 快速启动

### 方式一：Docker 启动（推荐）

#### 环境要求
- Docker
- Docker Compose

#### 启动步骤

##### 1. 使用 Docker Compose 启动所有服务
```bash
# 构建并启动所有服务
docker-compose up --build

# 后台运行
docker-compose up --build -d
```

##### 2. 一键启动脚本
```bash
# 使用提供的一键启动脚本
./run.sh
```
该脚本会自动启动所有服务并进行健康检查，如果检测到服务异常会自动清理。

##### 3. 停止服务

###### 方式一：使用一键停止脚本（推荐）

```bash
# 仅停止服务
./shutdown.sh

# 停止服务并清理镜像
./shutdown.sh --clean-images

# 停止服务并清理数据卷
./shutdown.sh --clean-volumes

# 停止服务并清理所有资源（容器、镜像、数据卷、网络）
./shutdown.sh --clean-all

# 查看帮助信息
./shutdown.sh --help
```

###### 方式二：使用 Docker Compose 命令

```bash
# 停止所有服务
docker-compose down

# 停止服务并删除镜像
docker-compose down --rmi all
```

### 方式二：本地启动

#### 环境要求
- Java 17（推荐使用 Jabba 管理）
- Python 3.8+
- Node.js 18.20.5+

#### 启动步骤

##### 1. 启动 Python 处理器
```bash
cd /home/watermelon/workspace/task-api-v3/python-processor
source .venv/bin/activate
python main.py
```
服务将在 `http://localhost:8001` 启动

##### 2. 启动 Node.js 处理器
```bash
cd /home/watermelon/workspace/task-api-v3/nodejs-processor
npm start
```
服务将在 `http://localhost:8002` 启动

##### 3. 启动主服务（Task API）
```bash
# 切换到 Java 17
jabba use openjdk@1.17.0

# 启动服务
cd /home/watermelon/workspace/task-api-v3/task-api
./mvnw spring-boot:run
```
服务将在 `http://localhost:8080` 启动

### 健康检查

#### 单独服务健康检查
- Python 处理器：`curl http://localhost:8001/health`
- Node.js 处理器：`curl http://localhost:8002/health`
- Task API：`curl http://localhost:8080/health`

#### 聚合健康检查
Task API 提供聚合健康检查接口，可以一次性检查所有服务状态：
```bash
curl http://localhost:8080/health
```

**响应格式：**
```json
{
  "code": 0,
  "data": [
    {"module": "python", "data": "success"},
    {"module": "nodejs", "data": "success"}
  ]
}
```

### 服务端口
- **task-api**: 8080
- **python-processor**: 8001
- **nodejs-processor**: 8002
