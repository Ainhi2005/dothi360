import { EntityManager } from 'typeorm';
import { AppDataSource } from '../../database/data-source';
import { AlgorithmConfigService } from '../../modules/algorithm-configs/algorithm-config.service';
export class PriorityScoringService {
  /**
   * Tính toán điểm ưu tiên (0 - 100) và trả về điểm số + cấp độ
   * Công thức: (Độ nguy hiểm * 15) + (Số lượt báo cáo * 2) + (Thời gian chờ * 1)
   */
  calculatePriority(severity: number, reportCount: number, createdAt: Date): { score: number, level: string } {
    // 1. Điểm mức độ nguy hiểm (severity từ 1-5): Max 75 điểm
    const severityScore = Math.min(severity * 15, 75);

    // 2. Điểm số lượng báo cáo: 2 điểm cho mỗi lượt report (Max 15 điểm)
    const reportScore = Math.min(reportCount * 2, 15);

    // 3. Điểm thời gian chờ đợi: 1 điểm cho mỗi giờ chờ (Max 10 điểm)
    const hoursWaiting = Math.abs(new Date().getTime() - createdAt.getTime()) / 36e5;
    const timeScore = Math.min(hoursWaiting * 1, 10);

    // 4. Tổng điểm
    const totalScore = Math.min(Math.round(severityScore + reportScore + timeScore), 100);

    // 5. Quy ra Level (LOW, MEDIUM, HIGH, EMERGENCY)
    let level = 'LOW';
    if (totalScore >= 85) {
      level = 'EMERGENCY';
    } else if (totalScore >= 60) {
      level = 'HIGH';
    } else if (totalScore >= 30) {
      level = 'MEDIUM';
    }

    return {
      score: totalScore,
      level
    };
  }

  async calculateConfigured(typePriority:number,severity:number,reportCount:number,createdAt:Date,manager:EntityManager=AppDataSource.manager){
    const c=await new AlgorithmConfigService().getActive('PRIORITY_SCORING',manager);
    const type=Math.min(Math.max(typePriority,1),5)/5*100,severityScore=Math.min(Math.max(severity,1),5)/5*100;
    const duplicates=Math.min(Math.max(reportCount-1,0),10)/10*100;
    const hours=Math.max(0,(Date.now()-createdAt.getTime())/36e5),waiting=Math.min(hours/c.waiting_cap_hours,1)*100;
    const score=Math.round(Math.min(100,type*c.type_weight+severityScore*c.severity_weight+duplicates*c.duplicate_weight+waiting*c.waiting_weight));
    const level=score>=c.emergency_min?'EMERGENCY':score>=c.high_min?'HIGH':score>=c.medium_min?'MEDIUM':'LOW';return{score,level};
  }
}
