import { Chip } from '@mui/material';
import { statusOf } from '../utils/format';

// Chip trạng thái thống toàn hệ thống
export const StatusChip = ({ group, code, size = 'small' }) => {
  const [color, label] = statusOf(group, code);
  return <Chip label={label} color={color} size={size} variant={color === 'default' ? 'outlined' : 'filled'} />;
};

// Chip sĩ số hiện tại/tối đa (xanh-vàng-đỏ như portal)
export const SiSoChip = ({ hienTai, toiDa }) => {
  const con = Number(toiDa) - Number(hienTai);
  const color = con <= 0 ? 'error' : con <= 3 ? 'warning' : 'success';
  return <Chip label={`${hienTai}/${toiDa}`} color={color} size="small" />;
};
