# 段 A — UI 手测清单（embercore-erp）

**生产 Web：** https://embercore-erp.web.app  
**Staging Web：** https://embercore-erp-staging.web.app（部署后）  
**记录结果：** 填完后更新 [SMOKE_TEST_LOG.md](SMOKE_TEST_LOG.md) 对应行。

**建议用时：** 45–60 分钟 · **平台：** 手机 Chrome + 桌面 Chrome 各测一轮 App Bar / 核心流。

---

## 测试账号

| 角色 | 邮箱 | 密码来源 | 用途 |
|------|------|----------|------|
| Superadmin | `kahliantoo@gmail.com` | bootstrap 凭据 | A5.1、注册审批 UI |
| Director（demo） | `demo.director@embersoullabs.com` | bootstrap 凭据 | A5.2–A5.3 |
| Staging admin | `staging.admin@embersoullabs.com` | `STAGING_ADMIN_PASSWORD` | Staging 环境 |
| 司机 | （若有） | 团队 vault | A5.4 |

> 密码勿写入本仓库；手测时在本地记 order ID / 截图即可。

---

## 测前准备

- [ ] 硬刷新（Ctrl+Shift+R）或清除站点缓存
- [ ] 确认登录页显示 **EmberSoul Labs** logo
- [ ] Superadmin 能进入 **Company Selection**
- [ ] 选中 **`demo_company`**（或任一 active 租户）

**执行人：** _______________ · **日期：** _______________ · **环境：** ☐ 生产 ☐ Staging

---

## A5.1 — Superadmin 建单 → 改状态 → 打印（~15 min）

| # | 步骤 | PASS | FAIL | 证据（order ID / 备注） |
|---|------|:----:|:----:|-------------------------|
| 1.1 | Superadmin 登录成功 | ☐ | ☐ | |
| 1.2 | Company Selection → 选公司 → 进入 Dashboard | ☐ | ☐ | 公司名：________ |
| 1.3 | App Bar 显示 logo，图标不拥挤（手机） | ☐ | ☐ | |
| 1.4 | Create Order → **Delivery / Remote** 一单 | ☐ | ☐ | Order ID：________ |
| 1.5 | 添加至少 1 个 catalog 商品 + 保存 | ☐ | ☐ | |
| 1.6 | 填写客户/联系人信息并提交订单 | ☐ | ☐ | |
| 1.7 | Order list 可见新订单 | ☐ | ☐ | |
| 1.8 | Order detail → 推进状态（至少 2 步） | ☐ | ☐ | 状态链：________ |
| 1.9 | Print PDF / 配送单 — 租户名与字段标签正常 | ☐ | ☐ | ☐ PDF 无花店硬编码 |

**A5.1 结果：** ☐ PASS ☐ FAIL

---

## A5.2 — 零售 POS + 配送全流程（~15 min）

| # | 步骤 | PASS | FAIL | 证据 |
|---|------|:----:|:----:|------|
| 2.1 | **Retail / Walk-in / POS** 建零售单 | ☐ | ☐ | Order ID：________ |
| 2.2 | 零售单含 `-WI` 或零售标记；收银/摘要页正常 | ☐ | ☐ | |
| 2.3 | 再建 **Delivery / Remote** 一单（可与 1.4 不同单） | ☐ | ☐ | Order ID：________ |
| 2.4 | （可选）分配司机 | ☐ | ☐ | 司机：________ |
| 2.5 | 订单号前缀符合租户配置（demo=`EC` 或 florist=`TFG`） | ☐ | ☐ | 前缀：________ |

**A5.2 结果：** ☐ PASS ☐ FAIL

---

## A5.3 — 客户 / 发票 / 报表（~10 min）

| # | 步骤 | PASS | FAIL | 证据 |
|---|------|:----:|:----:|------|
| 3.1 | Customers → 新建客户 | ☐ | ☐ | 客户 ID：________ |
| 3.2 | 编辑客户 → 搜索能找到 | ☐ | ☐ | |
| 3.3 | Invoices 列表可打开（如有未结订单） | ☐ | ☐ | |
| 3.4 | Sales Report → 选日期范围 | ☐ | ☐ | |
| 3.5 | Export CSV 下载成功、列对齐 | ☐ | ☐ | 文件名：________ |

**A5.3 结果：** ☐ PASS ☐ FAIL

---

## A5.4 — 司机仅见配送页（~5 min）

| # | 步骤 | PASS | FAIL | 证据 |
|---|------|:----:|:----:|------|
| 4.1 | 司机账号登录 → 进入 **My Deliveries** | ☐ | ☐ | |
| 4.2 | 手动访问 `/salesDashBoard` 或 Dashboard URL → **被拦截或跳转** | ☐ | ☐ | |
| 4.3 | 推进一单配送状态 | ☐ | ☐ | Order ID：________ |
| 4.4 | Staff 端 order detail 看到司机更新 | ☐ | ☐ | |

**A5.4 结果：** ☐ PASS ☐ FAIL ☐ SKIP（无司机账号）

---

## A5.5 — 离线队列（Android only，~10 min）

| # | 步骤 | PASS | FAIL | 证据 |
|---|------|:----:|:----:|------|
| 5.1 | 飞行模式 / 断网 → Create Order → 显示 queued | ☐ | ☐ | |
| 5.2 | 恢复网络 → 自动同步 | ☐ | ☐ | Firestore doc ID：________ |
| 5.3 | 同步后订单在 list 可见 | ☐ | ☐ | |

**A5.5 结果：** ☐ PASS ☐ FAIL ☐ SKIP（仅 Web 手测）

---

## A5.6 — 租户隔离开（Web 抽测，~5 min）

> 自动化 rules **101/101 PASS**；此项为 live 抽测。

| # | 步骤 | PASS | FAIL | 证据 |
|---|------|:----:|:----:|------|
| 6.1 | Director A 登录 → 订单列表**仅**见本公司 | ☐ | ☐ | 公司：________ |
| 6.2 | （可选）Superadmin 切换公司 → 可见另一租户数据 | ☐ | ☐ | |

**A5.6 结果：** ☐ PASS ☐ FAIL

---

## 段 C UI 抽测（注册审批，~10 min）

| # | 步骤 | PASS | FAIL | 证据 |
|---|------|:----:|:----:|------|
| C.1 | Superadmin → `/registrationRequests` → **Pending** 列表加载 | ☐ | ☐ | |
| C.2 | 展开一条 → Approve → 弹出 reset link 或成功提示 | ☐ | ☐ | 邮箱：________ |
| C.3 | `/tenantList` 可见新租户 | ☐ | ☐ | companyId：________ |

**段 C UI 结果：** ☐ PASS ☐ FAIL

---

## 汇总

| 项 | 结果 |
|----|------|
| A5.1 | ☐ PASS ☐ FAIL |
| A5.2 | ☐ PASS ☐ FAIL |
| A5.3 | ☐ PASS ☐ FAIL |
| A5.4 | ☐ PASS ☐ FAIL / SKIP |
| A5.5 | ☐ PASS ☐ FAIL / SKIP |
| A5.6 | ☐ PASS ☐ FAIL |
| 段 C UI | ☐ PASS ☐ FAIL |

**段 A UI 总评：** ☐ **全部 PASS**（可勾选 INTERNAL_TO_SAAS_ERP 阶段 1.5） ☐ 仍有 FAIL（见上表）

---

## 失败后快速排查

| 现象 | 检查 |
|------|------|
| 注册列表报错 index | `firebase deploy --only firestore:indexes --project embercore-erp` |
| 注册列表 TypeError | 已修 Timestamp；硬刷新 Hosting |
| 登录失败 | Auth Console 用户是否存在 · 密码 · `is_active` |
| 建单 permission-denied | Firestore rules 是否最新 · `companyRef` |
| 图片上传失败 | Storage 是否启用 · CORS |

---

*EmberCore · 段 A UI 手测清单 · 2026-06-27*
