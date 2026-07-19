# Customer Order Tracking — EmberCore

Last updated: 2026-07-19  
Status: **MVP implemented**

Public, token-based order tracking for Delivery and Pick Up orders (not Retail). Staff can auto-open or manually send a WhatsApp short link; customers see a safe status page with no prices.

## Decisions

| # | Topic | Decision |
|---|--------|----------|
| 1 | Lookup | **Both**: Order ID + phone last 4, **and** WhatsApp short link (`?t=` token) |
| 2 | Visible fields | Status; delivery/pickup date & time slot; masked recipient; proof photos. **No amount / price** |
| 3 | Languages | **EN + ZH + MS** (public page + staff `track.*` strings) |
| 4 | Link send | **Delivery:** auto when `out_of_delivery`. **Pick Up:** auto when Ready for Pickup (`ready_to_delivery`) |
| 5 | Order types | **Delivery + Pick Up** (not Retail) |
| 6 | Branding | Company name + logo from company profile |
| 7 | Recipient name | **Masked** (e.g. `Ali***`) |
| 8 | WhatsApp channel | Staff **device / `wa.me`** (not Meta Business API) |
| 9 | Bulk status update | **No** auto WhatsApp (avoids opening N windows) |

## What is implemented (MVP)

1. **Public page** — `web/track/index.html` at `/track` (token auto-lookup or form)
2. **Cloud Function** — `getOrderTracking` HTTPS POST/GET with CORS; safe payload only
3. **Token store** — `order_tracking_tokens/{token}` + `orders.tracking_token`
4. **Staff helpers** — `lib/backend/order_tracking_helpers.dart` (ensure token, WhatsApp launch, auto-send gates)
5. **Auto WhatsApp** after single-order status change:
   - `UpdateOrderStatusWidget`
   - `DriverDeliveryOrderCard` (`out_of_delivery`)
   - `OrderMoreActionSheetWidget` (wired after status updates; cancel does not match auto-send rules)
6. **Manual send** — Order detail More menu → “Send tracking link” (trackable orders only)
7. **Hosting rewrite** — `/track` and `/track/**` → `/track/index.html` before SPA fallback
8. **i18n** — `lib/l10n/strings/track_strings.dart`

## Endpoints

| Environment | Hosting | Function |
|-------------|---------|----------|
| Production | `https://embercore-erp.web.app/track` | `https://asia-southeast1-embercore-erp.cloudfunctions.net/getOrderTracking` |
| Staging | `https://embercore-erp-staging.web.app/track` | `https://asia-southeast1-embercore-erp-staging.cloudfunctions.net/getOrderTracking` |

The public page picks staging vs production from the hostname (`embercore-erp-staging` → staging CF; otherwise production).

### Request body (POST JSON)

```json
{ "token": "…" }
```

or

```json
{ "orderId": "ORD-…", "phoneLast4": "4567" }
```

### Safe response fields

`orderId`, `status`, `isPickup`, `deliveryDate`, `deliveryTimeSlot`, `recipientNameMasked`, `proofUrls`, `companyName`, `companyLogoUrl`

## Status labels (public page)

| Raw status | Delivery | Pick Up |
|------------|----------|---------|
| `ready_to_delivery` | Ready to Ship | Ready for Pickup |
| `out_of_delivery` | Out for Delivery | Out for Delivery |
| `completed` | Completed | Picked Up |

## Deploy notes

1. `flutter build web` copies `web/` (including `web/track/`) into `build/web/`.
2. Deploy scripts copy `build/web/*` → `firebase/public/` (so `/track/index.html` is included).
3. Deploy hosting + functions as needed:

```bash
# from repo root
flutter build web --release
# copy build/web → firebase/public (see scripts/deploy_*.ps1)
cd firebase
npm run deploy:hosting:staging   # or production
# deploy functions when getOrderTracking changes
```

Firebase hosting rewrites in `firebase/firebase.json` serve `/track` and `/track/**` to `/track/index.html` **before** the SPA `**` → `/index.html` rule.

## Key files

| Area | Path |
|------|------|
| Public UI | `web/track/index.html` |
| CF helpers | `firebase/functions/order_tracking.js` |
| CF HTTP | `firebase/functions/order_tracking_http.js` |
| Dart helpers | `lib/backend/order_tracking_helpers.dart` |
| Dart client | `lib/backend/order_tracking_service.dart` |
| Staff i18n | `lib/l10n/strings/track_strings.dart` |
| Tests | `firebase/test/order_tracking.test.js`, `test/order_tracking_helpers_test.dart` |

## Open points (confirm later)

1. Short-link TTL / revoke after N days?
2. Company subdomain vs shared `/track` path?
3. Optional upgrade to WhatsApp Business API for unattended sends?
4. Rate limiting / abuse protection on `getOrderTracking`?

## Non-goals (this phase)

- Customer self-order / cart / payment  
- Live driver GPS map  
- Customer edit/cancel order  
- Discount voucher portal  
