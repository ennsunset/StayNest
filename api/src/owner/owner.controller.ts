// src/owner/owner.controller.ts

import { Controller, Get, Post, Patch, Delete, Param, Body, Query, Req, UseGuards, ParseUUIDPipe, ParseIntPipe } from '@nestjs/common';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { RolesGuard } from '../auth/roles.guard';
import { Roles } from '../auth/roles.guard';
import { UserRole } from '../users/entities/user.entity';
import { OwnerService } from './owner.service';

@Controller('owner')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles(UserRole.OWNER)
export class OwnerController {
  constructor(private readonly ownerService: OwnerService) {}

  @Get('hostels')
  getHostels(@Req() req: any) {
    return this.ownerService.getHostels(req.user.sub);
  }

  @Get('dashboard')
  getDashboard(@Req() req: any) {
    return this.ownerService.getDashboard(req.user.sub);
  }

  @Get('bookings')
  getBookings(
    @Req() req: any,
    @Query('status') status?: string,
    @Query('page') page?: string,
    @Query('limit') limit?: string,
  ) {
    return this.ownerService.getBookings(req.user.sub, {
      status,
      page: parseInt(page || '1', 10),
      limit: parseInt(limit || '20', 10),
    });
  }

  @Patch('bookings/:id/accept')
  acceptBooking(@Req() req: any, @Param('id') bookingId: string) {
    return this.ownerService.acceptBooking(req.user.sub, bookingId);
  }

  @Patch('bookings/:id/decline')
  declineBooking(
    @Req() req: any,
    @Param('id') bookingId: string,
    @Body('reason') reason: string,
  ) {
    return this.ownerService.declineBooking(req.user.sub, bookingId, reason);
  }

  @Get('tenants')
  getTenants(@Req() req: any) {
    return this.ownerService.getTenants(req.user.sub);
  }

  @Get('payments')
  getPayments(
    @Req() req: any,
    @Query('page') page?: string,
    @Query('limit') limit?: string,
  ) {
    return this.ownerService.getPayments(req.user.sub, {
      page: parseInt(page || '1', 10),
      limit: parseInt(limit || '20', 10),
    });
  }

  @Get('hostels/:hostelId/rooms')
  getRooms(@Req() req: any, @Param('hostelId', ParseUUIDPipe) hostelId: string) {
    return this.ownerService.getRoomsForHostel(req.user.sub, hostelId);
  }

  @Get('hostels/:hostelId/floors')
  getFloors(@Req() req: any, @Param('hostelId', ParseUUIDPipe) hostelId: string) {
    return this.ownerService.getFloorsForHostel(req.user.sub, hostelId);
  }

  @Post('hostels/:hostelId/rooms')
  createRoom(
    @Req() req: any,
    @Param('hostelId', ParseUUIDPipe) hostelId: string,
    @Body() dto: { floorId: string; number: string; type: string; pricePesewas: number; pricePerSemesterPesewas?: number; hasAC?: boolean; hasPrivateBath?: boolean; description?: string; bedCount?: number },
  ) {
    return this.ownerService.createRoom(req.user.sub, hostelId, dto);
  }


  @Patch('rooms/:roomId')
  updateRoom(
    @Req() req: any,
    @Param('roomId', ParseUUIDPipe) roomId: string,
    @Body() dto: any,
  ) {
    return this.ownerService.updateRoom(req.user.sub, roomId, dto);
  }


  /** Get all maintenance requests across owner's hostels */
  @Get('maintenance')
  getMaintenanceRequests(@Req() req: any, @Query('status') status?: string) {
    return this.ownerService.getMaintenanceRequests(req.user.sub, status);
  }

  /** Update maintenance request status */
  @Patch('maintenance/:requestId')
  updateMaintenanceStatus(
    @Req() req: any,
    @Param('requestId') requestId: string,
    @Body() body: { status: string; assignedTo?: string },
  ) {
    return this.ownerService.updateMaintenanceStatus(req.user.sub, requestId, body);
  }

  /** Per-hostel revenue breakdown */
  @Get('revenue/breakdown')
  getRevenueBreakdown(@Req() req: any) {
    return this.ownerService.getRevenueBreakdown(req.user.sub);
  }

  /** Staff CRUD */
  @Get('staff')
  getStaff(@Req() req: any) {
    return this.ownerService.getStaff(req.user.sub);
  }

  @Post('staff')
  addStaff(@Req() req: any, @Body() body: { name: string; role: string; phone?: string; hostelId: string }) {
    return this.ownerService.addStaff(req.user.sub, body);
  }

  @Patch('staff/:staffId')
  updateStaff(@Req() req: any, @Param('staffId') staffId: string, @Body() body: any) {
    return this.ownerService.updateStaff(req.user.sub, staffId, body);
  }

  @Delete('staff/:staffId')
  removeStaff(@Req() req: any, @Param('staffId') staffId: string) {
    return this.ownerService.removeStaff(req.user.sub, staffId);
  }

  @Delete('rooms/:roomId')
  deleteRoom(
    @Req() req: any,
    @Param('roomId', ParseUUIDPipe) roomId: string,
  ) {
    return this.ownerService.deleteRoom(req.user.sub, roomId);
  }

  @Get('rooms/:roomId/beds')
  getBeds(@Req() req: any, @Param('roomId', ParseUUIDPipe) roomId: string) {
    return this.ownerService.getBedsForRoom(req.user.sub, roomId);
  }

  @Post('rooms/:roomId/beds')
  addBeds(
    @Req() req: any,
    @Param('roomId', ParseUUIDPipe) roomId: string,
    @Body('count') count: number,
  ) {
    return this.ownerService.addBeds(req.user.sub, roomId, count);
  }

  @Patch('beds/:bedId/status')
  updateBedStatus(
    @Req() req: any,
    @Param('bedId', ParseUUIDPipe) bedId: string,
    @Body('status') status: string,
  ) {
    return this.ownerService.updateBedStatus(req.user.sub, bedId, status);
  }



  @Patch('beds/:bedId/checkout')
  checkoutBed(@Req() req: any, @Param('bedId', ParseUUIDPipe) bedId: string) {
    return this.ownerService.checkoutBed(req.user.sub, bedId);
  }

  @Delete('beds/:bedId')
  deleteBed(@Req() req: any, @Param('bedId', ParseUUIDPipe) bedId: string) {
    return this.ownerService.deleteBed(req.user.sub, bedId);
  }

  // ── Add Hostel ──

  @Post('hostels')
  createHostel(@Req() req: any, @Body() body: any) {
    return this.ownerService.createHostel(req.user.sub, body);
  }

  @Patch('hostels/:hostelId/submit')
  submitHostel(@Req() req: any, @Param('hostelId', ParseUUIDPipe) hostelId: string) {
    return this.ownerService.submitHostel(req.user.sub, hostelId);
  }


  @Get('hostels/:hostelId')
  getHostel(@Req() req: any, @Param('hostelId', ParseUUIDPipe) hostelId: string) {
    return this.ownerService.getHostel(req.user.sub, hostelId);
  }

  @Patch('hostels/:hostelId')
  updateHostel(
    @Req() req: any,
    @Param('hostelId', ParseUUIDPipe) hostelId: string,
    @Body() body: any,
  ) {
    return this.ownerService.updateHostel(req.user.sub, hostelId, body);
  }

}
