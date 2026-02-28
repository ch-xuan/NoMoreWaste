'use client'

import { useState, useEffect } from 'react'
import { CheckCircle, XCircle, Clock, FileText, Loader2 } from 'lucide-react'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import {
    Dialog,
    DialogContent,
    DialogDescription,
    DialogFooter,
    DialogHeader,
    DialogTitle,
} from "@/components/ui/dialog"
import { Textarea } from "@/components/ui/textarea"
import { Label } from "@/components/ui/label"
// Tabs import removed
// I didn't create Tabs. User didn't ask for Tabs component specifically but "add approved & rejected beside the pending".
// Shadcn Tabs is standard. I'll check if I need to install it. 
// "can you change it back like this" -> Button UI.
// I will assume I need to implement simple tabs if Shadcn Tabs not present. 
// I'll implement simple state-based tabs to avoid install complexity unless I check.
// I installed button, dialog, textarea, label. Tabs was NOT installed.
// I will use manual buttons for tabs to save time/tokens.

export default function VerifyPage() {
    const [users, setUsers] = useState<any[]>([])
    const [isLoading, setIsLoading] = useState(true)
    const [statusFilter, setStatusFilter] = useState<'pending' | 'approved' | 'rejected'>('pending')

    useEffect(() => {
        fetchUsers()
    }, [statusFilter])

    const fetchUsers = async () => {
        setIsLoading(true)
        try {
            const response = await fetch(`/api/admin/users/verifications?status=${statusFilter}`)
            if (response.ok) {
                const data = await response.json()
                setUsers(data.users || [])
            }
        } catch (error) {
            console.error('Failed to fetch users:', error)
        } finally {
            setIsLoading(false)
        }
    }

    const handleVerificationComplete = () => {
        fetchUsers()
    }

    return (
        <div className="space-y-6">
            {/* Page Header */}
            <div className="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4">
                <div>
                    <h1 className="text-3xl font-bold tracking-tight">User Verification</h1>
                    <p className="text-muted-foreground">
                        Review and approve user registrations
                    </p>
                </div>

                {/* Custom Tabs */}
                <div className="flex p-1 bg-muted rounded-lg">
                    {['pending', 'approved', 'rejected'].map((status) => (
                        <button
                            key={status}
                            onClick={() => setStatusFilter(status as any)}
                            className={`
                                px-4 py-2 text-sm font-medium rounded-md transition-all capitalize
                                ${statusFilter === status
                                    ? 'bg-background text-foreground shadow-sm'
                                    : 'text-muted-foreground hover:text-foreground/80'
                                }
                            `}
                        >
                            {status}
                            {status === 'pending' && users.length > 0 && statusFilter === 'pending' && (
                                <span className="ml-2 bg-primary/10 text-primary px-1.5 py-0.5 rounded-full text-xs">
                                    {users.length}
                                </span>
                            )}
                        </button>
                    ))}
                </div>
            </div>

            {/* Verification Queue */}
            {isLoading ? (
                <div className="flex h-64 items-center justify-center">
                    <Loader2 className="h-8 w-8 animate-spin text-primary" />
                </div>
            ) : (
                <div className="space-y-4">
                    {users.length > 0 ? (
                        users.map((item) => (
                            <VerificationCard
                                key={item.id}
                                {...item}
                                currentStatus={statusFilter}
                                onVerifyComplete={handleVerificationComplete}
                            />
                        ))
                    ) : (
                        <div className="flex h-64 items-center justify-center rounded-lg border border-dashed">
                            <div className="text-center">
                                <CheckCircle className="mx-auto h-12 w-12 text-muted-foreground" />
                                <h3 className="mt-4 text-lg font-semibold">No {statusFilter} users</h3>
                                <p className="text-sm text-muted-foreground">
                                    There are no users in this category.
                                </p>
                            </div>
                        </div>
                    )}
                </div>
            )}
        </div>
    )
}

function VerificationCard({
    id,
    type,
    name,
    email,
    submittedAt,
    documents = [],
    role,
    orgName,
    displayName,
    uploadDocsBase64,
    verificationReason,
    currentStatus,
    onVerifyComplete,
    createdAt
}: {
    id: string
    type?: string
    name?: string
    email: string
    submittedAt?: string
    documents?: string[]
    role?: string
    orgName?: string
    displayName?: string
    uploadDocsBase64?: string
    verificationReason?: string
    currentStatus: string
    onVerifyComplete: () => void
    createdAt?: any
}) {
    // Timestamp handling - support string or firestore timestamp
    let dateStr = 'Unknown'
    if (submittedAt) dateStr = submittedAt
    if (createdAt && typeof createdAt === 'object' && createdAt._seconds) {
        dateStr = new Date(createdAt._seconds * 1000).toLocaleDateString()
    } else if (createdAt) {
        dateStr = new Date(createdAt).toLocaleDateString()
    }

    const userRole = (role || type || 'user') as 'ngo' | 'vendor' | 'volunteer' | 'user' | 'donor'
    const displayTitle = orgName || displayName || name || 'Unknown User'
    const [isDialogOpen, setIsDialogOpen] = useState(false)
    const [action, setAction] = useState<'approved' | 'rejected'>('approved')
    const [reason, setReason] = useState('')
    const [isSubmitting, setIsSubmitting] = useState(false)

    const typeConfig: Record<string, { label: string; color: string }> = {
        ngo: { label: 'NGO', color: 'bg-blue-100 text-blue-700' },
        vendor: { label: 'Vendor', color: 'bg-purple-100 text-purple-700' },
        volunteer: { label: 'Volunteer', color: 'bg-green-100 text-green-700' },
        donor: { label: 'Donor', color: 'bg-orange-100 text-orange-700' },
        user: { label: 'User', color: 'bg-gray-100 text-gray-700' },
        admin: { label: 'Admin', color: 'bg-red-100 text-red-700' },
    }

    const config = typeConfig[userRole] || typeConfig['user']

    const handleAction = (selectedAction: 'approved' | 'rejected') => {
        setAction(selectedAction)
        setReason('')
        setIsDialogOpen(true)
    }

    const handleSubmit = async () => {
        if (action === 'rejected' && !reason.trim()) return

        setIsSubmitting(true)
        try {
            const response = await fetch('/api/admin/users/verify', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                    userId: id,
                    action: action === 'approved' ? 'approve' : 'reject',
                    reason: reason.trim() || undefined
                }),
            })

            if (!response.ok) throw new Error('Failed to update status')

            setIsDialogOpen(false)
            onVerifyComplete()
        } catch (error) {
            console.error('Verification error:', error)
            alert('Failed to process verification. Please try again.')
        } finally {
            setIsSubmitting(false)
        }
    }

    // Function to download/view base64 file
    const handleViewDocument = () => {
        if (!uploadDocsBase64) return

        try {
            // Check if it's already a Data URL
            let dataUrl = uploadDocsBase64
            let mimeType = 'application/octet-stream' // Default fallback
            let extension = 'bin'

            // Detect MIME type from base64 signature if no prefix
            if (!dataUrl.startsWith('data:')) {
                // Magic numbers for common file types
                if (dataUrl.startsWith('/9j/')) { mimeType = 'image/jpeg'; extension = 'jpg' }
                else if (dataUrl.startsWith('iVBORw0KGgo')) { mimeType = 'image/png'; extension = 'png' }
                else if (dataUrl.startsWith('JVBERi0')) { mimeType = 'application/pdf'; extension = 'pdf' }
                else if (dataUrl.startsWith('R0lGOD')) { mimeType = 'image/gif'; extension = 'gif' }
                else {
                    // Fallback to PDF if unknown, as requested by user context often implies docs
                    mimeType = 'application/pdf'; extension = 'pdf'
                }

                dataUrl = `data:${mimeType};base64,${uploadDocsBase64}`
            } else {
                // Extract extension from existing data URL
                const matches = dataUrl.match(/^data:([^;]+);base64,/)
                if (matches && matches[1]) {
                    mimeType = matches[1]
                    const subtype = mimeType.split('/')[1]
                    extension = subtype || 'bin'
                }
            }

            // Create a link and click it to trigger download/view
            const link = document.createElement('a')
            link.href = dataUrl
            link.target = '_blank'
            link.download = `document-${id}.${extension}`
            document.body.appendChild(link)
            link.click()
            document.body.removeChild(link)
        } catch (e) {
            console.error("Error viewing document:", e)
            alert("Could not open document.")
        }
    }

    return (
        <div className="rounded-lg border bg-card p-6 shadow-sm transition-all hover:shadow-md">
            <div className="flex flex-col md:flex-row items-start justify-between gap-4">
                <div className="flex-1 space-y-3 w-full">
                    {/* Header */}
                    <div className="flex items-center gap-3">
                        <Badge className={config.color}>{config.label}</Badge>
                        <h3 className="text-lg font-semibold">{displayTitle}</h3>
                        {currentStatus !== 'pending' && (
                            <Badge variant={currentStatus === 'approved' ? 'default' : 'destructive'}>
                                {currentStatus === 'approved' ? 'Verified' : 'Rejected'}
                            </Badge>
                        )}
                    </div>

                    {/* Details */}
                    <div className="space-y-1 text-sm text-muted-foreground">
                        <p>Email: {email}</p>
                        <p className="flex items-center gap-2">
                            <Clock className="h-4 w-4" />
                            Submitted {dateStr}
                        </p>
                        {verificationReason && (
                            <p className="text-foreground mt-2 border-l-2 border-muted pl-2 italic">
                                "{verificationReason}"
                            </p>
                        )}
                    </div>

                    {/* Documents */}
                    <div className="space-y-2">
                        <p className="text-sm font-medium">Submitted Documents:</p>
                        <div className="flex flex-wrap gap-2">
                            {uploadDocsBase64 ? (
                                <button
                                    onClick={handleViewDocument}
                                    className="flex items-center gap-2 rounded-md border bg-muted px-3 py-1.5 text-xs font-medium hover:bg-muted/80 transition-colors"
                                >
                                    <FileText className="h-4 w-4" />
                                    View Document
                                </button>
                            ) : documents.length > 0 ? (
                                documents.map((doc, idx) => (
                                    <button
                                        key={idx}
                                        className="flex items-center gap-2 rounded-md border bg-muted px-3 py-1 text-xs hover:bg-muted/80"
                                    >
                                        <FileText className="h-3 w-3" />
                                        {doc}
                                    </button>
                                ))
                            ) : (
                                <span className="text-xs text-muted-foreground">No documents submitted</span>
                            )}
                        </div>
                    </div>
                </div>

                {/* Actions - Only status 'pending' shows actions usually, or maybe simple read-only for others */}
                {currentStatus === 'pending' && (
                    <div className="flex items-center gap-2 w-full md:w-auto">
                        {/* Custom Styled Buttons as requested */}
                        <Button
                            className="flex-1 md:flex-none bg-green-600 hover:bg-green-700 text-white gap-2"
                            onClick={() => handleAction('approved')}
                        >
                            <div className="rounded-full border border-white/40 p-0.5">
                                <CheckCircle className="h-3 w-3" />
                            </div>
                            Approve
                        </Button>
                        <Button
                            className="flex-1 md:flex-none bg-red-600 hover:bg-red-700 text-white gap-2"
                            onClick={() => handleAction('rejected')}
                        >
                            <div className="rounded-full border border-white/40 p-0.5">
                                <XCircle className="h-3 w-3" />
                            </div>
                            Reject
                        </Button>
                    </div>
                )}
            </div>

            <Dialog open={isDialogOpen} onOpenChange={setIsDialogOpen}>
                <DialogContent>
                    <DialogHeader>
                        <DialogTitle>
                            {action === 'approved' ? 'Approve User' : 'Reject User'}
                        </DialogTitle>
                        <DialogDescription>
                            Please provide a reason for this decision. This will be visible to the user.
                        </DialogDescription>
                    </DialogHeader>
                    <div className="space-y-4 py-4">
                        <div className="space-y-2">
                            <Label htmlFor="reason">Reason / Note <span className="text-red-500">*</span></Label>
                            <Textarea
                                id="reason"
                                placeholder={action === 'approved' ? "Verified documentation matches..." : "Missing required business license..."}
                                value={reason}
                                onChange={(e) => setReason(e.target.value)}
                            />
                        </div>
                    </div>
                    <DialogFooter>
                        <Button variant="outline" onClick={() => setIsDialogOpen(false)} disabled={isSubmitting}>
                            Cancel
                        </Button>
                        <Button
                            onClick={handleSubmit}
                            disabled={!reason.trim() || isSubmitting}
                            className={action === 'approved' ? 'bg-green-600 hover:bg-green-700' : 'bg-red-600 hover:bg-red-700'}
                        >
                            {isSubmitting ? (
                                <>
                                    <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                                    Updating...
                                </>
                            ) : (
                                action === 'approved' ? 'Confirm Approval' : 'Confirm Rejection'
                            )}
                        </Button>
                    </DialogFooter>
                </DialogContent>
            </Dialog>
        </div>
    )
}
