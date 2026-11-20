import type { useAssignments } from "../hooks/useAssignments";

type Props = { model: ReturnType<typeof useAssignments> };

export function AssignmentSummary({ model }: Props) {
  const { data } = model;
  return (
    <>
      <div className="assignment-summary">
        <div
          className={model.filter === "PENDING" ? "active" : ""}
          onClick={() =>
            model.setFilter(model.filter === "PENDING" ? "ALL" : "PENDING")
          }
          style={{ cursor: "pointer" }}
        >
          <strong>{data.filter((a) => !a.id && !a.ended_at).length}</strong>
          <span>Chưa phân công</span>
        </div>
        <div
          className={model.filter === "OFFERED" ? "active" : ""}
          onClick={() =>
            model.setFilter(model.filter === "OFFERED" ? "ALL" : "OFFERED")
          }
          style={{ cursor: "pointer" }}
        >
          <strong>
            {data.filter((a) => a.id && !a.accepted_by && !a.ended_at).length}
          </strong>
          <span>Chờ cán bộ xác nhận</span>
        </div>
        <div
          className={model.filter === "ACTIVE" ? "active" : ""}
          onClick={() =>
            model.setFilter(model.filter === "ACTIVE" ? "ALL" : "ACTIVE")
          }
          style={{ cursor: "pointer" }}
        >
          <strong>
            {data.filter((a) => a.accepted_by && !a.ended_at).length}
          </strong>
          <span>Đang thực hiện</span>
        </div>
        <div
          className={model.filter === "ENDED" ? "active" : ""}
          onClick={() =>
            model.setFilter(model.filter === "ENDED" ? "ALL" : "ENDED")
          }
          style={{ cursor: "pointer" }}
        >
          <strong>{data.filter((a) => a.ended_at).length}</strong>
          <span>Đã hoàn thành / Kết thúc</span>
        </div>
      </div>
    </>
  );
}
