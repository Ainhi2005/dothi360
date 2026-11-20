import { assignmentApi } from "../../assignments/assignment.api";
import type { CandidateOfficer } from "../../assignments/assignment.types";
import { useEffect, useState } from "react";
import { errorMessage } from "../../../lib/api";
import type { Assignment, Department } from "../../../types";

/** Quản lý trạng thái và thao tác, tách khỏi phần giao diện. */
export function useAssignments() {
  const [data, setData] = useState<Assignment[]>([]);
  const [departments, setDepartments] = useState<Department[]>([]);
  const [officers, setOfficers] = useState<CandidateOfficer[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const [selected, setSelected] = useState<Assignment>();
  const [selectedDeptId, setSelectedDeptId] = useState("");
  const [selectedOfficerId, setSelectedOfficerId] = useState("");
  const [reason, setReason] = useState("");
  const [toast, setToast] = useState("");
  const [approvingId, setApprovingId] = useState<string | null>(null);
  const [filter, setFilter] = useState<
    "ALL" | "PENDING" | "OFFERED" | "ACTIVE" | "ENDED"
  >("ALL");

  const load = () => {
    setLoading(true);
    Promise.all([assignmentApi.list(), assignmentApi.departments()])
      .then(([a, d]) => {
        setData(a.data.data);
        setDepartments(d.data.data);
        setError("");
      })
      .catch((e) => setError(errorMessage(e)))
      .finally(() => setLoading(false));
  };

  useEffect(() => {
    void load();
  }, []);

  // Duyệt nhanh đề xuất của AI (1-Click Approve)
  const handleApproveAi = async (incidentId: string) => {
    try {
      setApprovingId(incidentId);
      await assignmentApi.approveSuggestion(incidentId);
      setToast("Đã duyệt phân công cán bộ theo đề xuất AI thành công!");
      load();
    } catch (e) {
      setError(errorMessage(e));
    } finally {
      setApprovingId(null);
    }
  };

  // Mở modal điều phối / thay đổi cán bộ
  const openReassignModal = async (assignment: Assignment) => {
    try {
      const response = await assignmentApi.candidates(assignment.incident_id);
      const candidateDepartments = response.data.data.departments ?? [];
      const candidateOfficers: CandidateOfficer[] =
        response.data.data.officers ?? [];
      setDepartments(candidateDepartments);
      setOfficers(candidateOfficers);
      setSelected(assignment);
      const initialDept =
        assignment.department_id ||
        assignment.ai_suggested_department_id ||
        (candidateDepartments[0]?.id ?? "");
      const suggestedOfficerId =
        assignment.assigned_officer_id ||
        assignment.accepted_by ||
        assignment.ai_suggested_officer_id ||
        "";
      setSelectedDeptId(initialDept);
      setSelectedOfficerId(
        candidateOfficers.some((o) => o.id === suggestedOfficerId)
          ? suggestedOfficerId
          : "",
      );
      setReason(
        assignment.ai_suggestion_reason ||
          "Quản trị viên phân công cán bộ tiếp nhận xử lý hiện trường",
      );
    } catch (requestError) {
      setError(errorMessage(requestError));
    }
  };

  // Xác nhận phân công thủ công / thay đổi
  const handleConfirmAssignment = async () => {
    if (!selected || !selectedDeptId) return;
    try {
      await assignmentApi.assignOfficer({
        incident_id: selected.incident_id,
        department_id: selectedDeptId,
        officer_id: selectedOfficerId || undefined,
        reason: reason.trim() || undefined,
      });
      setSelected(undefined);
      setToast("Đã phân công cán bộ thành công!");
      load();
    } catch (e) {
      setError(errorMessage(e));
    }
  };

  const filteredOfficers = officers.filter(
    (o) => !selectedDeptId || o.department_id === selectedDeptId,
  );

  return {
    data,
    departments,
    loading,
    error,
    selected,
    setSelected,
    selectedDeptId,
    setSelectedDeptId,
    selectedOfficerId,
    setSelectedOfficerId,
    reason,
    setReason,
    toast,
    setToast,
    approvingId,
    filter,
    setFilter,
    load,
    handleApproveAi,
    openReassignModal,
    handleConfirmAssignment,
    filteredOfficers,
  };
}
