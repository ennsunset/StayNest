import { ConfigService } from '@nestjs/config';
export declare class R2StorageService {
    private readonly config;
    private readonly s3;
    private readonly bucket;
    private readonly publicUrl;
    constructor(config: ConfigService);
    private buildUrl;
    private putObject;
    upload(file: Express.Multer.File, folder: string): Promise<{
        key: string;
        url: string;
    }>;
    delete(key: string): Promise<void>;
}
