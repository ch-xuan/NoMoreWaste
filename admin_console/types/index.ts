/**
 * Domain Types for NoMoreWaste Admin Dashboard
 * Based on PRD - Administrative Oversight Module
 */

export type UserRole = 'admin' | 'superAdmin' | 'vendor' | 'ngo' | 'volunteer'
export type VerificationStatus = 'pending' | 'approved' | 'rejected'
export type DonationStatus = 'posted' | 'assigned' | 'in_transit' | 'completed' | 'cancelled' | 'expired'
export type DeliveryStatus = 'pending' | 'assigned' | 'picked_up' | 'in_transit' | 'delivered' | 'cancelled'
export type DietaryCategory = 'vegetarian' | 'vegan' | 'gluten_free' | 'dairy_free' | 'halal' | 'kosher'
export type ModerationStatus = 'pending' | 'approved' | 'flagged' | 'removed'
export type IncidentSeverity = 'low' | 'medium' | 'high' | 'critical'

/**
 * Base User Interface
 */
export interface User {
    id: string
    email: string
    name: string
    role: UserRole
    verified: boolean
    verificationStatus: VerificationStatus
    createdAt: Date | string
    updatedAt: Date | string
    status: 'active' | 'suspended' | 'banned'
}

/**
 * Vendor Interface (Food Vendors/Restaurants)
 */
export interface Vendor extends User {
    role: 'vendor'
    businessName: string
    businessLicense?: string
    hygieneRating?: string
    address: string
    phone: string
    pickupAddress: string
    verificationDocuments?: {
        url: string
        type: 'business_license' | 'hygiene_certificate' | 'other'
        uploadedAt: Date | string
        expiryDate?: Date | string
    }[]
    stats: {
        totalDonations: number
        completedDonations: number
        cancelledDonations: number
        totalKgDonated: number
        averageRating: number
    }
}

/**
 * NGO Interface
 */
export interface NGO extends User {
    role: 'ngo'
    organizationName: string
    registrationNumber: string
    address: string
    contactPerson: string
    phone: string
    verificationDocuments: {
        url: string
        type: 'registration' | 'tax_exempt' | 'other'
        uploadedAt: Date | string
    }[]
    stats: {
        totalRequests: number
        fulfilledRequests: number
        totalKgReceived: number
        mealsDistributed: number
        averagePickupTime: number // in minutes
    }
}

/**
 * Volunteer Interface
 */
export interface Volunteer extends User {
    role: 'volunteer'
    phone: string
    idDocument?: {
        url: string
        uploadedAt: Date | string
    }
    selfiePhoto?: string
    testResult?: {
        score: number
        passed: boolean
        attemptNumber: number
        completedAt: Date | string
    }
    trainingCompleted: boolean
    stats: {
        totalDeliveries: number
        completedDeliveries: number
        cancelledDeliveries: number
        averageRating: number
        reliabilityScore: number
    }
    location?: {
        latitude: number
        longitude: number
        lastUpdated: Date | string
    }
}

/**
 * Donation/Listing Interface
 */
export interface Donation {
    id: string
    vendorId: string
    vendor?: Vendor
    title: string
    description: string
    foodCategory: string
    quantity: number
    unit: 'kg' | 'lbs' | 'portions'
    expiryDate: Date | string
    dietaryCategories: DietaryCategory[]
    allergens: string[]
    photos: string[]
    status: DonationStatus
    moderationStatus: ModerationStatus
    pickupWindow: {
        start: Date | string
        end: Date | string
    }
    assignedNgoId?: string
    assignedNgo?: NGO
    createdAt: Date | string
    updatedAt: Date | string
    flagged?: {
        reason: string
        flaggedAt: Date | string
        flaggedBy: string
    }
}

/**
 * Delivery/Task Interface
 */
export interface Delivery {
    id: string
    donationId: string
    donation?: Donation
    vendorId: string
    vendor?: Vendor
    ngoId: string
    ngo?: NGO
    volunteerId?: string
    volunteer?: Volunteer
    status: DeliveryStatus
    pickupTime?: Date | string
    deliveryTime?: Date | string
    completedAt?: Date | string
    cancelledAt?: Date | string
    cancellationReason?: string
    noShowReason?: string
    distanceKm?: number
    notes?: string
    createdAt: Date | string
    updatedAt: Date | string
}

/**
 * Volunteer Test Interface
 */
export interface VolunteerTest {
    id: string
    title: string
    description: string
    questions: {
        id: string
        question: string
        options: string[]
        correctAnswer: number
        category: 'food_safety' | 'hygiene' | 'handling' | 'ethics'
    }[]
    passScore: number // percentage
    attemptLimit: number
    cooldownHours: number
    active: boolean
    createdAt: Date | string
    updatedAt: Date | string
}

/**
 * Test Attempt Interface
 */
export interface TestAttempt {
    id: string
    testId: string
    volunteerId: string
    volunteer?: Volunteer
    answers: number[]
    score: number
    passed: boolean
    attemptNumber: number
    completedAt: Date | string
}

/**
 * Moderation Item Interface
 */
export interface ModerationItem {
    id: string
    type: 'photo' | 'listing' | 'user_name' | 'incident'
    targetId: string // donation ID, user ID, etc.
    targetType: 'donation' | 'vendor' | 'ngo' | 'volunteer'
    content?: string
    photoUrl?: string
    reportedBy?: string
    reportReason?: string
    status: ModerationStatus
    priority: IncidentSeverity
    reviewedBy?: string
    reviewedAt?: Date | string
    action?: 'approved' | 'removed' | 'warning' | 'suspended' | 'banned'
    actionReason?: string
    createdAt: Date | string
}

/**
 * Incident/Flag Interface
 */
export interface Incident {
    id: string
    type: 'repeat_cancellation' | 'no_show' | 'expired_pickup' | 'inappropriate_content' | 'fraud' | 'other'
    severity: IncidentSeverity
    userId: string
    userRole: UserRole
    description: string
    relatedDonationId?: string
    relatedDeliveryId?: string
    autoDetected: boolean
    resolved: boolean
    resolvedBy?: string
    resolvedAt?: Date | string
    resolutionNotes?: string
    createdAt: Date | string
}

/**
 * Audit Log Interface
 */
export interface AuditLog {
    id: string
    adminId: string
    adminEmail: string
    action: string // 'approve_ngo', 'reject_vendor', 'remove_content', etc.
    targetType: 'user' | 'donation' | 'delivery' | 'moderation' | 'settings'
    targetId: string
    beforeState?: Record<string, unknown>
    afterState?: Record<string, unknown>
    reason?: string
    ipAddress?: string
    timestamp: Date | string
}

/**
 * System Settings Interface
 */
export interface SystemSettings {
    id: string
    maxPickupWindowHours: number
    volunteerDistanceRadiusKm: number
    allowedFoodCategories: string[]
    autoApprovalThresholds: {
        vendor: boolean
        ngo: boolean
        volunteer: boolean
    }
    notificationTemplates: {
        approvalEmail: string
        rejectionEmail: string
        safetyReminder: string
    }
    testSettings: {
        passScore: number
        maxAttempts: number
        cooldownHours: number
    }
    updatedBy: string
    updatedAt: Date | string
}

/**
 * Dashboard Stats Interface (PRD-aligned)
 */
export interface DashboardStats {
    pendingVerifications: {
        ngos: number
        vendors: number
        volunteers: number
        total: number
    }
    activeDonations: {
        count: number
        change: number // percentage
    }
    deliveriesInProgress: {
        count: number
        pickups: number
        inTransit: number
    }
    flagsAndIncidents: {
        unresolved: number
        high: number
        medium: number
        low: number
    }
    quickStats: {
        donationsToday: number
        successfulDeliveriesPercent: number
        activeVendors: number
        activeNGOs: number
        activeVolunteers: number
    }
}

/**
 * Report Data Interface
 */
export interface SystemReport {
    totalFoodRedistributed: {
        kg: number
        estimatedMeals: number
    }
    deliverySuccessRate: number
    ngoFulfillmentRates: {
        ngoId: string
        organizationName: string
        rate: number
    }[]
    volunteerReliability: {
        volunteerId: string
        name: string
        score: number
    }[]
    averagePickupTime: number
    period: {
        start: Date | string
        end: Date | string
    }
    generatedAt: Date | string
}

/**
 * Server Action Response Type
 */
export interface ActionResponse<T = void> {
    success: boolean
    data?: T
    error?: string
    message?: string
}
