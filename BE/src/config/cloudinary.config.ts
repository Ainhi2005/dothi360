import { v2 as cloudinary } from 'cloudinary';
import { CloudinaryStorage } from 'multer-storage-cloudinary';
import { env } from './env';

cloudinary.config({
  cloud_name: env.CLOUDINARY_CLOUD_NAME,
  api_key: env.CLOUDINARY_API_KEY,
  api_secret: env.CLOUDINARY_API_SECRET,
});

export const storage = new CloudinaryStorage({
  cloudinary: cloudinary,
  params: async (req, file) => {
    return {
      folder: env.CLOUDINARY_FOLDER,
      allowed_formats: ['jpg', 'png', 'jpeg', 'webp', 'mp4'],
      public_id: `media_${Date.now()}_${Math.floor(Math.random() * 1000)}`
    };
  },
});

export { cloudinary };
