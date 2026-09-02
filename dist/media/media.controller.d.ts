import { R2StorageService } from './r2-storage.service';
export declare class MediaController {
    private readonly storage;
    constructor(storage: R2StorageService);
    uploadOne(file: Express.Multer.File, folder?: string): Promise<{
        key: string;
        url: string;
    }>;
    uploadBatch(files: Express.Multer.File[], folder?: string): Promise<{
        uploaded: {
            key: string;
            url: string;
        }[];
    }>;
    remove(key: string): Promise<{
        deleted: string;
    }>;
}
