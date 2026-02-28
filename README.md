# NoMoreWaste
### Where Surplus Finds Purpose.

**NoMoreWaste** is a digital platform designed to reduce food waste and combat hunger by enabling the efficient redistribution of surplus food to communities in need. 
The platform connects key stakeholders within the food ecosystem to ensure that excess food is safely redirected instead of discarded. 
By streamlining transparent and accountable food sharing processes, NoMoreWaste promotes sustainability, strengthens community collaboration, and creates measurable social impact. 
The solution actively supports SDG 1 (No Poverty), SDG 2 (Zero Hunger), and SDG 12 (Responsible Consumption and Production) by addressing food insecurity while reducing environmental waste.

# Technical Architecture

The app follows a three-tier architecture:

**Frontend**
- Built with **Flutter** for cross-platform support (Android & iOS)
- Dedicated interfaces for Vendors, NGOs, and Volunteers
- Admin dashboard built using **Next.js**
- Core screens include:
  - Food listings
  - Donation submission
  - Delivery task management
  - Admin verification & monitoring

**Backend & Database**
- **Firebase Firestore** for real-time data storage (users, food listings, delivery tasks)
- **Firebase Authentication** for secure login and role-based access control

**AI Inplementation** 
- Gemini API auto-generates friendly and engaging food donation descriptions which helps vendors save time and improve listing quality and also enhances clarity to attract NGOs more effectively
- AI-powered recommendation system suggests relevant food listings to NGOs based on their needs and past selections, improving matching efficiency and reducing response time

# Implementation Details
### User Roles
Vendor, NGO, Volunteer, and Admin

### Food Listing
- Vendors initiate the process by posting surplus food listings, providing essential details such as item descriptions, quantities, and expiry dates to ensure transparency and safety.

### NGO Selection
- NGOs then browse available donations within the platform, selecting suitable items based on their needs and choosing either  self-pickup or delivery options.

### Volunteer Delivery
- volunteers can accept available tasks and transport food directly from vendors to NGOs, ensuring efficient and timely redistribution.

### Admin Controls
- Admin maintain platform integrity and trust where administrators verify vendors and NGOs, monitor active listings, and remove any inappropriate or unsafe content.

# Technology Stack:
**Frontend**
- Flutter (Mobile App)
- Next.js (Admin Dashboard)

**Backend**
- Firebase Firestore
- Firebase Authentication

**AI Integration**
- Gemini API (Automated Description Generation)

# Challenges Faced
- **Real-Time Synchronization**  
  Ensuring listings, delivery tasks, and notifications update instantly.
- **AI Reliability**  
  Preventing irrelevant or incorrect generated descriptions.
- **Building User Trust**  
  Verifying NGOs while maintaining a smooth onboarding process.

# Future Roadmap
NoMoreWaste aims to enhance transparency, efficiency, and long-term engagement within the platform. We plan to introduce a **GPS-based real-time delivery tracking system** to improve accountability and ensure safe, timely food transfers between vendors and NGOs. 
To strengthen trust and reduce manual verification efforts which we will implement **AI-assisted verification for NGOs and donation listings**  which can improve reliability and preventing misuse. Additionally, an **analytics dashboard** will provide actionable insights for vendors and administrators, enabling them to track donation impact, volunteer participation, and overall community contribution. To sustain user motivation and platform growth, we will introduce a **gamified reward system** that recognizes and incentivizes volunteers and vendors for their contributions which can foster a stronger and more engaged food redistribution ecosystem.
