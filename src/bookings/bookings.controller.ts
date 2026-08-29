// src/bookings/bookings.controller.ts

import { NotFoundException,
  Controller, Post, Get, Patch, Body, Param, Req,
  UseGuards, ParseUUIDPipe,
} from '@nestjs/common';
import { BookingsService } from './bookings.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { RolesGuard, Roles } from '../auth/roles.guard';
import { UserRole } from '../users/entities/user.entity';
import { CreateBookingDto, CancelBookingDto } from './bookings.dto';

@Controller('bookings')
@UseGuards(JwtAuthGuard)
export class BookingsController {
  constructor(private readonly bookings: BookingsService) {}

  /** Hold a bed — the student taps "Book" */
  @Post()
  @UseGuards(RolesGuard)
  @Roles(UserRole.STUDENT)
  hold(@Req() req: any, @Body() dto: CreateBookingDto) {
    return this.bookings.holdBed(req.user.sub, dto.bedId, dto.checkInDate, dto.duration, dto.paymentType);
  }

  /** Get all bookings for the logged-in student */
  @Get('mine')
  @UseGuards(RolesGuard)
  @Roles(UserRole.STUDENT)
  myBookings(@Req() req: any) {
    return this.bookings.findByStudent(req.user.sub);
  }

  /** Get a booking by ID */
  @Get(':id')
  findOne(@Param('id', ParseUUIDPipe) id: string) {
    return this.bookings.findById(id);
  }

  /** Get a booking by reference (e.g. STN-20260815-X8R2) */
  @Get('ref/:reference')
  findByRef(@Param('reference') reference: string) {
    return this.bookings.findByReference(reference);
  }

  /** Get agreement data for a booking */
  @Get(':id/agreement')
  getAgreement(@Param('id') id: string) {
    return this.bookings.getAgreement(id);
  }

  /** Get roommates for a booking */
  @Get(':id/roommates')
  getRoommates(@Param('id') id: string) {
    return this.bookings.getRoommates(id);
  }

  /** Create maintenance request */
  @Post(':id/maintenance')
  @UseGuards(RolesGuard)
  @Roles(UserRole.STUDENT)
  createMaintenance(
    @Param('id') id: string,
    @Req() req: any,
    @Body() body: { title: string; description?: string; category?: string; priority?: string },
  ) {
    return this.bookings.createMaintenance(id, req.user.sub, body);
  }

  /** Get maintenance requests for a booking */
  @Get(':id/maintenance')
  getMaintenance(@Param('id') id: string) {
    return this.bookings.getMaintenance(id);
  }

  /** Check in a tenant (owner action) */
  @Patch(':id/check-in')
  @UseGuards(RolesGuard)
  @Roles(UserRole.OWNER)
  checkIn(@Param('id') id: string) {
    return this.bookings.checkIn(id);
  }

  /** Sign the digital agreement */
  @Patch(':id/agreement/sign')
  signAgreement(@Param('id') id: string) {
    return this.bookings.signAgreement(id);
  }

  /** Cancel a booking */
  @Patch(':id/cancel')
  @UseGuards(RolesGuard)
  @Roles(UserRole.STUDENT)
  cancel(
    @Param('id', ParseUUIDPipe) id: string,
    @Req() req: any,
    @Body() dto: CancelBookingDto,
  ) {
    return this.bookings.cancel(id, req.user.sub, dto.reason);
  }

  /**
   * Confirm a booking (temporary — will be called by payment webhook in Stage 3).
   * For now, allows manual confirmation for testing.
   */
  @Patch(':id/confirm')
  confirm(@Param('id', ParseUUIDPipe) id: string) {
    return this.bookings.confirm(id);
  }

  /** Check installment eligibility for a hostel */
  @Get('installment-eligibility/:hostelId')
  async checkInstallmentEligibility(@Req() req: any, @Param('hostelId') hostelId: string) {
    return this.bookings.checkInstallmentEligibility(req.user.sub, hostelId);
  }

  /** Get installment plan for a booking */
  @Get(':id/installments')
  async getInstallmentPlan(@Param('id') id: string) {
    const result = await this.bookings.getInstallmentPlan(id);
    if (!result) return { plan: null, installments: [] };
    return result;
  }

  /** Pay an installment */
  @Patch(':id/installments/:installmentId/pay')
  async payInstallment(
    @Param('installmentId') installmentId: string,
    @Body() body: { paymentReference: string },
  ) {
    return this.bookings.payInstallment(installmentId, body.paymentReference);
  }

}
