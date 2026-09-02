// src/payments/payments.module.ts

import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Payment } from './entities/payment.entity';
import { Booking } from '../bookings/entities/booking.entity';
import { PaymentsService } from './payments.service';
import { PaymentsController } from './payments.controller';
import { PaystackProvider } from './paystack.provider';
import { BookingsModule } from '../bookings/bookings.module';

@Module({
  imports: [
    TypeOrmModule.forFeature([Payment, Booking]),
    BookingsModule,
  ],
  controllers: [PaymentsController],
  providers: [PaymentsService, PaystackProvider],
  exports: [PaymentsService],
})
export class PaymentsModule {}
