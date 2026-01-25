# GrabReward Backend API

This is a Next.js API server that replaces the Firebase Cloud Functions from `grabreward_backend`.

## Setup

1. Install dependencies:
```bash
npm install
```

2. Create a `.env.local` file with the following variables:
```env
# Firebase Admin SDK Configuration
# Store the entire service account JSON as a single-line string
# Download the service account JSON from Firebase Console (Project Settings > Service Accounts > Generate new private key)
# Then convert it to a single line. You can:
# - Use an online JSON minifier
# - Or use this command: cat service-account-key.json | jq -c
# - Or manually remove all newlines (keep \n in the private_key field)
FIREBASE_SERVICE_ACCOUNT='{"type":"service_account","project_id":"your-project-id","private_key_id":"...","private_key":"-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n","client_email":"firebase-adminsdk-xxxxx@your-project-id.iam.gserviceaccount.com",...}'

# API Keys
SECURE_KEY=your-secure-key
IP_KEY=your-ip-api-key
PAYOUT_KEY=your-payout-key
ADJOE_KEY=your-adjoe-key
MYSTERY_KEY=your-mystery-key
ADMIN_EMAIL=your-admin-email

# Cron Secret (for protecting cron endpoints)
CRON_SECRET=your-cron-secret
```

**Quick way to get FIREBASE_SERVICE_ACCOUNT value:**
1. Download the service account JSON file from Firebase Console
2. Run this command to convert it to a single line:
   ```bash
   cat path/to/your-service-account-key.json | jq -c
   ```
3. Copy the output and paste it as the value for `FIREBASE_SERVICE_ACCOUNT` (wrap in single quotes)

3. Run the development server:
```bash
npm run dev
```

## API Routes

### User Endpoints (Require Authentication)

All user endpoints require a Firebase Auth token in the `Authorization` header:
```
Authorization: Bearer <firebase-id-token>
```

- `GET /api/get-server-time` - Get server time and leaderboard time left
- `POST /api/authenticate-user` - Authenticate user and track IP
- `POST /api/claim-coins` - Claim coins from games
- `POST /api/claim-energy` - Claim energy
- `POST /api/request-payout` - Request a payout
- `POST /api/follow-reward` - Claim reward for following social media
- `POST /api/review-task-reward` - Claim reward for review task
- `POST /api/rating-reward` - Claim reward for app rating
- `POST /api/credit-signup-bonus` - Credit signup bonus
- `POST /api/set-referral` - Set referral code

### Postback Endpoints (Public)

- `GET /api/postback/adjoe` - Adjoe postback handler
- `POST /api/postback/special-reward` - Special reward postback
- `POST /api/postback/mystery-app` - Mystery app postback
- `POST /api/postback/read-earn` - Read & Earn postback
- `POST /api/postback/promotion-apps` - Promotion apps postback (app1, app2, app3, app4)

### Cron Endpoints (Protected)

All cron endpoints require a `CRON_SECRET` in the `Authorization` header:
```
Authorization: Bearer <CRON_SECRET>
```

These endpoints should be called by a cron service (e.g., Vercel Cron, GitHub Actions, or a dedicated cron service):

- `POST /api/cron/reset-leaderboard` - Reset leaderboard (runs daily at 5:59 PM IST)
- `POST /api/cron/reset-payout-count` - Reset daily payout count (runs daily at 5:59 PM IST)
- `POST /api/cron/reset-daily-game-count` - Reset daily game count (runs daily at 5:59 PM IST)
- `POST /api/cron/fix-source` - Fix user source attribution (runs every 6 hours)
- `POST /api/cron/get-xoxoday-payment-status` - Check xoxoday payment status (runs every 6 hours)
- `POST /api/cron/get-cashfree-payment-status` - Check cashfree payment status (runs every 30 minutes)
- `POST /api/cron/send-promo-notification` - Send promo notification (runs every 419 minutes)
- `POST /api/cron/process-scheduled-notifications` - Process scheduled notifications (should run every minute for accurate timing)
- `POST /api/cron/on-app-data-change` - Handle app data changes

## Migration Notes

### Changes from Firebase Functions

1. **Authentication**: Instead of `context.auth`, use the `verifyAuth` middleware which verifies Firebase ID tokens from the `Authorization` header.

2. **HTTP Methods**: 
   - Firebase `onCall` functions → `POST` requests
   - Firebase `onRequest` functions → `GET` or `POST` requests based on the original implementation

3. **Scheduled Functions**: Converted to cron endpoints that can be called by external cron services. You'll need to set up cron jobs to call these endpoints at the specified intervals.

4. **IP Address**: Use `getRequestIpAddress` helper instead of `context.rawRequest.headers`.

5. **Environment Variables**: All Firebase Functions config values are now environment variables.

## Setting Up Cron Jobs

You can use any cron service to call the cron endpoints. Here are some options:

### Option 1: Vercel Cron (Recommended if deploying to Vercel)

1. **The `vercel.json` file is already configured** with all cron jobs. The cron schedule is set to UTC time.

2. **Important**: The original Firebase Functions ran at IST (UTC+5:30). The Vercel cron jobs are configured as:
   - **Daily resets** (leaderboard, payout count, daily game count): `29 12 * * *` (12:29 PM UTC = 5:59 PM IST)
   - **Every 6 hours** (fix source, xoxoday payment status): `0 */6 * * *`
   - **Every 30 minutes** (cashfree payment status): `*/30 * * * *`
   - **Every 7 hours** (promo notification): `0 */7 * * *` (approximately every 419 minutes)

3. **Set up environment variables** in Vercel:
   - Go to your Vercel project settings
   - Navigate to "Environment Variables"
   - Add all required environment variables including:
     - `FIREBASE_SERVICE_ACCOUNT` (your Firebase service account JSON as a single-line string)
     - `CRON_SECRET` (**REQUIRED if using GitHub Actions or external cron services** - generate with `openssl rand -base64 32`)
     - All other API keys (SECURE_KEY, IP_KEY, etc.)

   **Important**: If you're using GitHub Actions for cron jobs, make sure `CRON_SECRET` is set to the **exact same value** in both:
   - Vercel environment variables (for the API to verify)
   - GitHub Secrets (for GitHub Actions to send)

4. **Deploy to Vercel**:
   ```bash
   vercel --prod
   ```

5. **Verify cron jobs are active**:
   - Go to your Vercel project dashboard
   - Navigate to "Crons" tab
   - You should see all configured cron jobs listed
   - Click on each cron job to see execution history and logs

**Note**: The cron route handlers automatically support both:
- **Vercel Cron**: Detects the `x-vercel-cron: 1` header that Vercel automatically adds
- **Custom CRON_SECRET**: For external cron services, use `Authorization: Bearer <CRON_SECRET>` header

This means Vercel Cron will work automatically without needing to set up CRON_SECRET, but you can still use CRON_SECRET for external cron services if needed.

### Option 2: GitHub Actions

To set up GitHub Actions for cron jobs:

1. **Set up GitHub Secrets**:
   - Go to your GitHub repository
   - Navigate to Settings → Secrets and variables → Actions
   - Add the following secrets:
     - `API_URL`: Your API base URL (e.g., `https://your-app.vercel.app` or `https://api.yourdomain.com`)
     - `CRON_SECRET`: Your cron secret (generate with `openssl rand -base64 32`)

2. **Set the same CRON_SECRET in Vercel** (CRITICAL):
   - Go to your Vercel project settings
   - Navigate to "Environment Variables"
   - Add `CRON_SECRET` with the **exact same value** as in GitHub Secrets
   - This is required - the API needs to verify the secret that GitHub Actions sends
   - Redeploy after adding the environment variable

3. **Create workflow files** (if not already created):
   - Create `.github/workflows/cron-daily.yml` for daily jobs
   - Create `.github/workflows/cron-6hours.yml` for 6-hour jobs
   - Create `.github/workflows/cron-30minutes.yml` for 30-minute jobs
   - Create `.github/workflows/cron-7hours.yml` for 7-hour jobs

4. **Enable GitHub Actions**:
   - The workflows will automatically run on the scheduled times
   - You can also manually trigger them from the Actions tab

**Troubleshooting 401 Errors**:
- ✅ **Most common issue**: `CRON_SECRET` not set in Vercel environment variables
- ✅ Verify `CRON_SECRET` is set in **both** GitHub Secrets and Vercel (must be identical)
- ✅ Ensure no extra spaces or line breaks in the secret value
- ✅ Check Vercel function logs for authentication failure details
- ✅ Verify `API_URL` in GitHub Secrets is correct (no trailing slash)
- ✅ After adding `CRON_SECRET` to Vercel, **redeploy** your application

**Note**: GitHub Actions is free for public repositories. For private repositories, you get 2,000 minutes/month on the free tier.

### Option 3: External Cron Service

Use services like cron-job.org, EasyCron, or similar:
- Configure them to POST to your cron endpoints
- Set the `Authorization: Bearer <CRON_SECRET>` header
- Set the schedule according to your needs

## Deployment

1. Build the project:
```bash
npm run build
```

2. Start the production server:
```bash
npm start
```

Or deploy to a platform like Vercel, Railway, or your preferred hosting service.
