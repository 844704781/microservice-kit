const express = require('express');
const app = express();
const PORT = process.env.PORT || 8002;

// 中间件配置
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// 健康检查接口
app.get('/health', (req, res) => {
  res.json({ code: 0, message: 'success' });
});

// 启动服务器
app.listen(PORT, '0.0.0.0', () => {
  console.log(`Node.js Processor server is running on http://0.0.0.0:${PORT}`);
  console.log(`Health check: http://localhost:${PORT}/health`);
});

// 优雅关闭
process.on('SIGTERM', () => {
  console.log('SIGTERM received, shutting down gracefully');
  process.exit(0);
});

process.on('SIGINT', () => {
  console.log('SIGINT received, shutting down gracefully');
  process.exit(0);
});