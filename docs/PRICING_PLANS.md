# EmberCore — 套餐与功能分层

**产品：** EmberCore · **公司：** EmberSoulLabs  
**定位：** 订阅制 SaaS ERP（非一次性卖断）  
**币种：** Stripe 主定价 **MYR（马币）** · 公司注册马来西亚（SSM）  
**参考：** 新加坡客户可另建 SGD Price（见文末对照表）

**Stripe 英文文案与年付配置：** [STRIPE_BILLING_SETUP.md](STRIPE_BILLING_SETUP.md)（Appendix A）

**最后更新：** 2026-10-17  
**权威合同：** 以下价格、额度与模块以本节为准。旧的 RM 499、年付 699/1999/4999、Starter 2,000 单、Pro/Business 无限员工或无限订单不再有效。

---

## 设计原则

1. **Starter 要够用** — 小店主能日常经营，不因「缺导出」产生数据绑架感。
2. **Pro 卖差异化** — WhatsApp 建单、Shopify 导单、BOM/利润分析是升级动力，不放 Starter。
3. **Business 卖额度与支持** — 更高员工、订单和群发额度，以及优先支持标记。多门店、总部看板、跨店库存、多仓库、Open API 与 AI 分析尚未实现，不得当作已开通功能销售。
4. **额度制控成本** — 客户群发按人数/月封顶，消息成本可预测。
5. **14 天试用** — 在 App / Firestore 管理（`subscription_status: trialing`），Stripe 产品不设 trial period。

---

## 套餐总览

| 档位 | 月费 MYR | 月费 SGD | 年费 MYR | 年费 SGD | 员工 | 订单/月 | 公司 |
|------|----------:|---------:|---------:|---------:|-----:|--------:|-----:|
| **Starter** | 69 | 29 | 690 | 290 | 2 | 500 | 1 |
| **Pro** | 199 | 79 | 1,990 | 790 | 10 | 3,000 | 1 |
| **Business** | 399 | 159 | 3,990 | 1,590 | 30 | 10,000 | 1 |

**试用（14 天）：** Pro 模块，3 名员工，**100 笔试用订单（终身，不是 Pro 的 3,000/月）**，1 家公司。

**未运营，所有套餐均不可用：** 多门店 / 总部看板、Open API、跨店库存、多仓库、AI 经营分析、Appointments。Business 的优先支持只是分类标记，不是新的产品模块。

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
| 客户群发 | ➖ | 🔢 2,000/月 | 🔢 10,000/月 | `PlatformModule.customerBroadcast`。发送走客户端，月累计计数尚未落地 |
| 审计日志 | ➖ | ✅ | ✅ | `viewAuditLog` 权限 + 3+ 员工场景 |
| 多角色权限 | ➖ | ✅ | ✅ | 完整 RBAC（33 权限） |
| 自定义报表 | ➖ | ✅ | ✅ | 扩展 reports |
| API / Webhook | ➖ | ➖ | 🔜 | Open API 未实现，不随 Pro 或 Business 开通 |

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
| 最多 **2** 个员工 | 含 director；超额提示升级 |
| 最多 **500** 笔订单/月 | 合同额度。付费月度计数重置尚未在规则中落地；试用 100 笔仍单独执行 |
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
| Business | **10,000 人/月** | 超出时阻止本次发送 |

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
| EmberCore Business | `business` | **MYR** | 每月 | **RM 399** |

**年付 Price：** RM 690 / RM 1,990 / RM 3,990。SGD 月付 29 / 79 / 159，年付 290 / 790 / 1,590。

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
| customerBroadcast | ❌ | ✅（2,000/月） | ✅（10,000/月） |
| invoices | ✅ | ✅ | ✅ |
| appointments | ❌ | ❌ | 🔜 |

**Starter CSV：** 导入/导出不绑 Pro，始终允许（仅校验 `manageProducts` / 客户权限）。

---

## 试用与升降级

| 场景 | 行为 |
|------|------|
| 新租户注册批准 | `plan_tier: pro`，`subscription_status: trialing`，14 天，3 员工 / 100 订单 |
| 试用期内 | Pro 模块；额度仍是试用额度，不是付费 Pro 的 10 人 / 3,000 单 |
| 试用结束未付款 | 禁止新建计费操作；历史记录和导出保留 |
| 升级 | 只在已验证的付款确认或经过审计的 Super Admin 手动开通后写入新权益 |
| 降级 | 不删除员工、订单或产品；新写入受较低额度限制 |
| 过期 | 保留历史记录；限制新的计费写入 |

---

## 代码现状 vs 本文档（待对齐）

| 项 | 当前代码 | 目标（本文档） |
|----|----------|----------------|
| 套餐档位 | starter / pro / business | 与 `plan_entitlements.js` 一致 |
| 付费员工 / 订单 | 2/500、10/3000、30/10000 | 公司数均为 1 |
| 试用 | 3 员工 / 100 订单 / Pro 模块 | 不套用付费月额度 |
| 模块门控 | 导航与 Shopify 导入 | 见 `plan_entitlements` |
| 付费订单月重置 | 未落地 | 不把试用计数当成月额度 |
| 群发月累计 | 未落地 | 客户端按单次人数拦截 |
| Appointments、多门店、API、AI | 未实现 | 所有套餐保持关闭 |

**关键文件：**

- `firebase/functions/stripe_billing.js` — `PLAN_LIMITS`、`priceIdForPlan`
- `lib/backend/subscription_helpers.dart` — 默认试用字段
- `lib/platform/platform_module.dart` — 模块枚举
- `lib/pages/billing_page/billing_page_widget.dart` — 套餐 UI

---

## 对外文案草案（定价页 · 中文）

### Starter — RM 69/月

适合小店。订单、POS、配送、客户、产品、发票与基础报表，以及授权 CSV 导出。最多 2 名员工，每月 500 笔订单。不含 WhatsApp 导单、Shopify、BOM、生产菜单和客户群发。

### Pro — RM 199/月

含 Starter 全部能力，另加 WhatsApp 建单、Shopify 导单、BOM、生产菜单、审计日志、租户 RBAC，以及每月 2,000 人客户群发。10 名员工，每月 3,000 笔订单。

### Business — RM 399/月

含 Pro 全部能力。30 名员工，每月 10,000 笔订单，客户群发 10,000 人/月，并标记优先支持。多门店、总部看板、跨店库存、多仓库、Open API 与 AI 分析尚未开通。

---

## 新币对照（可选第二市场）

面向新加坡客户时，可在 Stripe 另建 SGD Price（不必改 Firestore `plan_tier`）：

| 档位 | 马币（主） | 新币（参考） |
|------|-----------|-------------|
| Starter | RM 69 / RM 690 年 | S$ 29 / S$ 290 年 |
| Pro | RM 199 / RM 1,990 年 | S$ 79 / S$ 790 年 |
| Business | RM 399 / RM 3,990 年 | S$ 159 / S$ 1,590 年 |

---

*EmberCore by EmberSoulLabs · 套餐与功能分层 · 2026-06-23*
