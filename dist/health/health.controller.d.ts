import { DataSource } from 'typeorm';
export declare class HealthController {
    private readonly dataSource;
    constructor(dataSource: DataSource);
    check(): Promise<{
        status: string;
        timestamp: string;
        version: string;
        checks: {
            database: string;
        };
    }>;
    private isDatabaseHealthy;
}
