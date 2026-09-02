"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.winstonConfig = void 0;
const winston = require("winston");
exports.winstonConfig = {
    transports: [
        new winston.transports.Console({
            format: process.env.NODE_ENV === 'production'
                ? winston.format.combine(winston.format.timestamp(), winston.format.json())
                : winston.format.combine(winston.format.timestamp({ format: 'HH:mm:ss' }), winston.format.colorize(), winston.format.printf(({ timestamp, level, message, context, requestId, ...meta }) => {
                    const ctx = context ? `[${context}]` : '';
                    const rid = requestId ? `(${requestId})` : '';
                    const extra = Object.keys(meta).length ? ` ${JSON.stringify(meta)}` : '';
                    return `${timestamp} ${level} ${ctx}${rid} ${message}${extra}`;
                })),
        }),
    ],
};
//# sourceMappingURL=winston.config.js.map