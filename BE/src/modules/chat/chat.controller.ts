import { Request, Response, NextFunction } from 'express';
import { AiService } from '../../common/services/ai.service';

const aiService = new AiService();

export const chatWithBot = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    const { message } = req.body;
    const userId = (req as any).user.id;

    if (!message) {
      res.status(400).json({ success: false, message: 'Thiếu nội dung tin nhắn' });
      return;
    }

    const reply = await aiService.chatWithFunctionCalling(userId, message);

    res.status(200).json({
      success: true,
      data: {
        reply
      }
    });
  } catch (error) {
    next(error);
  }
};
