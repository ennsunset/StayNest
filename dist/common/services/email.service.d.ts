import { ConfigService } from '@nestjs/config';
export declare class EmailService {
    private config;
    private readonly apiKey;
    private readonly fromEmail;
    constructor(config: ConfigService);
    send(to: string, subject: string, html: string): Promise<boolean>;
}
