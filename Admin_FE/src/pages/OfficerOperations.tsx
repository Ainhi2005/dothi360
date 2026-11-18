import { useEffect, useState } from 'react';
import { RefreshCw } from 'lucide-react';
import { api, errorMessage } from '../lib/api';
import { PageHeader } from '../components/PageHeader';
import { PageState } from '../components/PageState';
import type { IncidentType } from '../types';

type Row = Record<string, any>;

export default function OfficerOperations() {
  const [types, setTypes] = useState<IncidentType[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [typeId, setTypeId] = useState('');
  const [items, setItems] = useState<{ title: string; description?: string; is_required: boolean }[]>([]);

  const load = async () => {
    setLoading(true);
    try {
      const t = await api.get('/incident-types');
      setTypes(t.data.data);
      setError('');
    } catch (e) {
      setError(errorMessage(e));
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    void load();
  }, []);

  const loadChecklist = async (id: string) => {
    setTypeId(id);
    if (!id) return setItems([]);
    const r = await api.get(`/officer-operations/admin/checklists/${id}`);
    setItems(
      r.data.data.map((x: Row) => ({
        title: x.title,
        description: x.description,
        is_required: x.is_required,
      }))
    );
  };

  const saveChecklist = async () => {
    await api.put(`/officer-operations/admin/checklists/${typeId}`, { items });
    await loadChecklist(typeId);
  };

  return (
    <section>
      <PageHeader
        title="Checklist hiện trường"
        parent="Điều hành"
        description="Quản lý các bước xử lý và điều kiện nghiệm thu theo loại sự cố."
        actions={
          <button className="refresh-button" onClick={load}>
            <RefreshCw /> Làm mới
          </button>
        }
      />
      <PageState loading={loading} error={error} onRetry={load} />
      {!loading && !error && (
        <>
          <article className="panel detail-section">
            <h3>Checklist theo loại sự cố</h3>
            <select value={typeId} onChange={(e) => void loadChecklist(e.target.value)}>
              <option value="">Chọn loại sự cố</option>
              {types.map((t) => (
                <option key={t.id} value={t.id}>
                  {t.name}
                </option>
              ))}
            </select>
            {typeId && (
              <>
                <div className="capability-list">
                  {items.map((item, index) => (
                    <label key={index}>
                      <input
                        type="checkbox"
                        checked={item.is_required}
                        onChange={(e) =>
                          setItems((v) =>
                            v.map((x, i) =>
                              i === index ? { ...x, is_required: e.target.checked } : x
                            )
                          )
                        }
                      />
                      <span>
                        <input
                          value={item.title}
                          onChange={(e) =>
                            setItems((v) =>
                              v.map((x, i) => (i === index ? { ...x, title: e.target.value } : x))
                            )
                          }
                        />
                        <small>Bắt buộc</small>
                      </span>
                      <button onClick={() => setItems((v) => v.filter((_, i) => i !== index))}>
                        ×
                      </button>
                    </label>
                  ))}
                </div>
                <div className="modal-actions">
                  <button
                    className="button secondary"
                    onClick={() => setItems((v) => [...v, { title: '', is_required: true }])}
                  >
                    Thêm bước
                  </button>
                  <button className="button primary" onClick={saveChecklist}>
                    Lưu checklist
                  </button>
                </div>
              </>
            )}
          </article>
        </>
      )}
    </section>
  );
}
