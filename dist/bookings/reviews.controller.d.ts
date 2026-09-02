import { ReviewsService } from './reviews.service';
export declare class ReviewsController {
    private readonly reviews;
    constructor(reviews: ReviewsService);
    create(req: any, bookingId: string, body: {
        rating: number;
        body?: string;
    }): Promise<any>;
    getForHostel(hostelId: string, limit?: string, offset?: string): Promise<{
        reviews: any;
        stats: {
            count: any;
            average: number;
        };
    }>;
    getForBooking(bookingId: string): Promise<{
        review: any;
        hasReviewed: boolean;
    }>;
    canReview(hostelId: string, req: any): Promise<{
        canReview: boolean;
        bookingId?: string;
    }>;
    delete(id: string, req: any): Promise<{
        deleted: boolean;
    }>;
}
