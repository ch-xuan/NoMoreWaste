'use client'

import { useState } from 'react'
import { useRouter } from 'next/navigation'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import * as z from 'zod'
import { Loader2 } from 'lucide-react'

// Validation schema
const loginSchema = z.object({
    email: z.string().email('Please enter a valid email address'),
    password: z.string().min(6, 'Password must be at least 6 characters'),
})

type LoginFormData = z.infer<typeof loginSchema>

export default function LoginPage() {
    const router = useRouter()
    const [isLoading, setIsLoading] = useState(false)
    const [error, setError] = useState<string | null>(null)
    const [showPassword, setShowPassword] = useState(false)

    const {
        register,
        handleSubmit,
        formState: { errors },
    } = useForm<LoginFormData>({
        resolver: zodResolver(loginSchema),
    })

    const onSubmit = async (data: LoginFormData) => {
        setIsLoading(true)
        setError(null)

        try {
            // Import Firebase auth dynamically to avoid SSR issues
            const { auth } = await import('@/lib/firebase/client')
            const { signInWithEmailAndPassword } = await import('firebase/auth')

            // Sign in with Firebase
            const userCredential = await signInWithEmailAndPassword(
                auth,
                data.email,
                data.password
            )

            // Get the ID token
            const idToken = await userCredential.user.getIdToken()

            // Send token to our API to create session cookie
            const response = await fetch('/api/auth/login', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify({ idToken }),
            })

            const result = await response.json()

            if (!response.ok) {
                throw new Error(result.error || 'Authentication failed')
            }

            // Redirect to dashboard
            router.push('/dashboard')
        } catch (err: any) {
            console.error('Login error:', err)

            // Handle Firebase specific errors
            if (err.code === 'auth/user-not-found' || err.code === 'auth/wrong-password') {
                setError('Invalid email or password')
            } else if (err.code === 'auth/too-many-requests') {
                setError('Too many failed attempts. Please try again later.')
            } else if (err.message) {
                setError(err.message)
            } else {
                setError('Authentication failed. Please try again.')
            }
        } finally {
            setIsLoading(false)
        }
    }

    return (
        <div className="w-full">
            {/* Logo & Title */}
            <div className="mb-8 text-center">
                <div className="mx-auto mb-4 flex h-20 w-20 items-center justify-center rounded-lg bg-transparent overflow-hidden">
                    <img
                        src="/app_icon.png"
                        alt="NoMoreWaste Logo"
                        className="h-full w-full object-cover"
                    />
                </div>
                <h1 className="text-2xl font-bold text-gray-900 dark:text-white">
                    NoMoreWaste
                </h1>
                <p className="mt-2 text-sm text-gray-600 dark:text-gray-400">
                    Admin Dashboard
                </p>
            </div>

            {/* Login Card */}
            <div className="rounded-lg border bg-card p-8 shadow-lg">
                <h2 className="mb-6 text-xl font-semibold">Sign In</h2>

                {error && (
                    <div className="mb-4 rounded-md bg-destructive/10 p-3 text-sm text-destructive">
                        {error}
                    </div>
                )}

                <form onSubmit={handleSubmit(onSubmit)} className="space-y-4">
                    {/* Email Field */}
                    <div>
                        <label
                            htmlFor="email"
                            className="mb-2 block text-sm font-medium text-foreground"
                        >
                            Email Address
                        </label>
                        <input
                            id="email"
                            type="email"
                            placeholder="admin@nomorewaste.com"
                            className="flex h-10 w-full rounded-md border border-input bg-background px-3 py-2 text-sm ring-offset-background placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:cursor-not-allowed disabled:opacity-50"
                            {...register('email')}
                        />
                        {errors.email && (
                            <p className="mt-1 text-sm text-destructive">
                                {errors.email.message}
                            </p>
                        )}
                    </div>

                    {/* Password Field */}
                    <div>
                        <label
                            htmlFor="password"
                            className="mb-2 block text-sm font-medium text-foreground"
                        >
                            Password
                        </label>
                        <div className="relative">
                            <input
                                id="password"
                                type={showPassword ? "text" : "password"}
                                placeholder="••••••••"
                                className="flex h-10 w-full rounded-md border border-input bg-background px-3 py-2 pr-10 text-sm ring-offset-background placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:cursor-not-allowed disabled:opacity-50"
                                {...register('password')}
                            />
                            <button
                                type="button"
                                onClick={() => setShowPassword(!showPassword)}
                                className="absolute right-2 top-1/2 -translate-y-1/2 text-muted-foreground hover:text-foreground"
                            >
                                {showPassword ? '👁️' : '👁️‍🗨️'}
                            </button>
                        </div>
                        {errors.password && (
                            <p className="mt-1 text-sm text-destructive">
                                {errors.password.message}
                            </p>
                        )}
                    </div>

                    {/* Submit Button */}
                    <button
                        type="submit"
                        disabled={isLoading}
                        className="inline-flex h-10 w-full items-center justify-center rounded-md bg-primary px-4 py-2 text-sm font-medium text-primary-foreground ring-offset-background transition-colors hover:bg-primary/90 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50"
                    >
                        {isLoading ? (
                            <>
                                <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                                Signing in...
                            </>
                        ) : (
                            'Sign In'
                        )}
                    </button>
                </form>

                {/* Development Notice */}
                <div className="mt-6 rounded-md bg-muted p-3 text-xs text-muted-foreground">
                    <strong>Note:</strong> Please use your Firebase Admin credentials to sign in.
                </div>
            </div>
        </div>
    )
}
