export declare enum UtilityType {
    ELECTRICITY = "ELECTRICITY",
    WATER = "WATER",
    INTERNET = "INTERNET"
}
export declare enum BillStatus {
    PENDING = "PENDING",
    SETTLED = "SETTLED",
    OVERDUE = "OVERDUE"
}
export declare class UtilityAccount {
    id: string;
    bookingId: string;
    utilityType: UtilityType;
    creditPesewas: number;
    estimatedDaysLeft: number;
    createdAt: Date;
    updatedAt: Date;
}
export declare class UtilityBill {
    id: string;
    accountId: string;
    label: string;
    description: string;
    utilityType: UtilityType;
    amountPesewas: number;
    status: BillStatus;
    billingPeriod: string;
    dueDate: Date | null;
    paidAt: Date | null;
    createdAt: Date;
    updatedAt: Date;
}
