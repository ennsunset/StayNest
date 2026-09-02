"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
require("./instrument");
const core_1 = require("@nestjs/core");
const config_1 = require("@nestjs/config");
const common_1 = require("@nestjs/common");
const nest_winston_1 = require("nest-winston");
const helmet_1 = require("helmet");
const app_module_1 = require("./app.module");
async function bootstrap() {
    const app = await core_1.NestFactory.create(app_module_1.AppModule, { bufferLogs: true });
    const config = app.get(config_1.ConfigService);
    const logger = app.get(nest_winston_1.WINSTON_MODULE_NEST_PROVIDER);
    app.useLogger(logger);
    app.use((0, helmet_1.default)());
    app.enableCors({
        origin: config.get('CORS_ORIGIN', '*'),
        credentials: true,
    });
    app.useGlobalPipes(new common_1.ValidationPipe({
        whitelist: true,
        forbidNonWhitelisted: true,
        transform: true,
    }));
    const prefix = config.get('API_PREFIX', 'api/v1');
    app.setGlobalPrefix(prefix, {
        exclude: ['health'],
    });
    app.enableShutdownHooks();
    const port = config.get('PORT', 3000);
    await app.listen(port);
    logger.log(`StayNest API listening on :${port}`, 'Bootstrap');
}
bootstrap();
//# sourceMappingURL=main.js.map