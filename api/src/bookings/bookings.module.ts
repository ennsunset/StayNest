// src/bookings/bookings.module.ts

import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { ScheduleModule } from '@nestjs/schedule';
import { Booking } from './entities/booking.entity';
import { Refund } from './entities/refund.entity';
import { MoveInTask } from './entities/move_in_task.entity';
import { UtilityAccount, UtilityBill } from './entities/utility_account.entity';
import { InstallmentPlan, Installment } from './entities/installment.entity';
import { Bed } from '../hostels/entities/hostel.entity';
import { BookingsService } from './bookings.service';
import { VisitorsService } from './visitors.service';
import { CommunityService } from './community.service';
import { CommunityController } from './community.controller';
import { AnnouncementsService } from './announcements.service';
import { AnnouncementsController } from './announcements.controller';
import { ReviewsService } from './reviews.service';
import { ReviewsController } from './reviews.controller';
import { BookingsController } from './bookings.controller';
import { NotificationsModule } from '../notifications/notifications.module';

@Module({
  imports: [
    ScheduleModule.forRoot(),
    TypeOrmModule.forFeature([Booking, Bed, InstallmentPlan, Installment, MoveInTask, UtilityAccount, UtilityBill]),
    NotificationsModule,
  ],
  controllers: [BookingsController, CommunityController, AnnouncementsController, ReviewsController],
  providers: [BookingsService, VisitorsService, CommunityService, AnnouncementsService, ReviewsService],
  exports: [BookingsService],
})
export class BookingsModule {}
