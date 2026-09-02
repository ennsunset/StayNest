import { Repository } from 'typeorm';
import { User, UserRole } from './entities/user.entity';
export declare class UsersService {
    private readonly repo;
    constructor(repo: Repository<User>);
    findByEmail(email: string): Promise<User | null>;
    findById(id: string): Promise<User | null>;
    create(data: {
        fullName: string;
        email: string;
        password: string;
        role?: UserRole;
        phone?: string;
        university?: string;
        level?: string;
    }): Promise<User>;
    validatePassword(user: User, password: string): Promise<boolean>;
    updatePhone(userId: string, phone: string): Promise<void>;
    markPhoneVerified(userId: string): Promise<void>;
    markEmailVerified(userId: string): Promise<void>;
    completeProfile(userId: string, dto: {
        university?: string;
        level?: string;
        interests?: string[];
    }): Promise<User>;
    updatePassword(userId: string, newPassword: string): Promise<void>;
    updateProfile(userId: string, data: {
        fullName?: string;
        phone?: string;
        level?: string;
        university?: string;
        avatarUrl?: string;
    }): Promise<any>;
    createSocialUser(data: {
        fullName: string;
        email: string;
        provider: string;
    }): Promise<User>;
}
