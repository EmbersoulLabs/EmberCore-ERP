# EmberCore — 套餐与功能分层

**产品：** EmberCore · **公司：** EmberSoulLabs  
**定位：** 订阅制 SaaS ERP（非一次性卖断）  
**币种：** Stripe 主定价 **MYR（马币）** · 公司注册马来西亚（SSM）  
**参考：** 新加坡客户可另建 SGD Price（见文末对照表）

**Stripe 英文文案与年付配置：** [STRIPE_BILLING_SETUP.md](STRIPE_BILLING_SETUP.md)（Appendix A）

**最后更新：** 2026-06-23

---

## 设计原则

1. **Starter 要够用** — 小店主能日常经营，不因「缺导出」产生数据绑架感。
2. **Pro 卖差异化** — WhatsApp 建单、Shopify 导单、BOM/利润分析是升级动力，不放 Starter。
3. **Business 卖规模** — 多门店、总部看板、API；Enterprise 改称为 **Business**，避免与 B2B 客户混淆。
4. **额度制控成本** — 客户群发按人数/月封顶，消息成本可预测。
5. **14 天试用** — 在 App / Firestore 管理（`subscription_status: trialing`），Stripe 产品不设 trial period。

---

## 套餐总览

| 档位 | 月费（马币） | 目标用户 | 员工上限 | 订单上限 |
|------|-------------|----------|----------|----------|
| **Starter** | **RM 59–89** | 1–3 人花店、小零售 | **2** | **2,000 笔/月** |
| **Pro** | **RM 179–249** | 成长中门店 | **无限** | **无限** |
| **Business** | **RM 449–599** | 连锁 / 企业 | **无限** | **无限** |

**Stripe 建议标价（月付）：** Starter **RM 69** · Pro **RM 199** · Business **RM 499**

**年付（约 15%  off，可选）：** Starter **RM 699/年** · Pro **RM 1,999/年** · Business **RM 4,999/年**

> **定价锚点：** Starter 约 RM 2–3/天；Pro 约 3× Starter，换 WhatsApp + Shopify + 经营分析；Business 约 7× Starter，换多门店与 API。  
> **SST：** 面向马来西亚 B2B 订阅，按现行法规确认是否含/另加 8% SST，发票由 EmberSoulLabs 开具。

---

## 功能矩阵

图例：✅ 包含 · ➖ 不含 · 🔢 额度制 · 🔜 规划中

### 核心 ERP（Starter 即含）

| 功能 | Starter | Pro | Business | 代码模块 / 备注 |
|------|---------|-----|----------|-----------------|
| 订单管理 | ✅ | ✅ | ✅ | `PlatformModule.orders` |
| POS 收银 | ✅ | ✅ | ✅ | `PlatformModule.pos` |
| 配送管理 | ✅ | ✅ | ✅ | `PlatformModule.drivers` |
| 客户管理 | ✅ | ✅ | ✅ | `PlatformModule.customers` |
| 产品管理 | ✅ | ✅ | ✅ | `PlatformModule.products` |
| 基础销售报表 | ✅ | ✅ | ✅ | `PlatformModule.reports`（基础视图） |
| 基础权限（Owner + Staff） | ✅ | ✅ | ✅ | 简化 RBAC；Pro 起多角色 |
| **CSV 导入** | ✅ | ✅ | ✅ | 产品/客户导入 — **Starter 即开放** |
| **CSV 导出** | ✅ | ✅ | ✅ | 产品/客户/订单导出 — **Starter 即开放** |

### 差异化能力（Pro 起）

| 功能 | Starter | Pro | Business | 代码模块 / 备注 |
|------|---------|-----|----------|-----------------|
| **WhatsApp 一键建单** | ➖ | ✅ | ✅ | `PlatformModule.whatsappImport` — **核心卖点** |
| **Shopify 自动导单** | ➖ | ✅ | ✅ | `PlatformModule.shopifyImport` |
| BOM / 成本管理 | ➖ | ✅ | ✅ | `PlatformModule.materialsBom` |
| 利润分析 | ➖ | ✅ | ✅ | Profit Summary 报表 |
| 库存预警 | ➖ | ✅ | ✅ | 待接 inventory 模块 |
| 客户群发 | ➖ | 🔢 2,000/月 | 🔢 无限 | `PlatformModule.customerBroadcast` + 额度字段 |
| 审计日志 | ➖ | ✅ | ✅ | `viewAuditLog` 权限 + 3+ 员工场景 |
| 多角色权限 | ➖ | ✅ | ✅ | 完整 RBAC（33 权限） |
| 自定义报表 | ➖ | ✅ | ✅ | 扩展 reports |
| API / Webhook | ➖ | ✅ | ✅ | Business 为 Open API + Dedicated |

### 企业能力（Business）

| 功能 | Starter | Pro | Business | 备注 |
|------|---------|-----|----------|------|
| 多门店 | ➖ | ➖ | ✅ | 多 `Companies` 或 org 层级 — 🔜 |
| 总部 Dashboard | ➖ | ➖ | ✅ | 🔜 |
| 跨店库存 | ➖ | ➖ | ✅ | 🔜 |
| 多仓库 | ➖ | ➖ | ✅ | 🔜 |
| 多司机调度 | ➖ | ➖ | ✅ | 增强 drivers 模块 |
| 多品牌 | ➖ | ➖ | ✅ | 白标 / 子品牌 — 🔜 |
| AI 经营分析 | ➖ | ➖ | 🔜 | 未来版本 |
| Dedicated Support | ➖ | ➖ | ✅ | 人工 SLA |

### Starter 明确限制

| 限制项 | 说明 |
|--------|------|
| 最多 **2** 个员工 | 含 director；超额提示升级 Pro |
| 最多 **2,000** 笔订单/月 | 计数器校验；超额提示升级 |
| 无 API / Webhook | Business 或 Pro（按上表） |
| 无自动化集成 | 无 WhatsApp / Shopify |
| 无 BOM / 利润报表 | 经营分析属 Pro |
| 客户群发 | 不可用 |

---

## 客户群发额度

| 档位 | 额度 | 超额行为 |
|------|------|----------|
| Starter | **0**（功能不可用） | 隐藏入口或展示升级 CTA |
| Pro | **2,000 人/月** | 软提示 + 阻止发送 |
| Business | **无限**（或 10,000+ 可配置） | — |

**Firestore 建议字段（`Companies`）：**

- `broadcast_quota_monthly` — 每月上限
- `broadcast_sent_this_month` — 当月已发（Cloud Function 或客户端原子递增）
- `broadcast_quota_reset_at` — 月初重置

---

## 竞争力排序（产品叙事）

对外宣传 / 定价页按此顺序突出：

1. ⭐ **WhatsApp 一键建单** — 东南亚花店/零售强需求
2. ⭐ **Shopify 自动导单** — 线上线下一体
3. ⭐ **配送 + 司机管理** — Starter 即有，差异化基础
4. ⭐ **BOM + 利润分析** — Pro 经营决策
5. ⭐ **AI 经营分析** — Business / 未来版本

**升级路径话术：**

- Starter → Pro：「订单多了、要用 WhatsApp/Shopify、要看利润」
- Pro → Business：「第二家店、要总部看板、要 API 对接」

---

## Stripe 产品配置

### 建议创建 3 个产品（Test mode 先行）

| Stripe 产品名 | plan_tier | 币种 | 周期 | 建议标价 |
|---------------|-----------|------|------|----------|
| EmberCore Starter | `starter` | **MYR** | 每月 | **RM 69** |
| EmberCore Pro | `pro` | **MYR** | 每月 | **RM 199** |
| EmberCore Business | `business` | **MYR** | 每月 | **RM 499** |

**年付 Price（可选）：** RM 699 / RM 1,999 / RM 4,999 — env key：`STRIPE_PRICE_*_YEARLY`。

### Functions 环境变量（待扩展 Business）

当前代码仅 `starter` / `pro`（见 `firebase/functions/stripe_billing.js`）。Business 需增加：

```
STRIPE_PRICE_BUSINESS_MONTHLY=price_...
STRIPE_PRICE_BUSINESS_YEARLY=price_...   # optional
```

### Metadata

Checkout `subscription_data.metadata` 必须含：

```json
{ "companyId": "<Companies doc id>", "planTier": "starter|pro|business" }
```

---

## 与 `PlatformModule` 的门控映射

实现 **按套餐锁模块** 时，在 `PlatformConfigService` 或独立 `PlanFeatureService` 中合并：

```
plan_tier 允许的模块 = industry 预设模块 ∩ 套餐模块
```

| PlatformModule | starter | pro | business |
|----------------|---------|-----|----------|
| orders, pos, drivers, customers, products, reports | ✅ | ✅ | ✅ |
| whatsappImport | ❌ | ✅ | ✅ |
| shopifyImport | ❌ | ✅ | ✅ |
| materialsBom, productionMenu | ❌ | ✅ | ✅ |
| customerBroadcast | ❌ | ✅（额度） | ✅（无限） |
| invoices | ✅ | ✅ | ✅ |
| appointments | ❌ | ❌ | 🔜 |

**Starter CSV：** 导入/导出不绑 Pro，始终允许（仅校验 `manageProducts` / 客户权限）。

---

## 试用与升降级

| 场景 | 行为 |
|------|------|
| 新租户注册批准 | `plan_tier: starter`，`subscription_status: trialing`，14 天 |
| 试用期内 | 全 Starter 功能；**不**开放 Pro 模块（或可选「试用 Pro 3 天」营销） |
| 试用结束未付款 | 禁止建单；Billing 页 CTA |
| Starter → Pro | Stripe Checkout 换 Price；Webhook 更新 `plan_tier` + 解锁模块 |
| Pro → Business | 同上；多门店能力 🔜 随 Business 功能上线 |
| 降级 | Stripe Portal；周期结束后生效；超员工/订单需提示清理 |

---

## 代码现状 vs 本文档（待对齐）

| 项 | 当前代码 | 目标（本文档） |
|----|----------|----------------|
| 套餐档位数 | starter / pro | + **business** |
| Starter 员工上限 | 5（`PLAN_LIMITS`） | **2** |
| Starter 订单上限 | 500/月 | **2,000/月** |
| 按套餐锁模块 | 未实现 | `PlanFeatureService` + UI 升级 CTA |
| 客户群发额度 | 未实现 | `broadcast_quota_*` 字段 |
| Billing 页 | 仅 Starter / Pro 卡片 | + Business；展示功能对比 |
| 币种 | 文档曾混用 SGD | **MYR** 主定价 |

**关键文件：**

- `firebase/functions/stripe_billing.js` — `PLAN_LIMITS`、`priceIdForPlan`
- `lib/backend/subscription_helpers.dart` — 默认试用字段
- `lib/platform/platform_module.dart` — 模块枚举
- `lib/pages/billing_page/billing_page_widget.dart` — 套餐 UI

---

## 对外文案草案（定价页 · 中文）

### Starter — RM 69/月

适合 1–3 人的花店与小零售店。订单、POS、配送、客户与产品管理，以及 CSV 导入导出与基础报表。最多 2 名员工，每月 2,000 笔订单。

### Pro — RM 199/月

适合成长中的门店。含 Starter 全部能力，另加 **WhatsApp 建单**、**Shopify 导单**、BOM 成本、利润分析、库存预警、审计日志、多角色权限与每月 2,000 人客户群发。员工与订单不限。

### Business — RM 499/月

适合连锁与企业。含 Pro 全部能力，另加多门店、总部 Dashboard、跨店库存、Open API 与专属支持。（部分能力随版本发布逐步开放。）

---

## 新币对照（可选第二市场）

面向新加坡客户时，可在 Stripe 另建 SGD Price（不必改 Firestore `plan_tier`）：

| 档位 | 马币（主） | 新币（参考） |
|------|-----------|-------------|
| Starter | RM 69 | S$ 22 |
| Pro | RM 199 | S$ 65 |
| Business | RM 499 | S$ 165 |

---

*EmberCore by EmberSoulLabs · 套餐与功能分层 · 2026-06-23*
