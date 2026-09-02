"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.AppModule = void 0;
const common_1 = require("@nestjs/common");
const config_1 = require("@nestjs/config");
const typeorm_1 = require("@nestjs/typeorm");
const nest_winston_1 = require("nest-winston");
const setup_1 = require("@sentry/nestjs/setup");
const winston_config_1 = require("./common/logger/winston.config");
const request_id_middleware_1 = require("./common/middleware/request-id.middleware");
const request_logger_middleware_1 = require("./common/middleware/request-logger.middleware");
const common_module_1 = require("./common/common.module");
const health_module_1 = require("./health/health.module");
const media_module_1 = require("./media/media.module");
const owner_module_1 = require("./owner/owner.module");
const ai_module_1 = require("./ai/ai.module");
const messaging_module_1 = require("./messaging/messaging.module");
const notifications_module_1 = require("./notifications/notifications.module");
const auth_module_1 = require("./auth/auth.module");
const users_module_1 = require("./users/users.module");
const hostels_module_1 = require("./hostels/hostels.module");
const bookings_module_1 = require("./bookings/bookings.module");
const payments_module_1 = require("./payments/payments.module");
let AppModule = class AppModule {
    configure(consumer) {
        consumer
            .apply(request_id_middleware_1.RequestIdMiddleware, request_logger_middleware_1.RequestLoggerMiddleware)
            .forRoutes('*');
    }
};
exports.AppModule = AppModule;
exports.AppModule = AppModule = __decorate([
    (0, common_1.Module)({
        imports: [
            setup_1.SentryModule.forRoot(),
            config_1.ConfigModule.forRoot({
                isGlobal: true,
                envFilePath: '.env',
            }),
            nest_winston_1.WinstonModule.forRoot(winston_config_1.winstonConfig),
            typeorm_1.TypeOrmModule.forRootAsync({
                inject: [config_1.ConfigService],
                useFactory: (config) => ({
                    type: 'postgres',
                    host: config.get('DB_HOST', 'localhost'),
                    port: config.get('DB_PORT', 5432),
                    username: config.get('DB_USERNAME', 'staynest'),
                    password: config.get('DB_PASSWORD', ''),
                    database: config.get('DB_NAME', 'staynest'),
                    ssl: config.get('DB_SSL') === 'true'
                        ? { rejectUnauthorized: false }
                        : false,
                    autoLoadEntities: true,
                    synchronize: false,
                    logging: config.get('NODE_ENV') === 'development'
                        ? ['error', 'warn', 'migration']
                        : ['error'],
                }),
            }),
            common_module_1.CommonModule,
            health_module_1.HealthModule,
            auth_module_1.AuthModule,
            owner_module_1.OwnerModule,
            ai_module_1.AiModule,
            messaging_module_1.MessagingModule,
            notifications_module_1.NotificationsModule,
            media_module_1.MediaModule,
            users_module_1.UsersModule,
            hostels_module_1.HostelsModule,
            bookings_module_1.BookingsModule,
            payments_module_1.PaymentsModule,
        ],
    })
], AppModule);
//# sourceMappingURL=app.module.js.map