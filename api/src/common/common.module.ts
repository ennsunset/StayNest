import { Global, Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AuditLog } from './entities/audit-log.entity';
import { AuditService } from './services/audit.service';
import { SmsService } from './services/sms.service';
import { EmailService } from './services/email.service';

@Global()
@Module({
  imports: [TypeOrmModule.forFeature([AuditLog])],
  providers: [AuditService, SmsService, EmailService],
  exports: [AuditService, SmsService, EmailService],
})
export class CommonModule {}
