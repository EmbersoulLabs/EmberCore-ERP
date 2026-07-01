# Smoke Test Log

**Current production target:** Firebase project **`embercore-erp`** · Web **https://embercore-erp.web.app**

Related: [SAAS_EXECUTION_PLAN.md §段 A](SAAS_EXECUTION_PLAN.md) · [INTERNAL_TO_SAAS_ERP.md §阶段 1](INTERNAL_TO_SAAS_ERP.md) · [WORKFLOW.md §16](WORKFLOW.md)

**Last automated run:** 2026-06-27 · auth smoke + **段 C 注册 E2E（2–4）PASS**

---

## 段 A — embercore-erp 冒烟验收（A5）

> **段 A 完成标志：** superadmin 登录 → 选公司 → 建单 → 改状态 → 打印；**无需**手改 Firestore。  
> **段 A 验收：** 下表 6 项全 **PASS**。

### A5 手测 + 自动化结果

| # | 场景 | 平台 | 2026-06-27 | 结果 | 证据 / 备注 |
|---|------|------|------------|------|-------------|
| **A5.1** | superadmin 登录 → 选公司 → 建单 → 改状态 → 打印 | Web | 2026-06-27 | **PARTIAL** | **AUTO PASS** superadmin Auth + role（`embercore_smoke_check.js`）· **MANUAL** 待 UI 建单/改状态/打印 |
| **A5.2** | 零售 POS、配送单全流程 | Web + APK 其一 | — | **MANUAL** | 建议 `demo_company` director 账号走 WI + Delivery 各一单 |
| **A5.3** | 客户 CRUD、发票、报表导出 | Web | — | **MANUAL** | 含 CSV 导出、发票列表 |
| **A5.4** | 司机仅见配送页 | Web/APK | 2026-06-27 | **PARTIAL** | **AUTO PASS** `role_route_guard_test.dart`（`/salesDashBoard` 对 driver deny；home=`/driverDeliveryPage`）· **MANUAL** 待 live 登录司机账号 |
| **A5.5** | 离线队列重连 | Android | 2026-06-27 | **PARTIAL** | **AUTO PASS** `offline_write_queue_test.dart`（enqueue + flush）· **MANUAL** 待 APK 断网建单 → 联网同步 |
| **A5.6** | **租户隔离开**：非 superadmin 不可读其他 `companyRef` | Web / Rules | 2026-06-27 | **PASS** | `npm run test:firebase` **101/101** — orders / Order_item / counter / product / customers / SaaS onboarding |

**段 A 总状态：** ⬜ **进行中** — 生产 Auth / Hosting / demo 租户 / rules 全绿；**A5.1 UI + A5.2–A5.3 手测 + A5.4/A5.5 真机** 待完成。

### 段 A 自动化预检（2026-06-27）

| Check | Command | Result | Notes |
|-------|---------|--------|-------|
| Flutter unit tests | `flutter test` | **PASS** | **326/326** |
| Firestore + Storage rules (emulator) | `cd firebase && npm run test:firebase` | **PASS** | **101/101** suites；含租户隔离开、counter、registration rules |
| Hosting 可达 | `node scripts/embercore_smoke_check.js` | **PASS** | `https://embercore-erp.web.app` HTTP 200，含 Flutter assets |
| Superadmin Auth + 角色 | `embercore_smoke_check.js` | **PASS** | `kahliantoo@gmail.com` → `superadmin` · uid `MxWI2jMqTtdBE9cC1RftfV1FmOG2` |
| Director Auth + 角色 | `embercore_smoke_check.js` | **PASS** | `demo.director@embersoullabs.com` → `director` · uid `7YSbkHNkPBgmchs18FI0lZLplCA3` |
| Demo 租户 + Storage | `embercore_smoke_check.js` | **PASS** | `demo_company` active · platform config 存在 · Storage 上传/删除 OK |
| 注册提交 Step 1（段 C） | `npm run smoke:registration` | **PASS** | 匿名 Firestore create + admin 可读 |
| 注册 E2E Steps 2–4（段 C） | `npm run smoke:registration:e2e -- --fresh` | **PASS** | 见下表 · 2026-06-27 |

---

## 段 C — 注册开通 E2E（2026-06-27）

> **完成标志：** 陌生人注册 → superadmin 批准 → director 登录 → 首单 `EC-` 前缀。

| Step | 操作 | 命令 / 路径 | 2026-06-27 | 结果 | 证据 |
|------|------|-------------|------------|------|------|
| **1** | 匿名提交 `user_registration_requests` | `npm run smoke:registration` | 2026-06-27 | **PASS** | pending doc · anon read denied |
| **2** | superadmin 调用 `approveRegistrationRequest` | `npm run smoke:registration:e2e` | 2026-06-27 | **PASS** | Callable 开通租户 · company `NWNQ3DFnJ1zazzwc9CSY` |
| **3** | director 登录 + `users/{uid}` profile | 同上 | 2026-06-27 | **PASS** | role `director` · `companyRef` 正确 |
| **4** | `tenant_platform_config.order_id_prefix=EC` + 首单 | 同上 | 2026-06-27 | **PASS** | 订单 `EC-JUN26-00099` · industry `generic` |

**Latest E2E tenant:** `saas-e2e-2026-06-27t12-39-49-054z@embersoullabs.com` · company `NWNQ3DFnJ1zazzwc9CSY`

```bash
cd firebase
set EMBERCORE_SUPERADMIN_PASSWORD=<from vault>
npm run smoke:registration:e2e -- --fresh   # Step 1–4 全自动
npm run smoke:registration:e2e -- --email pending@example.com   # 批准已有 pending
```

**段 C E2E 总状态：** ✅ **PASS**（自动化）· UI 手测（App 内点批准 + reset link 流程）仍建议抽测一次。

---

```bash
# Flutter
flutter test

# Firebase rules + counter integration (needs Java 21+)
cd firebase
npm run test:firebase

# Production smoke (passwords from team vault — do not commit)
set EMBERCORE_SUPERADMIN_PASSWORD=<from vault>
set EMBERCORE_DIRECTOR_PASSWORD=<from vault>
npm run smoke:embercore
npm run smoke:registration:e2e -- --fresh
```

**段 A 手测清单（可打印）：** [PHASE_A_UI_SMOKE_CHECKLIST.md](PHASE_A_UI_SMOKE_CHECKLIST.md)  
**Staging 部署指南：** [STAGING_EMBERCORE.md](STAGING_EMBERCORE.md)

---

在 **https://embercore-erp.web.app** 硬刷新（Ctrl+Shift+R）后执行。记录 order ID / 截图到上表 Evidence 列。

### A5.1 — Superadmin 核心流（Web，~15 min）

1. Superadmin 登录（`kahliantoo@gmail.com` 或你的 superadmin）
2. **Company Selection** → 选 `demo_company`（或任一 active 租户）
3. **Dashboard** → Create Order → **Delivery** 一单 → 填客户 → 加商品 → 提交
4. **Order list** → 打开订单 → 推进状态（Pending → … → Delivered 或等价链）
5. **Print PDF** / 配送单 — 确认租户名与字段标签正常

### A5.2 — 零售 + 配送（Web 或 APK，~15 min）

1. **Retail / POS**：Walk-in 零售单 → 收银 → 小票/摘要页
2. **Delivery**：再建配送单 → 分配司机（如有）→ 司机端可见（接 A5.4）

### A5.3 — 客户 / 发票 / 报表（Web，~10 min）

1. **Customers** → 新建 → 编辑 → 搜索
2. **Invoices** → 列表 / 确认页（如有未结订单）
3. **Sales report** → 选日期范围 → **Export CSV**

### A5.4 — 司机路由（Web/APK，~5 min）

1. 司机账号登录 → 应进入 **My Deliveries**，**不能**打开 Dashboard / Order list URL
2. 推进一单状态 → staff 端订单详情同步

### A5.5 — 离线队列（Android only，~10 min）

1. 开启飞行模式 → Create Order → 确认 queued
2. 恢复网络 → 确认同步成功、Firestore 有订单 doc

---

## A1–A4 部署与种子（embercore-erp）

| # | 任务 | 状态 | 日期 | 备注 |
|---|------|------|------|------|
| A1 | `firebase/` 在仓库 + `.firebaserc` → `embercore-erp` | ✅ | 2026-06-24 | |
| A2 | Auth / Firestore / Storage / Hosting / Functions | ✅ | 2026-06-24 | `asia-southeast1` |
| A3.1 | `firestore.rules` + indexes 部署 | ✅ | 2026-06-27 | registration `status+created_time` index 已加 |
| A3.2 | `storage.rules` + CORS | ✅ | 2026-06-24 | |
| A3.3 | Cloud Functions（含 `approveRegistrationRequest`） | ✅ | 2026-06-27 | |
| A3.4 | `flutter build web` → Hosting | ✅ | 2026-06-27 | 含 logo + registration Timestamp 修复 |
| A3.5 | `npm run test:firebase` | ✅ | 2026-06-27 | 101/101 |
| A4 | 种子：superadmin + demo 租户 + 商品 | ⬜ | | Console / 脚本确认 `demo_company` counters + 至少 1 product |
| A4b | 老花店 `tenant_platform_config` florist | ⬜ | | 无老用户可跳过 |

**Staging（A2 扩展）：** 见 [STAGING_EMBERCORE.md](STAGING_EMBERCORE.md) · Firestore + **rules** + indexes 已部署 · **Hosting 已部署** https://embercore-erp-staging.web.app · bootstrap 待 staging service account key

---

## Rules regression（`npm run test:firebase` — 2026-06-27）

| Area | Expected | Result |
|------|----------|--------|
| orders tenant isolation | driver/staff 不可跨 company | **PASS** |
| Order_item tenant isolation | 同上 | **PASS** |
| counter tenant isolation | driver 不可读他司 counter | **PASS** |
| product / customers writes | 不可写他司 | **PASS** |
| SaaS onboarding | registration create/read/approve；platform_config 读写边界 | **PASS** |
| storage rules | delivery proof / invoice / product image claims | **PASS** |
| init_counters + order counter integration | emulator 递增与建单 | **PASS** |

---

## Flutter tests（2026-06-27）

**Command:** `flutter test` · **Result:** **326 passed**

| File | 段 A 相关 |
|------|-----------|
| `role_route_guard_test.dart` | A5.4 司机路由 |
| `offline_write_queue_test.dart` | A5.5 离线队列逻辑 |
| `tenant_product_filter_test.dart` | 租户商品过滤 |
| `order_status_helpers_test.dart` | 状态链 |
| `registration_approval_service_test.dart` | Timestamp → DateTime 解析 |
| `order_id_service_test.dart` | 动态 order prefix |
| （其余 320+） | 回归 |

---

## 历史记录 — tfg-sales-record（2026-06-03 — 2026-06-05）

> 以下为迁移至 EmberCore 前的 **tfg-sales-record** 峰值季记录，仅供参考。

**Environment:** Firebase project `tfg-sales-record` · Web **https://tfg-sales-record.web.app**

### P1 automated verification (legacy)

| Check | Result | Notes |
|-------|--------|-------|
| Flutter unit tests | **CI** | 当时 67 cases |
| Production counter init | **PASS** | 2026-06-03 |
| Production user/counter audit | **PASS** | `npm run verify:peak` |
| Deploy Web + rules | **PASS** | 2026-06-05 |

### §16 Smoke — Summary (legacy)

| Step | Result | Notes |
|------|--------|-------|
| C1-1 Deploy rules | **PASS** | 2026-06-03 |
| C1-1b Deploy housing | **PASS** | tfg-sales-record.web.app |
| C1-4 Driver test account | **PASS** | `tfg.driver.smoke@gmail.com` |
| C3-2 Block staff routes | **PASS** | unit test |
| D3 Status chain | **PASS** | unit test |

### verify:peak warnings (closed 2026-06-03)

| Code | Resolution |
|------|------------|
| `USER_UID_MISMATCH` | `npm run fix:user-ids` |
| `NO_DRIVER_ACCOUNT` | `npm run create:driver` |

---

## Known issues / tickets

| Date | ID | Severity | Description | Status |
|------|-----|----------|-------------|--------|
| 2026-06-27 | a5-manual | info | A5.1 UI 建单/打印、A5.2–A5.3 手测待完成 | open |
| 2026-06-27 | a5-android | info | A5.5 需 Android APK 断网手测 | open |
| 2026-06-27 | a4-seed | info | 确认 `demo_company` counters + 测试商品已 seed | open |
| — | local-java | info | `npm run test:firebase` 需 **JDK 21+** | use CI or Temurin 21 |

---

*EmberCore by EmberSoulLabs · Smoke Test Log · updated 2026-06-27*
