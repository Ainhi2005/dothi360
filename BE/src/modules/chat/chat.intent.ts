import type { ChatHistory } from './chat.validation';
import { chatCatalog, type ChatIntent } from './chat.catalog';
export type RecognizedIntent = ChatIntent | 'privacy' | 'read_only' | 'out_of_scope' | 'clarify';
export function normalizeChat(text: string) {
  return text.toLowerCase().normalize('NFD').replace(/[\u0300-\u036f]/g, '').replace(/đ/g, 'd').replace(/[^a-z0-9 ]/g, ' ').replace(/\s+/g, ' ').trim();
}
export function matchIntent(message: string, history: ChatHistory = []): RecognizedIntent | null {
  const text = normalizeChat(message);
  if (/nguoi khac|user\s*id|reporter\s*id|toan he thong|tat ca (nguoi|tai khoan)|doi tai khoan|dong vai admin/.test(text)) return 'privacy';
  if (/(duyet|nghiem thu|phan cong|xoa|huy|sua).*(giup toi|thay toi|ho toi)|^(hay |lam on )?(duyet|phan cong|xoa|huy) (ho so|phan anh)/.test(text)) return 'read_only';
  const exact = chatCatalog.find(item => normalizeChat(item.question) === text);
  if (exact) return exact.id;
  if (/^(hi|hello|hey|chao|xin chao|chao ban|xin chao ban|alo)( ban)?$/.test(text)) return 'greeting';
  if (/^(cam on|thank you|thanks|tam biet|bye)( ban| nhe)?$/.test(text)) return 'thanks';
  if (/mat khau|quen mat khau/.test(text)) return 'password';
  if (/thong bao|nhan push|khong nhan.*tin/.test(text)) return 'notifications';
  if (/bi gop|duoc gop|trung lap|phan anh trung/.test(text)) return 'duplicates';
  if (/(la gi|nghia la|y nghia|giai thich|gom nhung|quy trinh)/.test(text) && /trang thai|nghiem thu|xu ly|phan cong/.test(text)) return 'statuses';
  if (/(cach|lam sao|huong dan|can|khong duoc|loi)/.test(text) && /vi tri|dinh vi|toa do|gps|ban do/.test(text)) return 'location';
  if (/\bai\b|phan tich anh/.test(text) && /anh|xac nhan|goi y|nhan dien/.test(text)) return 'ai_analysis';
  if (/anh/.test(text) && /chup|dinh kem|tai len|upload|dung luong|dinh dang/.test(text)) return 'upload_photo';
  if (/cach|lam sao|huong dan|muon gui|tao phan anh/.test(text) && /gui|tao|bao cao/.test(text) && /phan anh|su co|bao cao/.test(text)) return 'send_report';
  if (/lich su|danh sach.*(phan anh|ho so)|tat ca phan anh/.test(text)) return 'history';
  if (/cho.*nghiem thu|cho.*duyet/.test(text)) return 'pending_verification';
  if (/\bda (hoan tat|hoan thanh|xu ly xong)|nhung.*\bda\b.*xu ly/.test(text)) return 'resolved';
  if (/dang.*xu ly/.test(text)) return 'active';
  if (/gan nhat|moi nhat|cai toi bao|hom truoc.*xu ly/.test(text)) return 'latest';
  if (/tinh trang|trang thai|tien do|da.*xu ly.*chua|xu ly.*den dau/.test(text)) return 'history';
  if (/ban.*(giup|ho tro|lam).*gi|tro ly.*(gi|ho tro)|tro giup|gioi han|pham vi|huong dan su dung/.test(text)) return 'help';
  if (/^(no|cai do|ho so do|vay|the con)/.test(text)) {
    const previous = [...history].reverse().find(item => item.role === 'user');
    if (previous && /phan anh|ho so|trang thai|tinh trang|tien do/.test(normalizeChat(previous.content))) return 'latest';
  }
  if (/viet (bai|van|tho)|bai tap|lap trinh|viet code|chung khoan|bong da|tinh yeu|cong thuc nau|thoi tiet/.test(text)) return 'out_of_scope';
  if (text.length < 4 || /^(test|abc|toi muon hoi|hoi chut|giup toi)$/.test(text)) return 'clarify';
  // Only ask Gemini to classify a plausible in-scope question, not arbitrary chat.
  return /phan anh|ho so|do thi|su co|tien do|nghiem thu|bao.*hom|den duong|rac thai|ngap/.test(text) ? null : 'out_of_scope';
}
