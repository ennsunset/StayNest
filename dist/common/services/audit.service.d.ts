import { Repository } from 'typeorm';
import { AuditLog } from '../entities/audit-log.entity';
export interface AuditEntry {
    actorId?: string;
    actorRole?: string;
    action: string;
    targetType?: string;
    targetId?: string;
    beforeState?: Record<string, any>;
    afterState?: Record<string, any>;
    reason?: string;
    ip?: string;
    requestId?: string;
}
export declare class AuditService {
    private readonly repo;
    constructor(repo: Repository<AuditLog>);
    log(entry: AuditEntry): Promise<void>;
}
