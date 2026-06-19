# Privacy Policy (DRAFT) — EmberCore

> **DRAFT — NOT FOR PUBLICATION**  
> Review required by a Malaysia-qualified lawyer before use.  
> **草案 — 禁止直接对外发布** · 须经律师审阅。

**Last updated (draft):** `[YYYY-MM-DD]`  
**Effective date:** `[YYYY-MM-DD]`  
**Operator / 运营方:** EmberSoulLabs (`[SSM Registration No.]`)  
**Registered address:** `[FULL MALAYSIA ADDRESS]`  
**Product / 产品:** EmberCore  
**Website:** https://embersoullabs.com  
**App / Web app:** `[e.g. https://app.embersoullabs.com or https://embercore-erp.web.app]`  
**Privacy contact:** `[privacy@embersoullabs.com]`  
**General support:** `[support@embersoullabs.com]`

---

# English Version

## 1. Introduction

EmberSoulLabs (“**we**”, “**us**”, “**our**”) operates **EmberCore**, a cloud-based operations platform for businesses (including appointments, field service, point of sale, and delivery). This Privacy Policy explains how we collect, use, disclose, store, and protect **personal data** when you:

- visit our website or marketing pages;
- submit a **registration request** to use EmberCore;
- use EmberCore as a **staff user** of a business customer (“**Tenant**”); or
- contact us for support.

This policy is prepared with reference to Malaysia’s **Personal Data Protection Act 2010 (PDPA)**. If you are a **data subject** in Malaysia, you have rights under the PDPA as described below.

**Important — Tenant customer data:** If you are an end customer of a business that uses EmberCore (for example, a recipient of a delivery order), that business is usually the **data user** for your information. We process such data **on the Tenant’s instructions** as a **data processor**. Please contact the relevant business first; we will assist the Tenant as required by contract and law.

---

## 2. Roles

| Role | Who | Example |
|------|-----|---------|
| **Data user** | The Tenant (business subscriber) | Florist shop using EmberCore |
| **Data processor** | EmberSoulLabs | Hosting and processing Tenant data in EmberCore |
| **Platform users** | Tenant’s staff | Directors, admins, florists, drivers |
| **Registration applicants** | Prospective Tenants | Person submitting `/userSignup` |

For **staff accounts** and **registration requests**, EmberSoulLabs may act as **data user** for account administration. Your lawyer should confirm this split for your contracts.

---

## 3. Personal data we collect

### 3.1 Account and registration (staff / applicants)

| Data | Purpose |
|------|---------|
| Name, email, phone | Account, login, communication |
| Password (hashed) | Authentication via Firebase Auth — we do not store plain passwords |
| Job role, company association | Access control within a Tenant |
| Birthday (if provided at signup) | Optional profile field |
| Company name, UEN, address, phone, email, logo (company signups) | Registration review and tenant setup |

### 3.2 Business operations data (processed for Tenants)

When Tenants use EmberCore, the system may store personal data their staff enter about **their** customers and orders, for example:

- Customer and recipient names, phone numbers, email, billing address, birthday (if used)
- Delivery / service addresses, time windows, order notes
- Proof-of-delivery photos, signatures, or related images uploaded by staff
- Invoice and credit-related identifiers linked to customers

We process this data **only to provide the service to the Tenant**, not for our own marketing to those individuals unless separately permitted by law and contract.

### 3.3 Technical and usage data

| Data | Purpose |
|------|---------|
| Device identifiers, app version, crash logs | Stability, security, support (e.g. Firebase Crashlytics / Performance) |
| IP address, browser type (Web) | Security, fraud prevention, diagnostics |
| Push notification tokens (FCM) | Staff notices and operational alerts |
| Audit logs (user id, action, timestamp) | Security and accountability |

### 3.4 Payment data (when subscription billing is enabled)

If you pay for a subscription, payment card or bank details are handled by our **payment service provider** (e.g. `[Stripe / Billplz / other — TO BE CONFIRMED]`). We receive limited billing metadata (customer id, subscription status, last four digits if applicable) — **not** full card numbers stored by us.

### 3.5 Cookies and similar technologies (Web)

We may use essential cookies for login sessions and preferences (e.g. language). `[DESCRIBE ANALYTICS COOKIES IF ANY, e.g. Google Analytics — or state “we do not use non-essential cookies”]`. See our `[Cookie Policy URL — if separate]`.

---

## 4. How we use personal data

We use personal data to:

1. Provide, maintain, and improve EmberCore;
2. Authenticate users and enforce role-based access;
3. Process registration requests and onboard Tenants;
4. Send service-related notices (security, billing, product updates);
5. Provide customer support;
6. Comply with legal obligations and respond to lawful requests;
7. Protect against fraud, abuse, and security incidents.

**Legal bases (summary):** contract performance, legitimate interests (security, product improvement), consent where required (e.g. marketing emails, optional fields), and legal obligation.

We **do not sell** personal data.

---

## 5. Disclosure and subprocessors

We may share personal data with:

| Recipient | Why |
|-----------|-----|
| **Google Firebase / Google Cloud** | Authentication, database (Firestore), file storage, hosting, messaging, crash reporting — project `embercore-erp`, region **asia-southeast1** |
| `[Payment provider]` | Subscription payments |
| `[Email provider, if any]` | Transactional email |
| Professional advisers | Legal, accounting — under confidentiality |
| Authorities | When required by Malaysian or other applicable law |

A current list of subprocessors may be published at `[URL]` or provided on request.

**International transfer:** Data may be processed in Singapore and other countries where our subprocessors operate. We take steps required under PDPA for cross-border transfers `[DESCRIBE WITH LAWYER — e.g. consent, contractual clauses]`.

---

## 6. Security

We implement appropriate technical and organisational measures, including:

- TLS encryption in transit;
- Firebase security rules and tenant isolation by `companyRef`;
- Role-based access control in the application;
- Restricted access to production systems for authorised personnel only.

No method of transmission or storage is 100% secure. Tenants are responsible for strong passwords and controlling staff access within their organisation.

---

## 7. Retention

| Category | Retention (draft — confirm with lawyer) |
|----------|----------------------------------------|
| Active staff accounts | While the account is active and the Tenant subscribes |
| Registration requests | `[e.g. 24 months after decision]` |
| Tenant business data | While subscription is active + `[e.g. 90 days]` export window after termination |
| Backups | `[e.g. up to 35 days]` rolling backups if applicable |
| Audit / security logs | `[e.g. 12–24 months]` |

After retention periods, we delete or anonymise data unless law requires longer storage.

---

## 8. Your rights (Malaysia PDPA)

Subject to PDPA and applicable exceptions, you may request:

- **Access** to your personal data;
- **Correction** of inaccurate data;
- **Withdrawal of consent** where processing is consent-based;
- **Limitation** of processing in certain cases;

To exercise rights, email **`[privacy@embersoullabs.com]`** with sufficient identity verification. We aim to respond within **`[21]`** days.

If you are an end customer of a Tenant, contact the **Tenant** first; we will support them in handling your request.

You may lodge a complaint with the **Personal Data Protection Department (PDPC), Malaysia**: https://www.pdp.gov.my

---

## 9. Children

EmberCore is a **business-to-business** service. It is not directed at children under 18. We do not knowingly collect children’s personal data. Contact us if you believe we have done so.

---

## 10. Changes

We may update this policy. We will post the new version with an updated “Last updated” date and, for material changes, notify Tenant administrators by email or in-app notice.

---

## 11. Contact

**EmberSoulLabs**  
`[FULL ADDRESS]`  
Email: `[privacy@embersoullabs.com]`  
Phone: `[+60-X-XXXX XXXX]`

---

# 中文版本（草案）

## 1. 引言

EmberSoulLabs（「**我们**」）运营 **EmberCore** 云端运营平台（预约、外勤、收银、配送等）。本隐私政策说明我们如何依据马来西亚 **2010 年个人数据保护法（PDPA）** 收集、使用、披露、保存及保护**个人数据**。

适用范围包括：访问官网、提交 **注册申请**、作为租户**员工**使用系统、联系客服。

**重要 — 终端客户数据：** 若您是使用 EmberCore 的商家（租户）的客户（例如收花人），该商家通常是个人数据的**数据使用者**；我们仅**代租户处理**数据。请先联系该商家；我们将按合同与法律协助租户。

---

## 2. 我们收集的数据（摘要）

- **员工 / 申请人：** 姓名、邮箱、电话、角色、公司信息、密码（加密存储）、可选生日；公司注册时的 UEN、地址、Logo 等。  
- **租户业务数据：** 客户/收件人姓名、电话、地址、订单与发票相关字段、配送证明图片等（由租户员工录入）。  
- **技术数据：** 设备信息、崩溃日志、推送 token、IP、审计日志等。  
- **订阅付款（如已开通）：** 由 `[支付服务商]` 处理；我们不保存完整卡号。

---

## 3. 使用目的

提供与维护服务、身份验证与权限、注册审批与开通、服务通知与客服、安全与合规、产品改进。**我们不出售个人数据。**

---

## 4. 披露与受托处理

主要受托处理者：**Google Firebase / Google Cloud**（项目 `embercore-erp`，区域 **asia-southeast1**），用于认证、数据库、存储、托管、消息与崩溃报告。另有支付、邮件服务商及依法向主管机关披露的情形。

数据可能在马来西亚境外（如新加坡）处理。跨境传输措施：`[与律师确认后填写]`。

---

## 5. 安全与保留

采用传输加密、Firestore 安全规则、租户隔离（`companyRef`）、应用内角色权限等。保留期限见上文英文第 7 节表格（发布前与律师确认）。

---

## 6. 您的权利

在 PDPA 适用范围内，可申请查阅、更正、撤回同意等。联系 **`[privacy@embersoullabs.com]`**。租户终端客户请先联系**租户**。

可向马来西亚 **PDPC** 投诉：https://www.pdp.gov.my

---

## 7. 政策变更与联系

更新后将公布新版生效日期。重大变更将通知租户管理员。

**EmberSoulLabs** · `[地址]` · `[privacy@embersoullabs.com]` · `[电话]`

---

## Appendix — App store data safety (checklist)

Use this when filling Google Play / Apple App Store forms. Must **match** the published policy.

| Data type | Collected | Linked to user | Purpose |
|-----------|-----------|----------------|---------|
| Name | Yes | Yes | Account, orders |
| Email | Yes | Yes | Account |
| Phone | Yes | Yes | Account, orders |
| Physical address | Yes | Yes | Delivery / service |
| Photos | Yes | Yes | Proof of delivery, logos |
| Device IDs / crash data | Yes | Yes | Diagnostics |
| Financial info | `[If billing]` | Yes | Payments via PSP |

---

## Lawyer review notes (internal)

- [ ] Confirm data user vs processor for staff vs tenant customer data  
- [ ] Cross-border transfer mechanism (PDPA §129)  
- [ ] Retention periods vs backup and Firestore export practice  
- [ ] Marketing / newsletter — separate consent if added  
- [ ] Align with future **DPA** for B2B tenants  
- [ ] Malay language version required? `[Counsel to advise]`  

---

*Draft for EmberCore by EmberSoulLabs · Not legal advice · 2026-06-18*
