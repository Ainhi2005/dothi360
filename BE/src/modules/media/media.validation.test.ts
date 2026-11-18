import assert from 'node:assert/strict';
import test from 'node:test';
import { detectMediaMime, mediaFileFilter } from './media.validation';

function filter(mimetype: string): Promise<boolean> {
  return new Promise((resolve, reject) => {
    mediaFileFilter({} as never, { mimetype } as Express.Multer.File, ((error: Error | null, accepted?: boolean) => {
      if (error) reject(error);
      else resolve(Boolean(accepted));
    }) as never);
  });
}

test('chấp nhận định dạng media được hỗ trợ', async () => {
  await assert.doesNotReject(filter('image/jpeg'));
  await assert.doesNotReject(filter('video/mp4'));
});

test('từ chối file không thuộc whitelist', async () => {
  await assert.rejects(filter('application/pdf'), /Chỉ chấp nhận/);
});
test('xác định định dạng bằng chữ ký file thay vì chỉ tin MIME',()=>{assert.equal(detectMediaMime(Buffer.from([0xff,0xd8,0xff,0,0,0,0,0,0,0,0,0])),'image/jpeg');assert.equal(detectMediaMime(Buffer.from('not-an-image')) ,null);});
