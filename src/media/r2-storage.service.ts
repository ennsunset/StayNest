// src/media/r2-storage.service.ts

import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import {
  S3Client,
  PutObjectCommand,
  DeleteObjectCommand,
} from '@aws-sdk/client-s3';
import { randomUUID } from 'crypto';
// eslint-disable-next-line @typescript-eslint/no-var-requires
const sharp = require('sharp');

interface Variant {
  suffix: string;
  width: number;
}

const VARIANTS: Variant[] = [
  { suffix: '_sm', width: 200 },
  { suffix: '_md', width: 600 },
  { suffix: '_lg', width: 1200 },
];

@Injectable()
export class R2StorageService {
  private readonly s3: S3Client;
  private readonly bucket: string;
  private readonly publicUrl: string;

  constructor(private readonly config: ConfigService) {
    this.s3 = new S3Client({
      region: 'auto',
      endpoint: config.get<string>('R2_ENDPOINT')!,
      credentials: {
        accessKeyId: config.get<string>('R2_ACCESS_KEY_ID')!,
        secretAccessKey: config.get<string>('R2_SECRET_ACCESS_KEY')!,
      },
    });
    this.bucket = config.get<string>('R2_BUCKET', 'staynest-media');
    this.publicUrl = config.get<string>('R2_PUBLIC_URL', '');
  }

  private buildUrl(key: string): string {
    return this.publicUrl
      ? this.publicUrl + '/' + key
      : 'https://' + this.bucket + '.r2.dev/' + key;
  }

  private async putObject(key: string, body: Buffer, contentType: string) {
    await this.s3.send(
      new PutObjectCommand({
        Bucket: this.bucket,
        Key: key,
        Body: body,
        ContentType: contentType,
      }),
    );
  }

  async upload(
    file: Express.Multer.File,
    folder: string,
  ): Promise<{ key: string; url: string }> {
    const id = randomUUID();
    const baseKey = folder + '/' + id;

    // Upload original
    const origKey = baseKey + '.webp';
    const origBuf = await sharp(file.buffer).webp({ quality: 85 }).toBuffer();
    await this.putObject(origKey, origBuf, 'image/webp');

    // Upload size variants in parallel
    await Promise.all(
      VARIANTS.map(async (v) => {
        const buf = await sharp(file.buffer)
          .resize(v.width, undefined, { withoutEnlargement: true })
          .webp({ quality: 80 })
          .toBuffer();
        await this.putObject(baseKey + v.suffix + '.webp', buf, 'image/webp');
      }),
    );

    return { key: origKey, url: this.buildUrl(origKey) };
  }

  async delete(key: string): Promise<void> {
    // Delete original + all variants
    const dot = key.lastIndexOf('.');
    const base = dot > 0 ? key.substring(0, dot) : key;

    await Promise.all([
      this.s3.send(new DeleteObjectCommand({ Bucket: this.bucket, Key: key })),
      ...VARIANTS.map((v) =>
        this.s3.send(
          new DeleteObjectCommand({
            Bucket: this.bucket,
            Key: base + v.suffix + '.webp',
          }),
        ),
      ),
    ]);
  }
}
