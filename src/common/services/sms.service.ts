import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

@Injectable()
export class SmsService {
  private readonly clientId: string;
  private readonly clientSecret: string;
  private readonly senderId: string;

  constructor(private config: ConfigService) {
    this.clientId = config.get<string>('HUBTEL_CLIENT_ID', '');
    this.clientSecret = config.get<string>('HUBTEL_CLIENT_SECRET', '');
    this.senderId = config.get<string>('HUBTEL_SENDER_ID', 'StayNest');
  }

  async send(to: string, message: string): Promise<boolean> {
    if (!this.clientId || !this.clientSecret) {
      console.log(`[SMS STUB] To: ${to} | Message: ${message}`);
      return true;
    }

    try {
      const auth = Buffer.from(`${this.clientId}:${this.clientSecret}`).toString('base64');
      const res = await fetch(
        `https://smsc.hubtel.com/v1/messages/send?clientid=${encodeURIComponent(this.clientId)}&clientsecret=${encodeURIComponent(this.clientSecret)}&from=${encodeURIComponent(this.senderId)}&to=${encodeURIComponent(to)}&content=${encodeURIComponent(message)}`,
        { method: 'GET' },
      );
      const data = await res.json();
      console.log('[SMS] Hubtel response:', JSON.stringify(data));
      return res.ok;
    } catch (e) {
      console.error('[SMS] Hubtel error:', e);
      return false;
    }
  }
}
