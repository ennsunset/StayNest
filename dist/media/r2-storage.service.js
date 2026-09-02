"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __metadata = (this && this.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.R2StorageService = void 0;
const common_1 = require("@nestjs/common");
const config_1 = require("@nestjs/config");
const client_s3_1 = require("@aws-sdk/client-s3");
const crypto_1 = require("crypto");
const sharp = require('sharp');
const VARIANTS = [
    { suffix: '_sm', width: 200 },
    { suffix: '_md', width: 600 },
    { suffix: '_lg', width: 1200 },
];
let R2StorageService = class R2StorageService {
    constructor(config) {
        this.config = config;
        this.s3 = new client_s3_1.S3Client({
            region: 'auto',
            endpoint: config.get('R2_ENDPOINT'),
            credentials: {
                accessKeyId: config.get('R2_ACCESS_KEY_ID'),
                secretAccessKey: config.get('R2_SECRET_ACCESS_KEY'),
            },
        });
        this.bucket = config.get('R2_BUCKET', 'staynest-media');
        this.publicUrl = config.get('R2_PUBLIC_URL', '');
    }
    buildUrl(key) {
        return this.publicUrl
            ? this.publicUrl + '/' + key
            : 'https://' + this.bucket + '.r2.dev/' + key;
    }
    async putObject(key, body, contentType) {
        await this.s3.send(new client_s3_1.PutObjectCommand({
            Bucket: this.bucket,
            Key: key,
            Body: body,
            ContentType: contentType,
        }));
    }
    async upload(file, folder) {
        const id = (0, crypto_1.randomUUID)();
        const baseKey = folder + '/' + id;
        const origKey = baseKey + '.webp';
        const origBuf = await sharp(file.buffer).webp({ quality: 85 }).toBuffer();
        await this.putObject(origKey, origBuf, 'image/webp');
        await Promise.all(VARIANTS.map(async (v) => {
            const buf = await sharp(file.buffer)
                .resize(v.width, undefined, { withoutEnlargement: true })
                .webp({ quality: 80 })
                .toBuffer();
            await this.putObject(baseKey + v.suffix + '.webp', buf, 'image/webp');
        }));
        return { key: origKey, url: this.buildUrl(origKey) };
    }
    async delete(key) {
        const dot = key.lastIndexOf('.');
        const base = dot > 0 ? key.substring(0, dot) : key;
        await Promise.all([
            this.s3.send(new client_s3_1.DeleteObjectCommand({ Bucket: this.bucket, Key: key })),
            ...VARIANTS.map((v) => this.s3.send(new client_s3_1.DeleteObjectCommand({
                Bucket: this.bucket,
                Key: base + v.suffix + '.webp',
            }))),
        ]);
    }
};
exports.R2StorageService = R2StorageService;
exports.R2StorageService = R2StorageService = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [config_1.ConfigService])
], R2StorageService);
//# sourceMappingURL=r2-storage.service.js.map