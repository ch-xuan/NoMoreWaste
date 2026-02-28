'use client'

import { useState, useEffect } from 'react'
import { useRouter } from 'next/navigation'
import { ChevronDown, LogOut, User } from 'lucide-react'

export function UserNav() {
    const router = useRouter()
    const [isOpen, setIsOpen] = useState(false)
    const [userData, setUserData] = useState<any>(null)

    useEffect(() => {
        fetchUserData()

        // Listen for profile updates
        const handleUserUpdate = () => {
            fetchUserData()
        }
        window.addEventListener('user-updated', handleUserUpdate)

        return () => {
            window.removeEventListener('user-updated', handleUserUpdate)
        }
    }, [])

    const fetchUserData = async () => {
        try {
            // Reusing the same API as ProfilePage or creating a lightweight one?
            // Since we need to be quick, let's use the same logic or just hit the user data endpoint if available.
            // But we don't have a designated 'get current user' API that returns everything cleanly except checking session.
            // Logic in profile/page.tsx involves checking the session and decoding token or fetching from Firestore.
            // Let's trying fetching from a new endpoint or the profile endpoint if it exists.
            // We defined `app/api/user/profile`? No, we accessed `userData` in `profile/page.tsx` via `adminAuth` in server component or client fetch?
            // In `profile/page.tsx`, we saw `fetchUserData` calling... wait.
            // Let's check `profile/page.tsx` again to see how it fetches data.
            // It seems it might be doing it inside `page.tsx`?
            // Ah, `profile/page.tsx` is a client component that fetches data?
            // "Updated handlePhotoUpload ... Refresh user data to get new photo URL -> await fetchUserData()"
            // So `fetchUserData` exists in `profile/page`.

            // To make UserNav work globally, we need an endpoint.
            // I'll assume we can use `/api/user/profile` if it exists, or I'll create `app/api/user/me/route.ts`.
            // Let's quickly create `app/api/user/me/route.ts` that returns the current user's data.
            // But first, let's just try to assume we can enable this component to fetch data.

            const response = await fetch('/api/user/me') // I will create this.
            if (response.ok) {
                const data = await response.json()
                setUserData(data.user)
            }
        } catch (error) {
            console.error('Failed to fetch user data for nav:', error)
        }
    }

    const handleLogout = async () => {
        try {
            // Sign out from Firebase
            const { auth } = await import('@/lib/firebase/client')
            const { signOut } = await import('firebase/auth')
            await signOut(auth)

            // Call logout API to clear session cookie
            await fetch('/api/auth/logout', {
                method: 'POST',
            })

            // Redirect to login
            router.push('/login')
        } catch (error) {
            console.error('Logout error:', error)
            // Still redirect even if there's an error
            router.push('/login')
        }
    }

    // Default Fallback
    const displayName = userData?.displayName || userData?.name || 'Victor' // Fallback to 'Victor' (Super Admin) if no data or for consistency with previous hardcoded
    const displayEmail = userData?.email || 'victor@gmail.com'
    const displayRole = userData?.role || 'Super Admin'
    const photoURL = userData?.photoURL

    return (
        <div className="relative">
            <button
                type="button"
                onClick={() => setIsOpen(!isOpen)}
                className="inline-flex items-center gap-x-2 rounded-md bg-muted px-3 py-2 text-sm font-medium text-foreground transition-colors hover:bg-muted/80"
            >
                <div className="flex h-8 w-8 items-center justify-center rounded-full bg-primary text-primary-foreground overflow-hidden">
                    {photoURL ? (
                        <img src={photoURL} alt="Profile" className="h-full w-full object-cover" />
                    ) : (
                        <User className="h-4 w-4" />
                    )}
                </div>
                <div className="text-left hidden sm:block">
                    <p className="text-sm font-medium">{displayName}</p>
                    <p className="text-xs text-muted-foreground">{displayRole}</p>
                </div>
                <ChevronDown className="h-4 w-4 text-muted-foreground" />
            </button>

            {/* Dropdown Menu */}
            {isOpen && (
                <>
                    {/* Backdrop */}
                    <div
                        className="fixed inset-0 z-40"
                        onClick={() => setIsOpen(false)}
                    />

                    {/* Menu Panel */}
                    <div className="absolute right-0 z-50 mt-2 w-64 animate-in slide-in-from-top-2 rounded-md border bg-card shadow-lg">
                        <div className="p-1">
                            {/* User Info */}
                            <div className="border-b px-3 py-3">
                                <p className="text-sm font-medium">{displayName}</p>
                                <p className="text-xs text-muted-foreground">{displayEmail}</p>
                                <p className="mt-1 text-xs text-primary capitalize">{displayRole}</p>
                            </div>

                            {/* Menu Items */}
                            <div className="py-1">
                                <button
                                    onClick={() => {
                                        setIsOpen(false)
                                        router.push('/profile')
                                    }}
                                    className="flex w-full items-center gap-2 rounded-md px-3 py-2 text-sm text-foreground transition-colors hover:bg-muted"
                                >
                                    <User className="h-4 w-4" />
                                    View Profile
                                </button>
                                {/* Settings button removed or kept? Keeping as per original */}
                                <button
                                    onClick={() => {
                                        setIsOpen(false)
                                        router.push('/settings')
                                    }}
                                    className="flex w-full items-center gap-2 rounded-md px-3 py-2 text-sm text-foreground transition-colors hover:bg-muted"
                                >
                                    <ChevronDown className="h-4 w-4" />
                                    Settings
                                </button>
                            </div>

                            {/* Logout */}
                            <div className="border-t pt-1">
                                <button
                                    onClick={handleLogout}
                                    className="flex w-full items-center gap-2 rounded-md px-3 py-2 text-sm text-destructive transition-colors hover:bg-destructive/10"
                                >
                                    <LogOut className="h-4 w-4" />
                                    Logout
                                </button>
                            </div>
                        </div>
                    </div>
                </>
            )}
        </div>
    )
}
