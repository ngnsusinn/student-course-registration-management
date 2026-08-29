import { Card, CardContent, Typography, Stack, Box } from '@mui/material';
import { TEAL, TEAL_DARKER } from '../theme';

// Card tiêu đề có gạch đầu dòng teal — pattern chung mọi trang
export function SectionCard({ title, action, children, sx }) {
  return (
    <Card sx={{ mb: 2.5, ...sx }}>
      <CardContent>
        <Stack direction="row" justifyContent="space-between" alignItems="center" sx={{ mb: 1.5, flexWrap: 'wrap', gap: 1 }}>
          <Typography variant="h6" sx={{ display: 'flex', alignItems: 'center', gap: 1, '&::before': {
            content: '""', width: 4, height: 18, bgcolor: TEAL, borderRadius: 1, display: 'inline-block',
          } }}>
            {title}
          </Typography>
          {action}
        </Stack>
        {children}
      </CardContent>
    </Card>
  );
}

// Ô số liệu thống kê
export function StatBox({ value, label, color }) {
  return (
    <Box sx={{ border: '1px solid #e5e7eb', borderLeft: `4px solid ${color || TEAL}`, borderRadius: 1.5, p: 1.75, bgcolor: '#fff', height: '100%' }}>
      <Typography sx={{ fontFamily: 'Montserrat', fontWeight: 800, fontSize: 24, color: color || TEAL_DARKER }}>{value}</Typography>
      <Typography variant="body2" color="text.secondary">{label}</Typography>
    </Box>
  );
}
