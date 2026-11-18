# Đô thị 360 — Admin Web

## Chạy local

```powershell
Copy-Item .env.example .env
npm install
npm run dev
```

Backend mặc định chạy tại `http://localhost:3000/api/v1`. Có thể đổi qua `VITE_API_URL`.

Tài khoản seed: `admin@urban.com` / `123456`.

## Kiểm tra production

```powershell
npm run lint
npm run build
```

Các phân hệ hiện có: tổng quan, sự cố, phân công lại, người dùng, loại sự cố và đơn vị phụ trách.
