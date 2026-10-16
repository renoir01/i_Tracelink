# Security notes and deployment checklist

iTraceLink is a Flutter client backed by Firebase. Treat every value compiled into or bundled with the mobile app as public: app assets, Dart constants, Firebase client configuration, and values supplied through `--dart-define` can be inspected by users.

## Changes in this branch

- Firestore admin authorization uses an active record in `admins/{email}`, rather than trusting a user-editable `users/{uid}.userType` field.
- Public registration cannot assign the `admin` role and cannot create a verified profile.
- Profile self-updates are restricted to profile fields; verification and role fields are protected.
- Order creation requires the authenticated account to be the buyer and forbids self-orders.
- Transaction creation requires the authenticated account to be one of the named parties.
- Payment creation requires the authenticated account to be the payer and a positive amount.
- Admin login diagnostics no longer print administrator document contents or reveal whether an email has an admin record.
- The default counter test that referenced a nonexistent `MyApp` widget has been replaced with model tests.
- The tracked `.env` file is removed from this branch and is not declared as a Flutter asset. The file remains in Git history and must be treated as exposed until its credentials are rotated.

## Required before production

1. **Move payment and email provider secrets to a trusted backend.** The Flutter client must not call provider APIs using long-lived API secrets. Use a server-side endpoint or Firebase Cloud Functions that authenticates the caller, validates order ownership and amount against trusted order data, and verifies provider callbacks before updating payment status.
2. **Rotate exposed credentials immediately.** A real `.env` file was tracked in the public repository. Its contents have intentionally not been reproduced here. Treat every provider credential that may have been stored in it as exposed, rotate/revoke those credentials with each provider, and review provider logs. Removing the file in this branch does not remove it from existing Git history, prior clones, or old APKs. Consider purging it from history after rotating credentials.
3. **Review admin provisioning.** Create `admins/{email}` documents only through a trusted administrator workflow; set `isActive: true` only for approved admin accounts. Do not let ordinary clients create or edit these records.
4. **Test Firestore rules in the Firebase Emulator Suite** before deploying. In particular, verify every order, notification, certification, and traceability workflow against the rules and confirm the app does not depend on client-side payment-status updates.
5. **Review privacy access.** The current app permits authenticated users to read user profiles and several traceability collections. Decide which profile fields and traceability records should be visible to each actor and narrow read access where possible.
6. **Deploy rules intentionally.** Updating `firestore.rules` in GitHub does not itself publish the rules to the Firebase project. Review and deploy the rules through your normal Firebase release process.

## Important compatibility note

Payment/email services currently read configuration through `flutter_dotenv`. With `.env` no longer bundled, those credentials will not be available in the mobile app. This is intentional until the integrations are moved to a trusted backend; do not re-add secrets as Flutter assets to restore them.