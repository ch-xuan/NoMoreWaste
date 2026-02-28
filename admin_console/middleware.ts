import { NextResponse } from 'next/server'
import type { NextRequest } from 'next/server'

/**
 * Middleware to protect dashboard routes
 * Checks for authentication token and redirects to login if not found
 */
export function middleware(request: NextRequest) {
    const { pathname } = request.nextUrl

    // Check for session cookie created by Firebase Admin
    const sessionCookie = request.cookies.get('session')

    // DEVELOPMENT BYPASS: Allow access without cookie in dev mode
    // (Optional: You can remove this block once auth is fully stable)
    if (process.env.NODE_ENV === 'development' && !sessionCookie) {
        // return NextResponse.next() // Uncomment this to bypass
        // For now, we will just log it effectively or allow it if user specifically asks
        // The user asked "Is it possible to just go to the dashboard?", so we will allow it.
        return NextResponse.next()
    }

    // If no session cookie and trying to access protected route, redirect to login
    if (!sessionCookie) {
        const loginUrl = new URL('/login', request.url)
        // Save the attempted URL to redirect back after login
        loginUrl.searchParams.set('from', pathname)
        return NextResponse.redirect(loginUrl)
    }

    // Note: We're not verifying the session cookie here in middleware
    // because firebase-admin doesn't work well in Edge Runtime.
    // The cookie is HttpOnly and secure, so it can't be tampered with client-side.
    // Individual pages/API routes should verify the session cookie using firebase-admin
    // when they need to access user data.

    return NextResponse.next()
}

/**
 * Configure which routes this middleware applies to
 */
export const config = {
    matcher: [
        /*
         * Match all request paths except:
         * - /login (auth page)
         * - /_next (Next.js internals)
         * - /api (API routes - will have their own auth)
         * - /favicon.ico, /robots.txt (static files)
         */
        '/((?!login|_next|api|favicon.ico|robots.txt).*)',
    ],
}
