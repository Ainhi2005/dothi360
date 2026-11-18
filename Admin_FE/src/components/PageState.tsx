export function PageState({ loading, error, empty, onRetry }: { loading?: boolean; error?: string; empty?: boolean; onRetry?: () => void }) {
  if (loading) return <div className="state"><div className="spinner"/><p>Đang tải dữ liệu…</p></div>;
  if (error) return <div className="state"><p>{error}</p><button className="button secondary" onClick={onRetry}>Thử lại</button></div>;
  if (empty) return <div className="state"><p>Chưa có dữ liệu phù hợp.</p></div>;
  return null;
}
