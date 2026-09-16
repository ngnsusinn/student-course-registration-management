// ============================================================
// models/prepare.model.js — ⚠️ MODEL của CÔNG CỤ DEMO (1-click prepare/fix)
//   Phần DỮ LIỆU đi qua stored procedure như mọi model khác.
//   Phần TRIỂN KHAI stored procedure (DDL) dùng prepare/sqlRunner.js.
// ============================================================
import { spMulti } from '../db.js';
import { apFileSql } from '../prepare/sqlRunner.js';

// Trạng thái hiện tại: [cờ 2 thủ tục, các lớp demo, tài khoản demo]
export const trangThai = () => spMulti('CALL SP_Prepare_TrangThai()');

// Dọn & chuẩn bị dữ liệu demo (idempotent)
export const chuanBiDuLieu = (kichBan) => spMulti('CALL SP_Prepare_Demo(?)', [kichBan]);

// Triển khai 1 file SQL trong whitelist
export const apSql = (ma) => apFileSql(ma);
