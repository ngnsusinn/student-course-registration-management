import HomeIcon from '@mui/icons-material/Home';
import RateReviewIcon from '@mui/icons-material/RateReview';
import EventNoteIcon from '@mui/icons-material/EventNote';
import ChecklistIcon from '@mui/icons-material/Checklist';
import BlockIcon from '@mui/icons-material/Block';
import SchoolIcon from '@mui/icons-material/School';
import PaymentsIcon from '@mui/icons-material/Payments';
import TeacherIcon from '@mui/icons-material/Engineering';
import EditNoteIcon from '@mui/icons-material/EditNote';
import DashboardIcon from '@mui/icons-material/Dashboard';
import GroupsIcon from '@mui/icons-material/Groups';
import AccountBalanceIcon from '@mui/icons-material/AccountBalance';
import MenuBookIcon from '@mui/icons-material/MenuBook';
import AddBoxIcon from '@mui/icons-material/AddBox';
import TrendingUpIcon from '@mui/icons-material/TrendingUp';
import KeyIcon from '@mui/icons-material/Key';
import PersonIcon from '@mui/icons-material/Person';
import ScienceIcon from '@mui/icons-material/Science';

// ============================================================
// Menu theo vai tro — duong dan React Router
// ============================================================
export const MENUS = {
  SV: [
    { to: '/', label: 'Trang chủ', icon: HomeIcon, roles: ['SV'] },
    { to: '/thong-tin-ca-nhan', label: 'Thông tin cá nhân', icon: PersonIcon, roles: ['SV'] },
    { to: '/dang-ky', label: 'Đăng ký lớp học phần', icon: RateReviewIcon, roles: ['SV'] },
    { to: '/thoi-khoa-bieu', label: 'Thời khóa biểu', icon: EventNoteIcon, roles: ['SV'] },
    { to: '/dang-ky-cua-toi', label: 'Lớp HP đã đăng ký', icon: ChecklistIcon, roles: ['SV'] },
    { to: '/huy-dang-ky', label: 'Hủy đăng ký HP', icon: BlockIcon, roles: ['SV'] },
    { to: '/bang-diem', label: 'Kết quả học tập', icon: SchoolIcon, roles: ['SV'] },
    { to: '/hoc-phi', label: 'Học phí', icon: PaymentsIcon, roles: ['SV'] },
  ],
  GV: [
    { to: '/', label: 'Trang chủ', icon: HomeIcon, roles: ['GV'] },
    { to: '/lop-cua-toi', label: 'Lớp học phần của tôi', icon: TeacherIcon, roles: ['GV'] },
    { to: '/nhap-diem', label: 'Nhập điểm', icon: EditNoteIcon, roles: ['GV'] },
    { to: '/thoi-khoa-bieu-gv', label: 'Lịch dạy trong tuần', icon: EventNoteIcon, roles: ['GV'] },
  ],
  'PĐT': [
    { to: '/', label: 'Trang chủ', icon: HomeIcon, roles: ['PĐT'] },
    { to: '/quan-ly/sinh-vien', label: 'Quản lý sinh viên', icon: GroupsIcon, roles: ['PĐT'] },
    { to: '/quan-ly/khoa-nganh-lop', label: 'Khoa · Ngành · Lớp', icon: AccountBalanceIcon, roles: ['PĐT'] },
    { to: '/quan-ly/mon-hoc', label: 'Môn học · Giảng viên', icon: MenuBookIcon, roles: ['PĐT'] },
    { to: '/quan-ly/mo-lhp', label: 'Tạo lớp học phần', icon: AddBoxIcon, roles: ['PĐT'] },
    { to: '/quan-ly/diem-canh-bao', label: 'Điểm & Cảnh báo học vụ', icon: TrendingUpIcon, roles: ['PĐT'] },
    { to: '/quan-ly/hoc-phi', label: 'Quản lý học phí', icon: PaymentsIcon, roles: ['PĐT'] },
    { to: '/quan-ly/tai-khoan', label: 'Tài khoản & Phân quyền', icon: KeyIcon, roles: ['PĐT'] },
    { to: '/quan-ly/concurrency', label: 'Concurrency Lab (demo 4 lỗi)', icon: ScienceIcon, roles: ['PĐT'] },
  ],
};

export const menuFor = (role) => MENUS[role] || MENUS.SV;

// Nhãn breadcrumb theo đường dẫn
export const CRUMB_LABELS = {
  '/': 'Trang chủ',
  '/thong-tin-ca-nhan': 'Thông tin cá nhân',
  '/dang-ky': 'Đăng ký lớp học phần',
  '/thoi-khoa-bieu': 'Thời khóa biểu',
  '/dang-ky-cua-toi': 'Lớp học phần đã đăng ký',
  '/huy-dang-ky': 'Hủy đăng ký học phần',
  '/bang-diem': 'Kết quả học tập',
  '/hoc-phi': 'Học phí của tôi',
  '/lop-cua-toi': 'Lớp học phần của tôi',
  '/nhap-diem': 'Nhập điểm',
  '/thoi-khoa-bieu-gv': 'Lịch dạy trong tuần',
  '/quan-ly/sinh-vien': 'Quản lý sinh viên',
  '/quan-ly/khoa-nganh-lop': 'Khoa · Ngành · Lớp',
  '/quan-ly/mon-hoc': 'Môn học · Giảng viên · Phòng',
  '/quan-ly/mo-lhp': 'Tạo lớp học phần',
  '/quan-ly/diem-canh-bao': 'Điểm & Cảnh báo học vụ',
  '/quan-ly/hoc-phi': 'Quản lý học phí',
  '/quan-ly/tai-khoan': 'Tài khoản & Phân quyền',
  '/quan-ly/concurrency': 'Concurrency Lab — demo 4 lỗi',
};
