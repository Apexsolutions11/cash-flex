# Cash Flex Backend - Vercel Deployment

## ✅ Deployment Status

**Deployed Successfully!**

- **Production URL**: https://servercashflex.vercel.app
- **Project**: server_cashflex
- **Account**: spideyy78
- **Deployment Date**: January 25, 2026

## 🔧 Configured Cron Jobs (Vercel)

The following daily cron jobs are configured in `vercel.json` and will run automatically:

1. **Reset Leaderboard** - Runs daily at 12:29 PM UTC (5:59 PM IST)
   - Path: `/api/cron/reset-leaderboard`
   - Schedule: `29 12 * * *`

2. **Reset Payout Count** - Runs daily at 12:29 PM UTC (5:59 PM IST)
   - Path: `/api/cron/reset-payout-count`
   - Schedule: `29 12 * * *`

3. **Reset Daily Game Count** - Runs daily at 12:29 PM UTC (5:59 PM IST)
   - Path: `/api/cron/reset-daily-game-count`
   - Schedule: `29 12 * * *`

## ⚠️ Cron Jobs Requiring External Setup

Due to Vercel Hobby plan limitations (only daily cron jobs supported), the following cron jobs need to be set up using external services:

### Option 1: GitHub Actions (Recommended - Free)

Create GitHub Actions workflows to call these endpoints:

1. **Fix Source** - Every 6 hours
   - Path: `/api/cron/fix-source`
   - Schedule: `0 */6 * * *`
   - Requires: `CRON_SECRET` in Authorization header

2. **Get Xoxoday Payment Status** - Every 6 hours
   - Path: `/api/cron/get-xoxoday-payment-status`
   - Schedule: `0 */6 * * *`
   - Requires: `CRON_SECRET` in Authorization header

3. **Get Cashfree Payment Status** - Every 30 minutes
   - Path: `/api/cron/get-cashfree-payment-status`
   - Schedule: `*/30 * * * *`
   - Requires: `CRON_SECRET` in Authorization header

4. **Send Promo Notification** - Every 7 hours
   - Path: `/api/cron/send-promo-notification`
   - Schedule: `0 */7 * * *`
   - Requires: `CRON_SECRET` in Authorization header

5. **Process Scheduled Notifications** - Every minute
   - Path: `/api/cron/process-scheduled-notifications`
   - Schedule: `* * * * *`
   - Requires: `CRON_SECRET` in Authorization header

### Option 2: Upgrade to Vercel Pro

Upgrade to Vercel Pro plan to enable all cron job schedules directly in Vercel.

## 🔐 Required Environment Variables

**IMPORTANT**: Set these environment variables in Vercel Dashboard:

1. Go to: https://vercel.com/spideyy78s-projects/server_cashflex/settings/environment-variables

2. Add the following variables:

### Firebase Configuration
```
FIREBASE_SERVICE_ACCOUNT='{"type":"service_account","project_id":"cash-flex-3b6d3",...}'
```
- Download service account JSON from Firebase Console
- Convert to single line: `cat service-account-key.json | jq -c`
- Paste as value (wrap in single quotes)

### API Keys
```
SECURE_KEY=your-secure-key
IP_KEY=your-ip-api-key
PAYOUT_KEY=your-payout-key
ADJOE_KEY=your-adjoe-key
MYSTERY_KEY=your-mystery-key
ADMIN_EMAIL=your-admin-email
```

### Cron Secret (Required for external cron services)
```
CRON_SECRET=your-cron-secret
```
- Generate with: `openssl rand -base64 32`
- Use the same value in GitHub Actions secrets if using GitHub Actions

## 📝 Next Steps

1. **Set Environment Variables**
   - Add all required environment variables in Vercel Dashboard
   - Redeploy after adding variables: `vercel --prod`

2. **Set Up External Cron Jobs** (if needed)
   - Use GitHub Actions, cron-job.org, or similar service
   - Configure to POST to cron endpoints with `Authorization: Bearer <CRON_SECRET>` header

3. **Verify Deployment**
   - Test API endpoints: https://servercashflex.vercel.app/api/get-server-time
   - Check cron jobs in Vercel Dashboard → Crons tab

4. **Update App Configuration**
   - Update `backendApiUrl` in Flutter app to: `https://servercashflex.vercel.app/api`

## 🔗 Useful Links

- **Vercel Dashboard**: https://vercel.com/spideyy78s-projects/server_cashflex
- **Deployment Logs**: https://vercel.com/spideyy78s-projects/server_cashflex/BvunEmwiABjUVzVd4Stutzw4JZvx
- **Environment Variables**: https://vercel.com/spideyy78s-projects/server_cashflex/settings/environment-variables
- **Cron Jobs**: https://vercel.com/spideyy78s-projects/server_cashflex/settings/crons

## 📚 API Documentation

See `README.md` for complete API endpoint documentation.
