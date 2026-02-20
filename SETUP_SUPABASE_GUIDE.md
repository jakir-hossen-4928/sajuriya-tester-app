# Supabase Configuration Guide

To ensure the application functions correctly with the recently updated security policies and email verification requirements, please perform the following steps in your Supabase Dashboard.

## 1. Apply Database Changes
Run the updated SQL from `supabase/migrations/master_setup_script.sql` in your **Supabase SQL Editor**. (Note: The script has been updated to handle existing policies, so you can safely re-run it even if policies already exist). This will:
- Enable proper RLS policies and handle cleanup of old ones.
- Hide sensitive columns from unauthorized updates.
- Ensure the `on_auth_user_created` trigger handles profile management.

## 2. Authentication Settings
Go to **Authentication > Settings**:
- **Confirm email**: Ensure this is **Enabled**.
- **Secure password change**: Recommended **Enabled**.

## 3. Email Templates
Go to **Authentication > Email Templates** and update the **Confirm signup** template:

### Confirm Signup Template
**Subject**: `Verify your email for Sajuriya Tester`

**Body (HTML)**:
```html
<div style="font-family: sans-serif; padding: 20px; color: #333;">
  <h2 style="color: #4F46E5;">Welcome to Sajuriya Tester!</h2>
  <p>Hello,</p>
  <p>Thank you for joining our community. We're excited to have you on board.</p>
  <p>Please click the button below to verify your email address and activate your account:</p>
  <div style="margin: 30px 0;">
    <a href="{{ .ConfirmationURL }}" 
       style="background-color: #4F46E5; color: white; padding: 12px 24px; border-radius: 8px; text-decoration: none; font-weight: bold;">
       Verify My Email
    </a>
  </div>
  <p>If the button doesn't work, copy and paste this URL into your browser:</p>
  <p style="color: #666; font-size: 12px;">{{ .ConfirmationURL }}</p>
  <p>Once verified, you'll be able to access the marketplace and start testing apps.</p>
  <br/>
  <p>Best regards,<br/>The Sajuriya Team</p>
</div>
```

### Reset Password Template
**Subject**: `Reset your Sajuriya Tester password`

**Body (HTML)**:
```html
<div style="font-family: sans-serif; padding: 20px; color: #333;">
  <h2 style="color: #4F46E5;">Password Reset Request</h2>
  <p>Hello,</p>
  <p>We received a request to reset the password for your Sajuriya Tester account.</p>
  <p>If you didn't make this request, you can safely ignore this email. Otherwise, click the button below to choose a new password:</p>
  <div style="margin: 30px 0;">
    <a href="{{ .ConfirmationURL }}" 
       style="background-color: #4F46E5; color: white; padding: 12px 24px; border-radius: 8px; text-decoration: none; font-weight: bold;">
       Reset My Password
    </a>
  </div>
  <p>If the button doesn't work, copy and paste this URL into your browser:</p>
  <p style="color: #666; font-size: 12px;">{{ .ConfirmationURL }}</p>
  <br/>
  <p>Best regards,<br/>The Sajuriya Team</p>
</div>
```


## 5. Email Template Variables Reference
Supabase provides the following variables you can use to customize your emails:

| Variable | Description | Recommended Use |
| :--- | :--- | :--- |
| `{{ .ConfirmationURL }}` | The full verification/reset link. | Main action buttons (`<a>` tags). |
| `{{ .Token }}` | The 6-digit numeric OTP code. | Manual entry fallback for mobile apps. |
| `{{ .Email }}` | The user's email address. | Verifying the identity in text. |
| `{{ .Data.key }}` | Custom metadata (e.g., `.full_name`). | Personalized greetings. |
| `{{ .SiteURL }}` | Your configured Site URL. | Footer information. |
| `{{ .TokenHash }}` | Hashed version of the token. | Advanced routing (rarely needed for mobile). |
| `{{ .RedirectTo }}` | The destination URL after success. | Troubleshooting/Debug info. |

---

### Pro Tip for Mobile:
Always include both the `{{ .ConfirmationURL }}` (as a button) and the `{{ .Token }}` (as a fallback). This ensures your users can always verify their account even if deep-linking is blocked by their email provider.

