export declare enum UserRole {
    STUDENT = "STUDENT",
    OWNER = "OWNER",
    PLATFORM_SUPPORT = "PLATFORM_SUPPORT",
    PLATFORM_FINANCE = "PLATFORM_FINANCE",
    PLATFORM_ADMIN = "PLATFORM_ADMIN",
    SUPER_ADMIN = "SUPER_ADMIN"
}
export declare class User {
    id: string;
    fullName: string;
    email: string;
    phone: string | null;
    passwordHash: string;
    role: UserRole;
    university: string | null;
    level: string | null;
    avatarUrl: string | null;
    emailVerified: boolean;
    phoneVerified: boolean;
    idVerified: boolean;
    interests: string[];
    profileCompleted: boolean;
    isActive: boolean;
    createdAt: Date;
    updatedAt: Date;
}
