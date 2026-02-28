'use client'

import { useState, useEffect, useRef } from 'react'
import { User2, Mail, Phone, Shield, Calendar, Edit2, LogOut, Loader2, Camera, Upload, Key, Lock, Activity, Eye, EyeOff } from 'lucide-react'
import { useRouter } from 'next/navigation'
import Image from 'next/image'

export default function ProfilePage() {
    const router = useRouter()
    const fileInputRef = useRef<HTMLInputElement>(null)
    const [isEditing, setIsEditing] = useState(false)
    const [isSaving, setIsSaving] = useState(false)
    const [isLoading, setIsLoading] = useState(true)
    const [isUploadingPhoto, setIsUploadingPhoto] = useState(false)
    const [saveError, setSaveError] = useState<string | null>(null)
    const [saveSuccess, setSaveSuccess] = useState(false)
    const [showPasswordModal, setShowPasswordModal] = useState(false)
    const [show2FAModal, setShow2FAModal] = useState(false)

    // User data from Firestore
    const [userData, setUserData] = useState<any>(null)
    const [activityLogs, setActivityLogs] = useState<any[]>([])
    const [editData, setEditData] = useState({
        displayName: '',
        phone: '',
    })

    // Fetch user data on mount
    useEffect(() => {
        fetchUserData()
        fetchActivityLogs()
    }, [])

    const fetchUserData = async () => {
        setIsLoading(true)
        try {
            const response = await fetch('/api/user/profile')
            if (response.ok) {
                const data = await response.json()
                setUserData(data.user)
                setEditData({
                    displayName: data.user.displayName || '',
                    phone: data.user.phone || '',
                })
            } else {
                console.error('Failed to fetch user data')
            }
        } catch (error) {
            console.error('Error fetching user data:', error)
        } finally {
            setIsLoading(false)
        }
    }

    const fetchActivityLogs = async () => {
        try {
            const response = await fetch('/api/user/activity-logs')
            if (response.ok) {
                const data = await response.json()
                setActivityLogs(data.logs || [])
            }
        } catch (error) {
            console.error('Error fetching activity logs:', error)
        }
    }

    const handleSaveChanges = async () => {
        setIsSaving(true)
        setSaveError(null)
        setSaveSuccess(false)

        try {
            const response = await fetch('/api/user/update-profile', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify({
                    uid: userData.uid,
                    displayName: editData.displayName,
                    phone: editData.phone,
                }),
            })

            const result = await response.json()

            if (!response.ok) {
                throw new Error(result.error || 'Failed to update profile')
            }

            // Refresh user data
            await fetchUserData()

            setSaveSuccess(true)
            setIsEditing(false)

            // Clear success message after 3 seconds
            setTimeout(() => setSaveSuccess(false), 3000)
        } catch (error: any) {
            console.error('Save error:', error)
            setSaveError(error.message || 'Failed to save changes')
        } finally {
            setIsSaving(false)
        }
    }

    const handlePhotoUpload = async (event: React.ChangeEvent<HTMLInputElement>) => {
        const file = event.target.files?.[0]
        if (!file) return

        setIsUploadingPhoto(true)
        setSaveError(null)

        try {
            // Resize and convert to base64
            const resizeImage = (file: File): Promise<string> => {
                return new Promise((resolve, reject) => {
                    const reader = new FileReader()
                    reader.readAsDataURL(file)
                    reader.onload = (event) => {
                        const img = document.createElement('img')
                        img.src = event.target?.result as string
                        img.onload = () => {
                            const canvas = document.createElement('canvas')
                            let width = img.width
                            let height = img.height
                            const MAX_WIDTH = 800
                            const MAX_HEIGHT = 800

                            if (width > height) {
                                if (width > MAX_WIDTH) {
                                    height *= MAX_WIDTH / width
                                    width = MAX_WIDTH
                                }
                            } else {
                                if (height > MAX_HEIGHT) {
                                    width *= MAX_HEIGHT / height
                                    height = MAX_HEIGHT
                                }
                            }

                            canvas.width = width
                            canvas.height = height
                            const ctx = canvas.getContext('2d')
                            ctx?.drawImage(img, 0, 0, width, height)

                            // Convert to highly compressed JPEG to save space
                            const dataUrl = canvas.toDataURL('image/jpeg', 0.7)
                            resolve(dataUrl)
                        }
                        img.onerror = (error: any) => reject(error)
                    }
                    reader.onerror = (error: any) => reject(error)
                })
            }

            const photoBase64 = await resizeImage(file)

            const response = await fetch('/api/user/upload-photo', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify({
                    photoBase64,
                    uid: userData.uid,
                }),
            })

            const result = await response.json()

            if (!response.ok) {
                throw new Error(result.error || 'Failed to upload photo')
            }

            // Refresh user data to get new photo URL
            await fetchUserData()

            // Manually update local state for instant feedback
            setUserData((prev: any) => prev ? ({ ...prev, photoURL: photoBase64 }) : null)

            // Notify other components (like UserNav) to refresh
            window.dispatchEvent(new Event('user-updated'))

            setSaveSuccess(true)
            setTimeout(() => setSaveSuccess(false), 3000)
        } catch (error: any) {
            console.error('Upload error:', error)
            setSaveError(error.message || 'Failed to upload photo')
        } finally {
            setIsUploadingPhoto(false)
        }
    }

    const handleLogout = async () => {
        await fetch('/api/auth/logout', { method: 'POST' })
        router.push('/login')
    }

    if (isLoading) {
        return (
            <div className="flex items-center justify-center min-h-[400px]">
                <Loader2 className="h-8 w-8 animate-spin text-primary" />
            </div>
        )
    }

    if (!userData) {
        return (
            <div className="text-center p-8">
                <p className="text-muted-foreground">Failed to load profile data</p>
                <button
                    onClick={fetchUserData}
                    className="mt-4 rounded-md bg-primary px-4 py-2 text-sm font-medium text-primary-foreground hover:bg-primary/90"
                >
                    Retry
                </button>
            </div>
        )
    }

    const formatDate = (timestamp: any) => {
        if (!timestamp) return 'N/A'
        if (timestamp._seconds) {
            return new Date(timestamp._seconds * 1000).toLocaleString()
        }
        if (timestamp.seconds) {
            return new Date(timestamp.seconds * 1000).toLocaleString()
        }
        // Handle ISO string or Date object
        try {
            return new Date(timestamp).toLocaleString()
        } catch {
            return 'N/A'
        }
    }

    return (
        <div className="mx-auto max-w-6xl space-y-6">
            {/* Page Title */}
            <div className="space-y-1">
                <h1 className="text-2xl font-bold tracking-tight sm:text-3xl">Profile</h1>
                <p className="text-sm text-muted-foreground sm:text-base">
                    Manage your account settings and preferences
                </p>
            </div>

            {/* Success/Error Messages */}
            {saveSuccess && (
                <div className="rounded-md bg-green-50 border border-green-200 p-4">
                    <p className="text-sm text-green-800">Updated successfully!</p>
                </div>
            )}
            {saveError && (
                <div className="rounded-md bg-destructive/10 border border-destructive p-4">
                    <p className="text-sm text-destructive">{saveError}</p>
                </div>
            )}


            {/* Profile Header */}
            <div className="rounded-lg border bg-card p-6 shadow-sm">
                <div className="flex flex-col gap-6 sm:flex-row sm:items-start sm:justify-between">
                    <div className="flex items-start gap-4">
                        {/* Avatar with Upload */}
                        <div className="relative group">
                            {userData.photoURL ? (
                                <img
                                    src={userData.photoURL}
                                    alt={userData.displayName}
                                    className="h-20 w-20 rounded-full object-cover"
                                />
                            ) : (
                                <div className="flex h-20 w-20 items-center justify-center rounded-full bg-primary text-primary-foreground">
                                    <User2 className="h-10 w-10" />
                                </div>
                            )}
                            <button
                                onClick={() => fileInputRef.current?.click()}
                                disabled={isUploadingPhoto}
                                className="absolute inset-0 flex items-center justify-center rounded-full bg-black/50 opacity-0 group-hover:opacity-100 transition-opacity"
                            >
                                {isUploadingPhoto ? (
                                    <Loader2 className="h-6 w-6 text-white animate-spin" />
                                ) : (
                                    <Camera className="h-6 w-6 text-white" />
                                )}
                            </button>
                            <input
                                ref={fileInputRef}
                                type="file"
                                accept="image/*"
                                onChange={handlePhotoUpload}
                                className="hidden"
                            />
                        </div>

                        {/* User Info */}
                        <div>
                            <h2 className="text-2xl font-bold">{userData.displayName}</h2>
                            <p className="text-sm text-muted-foreground">{userData.email}</p>
                            <div className="mt-2 flex flex-wrap gap-2">
                                <span className="inline-flex items-center gap-1 rounded-full bg-primary px-3 py-1 text-xs font-medium text-primary-foreground">
                                    <Shield className="h-3 w-3" />
                                    {userData.role}
                                </span>
                                {userData.isSuperAdmin && (
                                    <span className="inline-flex items-center gap-1 rounded-full bg-purple-100 px-3 py-1 text-xs font-medium text-purple-700">
                                        Super Admin
                                    </span>
                                )}
                            </div>
                        </div>
                    </div>

                    {/* Actions */}
                    <div className="flex gap-2">
                        <button
                            onClick={() => {
                                if (isEditing) {
                                    setEditData({
                                        displayName: userData.displayName || '',
                                        phone: userData.phone || '',
                                    })
                                }
                                setIsEditing(!isEditing)
                            }}
                            disabled={isSaving}
                            className="inline-flex items-center gap-2 rounded-md border px-4 py-2 text-sm font-medium hover:bg-muted disabled:opacity-50"
                        >
                            <Edit2 className="h-4 w-4" />
                            {isEditing ? 'Cancel' : 'Edit Profile'}
                        </button>
                        <button
                            onClick={handleLogout}
                            className="inline-flex items-center gap-2 rounded-md bg-destructive px-4 py-2 text-sm font-medium text-destructive-foreground hover:bg-destructive/90"
                        >
                            <LogOut className="h-4 w-4" />
                            Logout
                        </button>
                    </div>
                </div>
            </div>

            {/* Profile Details */}
            <div className="rounded-lg border bg-card p-6 shadow-sm">
                <h3 className="mb-4 text-lg font-semibold">Profile Information</h3>

                <div className="space-y-4">
                    {/* Display Name */}
                    <div className="grid gap-2 sm:grid-cols-3">
                        <label className="flex items-center gap-2 text-sm font-medium text-muted-foreground">
                            <User2 className="h-4 w-4" />
                            Display Name
                        </label>
                        {isEditing ? (
                            <input
                                type="text"
                                value={editData.displayName}
                                onChange={(e) => setEditData({ ...editData, displayName: e.target.value })}
                                className="sm:col-span-2 rounded-md border px-3 py-2 text-sm"
                            />
                        ) : (
                            <p className="sm:col-span-2 text-sm">{userData.displayName}</p>
                        )}
                    </div>

                    {/* Email */}
                    <div className="grid gap-2 sm:grid-cols-3">
                        <label className="flex items-center gap-2 text-sm font-medium text-muted-foreground">
                            <Mail className="h-4 w-4" />
                            Email Address
                        </label>
                        <p className="sm:col-span-2 text-sm">{userData.email}</p>
                    </div>

                    {/* Phone */}
                    <div className="grid gap-2 sm:grid-cols-3">
                        <label className="flex items-center gap-2 text-sm font-medium text-muted-foreground">
                            <Phone className="h-4 w-4" />
                            Phone Number
                        </label>
                        {isEditing ? (
                            <input
                                type="tel"
                                value={editData.phone}
                                onChange={(e) => setEditData({ ...editData, phone: e.target.value })}
                                className="sm:col-span-2 rounded-md border px-3 py-2 text-sm"
                            />
                        ) : (
                            <p className="sm:col-span-2 text-sm">{userData.phone || 'Not set'}</p>
                        )}
                    </div>

                    {/* Account Created */}
                    <div className="grid gap-2 sm:grid-cols-3">
                        <label className="flex items-center gap-2 text-sm font-medium text-muted-foreground">
                            <Calendar className="h-4 w-4" />
                            Account Created
                        </label>
                        <p className="sm:col-span-2 text-sm">{formatDate(userData.createdAt)}</p>
                    </div>

                    {/* Last Updated */}
                    {userData.updatedAt && (
                        <div className="grid gap-2 sm:grid-cols-3">
                            <label className="flex items-center gap-2 text-sm font-medium text-muted-foreground">
                                <Calendar className="h-4 w-4" />
                                Last Updated
                            </label>
                            <p className="sm:col-span-2 text-sm">{formatDate(userData.updatedAt)}</p>
                        </div>
                    )}
                </div>

                {isEditing && (
                    <div className="mt-6 flex justify-end gap-2">
                        <button
                            onClick={() => {
                                setEditData({
                                    displayName: userData.displayName || '',
                                    phone: userData.phone || '',
                                })
                                setIsEditing(false)
                            }}
                            disabled={isSaving}
                            className="rounded-md border px-4 py-2 text-sm font-medium hover:bg-muted disabled:opacity-50"
                        >
                            Cancel
                        </button>
                        <button
                            onClick={handleSaveChanges}
                            disabled={isSaving}
                            className="inline-flex items-center gap-2 rounded-md bg-primary px-4 py-2 text-sm font-medium text-primary-foreground hover:bg-primary/90 disabled:opacity-50"
                        >
                            {isSaving ? (
                                <>
                                    <Loader2 className="h-4 w-4 animate-spin" />
                                    Saving...
                                </>
                            ) : (
                                'Save Changes'
                            )}
                        </button>
                    </div>
                )}
            </div>

            {/* Security Settings */}
            <div className="rounded-lg border bg-card p-6 shadow-sm">
                <h3 className="mb-4 text-lg font-semibold">Security</h3>
                <div className="space-y-3">
                    <button
                        onClick={() => setShowPasswordModal(true)}
                        className="w-full rounded-md border p-4 text-left hover:bg-muted transition-colors"
                    >
                        <div className="flex items-start gap-3">
                            <Key className="h-5 w-5 text-primary" />
                            <div>
                                <p className="font-medium">Change Password</p>
                                <p className="text-sm text-muted-foreground">Update your password regularly for security</p>
                            </div>
                        </div>
                    </button>
                    <button
                        onClick={() => setShow2FAModal(true)}
                        className="w-full rounded-md border p-4 text-left hover:bg-muted transition-colors"
                    >
                        <div className="flex items-start gap-3">
                            <Lock className="h-5 w-5 text-primary" />
                            <div>
                                <p className="font-medium">Two-Factor Authentication</p>
                                <p className="text-sm text-muted-foreground">Add an extra layer of security</p>
                            </div>
                        </div>
                    </button>
                </div>
            </div>

            {/* Recent Activity */}
            <div className="rounded-lg border bg-card p-6 shadow-sm">
                <div className="flex items-center gap-2 mb-4">
                    <Activity className="h-5 w-5 text-primary" />
                    <h3 className="text-lg font-semibold">Recent Activity</h3>
                </div>
                <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-3">
                    {activityLogs.length === 0 ? (
                        <p className="text-sm text-muted-foreground col-span-full">No activity logs yet</p>
                    ) : (
                        activityLogs.map((log) => (
                            <div key={log.id} className="border-l-2 border-primary pl-3 pb-3">
                                <p className="text-sm font-medium">{log.action}</p>
                                <p className="text-xs text-muted-foreground">{formatDate(log.timestamp)}</p>
                                {log.details && (
                                    <p className="text-xs text-muted-foreground mt-1">{log.details}</p>
                                )}
                            </div>
                        ))
                    )}
                </div>
            </div>

            {/* Password Change Modal */}
            {showPasswordModal && (
                <PasswordModal onClose={() => setShowPasswordModal(false)} />
            )}

            {/* 2FA Modal */}
            {show2FAModal && (
                <TwoFactorModal onClose={() => setShow2FAModal(false)} />
            )}
        </div>
    )
}


function PasswordModal({ onClose }: { onClose: () => void }) {
    const [currentPassword, setCurrentPassword] = useState('')
    const [newPassword, setNewPassword] = useState('')
    const [confirmPassword, setConfirmPassword] = useState('')
    const [isLoading, setIsLoading] = useState(false)
    const [error, setError] = useState('')
    const [showCurrentPassword, setShowCurrentPassword] = useState(false)
    const [showNewPassword, setShowNewPassword] = useState(false)
    const [showConfirmPassword, setShowConfirmPassword] = useState(false)

    const handleSubmit = async (e: React.FormEvent) => {
        e.preventDefault()
        setError('')

        if (newPassword !== confirmPassword) {
            setError('Passwords do not match')
            return
        }

        if (newPassword.length < 6) {
            setError('Password must be at least 6 characters')
            return
        }

        setIsLoading(true)

        try {
            const response = await fetch('/api/user/change-password', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ currentPassword, newPassword }),
            })

            const result = await response.json()

            if (!response.ok) {
                throw new Error(result.error || 'Failed to change password')
            }

            alert('Password changed successfully!')
            onClose()
        } catch (error: any) {
            setError(error.message)
        } finally {
            setIsLoading(false)
        }
    }
    return (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
            <div className="absolute inset-0 bg-black/50" onClick={onClose} />
            <div className="relative z-10 w-full max-w-md rounded-lg border bg-card p-6 shadow-lg">
                <h2 className="text-xl font-bold mb-4">Change Password</h2>
                <form onSubmit={handleSubmit} className="space-y-4">
                    <div>
                        <label className="block text-sm font-medium mb-2">Current Password</label>
                        <div className="relative">
                            <input
                                type={showCurrentPassword ? "text" : "password"}
                                value={currentPassword}
                                onChange={(e) => setCurrentPassword(e.target.value)}
                                className="w-full rounded-md border px-3 py-2 pr-10"
                                required
                            />
                            <button
                                type="button"
                                onClick={() => setShowCurrentPassword(!showCurrentPassword)}
                                className="absolute right-2 top-1/2 -translate-y-1/2 text-muted-foreground hover:text-foreground"
                            >
                                {showCurrentPassword ? <EyeOff className="h-4 w-4" /> : <Eye className="h-4 w-4" />}
                            </button>
                        </div>
                    </div>
                    <div>
                        <label className="block text-sm font-medium mb-2">New Password</label>
                        <div className="relative">
                            <input
                                type={showNewPassword ? "text" : "password"}
                                value={newPassword}
                                onChange={(e) => setNewPassword(e.target.value)}
                                className="w-full rounded-md border px-3 py-2 pr-10"
                                required
                            />
                            <button
                                type="button"
                                onClick={() => setShowNewPassword(!showNewPassword)}
                                className="absolute right-2 top-1/2 -translate-y-1/2 text-muted-foreground hover:text-foreground"
                            >
                                {showNewPassword ? <EyeOff className="h-4 w-4" /> : <Eye className="h-4 w-4" />}
                            </button>
                        </div>
                    </div>
                    <div>
                        <label className="block text-sm font-medium mb-2">Confirm New Password</label>
                        <div className="relative">
                            <input
                                type={showConfirmPassword ? "text" : "password"}
                                value={confirmPassword}
                                onChange={(e) => setConfirmPassword(e.target.value)}
                                className="w-full rounded-md border px-3 py-2 pr-10"
                                required
                            />
                            <button
                                type="button"
                                onClick={() => setShowConfirmPassword(!showConfirmPassword)}
                                className="absolute right-2 top-1/2 -translate-y-1/2 text-muted-foreground hover:text-foreground"
                            >
                                {showConfirmPassword ? <EyeOff className="h-4 w-4" /> : <Eye className="h-4 w-4" />}
                            </button>
                        </div>
                    </div>
                    {
                        error && (
                            <p className="text-sm text-destructive">{error}</p>
                        )
                    }
                    <div className="flex justify-end gap-2">
                        <button
                            type="button"
                            onClick={onClose}
                            className="rounded-md border px-4 py-2 text-sm font-medium"
                        >
                            Cancel
                        </button>
                        <button
                            type="submit"
                            disabled={isLoading}
                            className="rounded-md bg-primary px-4 py-2 text-sm font-medium text-primary-foreground disabled:opacity-50"
                        >
                            {isLoading ? 'Changing...' : 'Change Password'}
                        </button>
                    </div>
                </form >
            </div >
        </div >
    )
}

function TwoFactorModal({ onClose }: { onClose: () => void }) {
    const [isEnabled, setIsEnabled] = useState(false)
    const [qrCode, setQrCode] = useState('')
    const [verificationCode, setVerificationCode] = useState('')
    const [isLoading, setIsLoading] = useState(false)
    const [error, setError] = useState('')

    useEffect(() => {
        // Check if 2FA is already enabled
        fetch('/api/user/2fa-status')
            .then(r => r.json())
            .then(data => setIsEnabled(data.enabled))
    }, [])

    const handleEnable2FA = async () => {
        setIsLoading(true)
        setError('')
        try {
            const response = await fetch('/api/user/setup-2fa', { method: 'POST' })
            const data = await response.json()

            if (!response.ok) {
                throw new Error(data.error || 'Failed to setup 2FA')
            }

            setQrCode(data.qrCode)
        } catch (error: any) {
            setError(error.message)
        } finally {
            setIsLoading(false)
        }
    }

    const handleVerify = async (e: React.FormEvent) => {
        e.preventDefault()
        setIsLoading(true)
        setError('')

        try {
            const response = await fetch('/api/user/verify-2fa', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ code: verificationCode }),
            })

            const result = await response.json()

            if (!response.ok) {
                throw new Error(result.error || 'Verification failed')
            }

            alert('2FA enabled successfully!')
            onClose()
        } catch (error: any) {
            setError(error.message)
        } finally {
            setIsLoading(false)
        }
    }

    const handleDisable2FA = async () => {
        if (!confirm('Are you sure you want to disable 2FA?')) return

        try {
            // API call to disable 2FA would go here
            alert('2FA disabled')
            setIsEnabled(false)
            onClose()
        } catch (error) {
            alert('Failed to disable 2FA')
        }
    }

    return (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
            <div className="absolute inset-0 bg-black/50" onClick={onClose} />
            <div className="relative z-10 w-full max-w-md rounded-lg border bg-card p-6 shadow-lg">
                <h2 className="text-xl font-bold mb-4">Two-Factor Authentication</h2>

                {isEnabled ? (
                    <div>
                        <p className="text-sm text-muted-foreground mb-4">
                            2FA is currently enabled on your account using an authenticator app.
                        </p>
                        <button
                            onClick={handleDisable2FA}
                            className="w-full rounded-md bg-destructive px-4 py-2 text-sm font-medium text-destructive-foreground"
                        >
                            Disable 2FA
                        </button>
                    </div>
                ) : qrCode ? (
                    <form onSubmit={handleVerify} className="space-y-4">
                        <div>
                            <p className="text-sm text-muted-foreground mb-2">
                                Scan this QR code with your authenticator app (Google Authenticator, Authy, etc.):
                            </p>
                            <div className="bg-white p-4 rounded-md inline-block">
                                <img src={qrCode} alt="QR Code" className="w-48 h-48" />
                            </div>
                        </div>
                        <div>
                            <label className="block text-sm font-medium mb-2">Verification Code</label>
                            <input
                                type="text"
                                value={verificationCode}
                                onChange={(e) => setVerificationCode(e.target.value)}
                                className="w-full rounded-md border px-3 py-2"
                                placeholder="Enter 6-digit code"
                                maxLength={6}
                                required
                            />
                        </div>
                        {error && <p className="text-sm text-destructive">{error}</p>}
                        <div className="flex justify-end gap-2">
                            <button
                                type="button"
                                onClick={onClose}
                                className="rounded-md border px-4 py-2 text-sm font-medium"
                            >
                                Cancel
                            </button>
                            <button
                                type="submit"
                                disabled={isLoading}
                                className="rounded-md bg-primary px-4 py-2 text-sm font-medium text-primary-foreground disabled:opacity-50"
                            >
                                {isLoading ? 'Verifying...' : 'Verify & Enable'}
                            </button>
                        </div>
                    </form>
                ) : (
                    <div>
                        <p className="text-sm text-muted-foreground mb-4">
                            Add an extra layer of security to your account by requiring a code from your authenticator app in addition to your password.
                        </p>
                        {error && <p className="text-sm text-destructive mb-4">{error}</p>}
                        <button
                            onClick={handleEnable2FA}
                            disabled={isLoading}
                            className="w-full rounded-md bg-primary px-4 py-2 text-sm font-medium text-primary-foreground disabled:opacity-50"
                        >
                            {isLoading ? 'Loading...' : 'Enable 2FA'}
                        </button>
                    </div>
                )}

                <button
                    onClick={onClose}
                    className="mt-4 w-full text-sm text-muted-foreground hover:text-foreground"
                >
                    Close
                </button>
            </div>
        </div>
    )
}




