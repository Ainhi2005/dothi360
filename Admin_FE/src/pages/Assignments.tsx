import { AssignmentSummary } from "../features/assignments/components/AssignmentSummary";
import { AssignmentList } from "../features/assignments/components/AssignmentList";
import { AssignmentDialog } from "../features/assignments/components/AssignmentDialog";

import { RefreshCw } from "lucide-react";
import { PageHeader } from "../components/PageHeader";

import { Toast } from "../components/Toast";

import { useAssignments } from "../features/assignments/hooks/useAssignments";

export default function Assignments() {
  const model = useAssignments();
  const { toast, setToast, load } = model;
  return (
    <section>
      <PageHeader
        title="Phân công cán bộ"
        parent="Điều hành"
        description="AI tự động phân tích & gợi ý cán bộ phù hợp nhất. Quản trị viên chỉ cần 1 click để duyệt hoặc điều chỉnh."
        actions={
          <button className="refresh-button" onClick={load}>
            <RefreshCw /> Làm mới
          </button>
        }
      />

      <AssignmentSummary model={model} />

      <AssignmentList model={model} />

      {/* Modal Điều phối / Thay đổi cán bộ & đơn vị */}
      <AssignmentDialog model={model} />

      {toast && <Toast message={toast} onClose={() => setToast("")} />}
    </section>
  );
}
