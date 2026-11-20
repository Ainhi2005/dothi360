/** Metadata media đã upload; file thực tế được lưu ở dịch vụ media. */
export type UploadedMedia = {
  url: string;
  type: string;
  size: number;
  storage_key: string;
};

export const normalizeMedia = (item: string | UploadedMedia): UploadedMedia =>
  typeof item === "string"
    ? {
        url: item,
        type: "image/jpeg",
        size: 1,
        storage_key: item.split("/").pop() || `legacy_${Date.now()}`,
      }
    : item;
