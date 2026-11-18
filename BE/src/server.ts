/** Điểm khởi chạy backend: kết nối database/dịch vụ cần thiết rồi gọi app.listen và xử lý graceful shutdown. */
import 'reflect-metadata';
import app from './app';
import { env } from './config/env';
import { AppDataSource } from './database/data-source';
import { recalculateOpenIncidentPriorities } from './jobs/recalculate-priority.job';
import { sendPendingNotifications } from './jobs/send-notification.job';
import { createSlaReminders } from './jobs/sla-reminder.job';

const startServer = async () => {
  try {
    // 1. Kết nối Database trước
    await AppDataSource.initialize();
    console.log('✅ Database PostgreSQL kết nối thành công!');

    // 2. Mở port cho Express server
    const port = env.PORT;
    app.listen(port, () => {
      console.log(`🚀 Server đang chạy tại: http://localhost:${port}`);
      console.log(`👉 Bấm vào http://localhost:${port}/api/v1/health để kiểm tra`);
    });
    const priorityTimer=setInterval(()=>void recalculateOpenIncidentPriorities().catch(console.error),15*60*1000);priorityTimer.unref();
    const notificationTimer=setInterval(()=>void sendPendingNotifications().catch(console.error),30*1000);notificationTimer.unref();
    const slaTimer=setInterval(()=>void createSlaReminders().catch(console.error),5*60*1000);slaTimer.unref();
    void sendPendingNotifications().catch(console.error);

  } catch (error) {
    console.error('❌ Lỗi khởi động server:', error);
    process.exit(1);
  }
};

startServer();
