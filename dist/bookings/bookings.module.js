"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.BookingsModule = void 0;
const common_1 = require("@nestjs/common");
const typeorm_1 = require("@nestjs/typeorm");
const schedule_1 = require("@nestjs/schedule");
const booking_entity_1 = require("./entities/booking.entity");
const move_in_task_entity_1 = require("./entities/move_in_task.entity");
const utility_account_entity_1 = require("./entities/utility_account.entity");
const installment_entity_1 = require("./entities/installment.entity");
const hostel_entity_1 = require("../hostels/entities/hostel.entity");
const bookings_service_1 = require("./bookings.service");
const visitors_service_1 = require("./visitors.service");
const community_service_1 = require("./community.service");
const community_controller_1 = require("./community.controller");
const announcements_service_1 = require("./announcements.service");
const announcements_controller_1 = require("./announcements.controller");
const reviews_service_1 = require("./reviews.service");
const reviews_controller_1 = require("./reviews.controller");
const bookings_controller_1 = require("./bookings.controller");
const notifications_module_1 = require("../notifications/notifications.module");
let BookingsModule = class BookingsModule {
};
exports.BookingsModule = BookingsModule;
exports.BookingsModule = BookingsModule = __decorate([
    (0, common_1.Module)({
        imports: [
            schedule_1.ScheduleModule.forRoot(),
            typeorm_1.TypeOrmModule.forFeature([booking_entity_1.Booking, hostel_entity_1.Bed, installment_entity_1.InstallmentPlan, installment_entity_1.Installment, move_in_task_entity_1.MoveInTask, utility_account_entity_1.UtilityAccount, utility_account_entity_1.UtilityBill]),
            notifications_module_1.NotificationsModule,
        ],
        controllers: [bookings_controller_1.BookingsController, community_controller_1.CommunityController, announcements_controller_1.AnnouncementsController, reviews_controller_1.ReviewsController],
        providers: [bookings_service_1.BookingsService, visitors_service_1.VisitorsService, community_service_1.CommunityService, announcements_service_1.AnnouncementsService, reviews_service_1.ReviewsService],
        exports: [bookings_service_1.BookingsService],
    })
], BookingsModule);
//# sourceMappingURL=bookings.module.js.map