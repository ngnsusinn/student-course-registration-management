import { configureStore, createSlice } from '@reduxjs/toolkit';
import { getToken, getUser, setSession, clearSession } from '../api/client';

// ============================================================
// authSlice — phiên đăng nhập (Redux Toolkit, như portal)
// ============================================================
const authSlice = createSlice({
  name: 'auth',
  initialState: { token: getToken(), user: getUser() },
  reducers: {
    loggedIn(state, { payload }) {
      state.token = payload.token;
      state.user = payload.user;
      setSession(payload.token, payload.user);
    },
    loggedOut(state) {
      state.token = null;
      state.user = null;
      clearSession();
    },
  },
});

export const { loggedIn, loggedOut } = authSlice.actions;

export const store = configureStore({ reducer: { auth: authSlice.reducer } });

// Selectors tiện dụng
export const selectUser = (s) => s.auth.user;
export const selectRole = (s) => s.auth.user?.MaVaiTro || null;
