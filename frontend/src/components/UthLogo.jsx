import { Box } from '@mui/material';
import { TEAL, TEAL_DARKER, GOLD } from '../theme';

// ============================================================
// UthLogo — logo chữ "UTH" (wordmark), KHÔNG dùng file ảnh.
// Chữ U·T·H kiểu serif đậm + gradient teal (hoặc trắng trên nền
// tối) + gạch chân vàng gold, mô phỏng wordmark của UTH.
//   <UthLogo size={42} />                → nền sáng (teal)
//   <UthLogo size={64} tone="light" />   → nền tối (trắng)
// ============================================================
export const LOGO_FONT = '"Playfair Display","Times New Roman",Georgia,serif';
export const LOGO_TEXT = 'UTH';

const TONES = {
  // Nền sáng: chữ teal gradient
  dark: {
    fill: `linear-gradient(180deg, ${TEAL} 0%, ${TEAL_DARKER} 100%)`,
    color: TEAL_DARKER,
    textShadow: 'none',
  },
  // Nền tối (topbar/footer/login): chữ trắng ngà + bóng nhẹ
  light: {
    fill: 'linear-gradient(180deg,#ffffff 0%,#dff2f2 100%)',
    color: '#ffffff',
    textShadow: '0 1px 2px rgba(0,0,0,.28)',
  },
};

export default function UthLogo({ size = 40, tone = 'dark', rule, sx }) {
  const t = TONES[tone] || TONES.dark;
  const px = typeof size === 'number' ? size : 40;
  const showRule = rule === undefined ? px >= 24 : rule;

  return (
    <Box
      sx={{
        display: 'inline-flex',
        flexDirection: 'column',
        alignItems: 'center',
        justifyContent: 'center',
        lineHeight: 1,
        userSelect: 'none',
        flexShrink: 0,
        ...sx,
      }}
    >
      <Box
        component="span"
        role="img"
        aria-label="UTH"
        sx={{
          fontFamily: LOGO_FONT,
          fontWeight: 900,
          fontSize: size,
          lineHeight: 0.95,
          letterSpacing: '0.01em',
          color: t.color,
          textShadow: t.textShadow,
          backgroundImage: t.fill,
          WebkitBackgroundClip: 'text',
          backgroundClip: 'text',
          WebkitTextFillColor: 'transparent',
        }}
      >
        {LOGO_TEXT}
      </Box>

      {showRule && (
        <Box
          sx={{
            width: '100%',
            height: Math.max(2, Math.round(px * 0.07)),
            borderRadius: 99,
            mt: `${Math.max(2, Math.round(px * 0.1))}px`,
            backgroundImage: `linear-gradient(90deg, ${GOLD} 0%, #f0d98a 50%, ${GOLD} 100%)`,
          }}
        />
      )}
    </Box>
  );
}
