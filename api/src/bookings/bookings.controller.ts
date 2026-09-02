// src/bookings/bookings.controller.ts

import { NotFoundException,
  Controller, Post, Get, Patch, Body, Param, Req,
  UseGuards, ParseUUIDPipe, Delete,
} from '@nestjs/common';
import { BookingsService } from './bookings.service';
import { VisitorsService } from './visitors.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { RolesGuard, Roles } from '../auth/roles.guard';
import { UserRole } from '../users/entities/user.entity';
import { CreateBookingDto, CancelBookingDto } from './bookings.dto';

@Controller('bookings')
@UseGuards(JwtAuthGuard)
export class BookingsController {
  constructor(private readonly bookings: BookingsService, private readonly visitors: VisitorsService) {}

  /** Get refund status for a booking */
  @Get(':id/refund')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.STUDENT)
  getRefund(@Param('id', ParseUUIDPipe) id: string, @Req() req: any) {
    return this.bookings.getRefund(id, req.user.sub);
  }



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


  /** Verify a visitor pass (security/owner scan) */
  @Get('visitors/verify/:token')
  async verifyVisitorPass(@Param('token') token: string) {
    return this.visitors.verifyPass(token);
  }

  /** Delete a visitor pass (only non-active) */
  @Patch('visitors/:passId/delete')
  async deleteVisitorPass(@Req() req: any, @Param('passId') passId: string) {
    return this.visitors.deletePass(passId, req.user.sub);
  }

  /** Revoke a visitor pass */
  @Patch('visitors/:passId/revoke')
  async revokeVisitorPass(@Req() req: any, @Param('passId') passId: string) {
    return this.visitors.revokePass(passId, req.user.sub);
  }

  /** Create a visitor pass */
  @Post(':id/visitors')
  async createVisitorPass(@Req() req: any, @Param('id') bookingId: string, @Body() body: { visitorName: string; visitorPhone?: string; purpose?: string }) {
    return this.visitors.createPass(req.user.sub, bookingId, body);
  }

  /** List visitor passes for a booking */
  @Get(':id/visitors')
  async getVisitorPasses(@Req() req: any, @Param('id') bookingId: string) {
    return this.visitors.getPassesForBooking(bookingId, req.user.sub);
  }


  // ── Move-in Tasks ──

  @Get(':id/move-in-tasks')
  @UseGuards(JwtAuthGuard)
  async getMoveInTasks(@Param('id') bookingId: string, @Req() req: any) {
    return this.bookings.getMoveInTasks(bookingId, req.user.sub);
  }

  @Patch('move-in-tasks/:taskId')
  @UseGuards(JwtAuthGuard)
  async updateMoveInTask(
    @Param('taskId') taskId: string,
    @Body('status') status: string,
    @Req() req: any,
  ) {
    return this.bookings.updateMoveInTask(taskId, req.user.sub, status);
  }

  // ── Utility Bills ──

  @Get(':id/utilities')
  @UseGuards(JwtAuthGuard)
  async getUtilities(@Param('id') bookingId: string, @Req() req: any) {
    return this.bookings.getUtilityData(bookingId, req.user.sub);
  }

  @Post(':id/move-in-tasks')
  @UseGuards(JwtAuthGuard)
  async addCustomTask(
    @Param('id') bookingId: string,
    @Body('title') title: string,
    @Body('description') description: string,
    @Req() req: any,
  ) {
    return this.bookings.addCustomTask(bookingId, req.user.sub, title, description);
  }

  @Delete('move-in-tasks/:taskId')
  @UseGuards(JwtAuthGuard)
  async deleteCustomTask(@Param('taskId') taskId: string, @Req() req: any) {
    return this.bookings.deleteCustomTask(taskId, req.user.sub);
  }

  @Patch(':id/check-in-date')
  @UseGuards(JwtAuthGuard)
  async updateCheckInDate(
    @Param('id') bookingId: string,
    @Body('checkInDate') checkInDate: string,
    @Req() req: any,
  ) {
    return this.bookings.updateCheckInDate(bookingId, req.user.sub, checkInDate);
  }

  @Patch(':id/move-in-tasks/:taskId/owner')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.OWNER)
  async ownerUpdateTask(
    @Param('taskId') taskId: string,
    @Body('status') status: string,
    @Req() req: any,
  ) {
    return this.bookings.ownerUpdateTask(taskId, req.user.sub, status);
  }
}
