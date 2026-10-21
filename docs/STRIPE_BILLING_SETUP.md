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
  └── price_...  RM 690 / year

EmberCore Pro
  ├── price_...  RM 199 / month
  └── price_...  RM 1,990 / year

EmberCore Business
  ├── price_...  RM 399 / month
  └── price_...  RM 3,990 / year
```

在 Dashboard：**产品 → 选择 Product → 添加另一个价格 → 开单周期选「每年」**。

---

## 1. Stripe Dashboard (Test mode first)

Create **three** recurring products in **MYR**. For each product, add **monthly** then **yearly** price on the **same** product.

| Product | plan_tier | Monthly | Yearly (~15% off) |
|---------|-----------|---------|-------------------|
| EmberCore Starter | `starter` | RM 69 | RM 690 |
| EmberCore Pro | `pro` | RM 199 | RM 1,990 |
| EmberCore Business | `business` | RM 399 | RM 3,990 |

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

> **Note:** `stripe_billing.js` resolves Starter, Pro and Business for MY and SG, monthly and yearly. Amounts come from `saas_pricing_v1.js`. Paid caps come from `plan_entitlements.js`.

Deploy:

```bash
cd firebase
firebase deploy --only functions:createCheckoutSession,functions:createPortalSession,functions:stripeWebhook --project embercore-erp
```

## 3. App flow

- New tenants (registration approval) get a **14-day trial** with **Pro modules** and trial caps of 3 staff / 100 orders (`subscription_status: trialing`). Paid Starter limits are not applied during trial.
- **Director/Admin** → sidebar **Billing** → Subscribe or **Manage billing** (Stripe Portal).
- Webhook updates `Companies`: `plan_tier`, `subscription_status`, `max_staff_seats`, `max_orders_per_month`, etc.
- `past_due` / expired trial / `cancelled` → **Create Order** blocked with message.
- **Pro and Business modules** (WhatsApp import, Shopify, BOM, production menu, broadcast, audit log) are gated by `plan_entitlements.js`. Trial uses those modules with the 100-order trial cap. See [PRICING_PLANS.md](PRICING_PLANS.md).

## 4. Plan limits (target)

| Tier | max_staff_seats | max_orders_per_month |
|------|-----------------|----------------------|
| starter | 2 | 500 |
| pro | 10 | 3000 |
| business | 30 | 10000 |

Trial remains 3 staff and 100 lifetime orders. Every paid plan has `max_companies: 1`.

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
| **Description** | `Essential ERP for small shops. Orders, POS, delivery, customers, products, invoices, basic reports, and CSV import/export. Up to 2 staff and 500 orders per month.` |
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
| Yearly RM 690 | `Yearly — billed every year` |

**Marketing features** (Pricing table / Portal — one bullet per line):

- Up to 2 staff members
- Up to 500 orders/month
- Orders, POS & delivery
- Customer & product management
- Basic sales reports
- CSV import & export

---

### Product 2 — Pro

| Field | English |
|-------|---------|
| **Name** | `EmberCore Pro` |
| **Description** | `Everything in Starter, plus WhatsApp order import, Shopify sync, BOM, production menu, audit logs, tenant roles, and customer broadcast for 2,000 recipients per month. Up to 10 staff and 3,000 orders per month.` |
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
| Yearly RM 1,990 | `Yearly — billed every year` |

**Marketing features:**

- Up to 10 staff and 3,000 orders/month
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
| **Description** | `Everything in Pro, with 30 staff, 10,000 orders per month, customer broadcast for 10,000 recipients per month, and priority support. Multi-store, HQ, open API, and AI analysis are not included.` |
| **Statement descriptor** | `EMBERCORE BUSINESS` |

**Product metadata:**

| Key | Value |
|-----|-------|
| `plan_tier` | `business` |
| `platform` | `embercore` |

**Price descriptions:**

| Price | Description |
|-------|-------------|
| Monthly RM 399 | `Monthly — billed every month` |
| Yearly RM 3,990 | `Yearly — billed every year` |

**Marketing features:**

- Everything in Pro
- Up to 30 staff and 10,000 orders/month
- Customer broadcast (10,000/month)
- Priority support
- One company; multi-store and open API are not included

---

## Appendix B — Price ID checklist

After creating all 6 prices, record IDs here (do not commit live secrets to git):

| Env key | Price ID | Amount |
|---------|----------|--------|
| `STRIPE_PRICE_STARTER_MONTHLY` | `price_...` | RM 69/mo |
| `STRIPE_PRICE_STARTER_YEARLY` | `price_...` | RM 690/yr |
| `STRIPE_PRICE_PRO_MONTHLY` | `price_...` | RM 199/mo |
| `STRIPE_PRICE_PRO_YEARLY` | `price_...` | RM 1,990/yr |
| `STRIPE_PRICE_BUSINESS_MONTHLY` | `price_...` | RM 399/mo |
| `STRIPE_PRICE_BUSINESS_YEARLY` | `price_...` | RM 3,990/yr |

---

## Appendix C — Trial reminder

| Where | Trial? |
|-------|--------|
| Stripe Product / Price | **No** — leave trial period empty |
| Firestore `Companies` | **Yes** — `subscription_status: trialing`, `trial_ends_at` (+14 days) |
| App Billing page | User subscribes via Stripe **after** trial or during trial to add payment method |

*EmberCore by EmberSoulLabs · Stripe billing setup · 2026-06-23*
