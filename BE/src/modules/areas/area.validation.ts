import { z } from 'zod';
const position=z.tuple([z.number().min(-180).max(180),z.number().min(-90).max(90)]);
const polygon=z.object({type:z.literal('Polygon'),coordinates:z.array(z.array(position).min(4)).min(1)}).superRefine((v,c)=>{for(const ring of v.coordinates){const a=ring[0],b=ring[ring.length-1];if(a[0]!==b[0]||a[1]!==b[1]) c.addIssue({code:'custom',message:'Vòng polygon phải khép kín'});}});
export const areaSchema=z.object({department_id:z.uuid(),name:z.string().trim().min(2).max(200),geometry:polygon,is_active:z.boolean().optional()});
