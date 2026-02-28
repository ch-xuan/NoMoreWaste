'use client'

import { useState } from 'react'
import { Download, FileText, TrendingUp, Calendar, Loader2 } from 'lucide-react'

export default function ReportsPage() {
    const [isGenerating, setIsGenerating] = useState(false)
    const [selectedDateRange, setSelectedDateRange] = useState('Last 30 days')
    const [selectedFormat, setSelectedFormat] = useState('PDF')
    const [selectedMetrics, setSelectedMetrics] = useState({
        foodRedistribution: true,
        ngoFulfillment: true,
        volunteerPerformance: true,
        donorContribution: true,
    })

    const reportTemplates = [
        {
            id: '1',
            title: 'Monthly Impact Report',
            description: 'Total food redistributed, meals served, and CO2 emissions prevented',
            icon: TrendingUp,
            format: ['PDF', 'CSV'],
        },
        {
            id: '2',
            title: 'User Activity Report',
            description: 'Active donors, NGOs, and volunteer performance and contribution',
            icon: FileText,
            format: ['PDF', 'CSV'],
        },
        {
            id: '3',
            title: 'Delivery Performance',
            description: 'Success rate, average pickup time, and volunteer reliability',
            icon: Calendar,
            format: ['PDF', 'Excel'],
        },
    ]

    const handleGenerateReport = async () => {
        setIsGenerating(true)

        try {
            const response = await fetch('/api/reports/generate', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify({
                    dateRange: selectedDateRange,
                    format: selectedFormat,
                    metrics: selectedMetrics,
                }),
            })

            if (!response.ok) {
                throw new Error('Failed to generate report')
            }

            // Get the blob from response
            const blob = await response.blob()

            // Create download link
            const url = window.URL.createObjectURL(blob)
            const a = document.createElement('a')
            a.href = url
            a.download = `custom-report-${Date.now()}.${selectedFormat.toLowerCase()}`
            document.body.appendChild(a)
            a.click()
            window.URL.revokeObjectURL(url)
            document.body.removeChild(a)
        } catch (error) {
            console.error('Error generating report:', error)
            alert('Failed to generate report. Please try again.')
        } finally {
            setIsGenerating(false)
        }
    }

    const handleDownloadTemplate = async (templateId: string, format: string) => {
        try {
            const response = await fetch('/api/reports/template', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify({
                    templateId,
                    format,
                }),
            })

            if (!response.ok) {
                throw new Error('Failed to download report')
            }

            const blob = await response.blob()
            const url = window.URL.createObjectURL(blob)
            const a = document.createElement('a')
            a.href = url
            a.download = `${templateId}-report-${Date.now()}.${format.toLowerCase()}`
            document.body.appendChild(a)
            a.click()
            window.URL.revokeObjectURL(url)
            document.body.removeChild(a)
        } catch (error) {
            console.error('Error downloading template:', error)
            alert('Failed to download report. Please try again.')
        }
    }

    return (
        <div className="space-y-6">
            {/* Page Header */}
            <div className="space-y-1">
                <h1 className="text-2xl font-bold tracking-tight sm:text-3xl">Reports & Analytics</h1>
                <p className="text-sm text-muted-foreground sm:text-base">
                    Generate comprehensive reports for stakeholders
                </p>
            </div>

            {/* Quick Stats */}
            <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
                <QuickStat label="Total Donations" value="1,247" unit="this month" />
                <QuickStat label="Success Rate" value="94.2%" unit="deliveries" />
                <QuickStat label="Meals Served" value="12,435" unit="estimated" />
            </div>

            {/* Report Templates */}
            <div>
                <h2 className="mb-4 text-lg sm:text-xl font-semibold">Available Reports</h2>
                <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
                    {reportTemplates.map((template) => (
                        <ReportCard
                            key={template.id}
                            {...template}
                            onDownload={handleDownloadTemplate}
                        />
                    ))}
                </div>
            </div>

            {/* Custom Report Builder */}
            <div className="rounded-lg border bg-card p-4 sm:p-6">
                <h2 className="mb-4 text-lg sm:text-xl font-semibold">Custom Report Builder</h2>
                <p className="mb-6 text-sm text-muted-foreground">
                    Create a custom report with specific metrics and date ranges
                </p>

                <div className="space-y-4">
                    <div className="grid gap-4 sm:grid-cols-2">
                        <div>
                            <label className="mb-2 block text-sm font-medium">Date Range</label>
                            <select
                                value={selectedDateRange}
                                onChange={(e) => setSelectedDateRange(e.target.value)}
                                className="w-full rounded-md border border-input bg-background px-3 py-2 text-sm"
                            >
                                <option>Last 7 days</option>
                                <option>Last 30 days</option>
                                <option>Last 3 months</option>
                                <option>Custom range</option>
                            </select>
                        </div>
                        <div>
                            <label className="mb-2 block text-sm font-medium">Format</label>
                            <select
                                value={selectedFormat}
                                onChange={(e) => setSelectedFormat(e.target.value)}
                                className="w-full rounded-md border border-input bg-background px-3 py-2 text-sm"
                            >
                                <option>PDF</option>
                                <option>CSV</option>
                                <option>Excel</option>
                            </select>
                        </div>
                    </div>

                    <div>
                        <label className="mb-2 block text-sm font-medium">Include Metrics</label>
                        <div className="space-y-2">
                            <CheckboxOption
                                label="Food redistribution by category"
                                checked={selectedMetrics.foodRedistribution}
                                onChange={(checked) =>
                                    setSelectedMetrics({ ...selectedMetrics, foodRedistribution: checked })
                                }
                            />
                            <CheckboxOption
                                label="NGO fulfillment rates"
                                checked={selectedMetrics.ngoFulfillment}
                                onChange={(checked) =>
                                    setSelectedMetrics({ ...selectedMetrics, ngoFulfillment: checked })
                                }
                            />
                            <CheckboxOption
                                label="Volunteer performance"
                                checked={selectedMetrics.volunteerPerformance}
                                onChange={(checked) =>
                                    setSelectedMetrics({ ...selectedMetrics, volunteerPerformance: checked })
                                }
                            />
                            <CheckboxOption
                                label="Donor contribution rankings"
                                checked={selectedMetrics.donorContribution}
                                onChange={(checked) =>
                                    setSelectedMetrics({ ...selectedMetrics, donorContribution: checked })
                                }
                            />
                        </div>
                    </div>

                    <button
                        onClick={handleGenerateReport}
                        disabled={isGenerating}
                        className="mt-4 inline-flex items-center gap-2 rounded-md bg-primary px-6 py-2 text-sm font-medium text-primary-foreground hover:bg-primary/90 disabled:opacity-50"
                    >
                        {isGenerating ? (
                            <>
                                <Loader2 className="h-4 w-4 animate-spin" />
                                Generating...
                            </>
                        ) : (
                            <>
                                <Download className="h-4 w-4" />
                                Generate Custom Report
                            </>
                        )}
                    </button>
                </div>
            </div>
        </div>
    )
}

function QuickStat({ label, value, unit }: { label: string; value: string; unit: string }) {
    return (
        <div className="rounded-lg border bg-card p-4">
            <p className="text-sm font-medium text-muted-foreground">{label}</p>
            <p className="mt-2 text-2xl font-bold">{value}</p>
            <p className="text-xs text-muted-foreground">{unit}</p>
        </div>
    )
}

function ReportCard({
    id,
    title,
    description,
    icon: Icon,
    format,
    onDownload,
}: {
    id: string
    title: string
    description: string
    icon: any
    format: string[]
    onDownload: (id: string, format: string) => void
}) {
    return (
        <div className="rounded-lg border bg-card p-6 transition-all hover:shadow-md">
            <div className="mb-4 flex h-12 w-12 items-center justify-center rounded-full bg-primary/10">
                <Icon className="h-6 w-6 text-primary" />
            </div>
            <h3 className="mb-2 text-lg font-semibold">{title}</h3>
            <p className="mb-4 text-sm text-muted-foreground">{description}</p>

            <div className="flex flex-wrap gap-2">
                {format.map((fmt) => (
                    <button
                        key={fmt}
                        onClick={() => onDownload(id, fmt)}
                        className="inline-flex items-center gap-1 rounded-md border bg-background px-3 py-1 text-xs font-medium hover:bg-muted"
                    >
                        <Download className="h-3 w-3" />
                        {fmt}
                    </button>
                ))}
            </div>
        </div>
    )
}

function CheckboxOption({
    label,
    checked,
    onChange,
}: {
    label: string
    checked: boolean
    onChange: (checked: boolean) => void
}) {
    return (
        <label className="flex items-center gap-2 text-sm cursor-pointer">
            <input
                type="checkbox"
                className="h-4 w-4 rounded border-gray-300 cursor-pointer"
                checked={checked}
                onChange={(e) => onChange(e.target.checked)}
            />
            {label}
        </label>
    )
}
