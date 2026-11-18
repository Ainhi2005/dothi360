import {NextFunction,Request,Response} from'express';import{AreaService}from'./area.service';const s=new AreaService();
export const list=async(_q:Request,r:Response,n:NextFunction)=>{try{r.json({success:true,data:await s.list()})}catch(e){n(e)}};
export const create=async(q:Request,r:Response,n:NextFunction)=>{try{r.status(201).json({success:true,data:await s.save(q.body,q.user.id)})}catch(e){n(e)}};
export const update=async(q:Request,r:Response,n:NextFunction)=>{try{r.json({success:true,data:await s.save(q.body,q.user.id,String(q.params.id))})}catch(e){n(e)}};
export const remove=async(q:Request,r:Response,n:NextFunction)=>{try{await s.remove(String(q.params.id),q.user.id);r.json({success:true,message:'Đã ngừng sử dụng địa bàn'})}catch(e){n(e)}};
