// src/media/media.module.ts

import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { MediaController } from './media.controller';
import { R2StorageService } from './r2-storage.service';
import { AuthModule } from '../auth/auth.module';

@Module({
  imports: [ConfigModule, AuthModule],
  controllers: [MediaController],
  providers: [R2StorageService],
  exports: [R2StorageService],
})
export class MediaModule {}
