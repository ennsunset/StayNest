import { Module } from '@nestjs/common';
import { AiController } from './ai.controller';
import { AiService } from './ai.service';
import { HostelsModule } from '../hostels/hostels.module';

@Module({
  imports: [HostelsModule],
  controllers: [AiController],
  providers: [AiService],
})
export class AiModule {}
