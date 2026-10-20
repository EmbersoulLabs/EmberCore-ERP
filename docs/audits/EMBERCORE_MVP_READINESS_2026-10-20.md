# EmberCore MVP Release Readiness Audit — 2026-10-20

## Executive decision

**Audit result: PARTIAL. EmberCore is not ready for private beta, public SaaS registration, real paid launch, or multi-business production operation.**

The core ERP is substantially implemented and already operating on Firebase. PR #3 contains a credible, tested SaaS Phase 2 implementation for registration approval, 14-day trials, three paid plans, monthly quotas, Stripe webhook idempotency, and plan enforcement. It is, however, still a draft PR and is not deployed as one coherent release. More importantly, both `main` and PR #3 contain release-critical authorization defects: authenticated staff can read every tenant's user profiles, tenant admins can delete other tenants' orders, all active company documents are readable without authentication, and sensitive Storage objects (delivery proofs and invoice payment proofs) are publicly readable. Several Storage write paths also lack tenant binding.

Production is live but split across revisions: Hosting was last modified on 2026-10-12, the three Stripe functions were updated on 2026-10-17 at 08:47 UTC, and most other Functions date from 2026-06-27. The deployed Stripe archive could not be downloaded with the available account, so its exact source revision cannot be proven. Production has live-mode Stripe configuration and 18 Price configuration keys, but this audit performed no real transaction and found no dashboard/account evidence proving webhook endpoint health, portal configuration, tax behavior, or live lifecycle completion.

No Firestore backups or backup schedules exist. A Firestore ruleset rollback helper exists, but no complete application/data restoration rehearsal is evidenced.

## Audit identity and boundaries

| Item | Evidence |
|---|---|
| Repository | `EmbersoulLabs/EmberCore-ERP` |
| Evidence date | 2026-10-20, Asia/Singapore |
| Audited remote `main` | `92d140141c73f9b0f64d1cf54bc849ca504c16f6` |
| Audited PR #3 head / local HEAD | `d9392afcd73ee8d70fc8efb3371f744ce7e1f94b` |
| PR #3 base | `92d140141c73f9b0f64d1cf54bc849ca504c16f6` |
| PR state | Open, draft, mergeable, clean merge state |
| PR latest CI | GitHub Actions runs `39022310539` (pull request) and `39022307085` (push), both successful at `d9392af...` |
| Production modification by this audit | None |
| PR merged by this audit | No |
| Deployment performed by this audit | No |

The working tree already contained unrelated local modifications before this report was created, including launcher images, `firebase/package.json`, `firebase/firestore-debug.log`, `lib/backend/order_status_helpers.dart`, and `test/order_id_service_test.dart`. They were preserved and are not treated as audited commit content.

## Evidence model and implementation-state definitions

- **Implemented and deployed**: executable implementation exists and a production inventory or runtime record confirms deployment.
- **Implemented but not deployed**: executable implementation exists at the PR SHA, but production evidence predates or omits it.
- **Partially implemented**: a meaningful path exists, but required behavior, enforcement, or verification is incomplete.
- **Not implemented**: required behavior has no implementation evidence.
- **Unable to verify**: source or runtime evidence was unavailable or could not be tied to an exact revision.

# Overall Progress

Architecture: 75%

Backend: 82%

Frontend: 82%

Database: 70%

Authentication: 70%

AI Workflow: Excluded — not part of the documented EmberCore launch scope

Marketing Workflow: Excluded — not part of the documented EmberCore launch scope

Story Workflow: Excluded — not part of the documented EmberCore launch scope

Video Workflow: Excluded — not part of the documented EmberCore launch scope

Animation Workflow: Excluded — not part of the documented EmberCore launch scope

Provider Adapter: 75% (Stripe and Shopify only)

Billing: 70%

Testing: 78%

Deployment: 45%

Documentation: 75%

**MVP completion: 66%. Evidence confidence: High for repository and GitHub CI; Medium for production deployment; Low for live Stripe behavior and disaster recovery.** AI, marketing, story, video, and animation categories are excluded because the approved EmberCore MVP documents do not require them. Their absence does not reduce the MVP score.

## Explicit weighted MVP rubric

Capability scores use the required scale: `1.0 = verified complete and connected`, `0.5 = partial/incompletely connected`, `0.0 = missing, contradicted, or blocked`. No capability below is excluded.

| Category | Weight | Capability breakdown | Score | Earned |
|---|---:|---|---:|---:|
| Identity and provisioning | 10 | Login/registration 3×1.0; server-owned approval/provisioning 4×1.0; staff role boundary 3×0.5 | 0.85 | 8.5 |
| Tenant security | 20 | Firestore tenant isolation 10×0.0; Storage isolation 5×0.0; privilege/server authorization 5×0.5 | 0.125 | 2.5 |
| Core ERP operations | 20 | Products 3; orders 5; POS 3; receipts 3; delivery 3; search/filter 3 — all 1.0 | 1.0 | 20.0 |
| Optional launch integrations | 5 | Shopify 2.5×1.0; WhatsApp 2.5×1.0 | 1.0 | 5.0 |
| Billing and subscriptions | 20 | Checkout/catalog 4×1.0; customer/tenant mapping 3×1.0; signature/idempotency 4×1.0; lifecycle 4×0.5; trial/plan enforcement 3×1.0; live verification 2×0.5 | 0.85 | 17.0 |
| Reliability and integrity | 10 | Concurrent quota/duplicate handling 4×1.0; error recovery 3×0.5; release-critical test coverage 3×0.5 | 0.70 | 7.0 |
| Production operations | 15 | deployed parity 5×0.5; CI/artifacts 3×0.5; backup/restore 4×0.0; rollback 3×0.5 | 0.367 | 5.5 |
| **Total** | **100** | **65.5 / 100, rounded to nearest whole percent** |  | **66%** |

This is measured completion against the stated MVP capabilities, not a file-count estimate. A high feature score cannot override a P0 security failure.

# Architecture Progress Since Previous Baseline

The reliable baseline is remote `main` at `92d140141c73f9b0f64d1cf54bc849ca504c16f6`. PR #3 adds 44 changed files, approximately 5,725 insertions and 393 deletions.

## Completed

- Core ERP pages and workflows for products, customers, orders, POS, receipt/PDF output, delivery, reporting, and search/filter are implemented and covered by Flutter tests and the 2026-06-27 smoke record.
- Shopify HMAC validation and duplicate-import handling exist; `shopifyOrderCreated` is active in production.
- PR #3 implements server-owned registration approval, trial caps, paid-plan entitlements, atomic quota reservation, Business plan mapping, and Stripe event deduplication.
- PR #3 CI passed Flutter analysis/tests and Firestore/Storage rules tests at the exact head SHA.
- Additional audit-run unit verification passed 53/53 release-critical Node tests.

## In Progress

- PR #3 remains a draft and is not merged.
- SaaS UI, rules, registration, quota, and billing code are not deployed together as one traceable release.
- Stripe lifecycle logic is implemented in PR #3, but live dashboard behavior and the exact deployed source cannot be verified.
- Production smoke evidence predates PR #3 and still marks core UI/APK paths as manual or partial in `docs/SMOKE_TEST_LOG.md:20-25`.

## Not Started

- Firestore scheduled backups or retained backups: production queries returned empty arrays.
- A full restore rehearsal and documented RTO/RPO.
- Automated inclusion of the new Node SaaS suites in CI.

## Blocked

- Multi-tenant launch is blocked by Firestore and Storage authorization defects detailed below.
- Paid launch is blocked by lack of exact deployed-source provenance and live Stripe lifecycle evidence.
- Public registration is blocked until the authorization defects and deployed parity are resolved.

## Unknown

- Exact source of the deployed Stripe functions. Cloud Functions reports hash `24a56abec79b4e09325901c8310ee90252d501d2`, update time `2026-10-17T08:47:52.304Z`, version 3; the source archive download returned HTTP 403.
- Stripe Dashboard webhook delivery history, endpoint event selection, Customer Portal settings, tax configuration, and live subscription records.
- Exact production Firestore/Storage ruleset content and its commit provenance.
- Current Android APK artifact identity and its installation smoke result. PR #3 APK CI jobs were correctly skipped because APK builds only run on pushes to `main` (`.github/workflows/ci.yml:50-52`). No rebuild was performed.

# Folder and Code Inventory

## Present implementation surfaces

- Specifications and workflows: `docs/FEATURES.md`, `docs/WORKFLOW.md`, `docs/ORDER_WORKFLOW.md`, `docs/SAAS_ROADMAP.md`, `docs/PRICING_PLANS.md`.
- Flutter UI: `lib/pages/`, `lib/components/`, legacy generated page folders, `lib/flutter_flow/nav/nav.dart`.
- Authentication and authorization: `lib/auth/`, `firebase/functions/registration_provisioning.js`, `firebase/functions/staff_auth_claims.js`, `firebase/firestore.rules`.
- Billing: `lib/pages/billing_page/`, `lib/backend/stripe_billing_service.dart`, `firebase/functions/stripe_billing.js`.
- Persistence: generated Firestore record models under `lib/backend/schema/`; Firestore and Storage rules under `firebase/`.
- Server APIs and triggers: `firebase/functions/index.js`, Shopify modules, registration, branch provisioning, billing, quotas, reminders, and notifications.
- Tests: Flutter tests under `test/`; Node/rules tests under `firebase/test/`.
- Deployment: Firebase aliases/config, CI workflow, staging/production scripts, smoke scripts, and ruleset release helper.

## Missing Folders or Capabilities

- No backup/restore automation or restore-test artifact.
- No immutable release manifest tying Hosting, Rules, Functions, APK, and commit SHA together.
- No production Stripe verification artifact with redacted event IDs and lifecycle results.

## Duplicate Implementations

- Subscription and entitlement logic exists on both Flutter and Functions sides (`lib/platform/plan_entitlements.dart`, `lib/backend/monthly_usage.dart`, `lib/backend/trial_quota.dart`, and matching `firebase/functions/*`). This is intentional for UX plus server enforcement, but parity must remain tested.
- Legacy Malaysia-only Stripe configuration names coexist with country-specific MY/SG names in PR #3 (`firebase/functions/stripe_billing.js:31-50`). This is backward compatibility, not a second payment integration.

## Dead Code Candidates

- `defaultSubscriptionFields()` in PR #3 is explicitly described as unused by provisioning (`firebase/functions/stripe_billing.js:95-100`). Confirm and remove post-MVP or make its status explicit.
- Legacy generated Flutter pages and the `orderlist1Legacy` route require post-launch reachability review; no deletion is recommended during release hardening.

## Unused File Candidates

- The numerous placeholder `favicon.png` assets under non-web asset folders are candidates only. They were not proven unused and are not launch blockers.

# Database Review

## Existing Collections

Verified from code/rules: `Companies`, `users`, `user_registration_requests`, `staff_registration_intents`, `orders`, `Order_item`, `customers`, `product`, `custom_product`, `materials`, `price_lists`, `invoices`, `deleted_orders`, `counter`, `tenant_platform_config`, `role_permissions`, `audit_logs`, `staff_notices`, `plan_usage`, `plan_order_slots`, `trial_order_slots`, `trial_shopify_import_keys`, `shopify_import_keys`, `broadcast_reservations`, and `stripe_webhook_events`.

## Existing Tables

None; EmberCore uses Firestore rather than a relational database.

## Missing Tables or Collections

No schema collection is missing for the audited MVP. Operational backup metadata is absent, but should be implemented as platform configuration rather than an application collection.

## Missing Indexes

`firebase/firestore.indexes.json` exists. CI does not prove that all indexes are deployed and built in production; this remains unable to verify.

## Possible Optimizations

- Store an immutable deployment manifest containing Git SHA, Functions hashes, Hosting release, ruleset ID, and migration/preflight results.
- Prefer server-only collections for webhook event claims and quota ledgers; PR #3 rules already deny deletion and restrict mutations, but deploy parity must be proven.

# AI Architecture Review

Business Profile: represented by Companies/tenant configuration, but not an AI capability.

Campaign, Creative Assets, Prompt Library, AI Story, Marketing Analysis, Marketing Package, Animation Package, Knowledge Base, AI Router, Cost Tracker, Versioning: **Excluded from EmberCore MVP scope**. `parseOrderImport` uses Gemini, but that does not make the broader EmberOS AI architecture part of this release.

# Story Pipeline Review

Excluded from EmberCore MVP scope. No score impact.

# Marketing Pipeline Review

Excluded from EmberCore MVP scope. Customer broadcast is an ERP communication feature, not the EmberOS marketing pipeline.

# UI Review

Implemented routes/pages discovered include login, public registration, user signup, registration requests, tenant list, company selection/settings, industry settings, user list, role permissions, billing, dashboard, order list/detail/create/deleted/restore, POS summary and receipt preview, delivery order summary/print/receipt, driver assignments and driver delivery, product list/create/selection, material list/create/usage, customers, invoices, price lists, sales/profit reports, production menu, and audit log.

- **Completed/connected**: login, dashboards, orders, POS, products, customers, invoices, delivery, receipts, reports, user/role management.
- **Implemented but not deployed from PR #3**: country-aware public signup, approval/rejection flow changes, trial messaging, three-plan billing UI, and plan entitlement gating.
- **Manual verification still required**: live registration-to-first-order, POS/receipt print, driver route/proof flow, offline recovery, upgrade/downgrade UX, and cancellation UX.
- **Not launch scope**: multi-company headquarters dashboard, multi-warehouse, Open API, AI analytics, appointments. `docs/PRICING_PLANS.md:35` explicitly says these are not operational.

# API Review

## Finished

- `shopifyOrderCreated`: deployed, HMAC-verified, duplicate-aware.
- Staff notification and driver assignment triggers: deployed.
- `bootstrapEmbercorePlatform`, `approveRegistrationRequest`, and `createBranch`: deployed, though registration implementation predates PR #3.
- `createCheckoutSession`, `createPortalSession`, `stripeWebhook`: deployed and active, but exact source revision unknown.
- PR #3 source additionally includes `rejectRegistrationRequest` and `recordDirectorFirstLogin`; these were absent from the production function inventory.

## Missing

- No required MVP API is absent in PR #3. Live verification and deployment parity are missing.

## Deprecated

- Legacy MY-only Stripe Price configuration keys remain supported intentionally.

## Duplicate

- No duplicate Stripe provider integration was found or created.

# Feature Readiness Matrix

| Capability | State | Evidence | Release effect |
|---|---|---|---|
| User registration/login | Implemented; Phase 2 not deployed | `lib/pages/user_signup_page/`; `register_user_service.dart`; PR tests | P0 only because public launch would expose flawed tenant rules |
| Super Admin approval | Implemented but not deployed at PR revision | `registration_provisioning.js`; production approval function dates 2026-06-27 | P1 after security fix |
| Tenant provisioning | Implemented but not deployed at PR revision | PR test covers idempotent/concurrent approval and rollback | P1 |
| Company isolation | **Partially implemented / failed** | Most business docs use `companyRef`, but critical exceptions exist | **P0** |
| Staff roles/permissions | Partial | 30+ permissions and server rules exist; cross-tenant user read/admin delete flaws | **P0** |
| Product management | Implemented and deployed | Flutter pages/services, rules, tests | None |
| Order management | Implemented and deployed | order services/pages/rules/tests | P0 rules correction required |
| POS | Implemented and deployed | retail summary, checkout helpers, receipt flow | P1 manual smoke |
| Receipt generation | Implemented and deployed | PDF/ESC-POS code and tests | P1 hardware smoke |
| Delivery tracking | Implemented and deployed | driver pages, assignment/proof helpers | P0 Storage privacy; P1 manual smoke |
| Shopify | Implemented and deployed | function active; HMAC and duplicate tests | P1 tenant-specific production configuration verification |
| WhatsApp order handling | Implemented and deployed in app | parser/service/UI and tests | Optional; no MVP block beyond entitlement deployment |
| Search/filter | Implemented | order/product/company filter helpers and tests | None |
| Trial and paid quotas | Implemented but not deployed coherently | PR #3 atomic rules/functions; 53-test audit run | P0/P1 deployment gate |
| Data consistency/error recovery | Partial | transactions and offline queue exist; no backup/restore | **P0 backup** |

# Stripe Integration Status

| Check | Code status at PR #3 | Live status | Evidence / affected component |
|---|---|---|---|
| Checkout/subscription creation | PASS | Partial | Server chooses configured Price and ignores client amounts (`stripe_billing.js:501-580`); deployed function active |
| Starter/Pro/Business mapping | PASS | Unknown/partial | All MY/SG monthly/yearly mappings in PR (`stripe_billing.js:31-50`, `saas_pricing_v1.js:8-38`); deployed source unknown |
| Customer-to-tenant mapping | PASS | Unknown | customer and subscription metadata use `companyId`; mismatch checks at `stripe_billing.js:254-275,278-302` |
| Webhook signature | PASS | Endpoint configured, deliveries unknown | raw-body `constructEvent` in `firebase/functions/index.js:562-578`; unit signature test passed |
| Webhook idempotency | PASS in PR | Unknown | atomic event claim at `stripe_billing.js:370-386`; deployed source predates final PR commits |
| Activation | PASS in PR | Unknown | subscription sync maps active status and entitlements |
| Renewal | PASS in PR unit model | Unknown | `invoice.payment_succeeded` refreshes subscription (`stripe_billing.js:471-483`) |
| Failed payment | PASS in PR unit model | Unknown | `invoice.payment_failed` refreshes Stripe status; writes become blocked for `past_due` |
| Cancellation | PASS in PR unit model | Unknown | deletion event clears activation and subscription ID (`stripe_billing.js:396-436`) |
| Upgrade/downgrade | PASS in PR unit model | Unknown | Price-derived tier change tested; portal supplies the user path |
| Trial-to-paid | PASS in PR model | Unknown | verified active subscription replaces trial entitlement fields |
| Monthly usage reset | PASS in PR | Not deployed coherently | period-based rollover in `monthly_usage.js`; boundary/concurrency tests passed |
| Entitlement enforcement | Partial | Unknown | UI + Functions + rules exist, but authorization defects and deployment mismatch remain |
| Test/live isolation | Partial | **Live key present** | Redacted config query found `sk_live_*`, webhook secret, app URL, and 18 Price keys; no corresponding isolated staging/live verification evidence |

### Stripe-specific conclusions

- No duplicate integration is needed.
- PR #3 materially improves `main`. At `main`, billing supports only Starter/Pro, unknown Price IDs default to Starter, and no webhook event-id claim is present (`firebase/functions/stripe_billing.js` at `92d140...`, lines 16-19, 41-50, 81-124, 250-289, 305-307).
- The live Functions configuration contains complete-looking MY/SG and legacy Price keys, but configuration presence does not prove that the deployed source consumes them correctly.
- Because a live key is configured while the exact deployed billing source cannot be proven and no live lifecycle test evidence exists, **real paid launch is not approved**.

# Security Review

## P0-SEC-1 — Cross-tenant user-profile disclosure and privilege boundary failure

**Result: FAIL.** `firebase/firestore.rules:1315-1316` permits any `isStaffUser()` to read any `users/{userId}` document. No `companyRef` comparison is required. User records include role, email, and tenant reference in the rule fixtures (`firebase/test/firestore.rules.test.js:41-73`). This violates independent-business isolation.

The test suite contains broad business-document tenant tests, but no assertion denying tenant A staff from reading tenant B user profiles. Exact affected component: `match /users/{userId}`.

## P0-SEC-2 — Cross-tenant order deletion by tenant admin

**Result: FAIL.** `firebase/firestore.rules:1599` allows delete when `isPlatformAdminUser()` is true. `isPlatformAdminUser()` includes ordinary tenant `admin` (`firebase/firestore.rules:49-55`) and the first branch does not require `docBelongsToAuthTenant(resource.data)`. The alternative permission branch does include tenant binding (`firebase/firestore.rules:486-488`), but the admin branch bypasses it. Exact affected component: `match /orders/{orderId}` delete rule.

Similar unconditional platform-admin/superadmin branches should be audited collection-by-collection before release; only this directly demonstrated path is classified as a confirmed failure.

## P0-SEC-3 — Company subscription/billing metadata disclosure

**Result: FAIL.** `firebase/firestore.rules:1771-1774` permits every signed-in user to read every company, and permits unauthenticated reads when `is_active == true`. Company documents carry Stripe customer/subscription IDs, plan/status, limits, billing country/currency, and usage-period fields (`firebase/firestore.rules:1759-1768`). Firestore rules cannot hide individual fields. Exact affected component: `match /Companies/{document}`.

## P0-SEC-4 — Public sensitive media and unscoped tenant writes

**Result: FAIL.** `firebase/storage.rules` intentionally allows public reads for delivery proof images (`:92-95`), invoice payment proofs (`:98-106`), custom order-item images (`:86-89`), and customer broadcast images (`:109-112`). The Storage test explicitly expects unauthenticated delivery-proof access (`firebase/test/storage.rules.test.js:61-70`). These objects can contain addresses, signatures, payment evidence, and customer information.

Product and custom-product writes at `firebase/storage.rules:74-89` require only a staff role and do not bind the object path to the caller's tenant. Delivery-proof writes bind driver assignment only for drivers; a non-driver staff member from any tenant passes `canWriteTenantMedia()` without an order-company check (`:64-71,92-95`). Exact affected component: Storage rules path design.

## Authentication

Firebase Authentication and login flows are implemented. Phase 2 adds server-owned approval and first-login tracking. The registration request path is intentionally unauthenticated for creation and denies applicant reads. Production Auth provider settings were not independently queried.

## Role Permission

**FAIL for launch.** Fine-grained application permissions exist, but the confirmed user read and order-delete bypasses make the overall authorization boundary unsafe.

## Workspace/Tenant Isolation

**FAIL.** Most business collections correctly enforce `companyRef`; confirmed exceptions above are sufficient to fail the system-level control.

## API Validation

Stripe and Shopify validate signatures. Billing callable authorization binds director/admin to the caller's company (`firebase/functions/stripe_billing.js:223-252`). Registration approval checks superadmin in Functions. Client-supplied Stripe amounts/Price IDs are ignored.

## Rate Limit

No general callable/webhook rate limiting or App Check enforcement was verified. Stripe/Shopify signature validation mitigates spoofing but not all abuse. Classify as P1 hardening, not a standalone MVP blocker.

## Secret Storage

No live secret values were found committed. Example Firebase configuration files are present. Production Functions config uses a live Stripe secret and webhook secret; values were not exposed in this audit. `GEMINI_API_KEY` is attached through Secret Manager for `parseOrderImport` according to the production function inventory.

# Reliability and Data Integrity

- PR #3 uses Firestore transactions for trial/paid order slots and broadcast reservations. Boundary and concurrent-last-slot tests passed.
- Shopify import uses stable external-order locks; duplicate tests passed.
- Stripe event IDs are transactionally claimed in PR #3. Failed processing deletes the claim to permit retry (`stripe_billing.js:370-386,439-494`).
- Stale Stripe events are rejected by event creation timestamp, but the company update and timestamp comparison are not one Firestore transaction (`stripe_billing.js:278-367`). Concurrent different events can theoretically race after both read the same company snapshot. This is P1; make the stale-event compare-and-write transactional.
- Offline write queue code/tests exist, but the Android disconnect/reconnect smoke remains manual/partial (`docs/SMOKE_TEST_LOG.md:24`).
- Firestore backup query returned no backups and no schedules. This is a P0 production-operations blocker.

# Automated Verification

## Reused evidence

- PR #3 head `d9392af...`: GitHub CI pull-request run `39022310539` and push run `39022307085` succeeded.
- Jobs: Flutter succeeded twice; Firestore rules succeeded twice; APK jobs skipped by workflow condition.
- Main `92d140...`: GitHub CI run `38273050861` succeeded, including the main-only APK job where configured.
- Existing production smoke evidence dated 2026-06-27 reports 326 Flutter tests and 101 Firebase emulator checks, but is stale for PR #3 and does not override current findings.

## Audit-run verification

Command, run locally against PR #3 working-tree source without production access:

```text
node --test --test-concurrency=1 \
  test/stripe_billing.test.js \
  test/registration_provisioning.test.js \
  test/plan_entitlements.test.js \
  test/trial_quota.test.js \
  test/monthly_usage.test.js \
  test/shopify_webhook.test.js
```

Result: **53 tests, 53 passed, 0 failed**, duration approximately 12.2 seconds.

No APK rebuild was performed because PR #3 changes are SaaS/backend/UI logic, CI analysis/tests are green, and an APK rebuild would not resolve the security/deployment evidence gaps.

# Production Deployment Status

| Surface | Status | Evidence |
|---|---|---|
| Hosting | Active, pre-PR | `https://embercore-erp.web.app` returned HTTP 200; Last-Modified `2026-10-12T15:47:08Z` |
| Cloud Functions | Active but mixed revisions | Stripe functions updated 2026-10-17 08:47 UTC; registration/core functions mostly 2026-06-27 |
| PR #3 Functions | Not fully deployed | `rejectRegistrationRequest` and `recordDirectorFirstLogin` absent from inventory |
| Stripe config | Live-mode present | live secret prefix, webhook secret, production app URL, 18 Price keys; values not disclosed |
| GitHub Releases | None | GitHub API returned no releases |
| GitHub Deployments | None | GitHub API returned no deployment records |
| Branch protection | Disabled on `main` | GitHub branch API reports no required checks/protection |
| Backups | None | Firestore backups and schedules both returned `[]` |
| Rollback | Partial | Firestore ruleset promotion helper exists; no full Hosting/Functions/data rollback rehearsal |

# Technical Debt

- Documentation contradicts implementation in places. For example, `docs/PRICING_PLANS.md:146-153` says Business still needs extension even though PR #3 implements it, while `:200-210` contains stale “not landed” notes for monthly quota work now present in the PR.
- Production has no repository release/deployment records, making commit-to-runtime traceability weak.
- CI does not execute the new Node SaaS suites from PR #3; the audit had to run them separately.
- `main` is not protected and has no required status checks.
- Large generated Flutter widgets remain maintainability risks, but they are not immediate release blockers.
- Technical debt score: **42/100**, where 100 means severe debt and 0 means no observed debt.

# Product Blueprint Alignment

The authoritative EmberCore launch scope comes from `docs/PRICING_PLANS.md`, `docs/SAAS_ROADMAP.md`, `docs/SAAS_EXECUTION_PLAN.md`, and workflow/security documentation.

- Aligned: one company per tenant; Starter/Pro/Business; MY/SG prices; 14-day Pro-capability trial; 3 staff/100 lifetime trial orders; monthly paid quotas; WhatsApp/Shopify gates; core ERP available on Starter.
- Contradicted operationally: the documents promise tenant isolation, but current rules permit cross-tenant user reads, cross-tenant order deletion by tenant admins, public company metadata, and public sensitive media.
- Correctly deferred: multi-store/headquarters, cross-store inventory, multi-warehouse, Open API, appointments, AI business analytics, and new payment providers.

# Decision Boundaries

## Current Implementation

EmberCore has a mature single-/limited-tenant operational core and a strong unmerged SaaS Phase 2 implementation. Production is active but not a reproducible deployment of PR #3.

## My Decisions (from Blueprint)

- Starter/Pro/Business pricing and capabilities are authoritative as documented in `docs/PRICING_PLANS.md:25-35,42-85`.
- Trial is 14 days, uses Pro modules, and is limited to 3 staff and 100 lifetime orders (`docs/PRICING_PLANS.md:33,187-196`).
- Multi-store, Open API, multi-warehouse, appointments, and AI analytics are not launch scope (`docs/PRICING_PLANS.md:35`).

## Architect Suggestions

Only minimum launch actions are recommended: repair and regression-test tenant rules; complete backup/recovery; merge a reviewed PR; deploy one traceable release through staging; verify live Stripe without charging a real payment; then perform the critical smoke matrix. No new modules or redesign are proposed.

# Priority List

## Priority 1 — P0 launch blockers

1. Fix Firestore tenant boundaries for `users`, `Companies`, and order deletion; add explicit cross-tenant denial tests.
2. Redesign sensitive Storage paths/rules so reads and writes are authenticated and tenant-bound; migrate legacy public proof URLs where necessary.
3. Establish Firestore scheduled backup/retention and execute a documented restore rehearsal with RTO/RPO.
4. Resolve PR #3 review status, verify exact deployed Stripe source, and deploy Hosting/Rules/Functions as one versioned release after staging.
5. Complete a no-charge live Stripe verification using dashboard/test tooling or a controlled live-mode setup: signature delivery, activation, renewal simulation, failure, cancellation, upgrade/downgrade, and tenant mapping. Do not process a real customer payment during verification.

## Priority 2 — P1 before public launch

1. Add all six Node SaaS suites to CI and make checks required on protected `main`.
2. Make Stripe stale-event compare-and-write transactional.
3. Run live registration → approval → first order, POS/receipt, delivery proof, Shopify duplicate, WhatsApp, trial cap, paid cap, and cancellation smoke tests in staging, then a reduced production smoke.
4. Produce a release manifest and rollback procedure covering Hosting, Functions, rules, indexes, APK, configuration version, and data restoration.
5. Confirm legal/privacy retention text and tax/SST treatment before public registration.

## Priority 3 — post-launch backlog

- General API/App Check rate limiting and abuse monitoring.
- Clean stale pricing/status documentation and legacy configuration aliases.
- Reachability review for legacy generated pages and placeholder assets.
- Improve observability around webhook failures, quota denials, and backup health.

## Priority 4 — explicitly outside MVP

- Multi-store/headquarters dashboard, cross-store inventory, multi-warehouse, Open API, appointments, AI analytics, additional payment providers, and marketing redesign.

# Estimates and Scores

Current completion: 66%

MVP completion: 66%

Production readiness: 35%

Architecture score: 75/100

Maintainability score: 68/100

Scalability score: 70/100

Technical debt score: 42/100 (`100 = severe debt`, `0 = no observed debt`)

## Estimated remaining effort

**52–88 engineering/operations hours**, assuming no schema migration surprise:

- Firestore/Storage authorization fixes and regression tests: 16–28 h.
- Backup schedule, retention, restore rehearsal, and runbook: 8–16 h.
- CI integration, branch protection, release manifest, and rollback procedure: 6–10 h.
- Stripe deployed-source reconciliation and non-transaction live lifecycle verification: 8–14 h.
- Staging deployment and critical end-to-end smoke matrix: 10–14 h.
- Production promotion and post-deploy verification: 4–6 h.

# Minimum Release Path

1. Patch only the confirmed Firestore and Storage boundary defects; add negative tests for every affected path.
2. Add the 53-test Node SaaS suite to CI; protect `main` with Flutter, rules, and SaaS lifecycle checks.
3. Configure Firestore backups, document RPO/RTO, and successfully restore into a non-production project.
4. Review PR #3, resolve documentation drift, and move it out of draft only after the security patch is included.
5. Deploy the exact candidate SHA to staging as Hosting + Rules + Indexes + Functions; record hashes and ruleset IDs.
6. Run the critical staging smoke matrix, including two tenants attempting cross-access.
7. Verify Stripe live configuration/dashboard/webhooks without a real payment; use test clocks/test mode for lifecycle checks where possible, then verify live endpoint configuration and Price ownership.
8. Promote the same SHA to production, run the reduced production smoke, and record a release artifact. Build a new APK only if release-critical mobile code/config changed after the last valid main APK artifact.

# Evidence Gaps

- Stripe Dashboard access was unavailable; webhook delivery history, product/Price ownership, portal settings, tax, and subscriptions could not be verified.
- Deployed Stripe source archive access returned HTTP 403, preventing exact source-to-SHA comparison.
- Production ruleset content/commit provenance was not exported.
- No current APK artifact was downloaded or device-tested; existing evidence was reused as requested.
- No production registration/order mutation, payment, merge, or deployment was performed.
- GitHub has no Releases or Deployments records for this repository.

# Final release recommendation

**NO-GO for private beta, public SaaS registration, and paid launch today.** The minimum viable release is close in feature terms, but the verified tenant-isolation and recovery failures are categorical blockers. Fix those boundaries, establish recovery, merge and deploy one traceable PR #3-based release, and verify Stripe lifecycle behavior before onboarding any independent business or accepting payment.
