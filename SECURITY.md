# Security notes and deployment checklist

iTraceLink is a Flutter client backed by Firebase. Treat every value compiled into or bundled with the mobile app as public: app assets, Dart constants, Firebase client configuration, and values supplied through `--dart-define` can be inspected by users.

## Changes in this branch

- Firestore admin authorization uses an active record in `admins/{email}`, rather than trusting a user-editable `users/{uid}.userType` field.
- Public registration cannot assign the `admin` role and cannot create a verified profile.
- Profile self-updates are restricted to profile fields; verification and role fields are protected.
- Account profile reads are limited to the profile owner and active admins because profile records contain email and phone data.
- Order creation is restricted to the authenticated buyer, forbids self-orders, validates positive quantity/price and a pending/unpaid initial state, and checks the total against quantity × unit price (with a small rounding tolerance).
- Order updates are limited to role-specific lifecycle transitions. Buyers/sellers cannot change order parties, financial terms, delivery terms, or payment status from the client.
- Payment creation is allowed only for the authenticated buyer on an accepted order; the payee and amount must match that order and the new payment must be pending.
- Payment documents cannot be updated or deleted by mobile clients, including signed-in admins. A trusted backend using the Firebase Admin SDK must verify provider callbacks and update payment/order state.
- Transaction creation requires the authenticated account to be one of the named parties.
- Admin login diagnostics no longer print administrator document contents or reveal whether an email has an admin record.
- The default counter test that referenced a nonexistent `MyApp` widget has been replaced with model tests.
- The tracked `.env` file is removed from this branch and is not declared as a Flutter asset. The file remains in Git history and must be treated as exposed until its credentials are rotated.

## Required before production

1. **Move payment and email provider secrets to a trusted backend.** The Flutter client must not call provider APIs using long-lived API secrets. Use a server-side endpoint or Firebase Cloud Functions that authenticates the caller, validates order ownership and amount against trusted order data, and verifies provider callbacks before updating payment status.
2. **Rotate exposed credentials immediately.** A real `.env` file was tracked in the public repository. Its contents have intentionally not been reproduced here. Treat every provider credential that may have been stored in it as exposed, rotate/revoke those credentials with each provider, and review provider logs. Removing the file in this branch does not remove it from existing Git history, prior clones, or old APKs. Consider purging it from history after rotating credentials.
3. **Review admin provisioning.** Create `admins/{email}` documents only through a trusted administrator workflow; set `isActive: true` only for approved admin accounts. Do not let ordinary clients create or edit these records.
4. **Add and run Firestore Emulator Suite rule tests** before deploying. Verify owner/admin profile reads, rejected profile reads, valid and invalid order transitions, tampered totals, and denied client payment status changes.
5. **Finish the payment backend before enabling live payments.** The existing mobile payment-processing screen attempts to update payment/order status from the client; those writes are now intentionally denied. Do not treat a client-side status response as proof of payment. Implement authenticated server endpoints or Cloud Functions that verify the provider callback and then update the payment and order using the Admin SDK.
6. **Review traceability and business-collection access.** Several supply-chain collections still allow any signed-in user to read records; review the business need and limit them where appropriate.
7. **Deploy rules intentionally.** Updating `firestore.rules` in GitHub does not itself publish the rules to the Firebase project. Review and deploy the rules through your normal Firebase release process.

## Important compatibility note

Payment/email services currently read configuration through `flutter_dotenv`. With `.env` no longer bundled, those credentials will not be available in the mobile app. This is intentional until the integrations are moved to a trusted backend; do not re-add secrets as Flutter assets to restore them.