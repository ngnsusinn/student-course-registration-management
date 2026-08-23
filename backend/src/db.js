import mysql from 'mysql2/promise';
import { DB_CONFIG } from './config.js';

export const pool = mysql.createPool(DB_CONFIG);

export async function query(sql, params) {
  const [rows] = await pool.query(sql, params);
  return rows;
}

export async function getConnection() {
  return pool.getConnection();
}
