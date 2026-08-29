import { useState } from 'react';
import {
  Dialog, DialogTitle, DialogContent, DialogActions, Button, TextField,
  FormControlLabel, Checkbox, Alert, Typography,
} from '@mui/material';
import api, { errMessage } from '../api/client';
import { toast } from 'react-toastify';

// Modal đổi mật khẩu — gọi /api/auth/doimatkhau (log qua TRG_LogDoiMatKhau)
export default function ChangePasswordDialog({ open, onClose }) {
  const [form, setForm] = useState({ cu: '', moi: '', re: '' });
  const [show, setShow] = useState(false);
  const [busy, setBusy] = useState(false);

  const submit = async () => {
    if (form.moi.length < 6) return toast.error('Mật khẩu mới phải có ít nhất 6 ký tự.');
    if (form.moi !== form.re) return toast.error('Mật khẩu nhập lại không khớp.');
    if (form.moi === form.cu) return toast.error('Mật khẩu mới không được trùng mật khẩu cũ.');
    setBusy(true);
    try {
      const { data } = await api.post('/auth/doimatkhau', { MatKhauCu: form.cu, MatKhauMoi: form.moi });
      toast.success(`✅ ${data.message}`);
      setForm({ cu: '', moi: '', re: '' });
      onClose();
    } catch (e) {
      toast.error(errMessage(e, 'Đổi mật khẩu thất bại.'));
    } finally {
      setBusy(false);
    }
  };

  const type = show ? 'text' : 'password';
  return (
    <Dialog open={open} onClose={onClose} maxWidth="xs" fullWidth>
      <DialogTitle sx={{ fontFamily: 'Montserrat', fontWeight: 700, color: 'primary.dark' }}>🔑 Đổi mật khẩu</DialogTitle>
      <DialogContent>
        <Alert severity="info" sx={{ mb: 2, fontSize: 13 }}>
          Mỗi lần đổi mật khẩu đều được ghi vào nhật ký (trigger <b>TRG_LogDoiMatKhau</b>).
        </Alert>
        <TextField fullWidth size="small" type={type} label="Mật khẩu hiện tại" sx={{ mb: 1.75 }}
          value={form.cu} onChange={(e) => setForm({ ...form, cu: e.target.value })} />
        <TextField fullWidth size="small" type={type} label="Mật khẩu mới (≥ 6 ký tự)" sx={{ mb: 1.75 }}
          value={form.moi} onChange={(e) => setForm({ ...form, moi: e.target.value })} />
        <TextField fullWidth size="small" type={type} label="Nhập lại mật khẩu mới"
          value={form.re} onChange={(e) => setForm({ ...form, re: e.target.value })} />
        <FormControlLabel sx={{ mt: 1 }} control={<Checkbox checked={show} onChange={(e) => setShow(e.target.checked)} />}
          label={<Typography variant="body2">Hiện mật khẩu</Typography>} />
      </DialogContent>
      <DialogActions sx={{ px: 3, pb: 2 }}>
        <Button onClick={onClose}>Hủy</Button>
        <Button variant="contained" disabled={busy} onClick={submit}>
          {busy ? 'Đang xử lý...' : 'Đổi mật khẩu'}
        </Button>
      </DialogActions>
    </Dialog>
  );
}
