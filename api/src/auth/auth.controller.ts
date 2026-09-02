// src/auth/auth.controller.ts

import { Controller, Post, Body, Get, Patch, UseGuards, Req } from '@nestjs/common';
import { AuthService } from './auth.service';
import { RegisterDto, LoginDto, SocialLoginDto } from './auth.dto';
import { SendOtpDto, VerifyOtpDto, CompleteProfileDto } from './dto/auth-flow.dto';
import { JwtAuthGuard } from './jwt-auth.guard';

@Controller('auth')
export class AuthController {
  constructor(private readonly auth: AuthService) {}

  @Post('register')
  register(@Body() dto: RegisterDto) {
    return this.auth.register(dto);
  }

  @Post('login')
  login(@Body() dto: LoginDto) {
    return this.auth.login(dto.email, dto.password);
  }

  @Post('social')
  socialLogin(@Body() dto: SocialLoginDto) {
    return this.auth.socialLogin(dto.provider, dto.idToken, dto.fullName);
  }

  @UseGuards(JwtAuthGuard)
  @Post('refresh')
  refresh(@Req() req: any) {
    return this.auth.refresh(req.user.sub);
  }

  @UseGuards(JwtAuthGuard)
  @Get('me')
  async me(@Req() req: any) {
    return this.auth.getMe(req.user.sub);
  }

  @UseGuards(JwtAuthGuard)
  @Post('otp/send')
  sendOtp(@Req() req: any, @Body() dto: SendOtpDto) {
    return this.auth.sendOtp(req.user.sub, dto);
  }

  @UseGuards(JwtAuthGuard)
  @Post('otp/verify')
  verifyOtp(@Req() req: any, @Body() dto: VerifyOtpDto) {
    return this.auth.verifyOtp(req.user.sub, dto);
  }

  @UseGuards(JwtAuthGuard)
  @Patch('complete-profile')
  completeProfile(@Req() req: any, @Body() dto: CompleteProfileDto) {
    return this.auth.completeProfile(req.user.sub, dto);
  }

  @UseGuards(JwtAuthGuard)
  @Get('verification-status')
  getVerificationStatus(@Req() req: any) {
    return this.auth.getVerificationStatus(req.user.sub);
  }

  @UseGuards(JwtAuthGuard)
  @Patch('profile')
  updateProfile(@Req() req: any, @Body() body: { fullName?: string; phone?: string; avatarUrl?: string }) {
    return this.auth.updateProfile(req.user.sub, body);
  }

  @Post('password/forgot')
  forgotPassword(@Body() body: { email: string }) {
    return this.auth.forgotPassword(body.email);
  }

  @Post('password/reset')
  resetPassword(@Body() body: { email: string; code: string; newPassword: string }) {
    return this.auth.resetPassword(body.email, body.code, body.newPassword);
  }
}
