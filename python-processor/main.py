from fastapi import FastAPI
import uvicorn

# 创建FastAPI应用实例
app = FastAPI(
    title="Python Task Processor",
    description="Python任务处理器 - 负责处理视频处理、AI、爬虫等Python任务",
    version="1.0.0"
)

# 健康检查接口
@app.get("/health")
async def health_check():
    """健康检查接口"""
    return {
        "code": 0,
        "message": "success"
    }

if __name__ == "__main__":
    # 启动服务
    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=8001,
        reload=True,
        log_level="info"
    )