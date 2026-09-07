import { createTheme } from '@mui/material/styles';

// ============================================================
// Theme theo Portal UTH: teal #008689, Montserrat + Roboto
// ============================================================
export const TEAL = '#008689';
export const TEAL_DARK = '#008588';
export const TEAL_DARKER = '#006266';
export const TEAL_DEEP = '#004d50';
export const GREEN = '#008950';
export const BG = '#f5fafa';

const theme = createTheme({
  palette: {
    mode: 'light',
    primary: { main: TEAL, dark: TEAL_DARK, contrastText: '#fff' },
    success: { main: GREEN },
    warning: { main: '#ef6c00' },
    error: { main: '#c62828' },
    background: { default: BG, paper: '#ffffff' },
    text: { primary: '#333333', secondary: '#757575' },
  },
  typography: {
    fontFamily: '"Roboto","Segoe UI","Helvetica Neue",Arial,sans-serif',
    h1: { fontFamily: '"Montserrat","Segoe UI",sans-serif', fontWeight: 800 },
    h2: { fontFamily: '"Montserrat","Segoe UI",sans-serif', fontWeight: 800 },
    h3: { fontFamily: '"Montserrat","Segoe UI",sans-serif', fontWeight: 700 },
    h4: { fontFamily: '"Montserrat","Segoe UI",sans-serif', fontWeight: 700 },
    h5: { fontFamily: '"Montserrat","Segoe UI",sans-serif', fontWeight: 700 },
    h6: { fontFamily: '"Montserrat","Segoe UI",sans-serif', fontWeight: 700, color: TEAL_DARKER },
    button: { fontFamily: '"Montserrat","Segoe UI",sans-serif', textTransform: 'none', fontWeight: 600 },
  },
  shape: { borderRadius: 8 },
  components: {
    MuiCard: {
      styleOverrides: {
        root: {
          border: '1px solid #e5e7eb',
          boxShadow: '0 1px 3px rgba(0,0,0,.08)',
          borderRadius: 10,
        },
      },
    },
    MuiButton: {
      styleOverrides: {
        root: { borderRadius: 8 },
        containedPrimary: {
          '&:hover': {
            backgroundColor: '#fff',
            color: TEAL,
            border: '1px solid',
            borderColor: TEAL,
            boxShadow: '0 0 10px rgba(0,134,137,.35)',
          },
          border: '1px solid transparent',
        },
      },
    },
    MuiTableCell: {
      styleOverrides: {
        head: {
          backgroundColor: '#eef7f7',
          color: TEAL_DARKER,
          fontFamily: '"Montserrat",sans-serif',
          fontWeight: 700,
          fontSize: 12.5,
          textTransform: 'uppercase',
        },
      },
    },
    MuiChip: { styleOverrides: { root: { fontWeight: 600 } } },
  },
});

export default theme;
