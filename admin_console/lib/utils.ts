import { clsx, type ClassValue } from "clsx"
import { twMerge } from "tailwind-merge"

/**
 * Utility function to merge Tailwind CSS classes
 * Used by shadcn/ui components
 */
export function cn(...inputs: ClassValue[]) {
    return twMerge(clsx(inputs))
}

/**
 * Format date for display
 */
export function formatDate(date: Date | string): string {
    const d = typeof date === 'string' ? new Date(date) : date
    return new Intl.DateTimeFormat('en-US', {
        month: 'short',
        day: 'numeric',
        year: 'numeric',
    }).format(d)
}

/**
 * Format number with thousands separator
 */
export function formatNumber(num: number): string {
    return new Intl.NumberFormat('en-US').format(num)
}

/**
 * Calculate percentage change
 */
export function calculatePercentageChange(current: number, previous: number): number {
    if (previous === 0) return 0
    return ((current - previous) / previous) * 100
}
