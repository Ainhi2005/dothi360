export function Toast({ message, tone = 'success', onClose }: { message: string; tone?: 'success' | 'error'; onClose: () => void }) {
  return <div className={`toast ${tone}`} role="status"><span>{message}</span><button onClick={onClose} aria-label="Đóng">×</button></div>;
}
