import { AppDataSource } from '../../database/data-source';
import { Workbook } from 'exceljs';
export class AdminDashboardService{
 notifications(userId:string,page=1,limit=30){const safePage=Math.max(page,1),safeLimit=Math.min(Math.max(limit,1),100);return Promise.all([AppDataSource.query(`SELECT n.id,n.type,n.title,n.message,n.is_read,n.push_status,n.push_attempts,n.push_last_error,n.created_at,n.incident_id,n.data FROM notifications n WHERE n.user_id=$3 ORDER BY n.created_at DESC OFFSET $1 LIMIT $2`,[(safePage-1)*safeLimit,safeLimit,userId]),AppDataSource.query(`SELECT COUNT(*)::int total,COUNT(*)FILTER(WHERE push_status='FAILED')::int failed,COUNT(*)FILTER(WHERE is_read=FALSE)::int unread FROM notifications WHERE user_id=$1`,[userId])]).then(([data,count])=>({data,meta:{page:safePage,limit:safeLimit,...count[0],total_pages:Math.ceil(count[0].total/safeLimit)}}));}
 async summary(){const[r]=await AppDataSource.query(`SELECT COUNT(*)::int total,COUNT(*)FILTER(WHERE status NOT IN('RESOLVED','REJECTED','CANCELLED'))::int open,COUNT(*)FILTER(WHERE status='PENDING_ASSIGNMENT')::int unassigned,COUNT(*)FILTER(WHERE status='ASSIGNED')::int waiting,COUNT(*)FILTER(WHERE status IN('ACCEPTED','IN_PROGRESS'))::int processing,COUNT(*)FILTER(WHERE status='PENDING_VERIFICATION')::int pending_verification,COUNT(*)FILTER(WHERE status='RESOLVED')::int resolved,COUNT(*)FILTER(WHERE priority_level IN('HIGH','EMERGENCY')AND status NOT IN('RESOLVED','REJECTED','CANCELLED'))::int urgent FROM incidents`);const[u]=await AppDataSource.query(`SELECT COUNT(*)FILTER(WHERE role='OFFICER')::int officers,COUNT(*)FILTER(WHERE is_active)::int active_users FROM users`);return{...r,...u,completion_rate:r.total?Math.round(r.resolved/r.total*100):0};}
 trends(days=30){return AppDataSource.query(`SELECT d::date date,COUNT(i.id)::int created,COUNT(i.id)FILTER(WHERE i.status='RESOLVED')::int resolved FROM generate_series(CURRENT_DATE-$1::int+1,CURRENT_DATE,'1 day')d LEFT JOIN incidents i ON i.created_at::date=d::date GROUP BY d ORDER BY d`,[days]);}
 workload(){return AppDataSource.query(`SELECT d.id,d.name,COUNT(ia.id)FILTER(WHERE ia.ended_at IS NULL)::int open,COUNT(ia.id)FILTER(WHERE ia.ended_at IS NOT NULL)::int completed FROM departments d LEFT JOIN incident_assignments ia ON ia.department_id=d.id WHERE d.is_active=TRUE GROUP BY d.id,d.name ORDER BY open DESC`);}
 sla(_hours=24){return AppDataSource.query(`SELECT i.id,i.description,i.status,i.priority_level,i.created_at,EXTRACT(EPOCH FROM(NOW()-i.created_at))/3600 age_hours,EXTRACT(EPOCH FROM((i.created_at+CASE i.priority_level WHEN 'EMERGENCY' THEN INTERVAL '1 hour' WHEN 'HIGH' THEN INTERVAL '4 hours' WHEN 'MEDIUM' THEN INTERVAL '12 hours' ELSE INTERVAL '24 hours' END)-i.created_at))/3600 sla_hours FROM incidents i WHERE i.status NOT IN('RESOLVED','REJECTED','CANCELLED') AND NOW()>(i.created_at+CASE i.priority_level WHEN 'EMERGENCY' THEN INTERVAL '1 hour' WHEN 'HIGH' THEN INTERVAL '4 hours' WHEN 'MEDIUM' THEN INTERVAL '12 hours' ELSE INTERVAL '24 hours' END) ORDER BY i.created_at ASC`);}
 hotspots(){return AppDataSource.query(`SELECT ST_Y(ST_Centroid(ST_Collect(location::geometry))) latitude,ST_X(ST_Centroid(ST_Collect(location::geometry))) longitude,COUNT(*)::int count FROM incidents WHERE created_at>NOW()-INTERVAL '30 days' GROUP BY ST_SnapToGrid(location::geometry,0.01) ORDER BY count DESC LIMIT 100`);}
  async exportCsv() {
    const rows = await AppDataSource.query(`
      SELECT 
        i.id,
        it.name AS type_name,
        i.description,
        i.status,
        i.priority_level,
        i.report_count,
        i.created_at,
        i.resolved_at,
        d.name AS department_name,
        u.full_name AS officer_name
      FROM incidents i
      JOIN incident_types it ON it.id = i.incident_type_id
      LEFT JOIN LATERAL (
        SELECT a.department_id, a.accepted_by
        FROM incident_assignments a
        WHERE a.incident_id = i.id
        ORDER BY a.assigned_at DESC
        LIMIT 1
      ) a ON TRUE
      LEFT JOIN departments d ON d.id = a.department_id
      LEFT JOIN users u ON u.id = a.accepted_by
      ORDER BY i.created_at DESC
    `);

    const esc = (v: unknown) => `"${String(v ?? '').replaceAll('"', '""').replaceAll('\n', ' ').replaceAll('\r', '')}"`;

    const formatDate = (d: any) => {
      if (!d) return '-';
      const dt = new Date(d);
      if (isNaN(dt.getTime())) return '-';
      const pad = (n: number) => String(n).padStart(2, '0');
      return `${pad(dt.getDate())}/${pad(dt.getMonth() + 1)}/${dt.getFullYear()} ${pad(dt.getHours())}:${pad(dt.getMinutes())}`;
    };

    const formatStatus = (s: string) => {
      switch (s) {
        case 'PENDING_ASSIGNMENT': return 'Chờ phân công';
        case 'ASSIGNED': return 'Đã phân công';
        case 'ACCEPTED': return 'Đã tiếp nhận';
        case 'IN_PROGRESS': return 'Đang xử lý';
        case 'PENDING_VERIFICATION': return 'Chờ nghiệm thu';
        case 'RESOLVED': return 'Đã hoàn thành';
        case 'REJECTED': return 'Từ chối';
        case 'CANCELLED': return 'Đã hủy';
        default: return s ?? '-';
      }
    };

    const formatPriority = (p: string) => {
      switch (p) {
        case 'EMERGENCY': return 'Khẩn cấp';
        case 'HIGH': return 'Cao';
        case 'MEDIUM': return 'Trung bình';
        case 'LOW': return 'Thấp';
        default: return p ?? 'Thường';
      }
    };

    const header = [
      'STT',
      'Mã sự cố',
      'Loại sự cố',
      'Nội dung phản ánh',
      'Mức ưu tiên',
      'Trạng thái',
      'Lượt báo',
      'Đơn vị tiếp nhận',
      'Cán bộ phụ trách',
      'Thời gian tiếp nhận',
      'Thời gian hoàn tất',
    ].map(esc).join(',');

    const lines = rows.map((x: any, idx: number) => {
      const stt = idx + 1;
      const code = `#SC-${x.id.slice(0, 8).toUpperCase()}`;
      const type = x.type_name ?? 'Sự cố đô thị';
      const desc = x.description ?? '';
      const priority = formatPriority(x.priority_level);
      const status = formatStatus(x.status);
      const count = x.report_count ?? 1;
      const dept = x.department_name ?? 'Chưa phân công';
      const officer = x.officer_name ?? '-';
      const createdAt = formatDate(x.created_at);
      const resolvedAt = formatDate(x.resolved_at);

      return [
        stt,
        code,
        type,
        desc,
        priority,
        status,
        count,
        dept,
        officer,
        createdAt,
        resolvedAt,
      ].map(esc).join(',');
    });

    return '\uFEFF' + [header, ...lines].join('\r\n');
  }

  async exportXlsx(): Promise<Buffer> {
    const workbook = new Workbook();
    workbook.creator = 'Hệ thống Đô thị 360';
    workbook.created = new Date();

    const sheet = workbook.addWorksheet('Báo cáo sự cố', {
      pageSetup: {
        paperSize: 9, // A4
        orientation: 'landscape',
        fitToPage: true,
        fitToWidth: 1,
        fitToHeight: 0,
        margins: { left: 0.4, right: 0.4, top: 0.5, bottom: 0.5, header: 0.2, footer: 0.2 },
      },
    });

    const rows = await AppDataSource.query(`
      SELECT 
        i.id,
        it.name AS type_name,
        i.description,
        i.status,
        i.priority_level,
        i.report_count,
        i.created_at,
        i.resolved_at,
        d.name AS department_name,
        u.full_name AS officer_name
      FROM incidents i
      JOIN incident_types it ON it.id = i.incident_type_id
      LEFT JOIN LATERAL (
        SELECT a.department_id, a.accepted_by
        FROM incident_assignments a
        WHERE a.incident_id = i.id
        ORDER BY a.assigned_at DESC
        LIMIT 1
      ) a ON TRUE
      LEFT JOIN departments d ON d.id = a.department_id
      LEFT JOIN users u ON u.id = a.accepted_by
      ORDER BY i.created_at DESC
    `);

    // Row 1: Header cơ quan & Quốc hiệu
    sheet.mergeCells('A1:D1');
    sheet.getCell('A1').value = 'ỦY BAN NHÂN DÂN THÀNH PHỐ - HỆ THỐNG ĐÔ THỊ 360';
    sheet.getCell('A1').font = { name: 'Arial', size: 10, bold: true, color: { argb: 'FF0B6B4F' } };

    sheet.mergeCells('H1:K1');
    sheet.getCell('H1').value = 'CỘNG HÒA XÃ HỘI CHỦ NGHĨA VIỆT NAM';
    sheet.getCell('H1').font = { name: 'Arial', size: 10, bold: true };
    sheet.getCell('H1').alignment = { horizontal: 'center' };

    sheet.mergeCells('H2:K2');
    sheet.getCell('H2').value = 'Độc lập - Tự do - Hạnh phúc';
    sheet.getCell('H2').font = { name: 'Arial', size: 9, italic: true };
    sheet.getCell('H2').alignment = { horizontal: 'center' };

    // Row 4: Tiêu đề báo cáo
    sheet.mergeCells('A4:K4');
    sheet.getCell('A4').value = 'BÁO CÁO TỔNG HỢP TIẾP NHẬN & XỬ LÝ SỰ CỐ ĐÔ THỊ';
    sheet.getCell('A4').font = { name: 'Arial', size: 15, bold: true, color: { argb: 'FF16382D' } };
    sheet.getCell('A4').alignment = { horizontal: 'center', vertical: 'middle' };
    sheet.getRow(4).height = 26;

    // Row 5: Thời gian
    sheet.mergeCells('A5:K5');
    const nowStr = new Date().toLocaleString('vi-VN');
    sheet.getCell('A5').value = `Thời điểm kết xuất: ${nowStr}  |  Tổng số sự cố: ${rows.length}`;
    sheet.getCell('A5').font = { name: 'Arial', size: 10, italic: true, color: { argb: 'FF555555' } };
    sheet.getCell('A5').alignment = { horizontal: 'center' };

    // Row 7: Header bảng
    const headers = [
      'STT',
      'Mã sự cố',
      'Loại sự cố',
      'Nội dung phản ánh',
      'Mức ưu tiên',
      'Trạng thái',
      'Lượt báo',
      'Đơn vị tiếp nhận',
      'Cán bộ phụ trách',
      'Thời gian gửi',
      'Thời gian hoàn tất',
    ];

    const headerRow = sheet.getRow(7);
    headerRow.values = headers;
    headerRow.height = 24;
    headerRow.font = { name: 'Arial', size: 10, bold: true, color: { argb: 'FFFFFFFF' } };
    headerRow.alignment = { vertical: 'middle', horizontal: 'center' };

    for (let c = 1; c <= headers.length; c++) {
      const cell = headerRow.getCell(c);
      cell.fill = {
        type: 'pattern',
        pattern: 'solid',
        fgColor: { argb: 'FF0B6B4F' },
      };
      cell.border = {
        top: { style: 'thin', color: { argb: 'FF000000' } },
        bottom: { style: 'medium', color: { argb: 'FF000000' } },
        left: { style: 'thin', color: { argb: 'FFB8CBC3' } },
        right: { style: 'thin', color: { argb: 'FFB8CBC3' } },
      };
    }

    // Set column widths
    sheet.columns = [
      { key: 'stt', width: 6 },
      { key: 'code', width: 14 },
      { key: 'type', width: 22 },
      { key: 'desc', width: 36 },
      { key: 'priority', width: 13 },
      { key: 'status', width: 18 },
      { key: 'count', width: 10 },
      { key: 'dept', width: 24 },
      { key: 'officer', width: 20 },
      { key: 'created', width: 18 },
      { key: 'resolved', width: 18 },
    ];

    const formatStatus = (s: string) => {
      switch (s) {
        case 'PENDING_ASSIGNMENT': return 'Chờ phân công';
        case 'ASSIGNED': return 'Đã phân công';
        case 'ACCEPTED': return 'Đã tiếp nhận';
        case 'IN_PROGRESS': return 'Đang xử lý';
        case 'PENDING_VERIFICATION': return 'Chờ nghiệm thu';
        case 'RESOLVED': return 'Đã hoàn thành';
        case 'REJECTED': return 'Từ chối';
        case 'CANCELLED': return 'Đã hủy';
        default: return s || '-';
      }
    };

    const formatPriority = (p: string) => {
      switch (p) {
        case 'EMERGENCY': return 'Khẩn cấp';
        case 'HIGH': return 'Cao';
        case 'MEDIUM': return 'Trung bình';
        case 'LOW': return 'Thấp';
        default: return p || 'Thường';
      }
    };

    const formatDate = (d: any) => {
      if (!d) return '-';
      const dt = new Date(d);
      if (isNaN(dt.getTime())) return '-';
      const pad = (n: number) => String(n).padStart(2, '0');
      return `${pad(dt.getDate())}/${pad(dt.getMonth() + 1)}/${dt.getFullYear()} ${pad(dt.getHours())}:${pad(dt.getMinutes())}`;
    };

    let rowIndex = 8;
    for (let i = 0; i < rows.length; i++) {
      const r = rows[i];
      const dataRow = sheet.getRow(rowIndex);
      dataRow.values = [
        i + 1,
        `#SC-${r.id.slice(0, 8).toUpperCase()}`,
        r.type_name ?? 'Sự cố đô thị',
        r.description ?? '',
        formatPriority(r.priority_level),
        formatStatus(r.status),
        r.report_count ?? 1,
        r.department_name ?? 'Chưa phân công',
        r.officer_name ?? '-',
        formatDate(r.created_at),
        formatDate(r.resolved_at),
      ];
      dataRow.font = { name: 'Arial', size: 9.5 };
      dataRow.height = 20;

      const bg = i % 2 === 0 ? 'FFFFFFFF' : 'FFF6F9F7';

      for (let c = 1; c <= headers.length; c++) {
        const cell = dataRow.getCell(c);
        cell.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: bg } };
        cell.border = {
          top: { style: 'thin', color: { argb: 'FFE0E6E3' } },
          bottom: { style: 'thin', color: { argb: 'FFE0E6E3' } },
          left: { style: 'thin', color: { argb: 'FFE0E6E3' } },
          right: { style: 'thin', color: { argb: 'FFE0E6E3' } },
        };

        if (c === 1 || c === 2 || c === 5 || c === 6 || c === 7 || c === 10 || c === 11) {
          cell.alignment = { horizontal: 'center', vertical: 'middle' };
        } else {
          cell.alignment = { horizontal: 'left', vertical: 'middle', wrapText: true };
        }

        if (c === 5) {
          if (r.priority_level === 'EMERGENCY' || r.priority_level === 'HIGH') {
            cell.font = { name: 'Arial', size: 9.5, bold: true, color: { argb: 'FFD13B3B' } };
          } else if (r.priority_level === 'MEDIUM') {
            cell.font = { name: 'Arial', size: 9.5, bold: true, color: { argb: 'FFC07706' } };
          }
        }

        if (c === 6 && r.status === 'RESOLVED') {
          cell.font = { name: 'Arial', size: 9.5, bold: true, color: { argb: 'FF108558' } };
        }
      }
      rowIndex++;
    }

    rowIndex += 2;
    const signDateRow = sheet.getRow(rowIndex);
    signDateRow.getCell(9).value = 'Thành phố, ngày ..... tháng ..... năm 2026';
    signDateRow.getCell(9).font = { name: 'Arial', size: 10, italic: true };
    signDateRow.getCell(9).alignment = { horizontal: 'center' };

    rowIndex++;
    const signRoleRow = sheet.getRow(rowIndex);
    signRoleRow.getCell(2).value = 'NGƯỜI LẬP BÁO CÁO';
    signRoleRow.getCell(2).font = { name: 'Arial', size: 10, bold: true };
    signRoleRow.getCell(2).alignment = { horizontal: 'center' };

    signRoleRow.getCell(9).value = 'THỦ TRƯỞNG ĐƠN VỊ';
    signRoleRow.getCell(9).font = { name: 'Arial', size: 10, bold: true };
    signRoleRow.getCell(9).alignment = { horizontal: 'center' };

    rowIndex++;
    const signHintRow = sheet.getRow(rowIndex);
    signHintRow.getCell(2).value = '(Ký, ghi rõ họ tên)';
    signHintRow.getCell(2).font = { name: 'Arial', size: 9, italic: true, color: { argb: 'FF666666' } };
    signHintRow.getCell(2).alignment = { horizontal: 'center' };

    signHintRow.getCell(9).value = '(Ký tên, đóng dấu)';
    signHintRow.getCell(9).font = { name: 'Arial', size: 9, italic: true, color: { argb: 'FF666666' } };
    signHintRow.getCell(9).alignment = { horizontal: 'center' };

    const buffer = await workbook.xlsx.writeBuffer();
    return Buffer.from(buffer);
  }
 async aiMetrics(){const[summary]=await AppDataSource.query(`SELECT COUNT(*)::int analyzed,COUNT(*)FILTER(WHERE requires_manual_review)::int manual_review,ROUND(AVG((ai_analysis->'telemetry'->>'latency_ms')::numeric))::int avg_latency_ms,ROUND(AVG((ai_analysis->>'confidence')::numeric)*100,1)::float avg_confidence,COALESCE(SUM((ai_analysis->'telemetry'->>'total_tokens')::int),0)::int total_tokens FROM incident_reports WHERE ai_analysis IS NOT NULL`);const[feedback]=await AppDataSource.query(`SELECT COUNT(*)::int total_feedback,COUNT(*)FILTER(WHERE it.name=af.ai_incident_type)::int type_agreements,COUNT(*)FILTER(WHERE af.ai_severity=af.confirmed_severity)::int severity_agreements,ROUND(AVG(ABS(af.ai_severity-af.confirmed_severity)),2)::float severity_mae FROM ai_feedbacks af LEFT JOIN incident_types it ON it.id=af.confirmed_incident_type_id WHERE af.ai_incident_type IS NOT NULL OR af.ai_severity IS NOT NULL`);const[duplicates]=await AppDataSource.query(`SELECT COUNT(*)FILTER(WHERE duplicate_score IS NOT NULL)::int merged_by_hybrid,ROUND(AVG(duplicate_score)*100,1)::float avg_duplicate_confidence FROM incident_reports`);const analyzed=Number(summary.analyzed)||0,total=Number(feedback.total_feedback)||0;return{...summary,...feedback,...duplicates,manual_review_rate:analyzed?Math.round(Number(summary.manual_review)/analyzed*1000)/10:0,type_accuracy:total?Math.round(Number(feedback.type_agreements)/total*1000)/10:0,severity_accuracy:total?Math.round(Number(feedback.severity_agreements)/total*1000)/10:0};}
 aiConfusion(){return AppDataSource.query(`SELECT COALESCE(ai_incident_type,'Không xác định') predicted,COALESCE(it.name,'Không xác định') actual,COUNT(*)::int count FROM ai_feedbacks af LEFT JOIN incident_types it ON it.id=af.confirmed_incident_type_id WHERE af.ai_incident_type IS NOT NULL GROUP BY 1,2 ORDER BY 1,2`);}
 async aiComparison(){const metrics=await this.aiMetrics();return{measured:{ai_average_seconds:Math.round((Number(metrics.avg_latency_ms)||0)/100)/10,auto_classification_rate:Math.max(0,100-Number(metrics.manual_review_rate)),type_accuracy:metrics.type_accuracy,hybrid_duplicates:metrics.merged_by_hybrid},baseline_estimate:{manual_triage_seconds:120,required_manual_fields:2},disclaimer:'Baseline không AI là giả định trình diễn; số liệu AI được đo từ log hệ thống.'};}
 async aiSamplesCsv(){const rows=await AppDataSource.query(`SELECT r.id report_id,r.created_at,r.ai_analysis->'telemetry'->>'model' model,r.ai_analysis->'telemetry'->>'prompt_version' prompt_version,r.ai_analysis->>'suggested_incident_type' predicted_type,it.name confirmed_type,r.ai_analysis->>'suggested_severity' predicted_severity,af.confirmed_severity,r.ai_analysis->>'confidence' confidence,r.requires_manual_review FROM incident_reports r LEFT JOIN LATERAL(SELECT * FROM ai_feedbacks f WHERE f.report_id=r.id ORDER BY f.created_at DESC LIMIT 1)af ON TRUE LEFT JOIN incident_types it ON it.id=af.confirmed_incident_type_id WHERE r.ai_analysis IS NOT NULL ORDER BY r.created_at DESC`);const esc=(v:unknown)=>`"${String(v??'').replaceAll('"','""')}"`;return['report_id,created_at,model,prompt_version,predicted_type,confirmed_type,predicted_severity,confirmed_severity,confidence,manual_review',...rows.map((x:any)=>[x.report_id,x.created_at,x.model,x.prompt_version,x.predicted_type,x.confirmed_type,x.predicted_severity,x.confirmed_severity,x.confidence,x.requires_manual_review].map(esc).join(','))].join('\n');}
}
