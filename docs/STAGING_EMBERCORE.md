# EmberCore Staging — `embercore-erp-staging`

**Web URL：** https://embercore-erp-staging.web.app  
**生产对照：** `embercore-erp` → https://embercore-erp.web.app

**流程：** staging 冒烟通过 → 再部署 production。

---

## 项目对照

| 项 | Staging | Production |
|----|---------|------------|
| Firebase 项目 | `embercore-erp-staging` | `embercore-erp` |
| `.firebaserc` alias | `staging` | `production` |
| Flutter Web | `APP_ENV=staging` | 默认 production |
| Staging admin | `staging.admin@embersoullabs.com` | `kahliantoo@gmail.com` (superadmin) |
| Demo 公司 doc | `staging_company` | `demo_company` |

客户端配置：`lib/backend/firebase/firebase_config.dart`（staging 已指向 `embercore-erp-staging`）。

---

## 一次性 Console 设置

在 [Firebase Console → embercore-erp-staging](https://console.firebase.google.com/project/embercore-erp-staging)：

1. **Blaze 计划** — Cloud Functions 需要（可与 production 同 billing）
2. **Authentication** → Email/Password **启用**
3. **Firestore** — 首次 deploy rules 时会自动创建 `(default)` 库（`asia-southeast1` 推荐）
4. **Storage** → **Get Started**（否则图片上传 smoke 会 skip）
5. **Hosting** — 首次 `firebase deploy --only Hosting` 自动启用
6. **Web App** — 已注册 `EmberCore Staging Web`（2026-06-27）

### Service Account（bootstrap 脚本）

下载 Admin SDK key → 保存为（**勿提交 git**）：

`firebase/keys/embercore-erp-staging-serviceAccount.json`

或设置：

`GOOGLE_APPLICATION_CREDENTIALS=C:\path\to\staging-key.json`

---

## 部署命令

### 快速：Web + bootstrap

```powershell
# 与 production bootstrap 相同密码可复用，或独立 staging 密码
$env:STAGING_ADMIN_PASSWORD = "<from vault>"

powershell -File scripts/deploy_embercore_staging.ps1
```

### 分步

```powershell
cd firebase
firebase use staging

# Rules + indexes（若 503 则隔几分钟重试）
firebase deploy --only firestore:rules,firestore:indexes --project embercore-erp-staging

# Storage rules（需 Console 先启用 Storage）
firebase deploy --only storage --project embercore-erp-staging

# Functions（可选，与 production 同代码）
firebase deploy --only functions --project embercore-erp-staging

# Bootstrap 租户 + staging admin
$env:STAGING_ADMIN_PASSWORD = "<password>"
npm run bootstrap:staging

# Web
cd ..
flutter build web --release --dart-define=APP_ENV=staging
Copy-Item -Recurse -Force build\web\* firebase\public
cd firebase
firebase deploy --only Hosting --project embercore-erp-staging

# 自动化 smoke
npm run smoke:staging
```

### 完整发布门（测试 + 部署 + smoke）

```powershell
powershell -File scripts/deploy_staging_smoke.ps1
```

---

## 手测

完整 UI 清单：[PHASE_A_UI_SMOKE_CHECKLIST.md](PHASE_A_UI_SMOKE_CHECKLIST.md)  
结果记录：[SMOKE_TEST_LOG.md](SMOKE_TEST_LOG.md)

---

## 已知限制（2026-06-27）

| 项 | 状态 | 操作 |
|----|------|------|
| Firestore rules deploy | 可能 503 | 重试 `firebase deploy --only firestore:rules` |
| Storage | 待 Console 启用 | Storage → Get Started |
| Staging SA key | ✅ `firebase/keys/embercore-erp-staging-serviceAccount.json` | 勿提交 git |
| Firebase Authentication | ⬜ **待 Console 启用** | [Authentication → Get Started](https://console.firebase.google.com/project/embercore-erp-staging/authentication) → Email/Password |
| Android staging flavor | 仍指向旧 `tfg-vday-record-staging` | 需新 `google-services.json` 后再测 APK |

---

*EmberCore Staging · 2026-06-27*
