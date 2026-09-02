import { DataSource } from 'typeorm';
export declare class CommunityService {
    private readonly dataSource;
    constructor(dataSource: DataSource);
    createPost(studentId: string, hostelId: string, dto: {
        category: string;
        title: string;
        body: string;
        imageUrl?: string;
        pricePesewas?: number;
    }): Promise<any>;
    getPosts(hostelId: string, category?: string, limit?: number, offset?: number): Promise<any>;
    deletePost(postId: string, studentId: string): Promise<{
        success: boolean;
    }>;
    markSold(postId: string, studentId: string): Promise<{
        success: boolean;
    }>;
}
