import { useEffect, useState, type FormEvent } from 'react';
import { api, errorMessage } from '../lib/api';
type Suggestion = { id: string; label: string; group: string; question: string };
type Message = { role: 'user' | 'assistant'; content: string; source?: string };
export default function ChatAssistant() {
  const [catalog, setCatalog] = useState<Suggestion[]>([]);
  const [messages, setMessages] = useState<Message[]>([]);
  const [question, setQuestion] = useState(''), [busy, setBusy] = useState(false), [error, setError] = useState('');
  useEffect(() => { api.get('/chat/suggestions').then(r => setCatalog(r.data.data)).catch(e => setError(errorMessage(e))); }, []);
  async function send(suggestion?: Suggestion) {
    const text = (suggestion?.question ?? question).trim();
    if (!text || busy) return;
    const history = messages.slice(-10).map(({ role, content }) => ({ role, content: content.slice(0, 2000) }));
    setMessages(items => [...items, { role: 'user', content: text }]); setQuestion(''); setBusy(true); setError('');
    try {
      const response = await api.post('/chat', { message: text, history, ...(suggestion ? { suggestion_id: suggestion.id } : {}) }, { timeout: 40000 });
      const result = response.data.data;
      setMessages(items => [...items, { role: 'assistant', content: result.reply,
        source: result.mode === 'AI' ? 'Gemini phân tích và trả lời dựa trên dữ liệu hệ thống' : result.ai_used ? 'AI chưa trả lời được, dùng nội dung dự phòng đã kiểm tra' : result.mode === 'DATABASE' ? 'Truy vấn database, không gọi AI' : 'Kịch bản, không gọi AI' }]);
    } catch (cause) { setError(errorMessage(cause)); }
    finally { setBusy(false); }
  }
  function submit(event: FormEvent) { event.preventDefault(); void send(); }
  const groups = [...new Set(catalog.map(item => item.group))];
  return <section>
    <div className="page-heading"><div><h2>Trợ lý đô thị</h2><p>Bộ câu hỏi dùng chung với ứng dụng. Tra cứu chỉ đọc phản ánh do tài khoản đang đăng nhập gửi.</p></div></div>
    {error && <div className="alert" role="alert">{error}</div>}
    <div className="chat-admin-grid">
      <article className="panel"><h3>Câu hỏi có sẵn ({catalog.length})</h3><p>Chọn một câu để kiểm tra. Câu hỏi có sẵn không cần gọi Gemini.</p>
        {groups.map(group => <div className="chat-question-group" key={group}><h4>{group}</h4><div className="chat-question-options">
          {catalog.filter(item => item.group === group).map(item => <button key={item.id} className="button secondary" disabled={busy} onClick={() => void send(item)} title={item.question}>{item.label}</button>)}
        </div></div>)}
      </article>
      <article className="panel"><h3>Thử hội thoại</h3><p>Hướng dẫn, tra cứu và giải thích trạng thái; không sửa hoặc duyệt hồ sơ qua chat.</p>
        <div className="chat-admin-messages" role="log" aria-live="polite">{!messages.length && <p>Chọn câu hỏi bên trái hoặc nhập câu hỏi để bắt đầu.</p>}
          {messages.map((item, index) => <div key={index} className={`chat-admin-message ${item.role}`}><strong>{item.role === 'user' ? 'Bạn' : 'Trợ lý'}</strong><p>{item.content}</p>{item.source && <small>{item.source}</small>}</div>)}
          {busy && <p role="status">Đang trả lời…</p>}
        </div>
        <form onSubmit={submit} className="chat-admin-composer"><label htmlFor="chat-question">Câu hỏi<input id="chat-question" value={question} onChange={e => setQuestion(e.target.value)} maxLength={2000} placeholder="Ví dụ: kiểm tra lịch sử"/></label><button className="button primary" disabled={busy || !question.trim()}>Gửi</button></form>
      </article>
    </div>
  </section>;
}
