FROM openjdk:17-jdk-slim

# 安装curl用于健康检查
RUN apt-get update && apt-get install -y curl && rm -rf /var/lib/apt/lists/*

# 设置工作目录
WORKDIR /app

# 复制Maven包装器和配置文件
COPY mvnw .
COPY mvnw.cmd .
COPY .mvn .mvn
COPY pom.xml .

# 创建.m2目录并复制Maven设置文件（如果存在）
RUN mkdir -p /root/.m2
COPY settings.xml /root/.m2/settings.xml

# 给Maven包装器执行权限
RUN chmod +x ./mvnw

# 下载依赖（利用Docker缓存层）
RUN ./mvnw dependency:go-offline -B

# 复制源代码
COPY src src

# 构建应用
RUN ./mvnw clean package -DskipTests

# 暴露端口
EXPOSE 8080

# 启动应用
CMD ["java", "-jar", "target/task-api-0.0.1-SNAPSHOT.jar"]