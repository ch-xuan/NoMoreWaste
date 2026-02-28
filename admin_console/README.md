# NoMoreWaste Admin Dashboard

Enterprise-grade admin dashboard for the NoMoreWaste food redistribution platform. Built with Next.js 15, TypeScript, and Firebase.

## 🎯 Features

- **User Verification**: Review and approve NGO registrations and donor hygiene certificates
- **Live Operations**: Monitor active food rescue pickups and delivery statuses
- **Inventory Management**: Track surplus food listings with expiration dates and dietary info
- **Impact Analytics**: Visualize metrics like meals saved and CO2 emissions prevented
- **Real-time Updates**: Server-side rendering with Firebase Admin SDK integration

## 🛠 Tech Stack

- **Framework**: Next.js 15 (App Router, Turbopack)
- **Language**: TypeScript (Strict mode)
- **Styling**: Tailwind CSS v3 + shadcn/ui
- **Backend**: Firebase Admin SDK
- **Forms**: React Hook Form + Zod
- **Charts**: Recharts
- **Icons**: Lucide React
- **State**: Nuqs (URL state) + React Query (Server state)

## 🚀 Getting Started

### Prerequisites

- Node.js 18.17 or later
- Firebase project with Admin SDK credentials

### Installation

1. **Clone and install dependencies**:
```bash
npm install
```

2. **Set up environment variables**:
```bash
cp .env.local.example .env.local
```

Edit `.env.local` and add your Firebase Admin SDK credentials:
- `FIREBASE_PROJECT_ID`
- `FIREBASE_CLIENT_EMAIL`
- `FIREBASE_PRIVATE_KEY`

3. **Install shadcn/ui components** (run after npm install):
```bash
npx shadcn@latest add button input card table dropdown-menu dialog badge avatar sheet separator label toast tabs select
```

4. **Run the development server**:
```bash
npm run dev
```

Open [http://localhost:3000](http://localhost:3000) to view the dashboard.

## 📁 Project Structure

```
antitest/
├── app/
│   ├── (auth)/              # Authentication routes
│   │   ├── login/
│   │   └── layout.tsx
│   ├── (dashboard)/         # Protected dashboard routes
│   │   ├── layout.tsx       # Main dashboard layout
│   │   ├── page.tsx         # Dashboard home
│   │   ├── users/           # User management
│   │   ├── inventory/       # Food listings
│   │   ├── logistics/       # Pickups & deliveries
│   │   ├── reports/         # Analytics
│   │   └── settings/        # Settings
│   ├── api/                 # API routes
│   └── globals.css          # Global styles
├── components/
│   ├── ui/                  # shadcn/ui components
│   ├── features/            # Feature-specific components
│   └── layout/              # Layout components (Sidebar, Header)
├── lib/
│   ├── firebase/            # Firebase Admin SDK
│   ├── validations/         # Zod schemas
│   └── utils.ts             # Utility functions
├── types/
│   └── index.ts             # TypeScript types
└── middleware.ts            # Auth middleware
```

## 🔒 Authentication

The dashboard uses Firebase Admin SDK for server-side authentication. Protected routes are wrapped with middleware that validates session cookies.

## 📝 Development Guidelines

- **Server Components**: Use RSC for data fetching by default
- **Server Actions**: All mutations must use Server Actions with Zod validation
- **Error Handling**: Return `{ success: boolean, error?: string }` from all actions
- **Accessibility**: All interactive elements must have aria-labels
- **Type Safety**: Strict TypeScript mode - no implicit any

## 🧪 Available Scripts

- `npm run dev` - Start development server with Turbopack
- `npm run build` - Build for production
- `npm start` - Start production server
- `npm run lint` - Run ESLint
- `npm run type-check` - Run TypeScript compiler

## 📊 Key Modules

### User Verification
Review pending donor and NGO registrations with document preview and approval/rejection workflow.

### Live Operations
Monitor active food rescue missions with real-time status updates.

### Inventory Management
Track available food listings with filtering by dietary categories, expiration dates, and allergens.

### Impact Analytics
Visualize platform impact with charts showing meals saved, CO2 prevented, and user growth.

## 🤝 Contributing

This is an internal admin tool. For questions or issues, contact the development team.

## 📄 License

Proprietary - NoMoreWaste Internal Use Only
