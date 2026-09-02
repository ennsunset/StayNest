import { ConfigService } from '@nestjs/config';
export declare class SmsService {
    private config;
    private readonly clientId;
    private readonly clientSecret;
    private readonly senderId;
    constructor(config: ConfigService);
    send(to: string, message: string): Promise<boolean>;
}
