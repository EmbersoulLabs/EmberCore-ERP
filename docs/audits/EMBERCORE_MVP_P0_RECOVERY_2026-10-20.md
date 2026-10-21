# EmberCore MVP P0 Recovery — 2026-10-20

## Executive decision

**PARTIAL.** The candidate fixes the verified code-level tenant-isolation and authorization P0s and adds required SaaS lifecycle CI coverage. Local targeted gates and exact-head GitHub CI pass. Launch remains blocked by operational backup/restore certification, tenant-media migration, staging/deployment parity, and live Stripe configuration verification. No production system was changed.

## Identity

| Item | Value |
|---|---|
| Canonical audited main | `92d140141c73f9b0f64d1cf54bc849ca504c16f6` |
| SaaS PR #3 input head | `d9392afcd73ee8d70fc8efb3371f744ce7e1f94b` |
| Working branch | `saas/phase-2-onboarding` |
| Production changed | No |
| Merge/deployment/live charge | None |

## Five P0 blockers and disposition

| P0 | Exact original evidence | Recovery disposition |
|---|---|---|
| Firestore tenant boundaries | `users` reads were staff-global; active `Companies` were anonymously readable; tenant admins could delete cross-tenant `orders`/`Order_item` | **Resolved in candidate.** Rules now bind reads, writes and destructive operations to the canonical tenant; self-service updates cannot change role/company/privilege fields. Emulator denial tests pass. |
| Storage isolation | Delivery proof, invoice proof, product and custom product media were publicly readable; several write paths had no tenant identifier | **Resolved for new paths.** Authenticated tenant paths are enforced and clients write under `tenant_media/{companyId}/...`; legacy unscoped paths fail closed. Existing objects require a non-destructive migration before rollout. |
| Backup/recovery | Production inventory returned no backups or schedules; no repository restore rehearsal evidence | **Still P0.** `docs/DISASTER_RECOVERY.md` defines RPO/RTO, procedure and PASS evidence. No production backup/IAM changes were permitted. Prior claimed isolated restore cannot override absent current production recovery points. |
| Release parity | PR #3 was draft/unmerged and production revisions could not be tied to one source SHA | **Still P0 operationally.** Candidate is not merged or deployed, as required. Exact-head CI must pass before staging certification. |
| Stripe live readiness | Code existed, but dashboard endpoint health, Price ownership, portal settings and live lifecycle were unavailable; no payment was permitted | **Code/test portion resolved; live portion remains.** Signature, idempotency, ordering, mapping, cancellation/status transitions and stale-role denial pass mocks. No live charge occurred. |

## Implemented fixes

- Firestore: tenant-scoped user/company/audit/internal-message reads; tenant-bound destructive order operations; protected identity, role, company, permission, trial and subscription authority fields.
- Storage: authenticated tenant-scoped product, custom-product, delivery-proof, invoice-proof, company-logo and broadcast access; legacy sensitive paths fail closed.
- Client: tenant-aware product/custom-product/delivery-proof upload and delete paths, including fail-closed missing-tenant handling.
- Billing authorization: Firestore profile is the revocation authority; a stale privileged custom claim cannot retain billing access.
- CI: added a Node 20 `saas-lifecycle` job covering registration/provisioning, entitlements, trial and monthly quotas, Shopify HMAC/duplicates, and Stripe lifecycle/security.

## Verification evidence

| Gate | Result |
|---|---|
| Firebase Emulator Firestore/Storage + counters/orders | **131/131 PASS** |
| SaaS/Stripe targeted Node suites | **54/54 PASS** |
| Changed Flutter upload-path suites | **15/15 PASS** |
| Flutter analyzer | Exit 0 with 1,784 existing generated-code warnings/infos; no fatal analyzer error |
| GitHub push CI `39415637634` at `1efafd5c...` | **PASS**: Flutter, Firestore/Storage, SaaS lifecycle |
| GitHub PR CI `39415644198` at `1efafd5c...` | **PASS**: Flutter, Firestore/Storage, SaaS lifecycle |

The emulator matrix includes cross-tenant read/write/delete denials, self-role and tenant elevation denials, subscription tampering denial, trial/paid quota caps, monthly rollover, concurrent last-slot enforcement, and concurrent order-number uniqueness. The Stripe tests include invalid/valid signature handling, tenant mapping, stale-role denial, event idempotency and stale-event ordering. No real payment was attempted.

## Weighted MVP completion

The original audit rubric is retained so the comparison is measurable. Candidate code is scored as implemented but not deployed; operational requirements receive no PASS credit without evidence.

| Category | Weight | Candidate score | Earned |
|---|---:|---:|---:|
| Identity and provisioning | 10 | 1.00 | 10.0 |
| Tenant security | 20 | 0.90 | 18.0 |
| Core ERP operations | 20 | 1.00 | 20.0 |
| Optional launch integrations | 5 | 1.00 | 5.0 |
| Billing and subscriptions | 20 | 0.90 | 18.0 |
| Reliability and integrity | 10 | 0.90 | 9.0 |
| Production operations | 15 | 0.367 | 5.5 |
| **Total** | **100** |  | **85.5%, rounded to 86%** |

Tenant security is not 1.0 because legacy Storage objects still need migration and deployed validation. Billing is not 1.0 because live Stripe configuration is unverified. Production operations remains unchanged because backup, staging, deploy provenance, and restore evidence are absent.

## Remaining blockers and minimum release path

1. Review the security diff; exact-head GitHub CI has passed.
2. Inventory legacy sensitive Storage objects, copy them to tenant-scoped paths with an audited non-destructive job, update references, then verify before removing old objects.
3. Configure managed Firestore backup retention and Auth export under approved production operations; restore both into an isolated recovery project and retain the evidence required by the runbook.
4. Deploy this exact candidate to staging only and run a two-tenant registration-to-order, POS/receipt, delivery, Shopify duplicate, WhatsApp, quota and cancellation smoke matrix.
5. Verify the live Stripe endpoint, event selection, Price ownership and Customer Portal configuration without charging a customer; keep lifecycle simulations in Stripe test mode/test clocks.
6. After certification, promote the same SHA through the controlled production release process. Do not merge as part of this recovery ticket.

Estimated remaining effort: **24–42 hours** (Storage migration 4–8; backup/restore 8–16; exact-head review/CI and staging smoke 6–10; live Stripe configuration evidence 4–6; release manifest/rollback certification 2–4).
