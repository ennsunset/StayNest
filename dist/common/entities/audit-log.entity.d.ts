export declare class AuditLog {
    id: string;
    actorId: string | null;
    actorRole: string | null;
    action: string;
    targetType: string | null;
    targetId: string | null;
    beforeState: Record<string, any> | null;
    afterState: Record<string, any> | null;
    reason: string | null;
    ip: string | null;
    requestId: string | null;
    createdAt: Date;
}
