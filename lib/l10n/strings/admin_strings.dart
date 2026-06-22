/// Admin pages (user list, role permissions).
const Map<String, Map<String, String>> adminStrings = {
  'admin.userList.title': {
    'en': 'User List',
    'zh': '员工列表',
    'ms': 'Senarai Staf',
  },
  'admin.userList.noPermission': {
    'en': 'You do not have permission to view users.',
    'zh': '您没有查看员工的权限。',
    'ms': 'Anda tiada kebenaran untuk melihat staf.',
  },
  'admin.userList.loadFailed': {
    'en': 'Failed to load users.',
    'zh': '加载员工失败。',
    'ms': 'Gagal memuatkan staf.',
  },
  'admin.userList.noUsers': {
    'en': 'No users found.',
    'zh': '未找到员工。',
    'ms': 'Tiada staf dijumpai.',
  },
  'admin.userList.updateFailed': {
    'en': 'Update failed: {error}',
    'zh': '更新失败：{error}',
    'ms': 'Kemas kini gagal: {error}',
  },
  'admin.userList.deleteTitle': {
    'en': 'Delete user?',
    'zh': '删除员工？',
    'ms': 'Padam staf?',
  },
  'admin.userList.deleteBody': {
    'en': 'Delete profile for {name}?\n\n'
        'This removes the Firestore profile only. '
        'The Firebase Auth account remains.',
    'zh': '删除 {name} 的资料？\n\n'
        '仅删除 Firestore 资料，Firebase Auth 账户仍保留。',
    'ms': 'Padam profil {name}?\n\n'
        'Ini hanya memadam profil Firestore. '
        'Akaun Firebase Auth kekal.',
  },
  'admin.userList.deleted': {
    'en': 'User deleted.',
    'zh': '员工已删除。',
    'ms': 'Staf dipadam.',
  },
  'admin.userList.deleteFailed': {
    'en': 'Delete failed: {error}',
    'zh': '删除失败：{error}',
    'ms': 'Padam gagal: {error}',
  },
  'admin.userList.cannotEditRoles': {
    'en': 'You cannot edit staff roles.',
    'zh': '您无法编辑员工角色。',
    'ms': 'Anda tidak boleh mengedit peranan staf.',
  },
  'admin.userList.updated': {
    'en': 'User updated.',
    'zh': '员工已更新。',
    'ms': 'Staf dikemas kini.',
  },
  'admin.userList.addRole': {
    'en': 'Add role',
    'zh': '添加角色',
    'ms': 'Tambah peranan',
  },
  'admin.userList.addStaff': {
    'en': 'Add staff',
    'zh': '添加员工',
    'ms': 'Tambah staf',
  },
  'admin.userList.rolePermissionsTooltip': {
    'en': 'Role permissions — temporarily enable extra access for a role',
    'zh': '角色权限 — 临时为某角色开启额外权限',
    'ms': 'Kebenaran peranan — benarkan akses tambahan sementara',
  },
  'admin.userList.colName': {
    'en': 'Name',
    'zh': '姓名',
    'ms': 'Nama',
  },
  'admin.userList.colRole': {
    'en': 'Role',
    'zh': '角色',
    'ms': 'Peranan',
  },
  'admin.userList.colActions': {
    'en': 'Actions',
    'zh': '操作',
    'ms': 'Tindakan',
  },
  'admin.userList.editUser': {
    'en': 'Edit user',
    'zh': '编辑员工',
    'ms': 'Edit staf',
  },
  'admin.userList.deleteUser': {
    'en': 'Delete user',
    'zh': '删除员工',
    'ms': 'Padam staf',
  },
  'admin.rolePermissions.title': {
    'en': 'Role Permissions',
    'zh': '角色权限',
    'ms': 'Kebenaran Peranan',
  },
  'admin.rolePermissions.noAccess': {
    'en': 'Only Admin, Director, or Super Admin can manage role permissions.',
    'zh': '仅管理员、总监或超级管理员可管理角色权限。',
    'ms': 'Hanya Admin, Pengarah, atau Super Admin boleh mengurus kebenaran peranan.',
  },
  'admin.rolePermissions.intro': {
    'en': 'Company-wide defaults per role. Director and Admin can edit this matrix. '
        'Personal per-user overrides are Super Admin only (User List → Edit user). '
        'Example: while Admin is on leave, temporarily enable extra Florist permissions, then turn them off after Save.',
    'zh': '按角色设置全公司默认权限。Director 与 Admin 可编辑此矩阵。'
        '个人权限仅 Super Admin 可在「用户列表 → 编辑用户」中设置。'
        '例如：管理员休假时可临时为花艺师开启额外权限，保存后该角色全员生效。',
    'ms': 'Lalai syarikat mengikut peranan. Director dan Admin boleh edit matriks ini. '
        'Ganti peribadi per pengguna hanya Super Admin (Senarai Pengguna → Edit). '
        'Contoh: semasa Admin bercuti, benarkan kebenaran tambahan untuk Florist, kemudian matikan selepas Simpan.',
  },
  'admin.rolePermissions.superAdminNote': {
    'en':
        'Super Admin always has full access. Admin cannot assign the Director role.',
    'zh': 'Super Admin 始终拥有全部权限。Admin 不能分配 Director 角色。',
    'ms':
        'Super Admin sentiasa mempunyai akses penuh. Admin tidak boleh tetapkan peranan Director.',
  },
  'admin.rolePermissions.save': {
    'en': 'Save permissions',
    'zh': '保存权限',
    'ms': 'Simpan kebenaran',
  },
  'admin.rolePermissions.saved': {
    'en': 'Role permissions saved. Staff with that role will pick up changes shortly.',
    'zh': '角色权限已保存，该角色员工将很快生效。',
    'ms': 'Kebenaran peranan disimpan. Staf dengan peranan itu akan menerima perubahan tidak lama lagi.',
  },
  'admin.rolePermissions.saveFailed': {
    'en': 'Save failed: {error}',
    'zh': '保存失败：{error}',
    'ms': 'Simpan gagal: {error}',
  },
  'admin.rolePermissions.defaultsSubtitle': {
    'en': 'Defaults apply unless overridden below.',
    'zh': '以下为默认权限，可在下方覆盖。',
    'ms': 'Lalai terpakai melainkan ditulis ganti di bawah.',
  },
  'admin.rolePermissions.resetDefaults': {
    'en': 'Reset to defaults',
    'zh': '恢复默认',
    'ms': 'Set semula ke lalai',
  },
  'admin.rolePermissions.manageDialogTitle': {
    'en': 'Manage Roles',
    'zh': '管理角色',
    'ms': 'Urus Peranan',
  },
  'admin.userPermissions.sectionTitle': {
    'en': 'Personal permissions (this user only)',
    'zh': '个人权限（仅该用户）',
    'ms': 'Kebenaran peribadi (pengguna ini sahaja)',
  },
  'admin.userPermissions.intro': {
    'en':
        'Override this user\'s access vs their role. Only Super Admin can edit. Changes apply after they reopen the app.',
    'zh': '相对其角色单独调整权限。仅超级管理员可编辑。员工重新打开 App 后生效。',
    'ms':
        'Tulis ganti akses pengguna berbanding peranan. Hanya Super Admin boleh edit. Berkuat kuasa selepas mereka buka semula app.',
  },
  'admin.userPermissions.resetDefaults': {
    'en': 'Clear personal overrides',
    'zh': '清除个人覆盖',
    'ms': 'Kosongkan ganti peribadi',
  },
  'admin.userPermissions.usesRoleDefault': {
    'en': 'Uses role default',
    'zh': '使用角色默认',
    'ms': 'Guna lalai peranan',
  },
  'admin.userPermissions.customOverride': {
    'en': 'Custom for this user',
    'zh': '该用户单独设置',
    'ms': 'Khas untuk pengguna ini',
  },

  'admin.register.title': {
    'en': 'Add staff',
    'zh': '添加员工',
    'ms': 'Tambah staf',
  },
  'admin.register.heading': {
    'en': 'Create staff account',
    'zh': '创建员工账户',
    'ms': 'Cipta akaun staf',
  },
  'admin.register.hintSuperAdmin': {
    'en': 'Super admin: choose company, then create staff (Admin, Senior Florist, or Driver). '
        'You will be signed out — sign in again afterward.',
    'zh': '超级管理员：选择公司后创建员工（管理员、高级花艺师或司机）。'
        '创建后您将登出，请重新登录。',
    'ms': 'Super admin: pilih syarikat, kemudian cipta staf (Admin, Florist Kanan, atau Pemandu). '
        'Anda akan dilog keluar — log masuk semula selepas itu.',
  },
  'admin.register.hintAdmin': {
    'en': 'Creates a staff account for your company (Admin, Senior Florist, or Driver). '
        'You will be signed out — sign in again afterward.',
    'zh': '为本公司创建员工账户（管理员、高级花艺师或司机）。'
        '创建后您将登出，请重新登录。',
    'ms': 'Mencipta akaun staf untuk syarikat anda (Admin, Florist Kanan, atau Pemandu). '
        'Anda akan dilog keluar — log masuk semula selepas itu.',
  },
  'admin.register.fullName': {
    'en': 'Full name',
    'zh': '姓名',
    'ms': 'Nama penuh',
  },
  'admin.register.email': {
    'en': 'Email',
    'zh': '邮箱',
    'ms': 'E-mel',
  },
  'admin.register.phoneOptional': {
    'en': 'Phone (optional)',
    'zh': '电话（可选）',
    'ms': 'Telefon (pilihan)',
  },
  'admin.register.password': {
    'en': 'Password',
    'zh': '密码',
    'ms': 'Kata laluan',
  },
  'admin.register.confirmPassword': {
    'en': 'Confirm password',
    'zh': '确认密码',
    'ms': 'Sahkan kata laluan',
  },
  'admin.register.role': {
    'en': 'Role',
    'zh': '角色',
    'ms': 'Peranan',
  },
  'admin.register.company': {
    'en': 'Company',
    'zh': '公司',
    'ms': 'Syarikat',
  },
  'admin.register.noCompanies': {
    'en': 'No active companies found. Add a company in settings first.',
    'zh': '未找到活跃公司，请先在设置中添加公司。',
    'ms': 'Tiada syarikat aktif dijumpai. Tambah syarikat dalam tetapan dahulu.',
  },
  'admin.register.companyFromProfile': {
    'en': 'Your company (from profile)',
    'zh': '您的公司（来自资料）',
    'ms': 'Syarikat anda (dari profil)',
  },
  'admin.register.submit': {
    'en': 'Create staff account',
    'zh': '创建员工账户',
    'ms': 'Cipta akaun staf',
  },
  'admin.register.submitting': {
    'en': 'Creating…',
    'zh': '创建中…',
    'ms': 'Mencipta…',
  },
  'admin.register.passwordMismatch': {
    'en': 'Passwords do not match.',
    'zh': '两次密码不一致。',
    'ms': 'Kata laluan tidak sepadan.',
  },
  'admin.register.selectRole': {
    'en': 'Please select a role.',
    'zh': '请选择角色。',
    'ms': 'Sila pilih peranan.',
  },
  'admin.register.selectCompany': {
    'en': 'Please select a company.',
    'zh': '请选择公司。',
    'ms': 'Sila pilih syarikat.',
  },
  'admin.register.noCompanyRef': {
    'en': 'Your admin profile has no company. Ask a super admin to set companyRef.',
    'zh': '您的管理员资料未关联公司，请联系超级管理员设置 companyRef。',
    'ms': 'Profil admin anda tiada syarikat. Minta super admin tetapkan companyRef.',
  },
  'admin.register.failed': {
    'en': 'Registration failed.',
    'zh': '注册失败。',
    'ms': 'Pendaftaran gagal.',
  },
  'admin.register.successSignIn': {
    'en': 'Staff account created. Sign in again with your admin account.',
    'zh': '员工账户已创建，请使用管理员账户重新登录。',
    'ms': 'Akaun staf dicipta. Log masuk semula dengan akaun admin anda.',
  },

  'admin.editUser.title': {
    'en': 'Edit user',
    'zh': '编辑员工',
    'ms': 'Edit staf',
  },
  'admin.editUser.name': {
    'en': 'Name',
    'zh': '姓名',
    'ms': 'Nama',
  },
  'admin.editUser.phone': {
    'en': 'Phone',
    'zh': '电话',
    'ms': 'Telefon',
  },
  'admin.editUser.nameRequired': {
    'en': 'Name is required.',
    'zh': '姓名为必填项。',
    'ms': 'Nama diperlukan.',
  },
  'admin.editUser.roleNotAllowed': {
    'en': 'This role cannot be assigned.',
    'zh': '无法分配此角色。',
    'ms': 'Peranan ini tidak boleh ditugaskan.',
  },
  'admin.editUser.saveFailed': {
    'en': 'Save failed: {error}',
    'zh': '保存失败：{error}',
    'ms': 'Simpan gagal: {error}',
  },

  'admin.industrySettings.title': {
    'en': 'Industry settings',
    'zh': '行业设置',
    'ms': 'Tetapan industri',
  },
  'admin.industrySettings.noAccess': {
    'en': 'Only super admins can edit industry settings.',
    'zh': '仅超级管理员可编辑行业设置。',
    'ms': 'Hanya super admin boleh mengedit tetapan industri.',
  },
  'admin.industrySettings.intro': {
    'en': 'Customize modules, order types, and field labels for the active company. '
        'Saved to tenant_platform_config in Firestore.',
    'zh': '为当前所选公司配置功能模块、订单类型与字段标签。保存至 Firestore tenant_platform_config。',
    'ms': 'Sesuaikan modul, jenis pesanan dan label medan untuk syarikat aktif. '
        'Disimpan ke tenant_platform_config dalam Firestore.',
  },
  'admin.industrySettings.companyScope': {
    'en': 'Editing: {name} ({id})',
    'zh': '正在编辑：{name}（{id}）',
    'ms': 'Mengedit: {name} ({id})',
  },
  'admin.industrySettings.selectCompanyFirst': {
    'en': 'Select a single company (not “All companies”) before saving.',
    'zh': '请先选择单个公司（非“全部公司”）再保存。',
    'ms': 'Pilih satu syarikat (bukan “Semua syarikat”) sebelum menyimpan.',
  },
  'admin.industrySettings.industryPreset': {
    'en': 'Industry preset',
    'zh': '行业预设',
    'ms': 'Pratetap industri',
  },
  'admin.industrySettings.preset.generic': {
    'en': 'Generic (appointment + field service)',
    'zh': '通用（预约 + 外勤）',
    'ms': 'Generik (temujanji + perkhidmatan lapangan)',
  },
  'admin.industrySettings.preset.florist': {
    'en': 'Florist (legacy TFG)',
    'zh': '花店（旧版 TFG）',
    'ms': 'Kedai bunga (legasi TFG)',
  },
  'admin.industrySettings.preset.fieldService': {
    'en': 'Field service',
    'zh': '外勤服务',
    'ms': 'Perkhidmatan lapangan',
  },
  'admin.industrySettings.preset.transport': {
    'en': 'Transport / delivery',
    'zh': '运输 / 配送',
    'ms': 'Pengangkutan / penghantaran',
  },
  'admin.industrySettings.applyPresetButton': {
    'en': 'Reset form to preset defaults',
    'zh': '按预设重置表单',
    'ms': 'Set semula borang ke lalai pratetap',
  },
  'admin.industrySettings.applyPresetTitle': {
    'en': 'Apply preset defaults?',
    'zh': '应用预设默认值？',
    'ms': 'Gunakan lalai pratetap?',
  },
  'admin.industrySettings.applyPresetBody': {
    'en': 'This replaces modules, order types, prefix, and driver labels with the '
        'selected preset. Field label text you edited will be kept unless you change preset again.',
    'zh': '将用所选预设覆盖模块、订单类型、编号前缀与外勤角色标签。已编辑的字段标签文字会保留。',
    'ms': 'Ini menggantikan modul, jenis pesanan, awalan dan label pemandu dengan pratetap dipilih. '
        'Teks label medan yang anda edit akan dikekalkan.',
  },
  'admin.industrySettings.applyPresetConfirm': {
    'en': 'Apply',
    'zh': '应用',
    'ms': 'Gunakan',
  },
  'admin.industrySettings.orderIdPrefix': {
    'en': 'Order ID prefix',
    'zh': '订单编号前缀',
    'ms': 'Awalan ID pesanan',
  },
  'admin.industrySettings.orderTypes': {
    'en': 'Order types',
    'zh': '订单类型',
    'ms': 'Jenis pesanan',
  },
  'admin.industrySettings.orderTypesHint': {
    'en': 'Comma-separated, e.g. OnSite, WalkIn, Remote',
    'zh': '逗号分隔，例如 OnSite, WalkIn, Remote',
    'ms': 'Pisahkan dengan koma, cth. OnSite, WalkIn, Remote',
  },
  'admin.industrySettings.modulesTitle': {
    'en': 'Enabled modules',
    'zh': '已启用模块',
    'ms': 'Modul diaktifkan',
  },
  'admin.industrySettings.driverLabelEn': {
    'en': 'Field staff / driver label (English)',
    'zh': '外勤/司机角色名（英文）',
    'ms': 'Label kakitangan lapangan / pemandu (Inggeris)',
  },
  'admin.industrySettings.driverLabelZh': {
    'en': 'Field staff / driver label (Chinese)',
    'zh': '外勤/司机角色名（中文）',
    'ms': 'Label kakitangan lapangan / pemandu (Cina)',
  },
  'admin.industrySettings.fieldLabelsTitle': {
    'en': 'Field labels (order & customer forms)',
    'zh': '字段标签（订单与客户表单）',
    'ms': 'Label medan (borang pesanan & pelanggan)',
  },
  'admin.industrySettings.save': {
    'en': 'Save industry settings',
    'zh': '保存行业设置',
    'ms': 'Simpan tetapan industri',
  },
  'admin.industrySettings.saved': {
    'en': 'Industry settings saved.',
    'zh': '行业设置已保存。',
    'ms': 'Tetapan industri disimpan.',
  },
  'admin.industrySettings.saveFailed': {
    'en': 'Save failed: {error}',
    'zh': '保存失败：{error}',
    'ms': 'Simpan gagal: {error}',
  },
  'admin.industrySettings.module.orders': {
    'en': 'Orders',
    'zh': '订单',
    'ms': 'Pesanan',
  },
  'admin.industrySettings.module.pos': {
    'en': 'POS / retail',
    'zh': '收银 / 零售',
    'ms': 'POS / runcit',
  },
  'admin.industrySettings.module.fieldService': {
    'en': 'Field service',
    'zh': '外勤服务',
    'ms': 'Perkhidmatan lapangan',
  },
  'admin.industrySettings.module.drivers': {
    'en': 'Drivers / field staff',
    'zh': '司机 / 外勤',
    'ms': 'Pemandu / kakitangan lapangan',
  },
  'admin.industrySettings.module.customers': {
    'en': 'Customers',
    'zh': '客户',
    'ms': 'Pelanggan',
  },
  'admin.industrySettings.module.invoices': {
    'en': 'Invoices & credit',
    'zh': '发票与赊账',
    'ms': 'Invois & kredit',
  },
  'admin.industrySettings.module.products': {
    'en': 'Products',
    'zh': '产品',
    'ms': 'Produk',
  },
  'admin.industrySettings.module.materialsBom': {
    'en': 'Materials & BOM',
    'zh': '物料与 BOM',
    'ms': 'Bahan & BOM',
  },
  'admin.industrySettings.module.productionMenu': {
    'en': 'Production menu',
    'zh': '生产菜单',
    'ms': 'Menu pengeluaran',
  },
  'admin.industrySettings.module.reports': {
    'en': 'Reports',
    'zh': '报表',
    'ms': 'Laporan',
  },
  'admin.industrySettings.module.shopifyImport': {
    'en': 'Shopify import',
    'zh': 'Shopify 导入',
    'ms': 'Import Shopify',
  },
  'admin.industrySettings.module.whatsappImport': {
    'en': 'Order import',
    'zh': '订单导入',
    'ms': 'Import pesanan',
  },
  'admin.industrySettings.module.customerBroadcast': {
    'en': 'Customer broadcast',
    'zh': '客户群发',
    'ms': 'Siaran pelanggan',
  },
  'admin.industrySettings.module.appointments': {
    'en': 'Appointments (reserved)',
    'zh': '预约（预留）',
    'ms': 'Temujanji (ditempah)',
  },
  'admin.industrySettings.field.recipientName': {
    'en': 'Recipient / service contact name',
    'zh': '收件人 / 服务联系人',
    'ms': 'Nama penerima / kenalan perkhidmatan',
  },
  'admin.industrySettings.field.recipientPhone': {
    'en': 'Recipient / service contact phone',
    'zh': '收件人 / 服务联系人电话',
    'ms': 'Telefon penerima / kenalan perkhidmatan',
  },
  'admin.industrySettings.field.serviceNotes': {
    'en': 'Service notes / card message',
    'zh': '服务备注 / 贺卡留言',
    'ms': 'Nota perkhidmatan / mesej kad',
  },
  'admin.industrySettings.field.scheduledDate': {
    'en': 'Scheduled date',
    'zh': '预约 / 配送日期',
    'ms': 'Tarikh dijadualkan',
  },
  'admin.industrySettings.field.timeWindow': {
    'en': 'Time window',
    'zh': '时段',
    'ms': 'Tetingkap masa',
  },
  'admin.industrySettings.field.serviceAddress': {
    'en': 'Service / delivery address',
    'zh': '服务 / 配送地址',
    'ms': 'Alamat perkhidmatan / penghantaran',
  },
  'admin.industrySettings.field.customerId': {
    'en': 'Customer ID label',
    'zh': '客户编号标签',
    'ms': 'Label ID pelanggan',
  },

  'admin.registrationRequests.title': {
    'en': 'Registration requests',
    'zh': '注册审批',
    'ms': 'Permintaan pendaftaran',
  },
  'admin.registrationRequests.noAccess': {
    'en': 'Only super admins can review registration requests.',
    'zh': '仅超级管理员可审批注册申请。',
    'ms': 'Hanya super admin boleh semak permintaan pendaftaran.',
  },
  'admin.registrationRequests.intro': {
    'en': 'Review sign-up requests from /userSignup. Approve to create a company, '
        'tenant defaults, and a director login.',
    'zh': '审核来自 /userSignup 的注册申请。批准后将创建公司、租户默认配置及 director 登录账号。',
    'ms': 'Semak permintaan daftar dari /userSignup. Luluskan untuk cipta syarikat, '
        'lalai penyewa dan log masuk pengarah.',
  },
  'admin.registrationRequests.empty': {
    'en': 'No registration requests match this filter.',
    'zh': '没有符合筛选条件的注册申请。',
    'ms': 'Tiada permintaan pendaftaran sepadan penapis ini.',
  },
  'admin.registrationRequests.filter.all': {
    'en': 'All',
    'zh': '全部',
    'ms': 'Semua',
  },
  'admin.registrationRequests.status.pending': {
    'en': 'Pending',
    'zh': '待审核',
    'ms': 'Menunggu',
  },
  'admin.registrationRequests.status.approved': {
    'en': 'Approved',
    'zh': '已批准',
    'ms': 'Diluluskan',
  },
  'admin.registrationRequests.status.rejected': {
    'en': 'Rejected',
    'zh': '已拒绝',
    'ms': 'Ditolak',
  },
  'admin.registrationRequests.field.phone': {
    'en': 'Phone',
    'zh': '电话',
    'ms': 'Telefon',
  },
  'admin.registrationRequests.field.accountType': {
    'en': 'Account type',
    'zh': '账户类型',
    'ms': 'Jenis akaun',
  },
  'admin.registrationRequests.accountType.private': {
    'en': 'Private',
    'zh': '个人',
    'ms': 'Peribadi',
  },
  'admin.registrationRequests.accountType.company': {
    'en': 'Company',
    'zh': '公司',
    'ms': 'Syarikat',
  },
  'admin.registrationRequests.field.companyName': {
    'en': 'Company name',
    'zh': '公司名称',
    'ms': 'Nama syarikat',
  },
  'admin.registrationRequests.field.companyUen': {
    'en': 'UEN',
    'zh': 'UEN',
    'ms': 'UEN',
  },
  'admin.registrationRequests.field.companyPhone': {
    'en': 'Company phone',
    'zh': '公司电话',
    'ms': 'Telefon syarikat',
  },
  'admin.registrationRequests.field.companyEmail': {
    'en': 'Company email',
    'zh': '公司邮箱',
    'ms': 'E-mel syarikat',
  },
  'admin.registrationRequests.field.companyAddress': {
    'en': 'Address',
    'zh': '地址',
    'ms': 'Alamat',
  },
  'admin.registrationRequests.field.rejectionNote': {
    'en': 'Rejection note',
    'zh': '拒绝原因',
    'ms': 'Nota penolakan',
  },
  'admin.registrationRequests.approveButton': {
    'en': 'Approve',
    'zh': '批准',
    'ms': 'Luluskan',
  },
  'admin.registrationRequests.rejectButton': {
    'en': 'Reject',
    'zh': '拒绝',
    'ms': 'Tolak',
  },
  'admin.registrationRequests.approveTitle': {
    'en': 'Approve registration?',
    'zh': '批准注册？',
    'ms': 'Luluskan pendaftaran?',
  },
  'admin.registrationRequests.approveBody': {
    'en': 'Creates a new company, initializes tenant settings, and a director account '
        'for the applicant email.',
    'zh': '将创建新公司、初始化租户设置，并为申请人邮箱创建 director 账号。',
    'ms': 'Mencipta syarikat baharu, tetapan penyewa dan akaun pengarah untuk e-mel pemohon.',
  },
  'admin.registrationRequests.initialPassword': {
    'en': 'Initial password for applicant',
    'zh': '申请人初始密码',
    'ms': 'Kata laluan awal pemohon',
  },
  'admin.registrationRequests.approveSessionWarning': {
    'en': 'You may be signed out after approval (Firebase client limitation). '
        'Sign in again as super admin if needed.',
    'zh': '批准后您可能会退出登录（Firebase 客户端限制）。如需继续操作请重新以超级管理员登录。',
    'ms': 'Anda mungkin dilog keluar selepas kelulusan. Log masuk semula sebagai super admin jika perlu.',
  },
  'admin.registrationRequests.approveConfirm': {
    'en': 'Approve',
    'zh': '批准',
    'ms': 'Luluskan',
  },
  'admin.registrationRequests.rejectTitle': {
    'en': 'Reject registration?',
    'zh': '拒绝注册？',
    'ms': 'Tolak pendaftaran?',
  },
  'admin.registrationRequests.rejectNote': {
    'en': 'Reason (shown internally)',
    'zh': '原因（内部记录）',
    'ms': 'Sebab (rekod dalaman)',
  },
  'admin.registrationRequests.rejectConfirm': {
    'en': 'Reject',
    'zh': '拒绝',
    'ms': 'Tolak',
  },
  'admin.registrationRequests.approved': {
    'en': 'Registration approved. The applicant can sign in with the email and password you set.',
    'zh': '注册已批准。申请人可使用您设置的邮箱和密码登录。',
    'ms': 'Pendaftaran diluluskan. Pemohon boleh log masuk dengan e-mel dan kata laluan yang anda tetapkan.',
  },
  'admin.registrationRequests.approvedSignInAgain': {
    'en': 'Registration approved. Please sign in again as super admin.',
    'zh': '注册已批准。请重新以超级管理员身份登录。',
    'ms': 'Pendaftaran diluluskan. Sila log masuk semula sebagai super admin.',
  },
  'admin.registrationRequests.rejected': {
    'en': 'Registration rejected.',
    'zh': '注册已拒绝。',
    'ms': 'Pendaftaran ditolak.',
  },
  'admin.registrationRequests.actionFailed': {
    'en': 'Action failed.',
    'zh': '操作失败。',
    'ms': 'Tindakan gagal.',
  },
};
