# Optional background notifications

The app's Updates feed works on Firebase's free plan. This code adds background
FCM delivery and a private inbox. Deploying Cloud Functions requires a Blaze
billing account, even when usage stays within no-cost quotas. Nothing in the
build enables billing or deploys these functions.

After choosing to enable that service:

1. Run `npm ci --prefix functions`.
2. Deploy the repository's rules and `firebase deploy --only functions`.
3. Register the web VAPID public key and native APNs credentials in Firebase.
4. In ignored `web/firebase-config.local.json`, set `pushEnabled: true` and
   `webPushVapidKey` to the public VAPID key, then rebuild the apps.
5. For iOS, enable Push Notifications on the paid-team provisioning profile and
   use `app/ios/Flutter/Distribution.xcconfig` as described in the platform guide.

Messages contain generic activity descriptions and a room ID, never approved
cards or private notes. Device tokens are private to their user. Disabling push
or signing out removes this device's registration. Delivery is rate limited per
room/recipient and collapses superseded notifications. FCM delivery is best
effort; the live plan remains the source of truth.
