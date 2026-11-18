import { Request, Response, NextFunction } from 'express';
import { cloudinary } from '../../config/cloudinary.config';
import { detectMediaMime } from './media.validation';
import { env } from '../../config/env';
import { AppDataSource } from '../../database/data-source';

export const uploadFile = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    if (!req.file) {
      res.status(400).json({ success: false, message: 'Vui lòng chọn file' });
      return;
    }

    const detected=detectMediaMime(req.file.buffer);if(!detected||detected!==req.file.mimetype){res.status(400).json({success:false,message:'Nội dung file không khớp định dạng khai báo'});return;}
    const uploaded:any=await new Promise((resolve,reject)=>{const stream=cloudinary.uploader.upload_stream({folder:env.CLOUDINARY_FOLDER,resource_type:detected==='video/mp4'?'video':'image'},(error,result)=>error?reject(error):resolve(result));stream.end(req.file!.buffer);});
    
    res.status(200).json({
      success: true,
      message: 'Upload thành công',
      data: {
        url: uploaded.secure_url,
        type: detected,
        size: req.file.size,
        storage_key: uploaded.public_id,
      }
    });
  } catch (error) {
    next(error);
  }
};

export const removeOrphanUpload = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    const storageKey = String(req.body.storage_key ?? '');
    const mimeType = String(req.body.type ?? '');
    if (!storageKey.startsWith(`${env.CLOUDINARY_FOLDER}/`)) {
      res.status(400).json({ success: false, message: 'Khóa lưu trữ không hợp lệ' });
      return;
    }
    const [{ count }] = await AppDataSource.query('SELECT COUNT(*)::int count FROM incident_media WHERE storage_key=$1', [storageKey]);
    if (Number(count) > 0) {
      res.status(409).json({ success: false, message: 'Media đã được liên kết với phản ánh' });
      return;
    }
    await cloudinary.uploader.destroy(storageKey, { resource_type: mimeType.startsWith('video/') ? 'video' : 'image', invalidate: true });
    res.json({ success: true, message: 'Đã dọn media chưa sử dụng' });
  } catch (error) { next(error); }
};
