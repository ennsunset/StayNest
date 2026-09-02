import { CommunityService } from './community.service';
export declare class CommunityController {
    private readonly community;
    constructor(community: CommunityService);
    createPost(req: any, hostelId: string, body: {
        category: string;
        title: string;
        body: string;
        imageUrl?: string;
        pricePesewas?: number;
    }): Promise<any>;
    getPosts(hostelId: string, category?: string, limit?: string, offset?: string): Promise<any>;
    markSold(req: any, postId: string): Promise<{
        success: boolean;
    }>;
    deletePost(req: any, postId: string): Promise<{
        success: boolean;
    }>;
}
