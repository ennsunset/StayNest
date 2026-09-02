import { DataSource } from 'typeorm';
export declare class ReviewsService {
    private readonly dataSource;
    constructor(dataSource: DataSource);
    create(studentId: string, bookingId: string, dto: {
        rating: number;
        body?: string;
    }): Promise<any>;
    getForHostel(hostelId: string, limit?: number, offset?: number): Promise<{
        reviews: any;
        stats: {
            count: any;
            average: number;
        };
    }>;
    getForBooking(bookingId: string): Promise<any>;
    canReview(hostelId: string, studentId: string): Promise<{
        canReview: boolean;
        bookingId?: string;
    }>;
    delete(reviewId: string, studentId: string): Promise<void>;
}
