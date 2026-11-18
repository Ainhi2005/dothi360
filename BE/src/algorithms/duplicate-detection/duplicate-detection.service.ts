import { EntityManager } from 'typeorm';
import { AppDataSource } from '../../database/data-source';
import { Incident } from '../../modules/incidents/incident.entity';

export type DuplicateEvidence = { score:number;distance_score:number;time_score:number;text_score:number;visual_signal_score:number;distance_m:number;time_minutes:number };
const words=(value:string)=>new Set(value.toLocaleLowerCase('vi').normalize('NFD').replace(/[\u0300-\u036f]/g,'').replace(/[^a-z0-9\s]/g,' ').split(/\s+/).filter(x=>x.length>2));
const jaccard=(a:Set<string>,b:Set<string>)=>{const union=new Set([...a,...b]);if(!union.size)return 0;let common=0;for(const item of a)if(b.has(item))common++;return common/union.size;};

export class DuplicateDetectionService {
  async findDuplicate(incidentTypeId:string,longitude:number,latitude:number,manager:EntityManager=AppDataSource.manager,description='',aiAnalysis?:Record<string,unknown>|null):Promise<Incident|null>{
    const rows=await manager.query(`SELECT i.id,i.description,i.created_at,ST_Distance(i.location,ST_SetSRID(ST_Point($1,$2),4326)::geography)::float distance_m,EXTRACT(EPOCH FROM(NOW()-i.created_at))/60 time_minutes,(SELECT r.ai_analysis FROM incident_reports r WHERE r.incident_id=i.id ORDER BY r.created_at DESC LIMIT 1) ai_analysis FROM incidents i WHERE i.incident_type_id=$3 AND i.status NOT IN('RESOLVED','REJECTED','CANCELLED') AND i.created_at>=NOW()-INTERVAL '48 hours' AND ST_DWithin(i.location,ST_SetSRID(ST_Point($1,$2),4326)::geography,250)`,[longitude,latitude,incidentTypeId]);
    const currentSignals=new Set<string>((Array.isArray(aiAnalysis?.detected_signals)?aiAnalysis!.detected_signals:[]).map(String).map(x=>x.toLocaleLowerCase('vi')));
    let best:{id:string;evidence:DuplicateEvidence}|null=null;
    for(const row of rows){
      const distance=Math.max(0,1-Number(row.distance_m)/250),time=Math.max(0,1-Number(row.time_minutes)/(48*60));
      const text=jaccard(words(description),words(row.description??''));
      const oldSignals=new Set<string>((Array.isArray(row.ai_analysis?.detected_signals)?row.ai_analysis.detected_signals:[]).map(String).map((x:string)=>x.toLocaleLowerCase('vi')));
      const visual=jaccard(currentSignals,oldSignals),score=distance*.35+time*.20+text*.25+visual*.20;
      const evidence={score:Number(score.toFixed(4)),distance_score:distance,time_score:time,text_score:text,visual_signal_score:visual,distance_m:Number(row.distance_m),time_minutes:Number(row.time_minutes)};
      if(score>=.68&&(!best||score>best.evidence.score))best={id:row.id,evidence};
    }
    if(!best)return null;
    const incident=await manager.getRepository(Incident).findOneBy({id:best.id});
    if(incident)(incident as Incident&{duplicateEvidence:DuplicateEvidence}).duplicateEvidence=best.evidence;
    return incident;
  }
}
