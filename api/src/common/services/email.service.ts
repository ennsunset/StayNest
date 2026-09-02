import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

@Injectable()
export class EmailService {
  private readonly apiKey: string;
  private readonly fromEmail: string;

  constructor(private config: ConfigService) {
    this.apiKey = config.get<string>('RESEND_API_KEY', '');
    this.fromEmail = config.get<string>('RESEND_FROM_EMAIL', 'noreply@staynest.app');
  }

  async send(to: string, subject: string, html: string): Promise<boolean> {
    if (!this.apiKey) {
      console.log(`[EMAIL STUB] To: ${to} | Subject: ${subject}`);
      return true;
    }

    try {
      const res = await fetch('https://api.resend.com/emails', {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${this.apiKey}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          from: this.fromEmail,
          to,
          subject,
          html,
        }),
      });
      const data = await res.json();
      console.log('[EMAIL] Resend response:', JSON.stringify(data));
      return res.ok;
    } catch (e) {
      console.error('[EMAIL] Resend error:', e);
      return false;
    }
  }
}
