# EmberCore disaster recovery runbook

Status: release gate; procedure documented, production schedule and rehearsal not yet certified.

## Recovery objectives

- Target RPO: 24 hours for Firestore and Firebase Authentication.
- Target RTO: 4 hours to restore an isolated recovery project and validate critical reads.
- Production restoration requires an incident commander and a separate change approval. Never test a restore against production.

## Required protected assets

1. Daily Firestore managed backup with at least 14 retained copies.
2. Daily Firebase Authentication export stored in a versioned, access-controlled bucket with matching password-hash configuration.
3. Firebase rules, indexes, Functions, Hosting, client configuration, and the release manifest tied to an immutable Git SHA.
4. Stripe and Shopify configuration inventory. Secrets remain in the provider secret stores and must not be copied into the repository.

## Certification procedure

1. Record production project, backup identifier, Auth export object generation, source release SHA, operator, and UTC start time.
2. Create or select an empty, isolated recovery project. Verify its project ID is not a production alias before importing anything.
3. Restore the selected Firestore backup to the recovery project.
4. Import the matching Auth export using the recorded hash parameters.
5. Deploy the exact release SHA's rules, indexes, and Functions configuration to the recovery project only.
6. Run the two-tenant security suite and the registration, provisioning, order, quota, and Stripe-mock lifecycle suites.
7. Validate document and user counts, sample tenant ownership, order-to-line-item references, counters, and subscription authority fields.
8. Record completion time, achieved RPO/RTO, discrepancies, cleanup owner, and immutable evidence links. Delete the recovery project only after evidence is retained.

## Evidence required for PASS

- A current backup schedule/retention inventory.
- A successful Firestore restore operation identifier in an isolated project.
- A successful Auth import summary and hash-configuration record.
- Before/after collection and user counts, with no customer secrets in the report.
- Exact-head test results and an operator-signed recovery record.

## Current reconciliation (2026-10-20)

The repository and GitHub history contain no retrievable artifact for the previously described isolated Firestore + Auth restore. The release audit independently found no production Firestore backup or backup schedule. A prior isolated restore may demonstrate that the procedure once worked, but it does not prove that recoverable production backups currently exist. Therefore backup/recovery remains **FAIL** until the evidence above is captured. This recovery ticket made no production IAM, database, backup, or deployment changes.
