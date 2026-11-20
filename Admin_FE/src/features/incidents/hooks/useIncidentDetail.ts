import { incidentApi } from "../incident.api";
import { assignmentApi } from "../../assignments/assignment.api";
import type { CandidateOfficer } from "../../assignments/assignment.types";
import { useCallback, useEffect, useState } from "react";
import { useParams } from "react-router-dom";
import { errorMessage } from "../../../lib/api";
import type {
  IncidentDetail as IncidentDetailType,
  Department,
} from "../../../types";

/** Quản lý trạng thái và thao tác, tách khỏi phần giao diện. */
export function useIncidentDetail() {
  const { id } = useParams();
  const [data, setData] = useState<IncidentDetailType>();
  const [error, setError] = useState("");
  const [analyzing, setAnalyzing] = useState(false);
  const [analyzeMsg, setAnalyzeMsg] = useState("");
  const [verificationNote, setVerificationNote] = useState("");
  const [verifying, setVerifying] = useState(false);
  const [departments, setDepartments] = useState<Department[]>([]);
  const [officers, setOfficers] = useState<CandidateOfficer[]>([]);
  const [modalOpen, setModalOpen] = useState(false);
  const [selectedDeptId, setSelectedDeptId] = useState("");
  const [selectedOfficerId, setSelectedOfficerId] = useState("");
  const [assignReason, setAssignReason] = useState("");
  const [assigning, setAssigning] = useState(false);
  const [assignmentError, setAssignmentError] = useState("");
  const [approvingAi, setApprovingAi] = useState(false);
  const [toast, setToast] = useState("");

  const load = useCallback(
    () =>
      incidentApi
        .detail(id!)
        .then((r) => {
          setData(r.data.data);
          setError("");
        })
        .catch((e) => setError(errorMessage(e))),
    [id],
  );
  useEffect(() => {
    void load();
  }, [load]);

  const handleAiAnalyze = async () => {
    try {
      setAnalyzing(true);
      setAnalyzeMsg("");
      await incidentApi.analyze(id!);
      await load();
      setAnalyzeMsg("Phân tích AI hoàn tất!");
    } catch (e) {
      setAnalyzeMsg(errorMessage(e));
    } finally {
      setAnalyzing(false);
    }
  };

  const verify = async (decision: "APPROVE" | "REWORK") => {
    if (verificationNote.trim().length < 3) return;
    try {
      setVerifying(true);
      await incidentApi.verify(id!, decision, verificationNote.trim());
      setVerificationNote("");
      await load();
    } catch (e) {
      setError(errorMessage(e));
    } finally {
      setVerifying(false);
    }
  };

  const handleApproveAi = async () => {
    if (!data) return;
    try {
      setApprovingAi(true);
      await assignmentApi.approveSuggestion(data.id);
      setToast("Đã duyệt phân công cán bộ theo đề xuất AI thành công!");
      await load();
    } catch (e) {
      setError(errorMessage(e));
    } finally {
      setApprovingAi(false);
    }
  };

  const openAssignModal = async () => {
    if (!data) return;
    let availableDepartments = departments;
    let availableOfficers = officers;
    try {
      const response = await assignmentApi.candidates(data.id);
      availableDepartments = response.data.data.departments ?? [];
      availableOfficers = response.data.data.officers ?? [];
      setDepartments(availableDepartments);
      setOfficers(availableOfficers);
    } catch (e) {
      setError(errorMessage(e));
      return;
    }
    const initDept =
      data.assignment?.department_id ||
      data.ai_suggestion?.department_id ||
      availableDepartments[0]?.id ||
      "";
    const suggestedOfficerId =
      data.assignment?.assigned_officer_id ||
      data.assignment?.accepted_by ||
      data.ai_suggestion?.officer_id ||
      "";
    const initOfficer = availableOfficers.some(
      (officer: CandidateOfficer) => officer.id === suggestedOfficerId,
    )
      ? suggestedOfficerId
      : "";
    setSelectedDeptId(initDept);
    setSelectedOfficerId(initOfficer);
    setAssignReason(
      data?.ai_suggestion?.reason ||
        "Quản trị viên phân công cán bộ tiếp nhận xử lý hiện trường",
    );
    setAssignmentError("");
    setModalOpen(true);
  };

  const handleConfirmAssignment = async () => {
    if (!data || !selectedDeptId) return;
    try {
      setAssigning(true);
      setAssignmentError("");
      await assignmentApi.assignOfficer({
        incident_id: data.id,
        department_id: selectedDeptId,
        officer_id: selectedOfficerId || undefined,
        reason: assignReason.trim() || undefined,
      });
      setModalOpen(false);
      setToast("Đã phân công cán bộ thành công!");
      await load();
    } catch (e) {
      setAssignmentError(errorMessage(e));
    } finally {
      setAssigning(false);
    }
  };

  return {
    id,
    data,
    error,
    analyzing,
    analyzeMsg,
    verificationNote,
    setVerificationNote,
    verifying,
    departments,
    officers,
    modalOpen,
    setModalOpen,
    selectedDeptId,
    setSelectedDeptId,
    selectedOfficerId,
    setSelectedOfficerId,
    assignReason,
    setAssignReason,
    assigning,
    assignmentError,
    approvingAi,
    toast,
    setToast,
    load,
    handleAiAnalyze,
    verify,
    handleApproveAi,
    openAssignModal,
    handleConfirmAssignment,
  };
}
