import { LucideIcon } from 'lucide-react'

interface StatsCardProps {
    title: string
    value: string | number
    icon: LucideIcon
    trend?: {
        value: number
        isPositive: boolean
    }
    description?: string
}

export function StatsCard({ title, value, icon: Icon, trend, description }: StatsCardProps) {
    return (
        <div className="rounded-lg border bg-card p-6 shadow-sm transition-all hover:shadow-md">
            <div className="flex items-center justify-between">
                <div className="space-y-1">
                    <p className="text-sm font-medium text-muted-foreground">{title}</p>
                    <p className="text-3xl font-bold tracking-tight">{value}</p>
                    {description && (
                        <p className="text-xs text-muted-foreground">{description}</p>
                    )}
                    {trend && (
                        <div className="flex items-center gap-1">
                            <span
                                className={`text-sm font-medium ${trend.isPositive ? 'text-green-600' : 'text-red-600'
                                    }`}
                            >
                                {trend.isPositive ? '↑' : '↓'} {Math.abs(trend.value)}%
                            </span>
                            <span className="text-xs text-muted-foreground">vs last month</span>
                        </div>
                    )}
                </div>
                <div className="flex h-12 w-12 items-center justify-center rounded-full bg-primary/10">
                    <Icon className="h-6 w-6 text-primary" />
                </div>
            </div>
        </div>
    )
}
