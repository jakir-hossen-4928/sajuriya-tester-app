Here’s a **production-ready PRD (Product Requirements Document)** for **Sajuriya Tester** in Markdown format. It is structured for clarity, development, and future scaling. You can copy it as `PRD.md` in your project folder.

---

# Sajuriya Tester - Product Requirements Document (PRD)

---

## 1. Product Overview

**Product Name:** Sajuriya Tester
**Platform:** Android (Flutter)
**Backend:** Supabase (PostgreSQL, Auth, Edge Functions)
**Purpose:**

A peer-to-peer developer ecosystem where every user is a **Developer**. The platform operates on a "Developer Karma" system: you help others test their apps to earn the right to have yours tested.

**Target Users:**

*   **Developers**: Everyone is a developer. Users review each other's apps to satisfy Play Store's 14-day requirement.
*   **Admin**: Platform managers for verification and dispute resolution.

**Branding:** Sajuriya Tester
**Primary Colors:** Blue / Indigo
**Theme:** Modern, clean, Material 3 design

---

## 2. Features & Requirements

### 2.1 User Authentication & Onboarding
* Email & Google OAuth login.
* **Mandatory Play Store Linking**: Users must sign up with the email used for their Play Store account.
* **Mandatory Setup (Step-by-Step Tutorial)**:
  Before a user can list apps OR test others, they must complete these steps in their Google Play Console:
  1. **Add Tester Group**: Add `sajuriya-tester@googlegroups.com` in the 'Testers' section of their app.
  2. **Global Availability**: Select 'All Countries' in the Countries/Regions section.
  3. **Send for Review**: Confirm changes in 'Publishing Overview' and click 'Send for review'.
  4. **Approval**: Wait for Google's approval (approx. 30-60 mins) before publishing changes.
* Users must upload proof (screenshots) of these settings to move past onboarding.

### 2.2 Developer Karma System
* **Karma Rule**: Test 3 apps → Unlock 1 App Listing slot.
* Alternatively: Earn credits through testing → Spend credits to bypass testing limits.
* All users are "Testers" and "Developers" simultaneously.

### 2.3 Verification Flow 
1. **Package Check**: App detects if the target package is installed via `device_apps`.
2. **Device ID**: Logs unique hardware fingerprint.
3. **Screenshot Proof**: Mandatory upload of the app running on device.
4. **14-Day Streak**: Automated daily check. If uninstalled before 14 days, karma/credits are revoked.

### 2.4 Profile & Settings

* Display name, role, Google email
* Reputation score
* Credits
* Logout

---

## 3. Database Schema (Core Tables)

* **users** → id, email, full_name, role, google_email, credits, reputation_score
* **apps** → id, app_name, developer_name, package_name, playstore_url, logo_url, description, reward_credits, required_test_days, status
* **test_assignments** → id, tester_id, app_id, device_id, start_date, end_date, install_status, test_status, completed
* **google_group_access** → app_id, tester_id, group_email, joined_status
* **install_verifications** → assignment_id, screenshot_url, verification_method, verification_status, verified_at
* **credit_wallet** → user_id, balance
* **credit_transactions** → user_id, amount, type, reason, reference_id, created_at
* **app_reviews** → app_id, tester_id, rating, feedback, created_at

---

## 4. App Navigation Structure

**Bottom Navigation Bar:**

1. Home (Dashboard)
2. Apps (Marketplace)
3. My Tests (Assignments)
4. Wallet (Credits)
5. Profile (User info)

**Screens:**

* Splash Screen
* Authentication (Login / Signup / Google Login)
* Dashboard
* App Marketplace
* App Details
* Post App (Developer)
* My Testingx
* Install Verification
* Credit Wallet
* Reviews / Feedback
* Profile / Settings

---

## 5. UX / UI Requirements

* Modern Material 3 theme
* Light + Dark mode support
* Card-based app list
* Progress bars for 14-day testing
* Status badges: Pending / Verified / Completed
* Clear step-by-step workflow for testers
* Simple input forms for developers posting apps
* Clean typography and rounded buttons

---

## 6. Technical Requirements

* **Flutter version:** >= 3.10
* **Dart version:** >= 3.1
* **Supabase:** Auth, Storage, Edge Functions, PostgreSQL
* **Packages:**

  * `supabase_flutter`, `flutter_riverpod`, `go_router`, `device_apps`, `url_launcher`, `image_picker`, `cached_network_image`, `flutter_dotenv`, `uuid`, `intl`, `flutter_secure_storage`, `connectivity_plus`, `package_info_plus`, `device_info_plus`, `permission_handler`, `logger`
* **Android Package Name:** `com.sajuriyaStudio.sajuriyatester`

---

## 7. Security Requirements

* Supabase Row Level Security (RLS) for all tables
* Secure storage for session tokens
* Device fingerprinting to prevent credit farming
* Only testers in Google Group can access app installation

---

## 8. Milestones / Roadmap

| Phase   | Features                                | Duration |
| ------- | --------------------------------------- | -------- |
| Phase 1 | User Auth, App Posting, App Marketplace | 1 week   |
| Phase 2 | Test Assignments, Install Verification  | 1 week   |
| Phase 3 | Credit Wallet, Transactions, Reviews    | 1 week   |
| Phase 4 | Anti-cheat, Reputation, Play Store API  | 1 week   |
| Phase 5 | Polishing UI, Theme, Dark Mode          | 3–5 days |
| Phase 6 | QA / Beta Testing                       | 1 week   |

---

## 9. Notes

* App name for display: **Sajuriya Tester**
* Short and clean app name for Play Store
* Backend fully relational (PostgreSQL) for production-grade operations
* Modular Flutter architecture for scalability

---

Google Groups Email: sajuriya-tester@googlegroups.com

tell user to sing up or sing in to same account which account are thier play store account email..and also tell user to join the google group.. JOIN THE GROUP WITH SAME email address and tell user to add this group in thier play store account app tesing group.. and set country to all countries.. .






## Verification Flow 
Flutter app checks package installed
↓
Device ID stored
↓
Screenshot proof upload
↓
Daily background check
↓
14-day completion → credits


## ⭐ Credit / Exchange System (VERY IMPORTANT)

Without this your platform dies.

Rule:

Test 3 apps → post your own app


or

Earn credits → spend credits

## 🔐 Security & Anti-Cheat

You must handle:

Fake installs

Multiple devices

Emulator usage

Instant uninstall

Solutions:

Device fingerprinting
Firebase App Check (optional)
Reputation score
Install duration tracking

## On Device App Detection (Semi Reliable)

Flutter checks if package exists.

Flutter Package
device_apps

Code logic
Check if com.app.package installed


## APP Icon size: 512x512
use imgbb api key for host image .dont use supabase storage.



app backgroudn graident: 03B8D5,6A3DE8,536DFE hex color code.