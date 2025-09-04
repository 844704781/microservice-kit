FROM node:18-slim

# 安装curl用于健康检查
RUN apt-get update && apt-get install -y curl && rm -rf /var/lib/apt/lists/*

# 设置工作目录
WORKDIR /app

# 复制package文件
COPY package*.json ./

# 配置npm使用阿里云镜像源并安装依赖
RUN npm config set registry https://registry.npmmirror.com && \
    npm ci --only=production

# 复制应用代码
COPY main.js .

# 暴露端口
EXPOSE 8002

# 启动应用
CMD ["node", "main.js"]