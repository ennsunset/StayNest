import { Inject, Injectable, NestMiddleware } from '@nestjs/common';
import { Request, Response, NextFunction } from 'express';
import { WINSTON_MODULE_PROVIDER } from 'nest-winston';
import { Logger } from 'winston';

@Injectable()
export class RequestLoggerMiddleware implements NestMiddleware {
  constructor(
    @Inject(WINSTON_MODULE_PROVIDER) private readonly logger: Logger,
  ) {}

  use(req: Request, res: Response, next: NextFunction) {
    const start = Date.now();
    const { method, originalUrl } = req;
    const requestId = (req as any).requestId;

    res.on('finish', () => {
      const duration = Date.now() - start;
      const { statusCode } = res;

      const logData = {
        method,
        url: originalUrl,
        statusCode,
        duration,
        requestId,
      };

      if (statusCode >= 500) {
        this.logger.error('Request failed', logData);
      } else if (statusCode >= 400) {
        this.logger.warn('Client error', logData);
      } else {
        this.logger.info('Request completed', logData);
      }
    });

    next();
  }
}
