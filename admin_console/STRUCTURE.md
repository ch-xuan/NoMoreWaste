# NoMoreWaste Admin Dashboard - Updated Folder Structure (PRD-Aligned)

## ✅ Completed Files

### Configuration (Phase 1)
```
antitest/
├── package.json                    # ✅ Updated with Firebase client SDK
├── tsconfig.json                   # ✅ TypeScript strict config
├── next.config.js                  # ✅ Next.js 15 + Turbopack
├── tailwind.config.ts              # ✅ Tailwind + shadcn/ui theme
├── postcss.config.mjs              # ✅ PostCSS config
├── components.json                 # ✅ shadcn/ui config
├── .eslintrc.json                  # ✅ ESLint rules
├── .gitignore                      # ✅ Git ignore
├── .env.local.example              # ✅ Updated with client + admin SDK
├── README.md                       # ✅ Project documentation
└── STRUCTURE.md                    # This file
```

### Core Files (Phase 1)
```
antitest/
├── app/
│   ├── layout.tsx                  # ✅ Root layout
│   ├── page.tsx                    # ✅ Root page (redirects)
│   ├── globals.css                 # ✅ Global styles + CSS vars
│   └── (dashboard)/
│       ├── layout.tsx              # ✅ Basic dashboard layout
│       └── page.tsx                # ✅ Dashboard placeholder
├── lib/
│   ├── utils.ts                    # ✅ Utility functions
│   └── firebase/
│       └── admin.ts                # ✅ Firebase Admin SDK
└── types/
    └── index.ts                    # ✅ Updated PRD-aligned types
```

---

## 📋 Planned Structure (PRD-Aligned)

### Navigation Structure (8 Main Modules)

Based on PRD Admin Main Navigation:

1. **Dashboard** - Overview with widgets
2. **User Verification** - NGO/Vendor/Volunteer approvals
3. **Donations Monitoring** - Live donation lifecycle tracking
4. **Tasks & Deliveries** - Delivery tracking with volunteers
5. **Content Moderation** - Flagged content review
6. **Reports & Analytics** - System reports and exports
7. **System Settings** - Configurable rules and templates
8. **Audit Logs** - Admin action tracking

---

### Phase 2: Firebase Integration & Authentication

```
lib/
└── firebase/
    ├── admin.ts                    # ✅ Already created
    ├── client.ts                   # Firebase Web SDK init
    └── auth.ts                     # Auth helpers (custom claims)

middleware.ts                       # Next.js auth middleware

app/
└── (auth)/
    ├── layout.tsx                  # Minimal centered layout
    └── login/
        └── page.tsx                # Admin login page
```

---

### Phase 3: Core Layout & Navigation

```
components/
└── layout/
    ├── sidebar.tsx                 # PRD 8-item navigation
    ├── header.tsx                  # Breadcrumbs + user profile
    └── user-nav.tsx                # Profile dropdown with logout

app/(dashboard)/
└── layout.tsx                      # Update with Sidebar + Header
```

---

### Phase 4: Dashboard Overview

```
app/(dashboard)/
└── page.tsx                        # Dashboard with 5 widget sections

components/features/dashboard/
├── pending-verifications-card.tsx  # NGO/Vendor/Volunteer counts
├── active-donations-card.tsx       # Live donation count
├── deliveries-card.tsx             # Pickups + in-transit
├── incidents-card.tsx              # Flags with severity
└── quick-stats.tsx                 # 5 quick metrics
```

---

### Phase 5: User Verification Module

```
app/(dashboard)/verification/
├── page.tsx                        # Verification queue (all types)
├── ngos/
│   └── [id]/
│       └── page.tsx                # NGO verification detail
├── vendors/
│   └── [id]/
│       └── page.tsx                # Vendor verification detail
└── volunteers/
    └── [id]/
        └── page.tsx                # Volunteer + test approval

components/features/verification/
├── verification-queue.tsx          # Data table with filters
├── document-viewer.tsx             # PDF/image viewer
├── verification-actions.tsx        # Approve/Reject with notes
└── status-badge.tsx                # Pending/Approved/Rejected
```

---

### Phase 6: Volunteer Test Management

```
app/(dashboard)/settings/
└── tests/
    ├── page.tsx                    # Test list
    ├── [id]/
    │   └── page.tsx                # Test builder
    └── analytics/
        └── page.tsx                # Test analytics

components/features/tests/
├── test-builder.tsx                # Question editor
├── test-analytics.tsx              # Pass rates, common errors
└── test-config.tsx                 # Pass score, attempts, cooldown
```

---

### Phase 7: Donations & Activity Monitoring

```
app/(dashboard)/donations/
├── page.tsx                        # Live donations monitor
└── [id]/
    └── page.tsx                    # Donation lifecycle detail

components/features/donations/
├── donations-table.tsx             # Data table with lifecycle stages
├── donation-filters.tsx            # Filter by vendor/NGO/status
├── flag-detector.tsx               # Highlight unusual patterns
└── lifecycle-timeline.tsx          # Visual donation flow
```

---

### Phase 8: Tasks & Deliveries

```
app/(dashboard)/deliveries/
├── page.tsx                        # Delivery tracking dashboard
└── [id]/
    └── page.tsx                    # Delivery detail

components/features/deliveries/
├── delivery-table.tsx              # Active deliveries
├── delivery-map.tsx                # Real-time tracking (placeholder)
├── volunteer-tracker.tsx           # Volunteer location
└── delivery-timeline.tsx           # Pickup → in-transit → delivered
```

---

### Phase 9: Content Moderation

```
app/(dashboard)/moderation/
├── page.tsx                        # Moderation queue
└── [id]/
    └── page.tsx                    # Moderation item detail

components/features/moderation/
├── moderation-queue.tsx            # Flagged items table
├── content-preview.tsx             # Photo/text preview
├── moderation-actions.tsx          # One-click actions
└── incident-form.tsx               # Escalation form
```

---

### Phase 10: Reports & Analytics

```
app/(dashboard)/reports/
└── page.tsx                        # Reports dashboard

components/features/reports/
├── report-generator.tsx            # Report type selector
├── metrics-chart.tsx               # Recharts visualizations
├── export-buttons.tsx              # CSV/PDF export
├── ngo-fulfillment-table.tsx       # NGO performance
└── volunteer-reliability-table.tsx # Volunteer ratings
```

---

### Phase 11: System Settings & Audit Logs

```
app/(dashboard)/settings/
├── page.tsx                        # Settings overview
├── rules/
│   └── page.tsx                    # Configurable system rules
├── notifications/
│   └── page.tsx                    # Email template editor
└── tests/
    └── page.tsx                    # (see Phase 6)

app/(dashboard)/audit/
└── page.tsx                        # Audit log viewer

components/features/settings/
├── rules-form.tsx                  # Pickup window, distance, etc.
└── notification-editor.tsx         # Template editor

components/features/audit/
├── audit-log-table.tsx             # Searchable log table
└── audit-detail-dialog.tsx         # Before/after state viewer
```

---

### Phase 12: Server Actions & Validation

```
lib/
├── actions/
│   ├── verification.ts             # Approve/reject actions
│   ├── moderation.ts               # Content moderation actions
│   ├── donations.ts                # Donation management
│   ├── deliveries.ts               # Delivery management
│   ├── settings.ts                 # Settings updates
│   └── audit.ts                    # Audit logging utility
└── validations/
    ├── verification.ts             # Zod schemas for verification
    ├── moderation.ts               # Zod schemas for moderation
    ├── donation.ts                 # Zod schemas for donations
    ├── delivery.ts                 # Zod schemas for deliveries
    └── settings.ts                 # Zod schemas for settings
```

---

## 🔐 Security Implementation

### Custom Claims Flow

1. **Admin User Creation**:
   - Create user in Firebase Auth
   - Run one-time Cloud Function to set custom claims:
     ```typescript
     {
       role: 'admin',
       verified: true
     }
     ```

2. **Middleware Enforcement**:
   - Check session cookie
   - Verify custom claims server-side
   - Redirect non-admins

3. **Server Action Security**:
   - Every action verifies admin role
   - Audit logs for all admin actions
   - IP address logging

---

## 📦 shadcn/ui Components Required

Install after `npm install`:

```bash
npx shadcn@latest add button input card table dropdown-menu dialog badge avatar sheet separator label toast tabs select
```

Additional components for specific features:
- Form components for settings/moderation
- Data table components for queues
- Alert components for confirmations

---

## 🔑 Environment Setup

1. Copy `.env.local.example` to `.env.local`
2. Fill in Firebase config from Firebase Console:
   - Web app config for client SDK (NEXT_PUBLIC_* vars)
   - Service account for admin SDK (already provided)
3. Add your private key manually (not in repo)

---

## 📊 Firestore Collections (Expected)

The dashboard will read from these collections:

```
users/
  {userId}/
    - role: 'vendor' | 'ngo' | 'volunteer' | 'admin'
    - verificationStatus: 'pending' | 'approved' | 'rejected'
    - verificationDocuments: []
    - stats: {}

donations/
  {donationId}/
    - vendorId
    - status
    - moderationStatus
    - ...

deliveries/
  {deliveryId}/
    - donationId
    - volunteerId
    - status
    - ...

moderationItems/
  {itemId}/
    - type
    - targetId
    - status
    - ...

incidents/
  {incidentId}/
    - type
    - severity
    - userId
    - ...

auditLogs/
  {logId}/
    - adminId
    - action
    - timestamp
    - ...

systemSettings/
  config/
    - maxPickupWindowHours
    - volunteerDistanceRadiusKm
    - ...

volunteerTests/
  {testId}/
    - questions: []
    - passScore
    - ...
```

---

## 🚀 Next Steps

After reviewing this structure:

1. **Confirm approval** to proceed with implementation
2. **Phase 2**: Set up Firebase client SDK and authentication
3. **Phase 3**: Build sidebar and header components
4. **Phase 4**: Implement dashboard overview
5. **Continue through phases** as outlined above

---

## ⚠️ Important Notes

> **Custom Claims**: Must be set via Cloud Functions (server-side only)

> **Audit Logging**: Every admin action must create an audit log entry

> **Security Rules**: Firestore rules must enforce role-based access

> **Document Storage**: Use base64 or Firebase Storage (not specified in PRD)
