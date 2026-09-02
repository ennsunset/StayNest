import { ConfigService } from '@nestjs/config';
import { HostelsService } from '../hostels/hostels.service';
interface ChatRequest {
    message: string;
    history: {
        role: string;
        content: string;
    }[];
}
export interface ChatResponse {
    message: string;
    hostels?: any[];
}
export declare class AiService {
    private config;
    private hostelsService;
    private readonly logger;
    constructor(config: ConfigService, hostelsService: HostelsService);
    private callClaude;
    chat(req: ChatRequest): Promise<ChatResponse>;
    private fallbackParse;
}
export {};
