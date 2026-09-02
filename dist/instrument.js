"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const Sentry = require("@sentry/nestjs");
const profiling_node_1 = require("@sentry/profiling-node");
Sentry.init({
    dsn: process.env.SENTRY_DSN || '',
    environment: process.env.SENTRY_ENVIRONMENT || 'development',
    integrations: [(0, profiling_node_1.nodeProfilingIntegration)()],
    tracesSampleRate: process.env.NODE_ENV === 'production' ? 0.2 : 1.0,
    profilesSampleRate: process.env.NODE_ENV === 'production' ? 0.2 : 1.0,
    enabled: !!process.env.SENTRY_DSN,
});
//# sourceMappingURL=instrument.js.map