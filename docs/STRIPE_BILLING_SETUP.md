# Stripe billing setup (EmberCore SaaS)

**套餐定义：** [PRICING_PLANS.md](PRICING_PLANS.md)

## Product vs Price（产品 vs 价格）

Stripe 结构：**1 个 Product 可挂多个 Price**，年付**不需要**另开 Product。

| 层级 | Products | Prices per product | Total prices |
|------|----------|-------------------|--------------|
| EmberCore SaaS | **3**（Starter / Pro / Business） | 2（Monthly + Yearly） | **6** |

```
EmberCore Starter
  ├── price_...  RM 69 / month
  └── price_...  RM 699 / year

EmberCore Pro
  ├── price_...  RM 199 / month
  └── price_...  RM 1,999 / year

EmberCore Business
  ├── price_...  RM 499 / month
  └── price_...  RM 4,999 / year
```

在 Dashboard：**产品 → 选择 Product → 添加另一个价格 → 开单周期选「每年」**。

---

## 1. Stripe Dashboard (Test mode first)

Create **three** recurring products in **MYR**. For each product, add **monthly** then **yearly** price on the **same** product.

| Product | plan_tier | Monthly | Yearly (~15% off) |
|---------|-----------|---------|-------------------|
| EmberCore Starter | `starter` | RM 69 | RM 699 |
| EmberCore Pro | `pro` | RM 199 | RM 1,999 |
| EmberCore Business | `business` | RM 499 | RM 4,999 |

For each price:

1. Type: **Recurring** · Currency: **MYR** · Billing: **Monthly** or **Yearly**
2. Copy **Price ID** (`price_...`) — not Product ID (`prod_...`)
3. Do **not** set Stripe trial period — 14-day trial is managed in Firestore (`subscription_status: trialing`)

**English copy for Name / Description / Statement descriptor:** see [Appendix A](#appendix-a--stripe-product-copy-english).

Also:

4. Enable **Customer Portal** (Settings → Billing → Customer portal)
5. Add webhook endpoint after deploy:
   - URL: `https://asia-southeast1-embercore-erp.cloudfunctions.net/stripeWebhook`
   - Events: `checkout.session.completed`, `customer.subscription.*`, `invoice.payment_failed`

## 2. Firebase Functions config

```bash
cd firebase/functions
npm install

firebase functions:config:set \
  stripe.secret_key="sk_test_..." \
  stripe.webhook_secret="whsec_..." \
  stripe.app_url="https://embercore-erp.web.app" \
  stripe.price_starter_monthly="price_..." \
  stripe.price_pro_monthly="price_..." \
  stripe.price_business_monthly="price_..."

# Optional yearly (MYR):
# stripe.price_starter_yearly="price_..."
# stripe.price_pro_yearly="price_..."
# stripe.price_business_yearly="price_..."
```

Or env vars: `STRIPE_SECRET_KEY`, `STRIPE_WEBHOOK_SECRET`, `BILLING_APP_URL`, `STRIPE_PRICE_STARTER_MONTHLY`, `STRIPE_PRICE_PRO_MONTHLY`, `STRIPE_PRICE_BUSINESS_MONTHLY`.

> **Note:** `stripe_billing.js` currently implements **starter** and **pro** only. Add `business` to `PLAN_LIMITS` and `priceIdForPlan` before deploying Business checkout.

Deploy:

```bash
cd firebase
firebase deploy --only functions:createCheckoutSession,functions:createPortalSession,functions:stripeWebhook --project embercore-erp
```

## 3. App flow

- New tenants (registration approval) get **14-day trial** on **Starter** limits (`plan_tier: starter`, `subscription_status: trialing`).
- **Director/Admin** → sidebar **Billing** → Subscribe or **Manage billing** (Stripe Portal).
- Webhook updates `Companies`: `plan_tier`, `subscription_status`, `max_staff_seats`, `max_orders_per_month`, etc.
- `past_due` / expired trial / `cancelled` → **Create Order** blocked with message.
- **Pro-only modules** (WhatsApp import, Shopify, BOM, audit log) should be gated by `plan_tier` — see [PRICING_PLANS.md](PRICING_PLANS.md).

## 4. Plan limits (target)

| Tier | max_staff_seats | max_orders_per_month |
|------|-----------------|----------------------|
| starter | 2 | 2000 |
| pro | null (unlimited) | null |
| business | null | null |

Legacy code may still use 5 / 500 until updated in `stripe_billing.js` and `subscription_helpers.dart`.

## 5. Legacy tenants

Existing companies **without** `subscription_status` are treated as **active** (no disruption).

## 6. Go live

Switch to live Stripe keys + live Price IDs + live webhook secret in production config.

## 7. Local payment alternatives (optional)

For tenants who prefer FPX / DuitNow without card: Billplz, ToyyibPay, or Revenue Monster can supplement Stripe — webhook must still write the same `Companies` subscription fields.

---

## Appendix A — Stripe product copy (English)

Copy-paste into Stripe Dashboard → **Product catalog** → each product.

### Product 1 — Starter

| Field | English |
|-------|---------|
| **Name** | `EmberCore Starter` |
| **Description** | `Essential ERP for small shops and florists. Orders, POS, delivery, customers, products, basic reports, and CSV import/export. Up to 2 staff and 2,000 orders per month.` |
| **Statement descriptor** (≤22 chars, appears on card/bank statement) | `EMBERCORE STARTER` |

**Product metadata (optional):**

| Key | Value |
|-----|-------|
| `plan_tier` | `starter` |
| `platform` | `embercore` |

**Price descriptions (optional):**

| Price | Description |
|-------|-------------|
| Monthly RM 69 | `Monthly — billed every month` |
| Yearly RM 699 | `Yearly — save ~15% vs monthly` |

**Marketing features** (Pricing table / Portal — one bullet per line):

- Up to 2 staff members
- Up to 2,000 orders/month
- Orders, POS & delivery
- Customer & product management
- Basic sales reports
- CSV import & export

---

### Product 2 — Pro

| Field | English |
|-------|---------|
| **Name** | `EmberCore Pro` |
| **Description** | `For growing stores. Everything in Starter, plus WhatsApp order import, Shopify sync, BOM & cost tracking, profit analytics, inventory alerts, audit logs, advanced roles, and custom reports. Unlimited staff and orders. Customer broadcast: 2,000 contacts/month.` |
| **Statement descriptor** | `EMBERCORE PRO` |

**Product metadata:**

| Key | Value |
|-----|-------|
| `plan_tier` | `pro` |
| `platform` | `embercore` |

**Price descriptions:**

| Price | Description |
|-------|-------------|
| Monthly RM 199 | `Monthly — billed every month` |
| Yearly RM 1,999 | `Yearly — save ~15% vs monthly` |

**Marketing features:**

- Unlimited staff & orders
- WhatsApp one-tap order import
- Shopify order sync
- BOM, cost & profit analytics
- Audit logs & advanced permissions
- Customer broadcast (2,000/month)

---

### Product 3 — Business

| Field | English |
|-------|---------|
| **Name** | `EmberCore Business` |
| **Description** | `For chains and multi-location businesses. Everything in Pro, plus multi-store management, HQ dashboard, cross-store inventory, advanced API access, unlimited customer broadcast, and dedicated support. Multi-store and HQ features are rolling out — subscribers get early access.` |
| **Statement descriptor** | `EMBERCORE BUSINESS` |

**Product metadata:**

| Key | Value |
|-----|-------|
| `plan_tier` | `business` |
| `platform` | `embercore` |

**Price descriptions:**

| Price | Description |
|-------|-------------|
| Monthly RM 499 | `Monthly — billed every month` |
| Yearly RM 4,999 | `Yearly — save ~15% vs monthly` |

**Marketing features:**

- Everything in Pro
- Multi-store & HQ dashboard
- Cross-store inventory
- Open API & webhooks
- Unlimited customer broadcast
- Dedicated support

---

## Appendix B — Price ID checklist

After creating all 6 prices, record IDs here (do not commit live secrets to git):

| Env key | Price ID | Amount |
|---------|----------|--------|
| `STRIPE_PRICE_STARTER_MONTHLY` | `price_...` | RM 69/mo |
| `STRIPE_PRICE_STARTER_YEARLY` | `price_...` | RM 699/yr |
| `STRIPE_PRICE_PRO_MONTHLY` | `price_...` | RM 199/mo |
| `STRIPE_PRICE_PRO_YEARLY` | `price_...` | RM 1,999/yr |
| `STRIPE_PRICE_BUSINESS_MONTHLY` | `price_...` | RM 499/mo |
| `STRIPE_PRICE_BUSINESS_YEARLY` | `price_...` | RM 4,999/yr |

---

## Appendix C — Trial reminder

| Where | Trial? |
|-------|--------|
| Stripe Product / Price | **No** — leave trial period empty |
| Firestore `Companies` | **Yes** — `subscription_status: trialing`, `trial_ends_at` (+14 days) |
| App Billing page | User subscribes via Stripe **after** trial or during trial to add payment method |

*EmberCore by EmberSoulLabs · Stripe billing setup · 2026-06-23*
