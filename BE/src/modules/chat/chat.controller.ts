import { Request, Response, NextFunction } from 'express';
import { ChatService } from './chat.service';
import { chatSuggestions } from './chat.catalog';

const chatService = new ChatService();
export const getChatSuggestions = (_req: Request, res: Response) => {
  res.json({ success: true, data: chatSuggestions() });
};

export const chatWithBot = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    const { message, history, suggestion_id } = req.body;
    const userId = (req as any).user.id;

    if (!message) {
      res.status(400).json({ success: false, message: 'Thiếu nội dung tin nhắn' });
      return;
    }

    const result = await chatService.reply(userId, message, history, suggestion_id);

    res.status(200).json({
      success: true,
      data: result,
    });
  } catch (error) {
    if ((error as any).code === 'AI_PROVIDER_UNAVAILABLE') {
      res.status(503).json({ success: false, code: 'AI_PROVIDER_UNAVAILABLE', message: (error as any).message });
      return;
    }
    next(error);
  }
};
