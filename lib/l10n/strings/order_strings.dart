/// Order module UI strings.
const Map<String, Map<String, String>> orderStrings = {
  // Titles
  'order.list.title': {
    'en': 'Order Management',
    'zh': '订单管理',
    'ms': 'Pengurusan Pesanan',
  },
  'order.list.subtitle': {
    'en': 'Manage delivery, pickup, and retail orders',
    'zh': '管理配送、自取与零售订单',
    'ms': 'Urus pesanan penghantaran, ambil & runcit',
  },
  'order.create.fulfillmentType': {
    'en': 'Fulfillment type',
    'zh': '履约方式',
    'ms': 'Jenis pemenuhan',
  },
  'order.list.importTooltip': {
    'en': 'Import order from WhatsApp text',
    'zh': '从 WhatsApp 文本导入订单',
    'ms': 'Import pesanan dari teks WhatsApp',
  },
  'order.list.exportTooltip': {
    'en': 'Export filtered orders to CSV',
    'zh': '导出当前筛选订单为 CSV',
    'ms': 'Eksport pesanan ditapis ke CSV',
  },
  'order.detail.title': {
    'en': 'Order Detail',
    'zh': '订单详情',
    'ms': 'Butiran Pesanan',
  },
  'order.detail.unnamedCustomer': {
    'en': 'Customer not set',
    'zh': '未填写客户',
    'ms': 'Pelanggan belum ditetapkan',
  },
  'order.detail.sectionDetails': {
    'en': 'Order Details',
    'zh': '订单信息',
    'ms': 'Butiran Pesanan',
  },
  'order.detail.sectionShipping': {
    'en': 'Shipping Information',
    'zh': '配送信息',
    'ms': 'Maklumat Penghantaran',
  },
  'order.detail.sectionItems': {
    'en': 'Order Items',
    'zh': '订单产品',
    'ms': 'Item Pesanan',
  },
  'order.detail.sectionTimeline': {
    'en': 'Order Timeline',
    'zh': '订单进度',
    'ms': 'Garis Masa Pesanan',
  },
  'order.detail.missingOrderRef': {
    'en': 'Order reference missing. Open this page from the order list.',
    'zh': '缺少订单引用，请从订单列表进入。',
    'ms': 'Rujukan pesanan tiada. Buka dari senarai pesanan.',
  },
  'order.detail.loadError': {
    'en': 'Cannot load order: {error}',
    'zh': '无法加载订单：{error}',
    'ms': 'Tidak dapat memuatkan pesanan: {error}',
  },
  'order.partial.title': {
    'en': 'Partial delivery',
    'zh': '部分送达',
    'ms': 'Penghantaran Separa',
  },
  'order.statusSheet.title': {
    'en': 'Update Order Status',
    'zh': '更新订单状态',
    'ms': 'Kemas Kini Status Pesanan',
  },

  // Field labels
  'order.field.orderId': {
    'en': 'Order ID:',
    'zh': '订单号：',
    'ms': 'ID Pesanan:',
  },
  'order.field.deliveryDate': {
    'en': 'Delivery Date:',
    'zh': '配送日期：',
    'ms': 'Tarikh Penghantaran:',
  },
  'order.field.deliveryTime': {
    'en': 'Delivery Time Slot:',
    'zh': '配送时段：',
    'ms': 'Slot Masa Penghantaran:',
  },
  'order.field.method': {
    'en': 'Method:',
    'zh': '方式：',
    'ms': 'Kaedah:',
  },
  'order.field.customer': {
    'en': 'Customer:',
    'zh': '客户：',
    'ms': 'Pelanggan:',
  },
  'order.field.total': {
    'en': 'Total Amount:',
    'zh': '总金额：',
    'ms': 'Jumlah:',
  },
  'order.field.recipient': {
    'en': "Recipient's name:",
    'zh': '收件人：',
    'ms': 'Nama penerima:',
  },
  'order.field.address': {
    'en': 'Delivery Address:',
    'zh': '配送地址：',
    'ms': 'Alamat Penghantaran:',
  },
  'order.field.postal': {
    'en': 'Postal code:',
    'zh': '邮编：',
    'ms': 'Poskod:',
  },
  'order.field.phone': {
    'en': 'Recipient phone:',
    'zh': '收件人电话：',
    'ms': 'Telefon penerima:',
  },

  // List columns
  'order.col.orderId': {
    'en': 'Order ID',
    'zh': '订单号',
    'ms': 'ID Pesanan',
  },
  'order.col.customer': {
    'en': 'Customer',
    'zh': '客户',
    'ms': 'Pelanggan',
  },
  'order.col.recipient': {
    'en': 'Recipient',
    'zh': '收件人',
    'ms': 'Penerima',
  },
  'order.col.address': {
    'en': 'Address',
    'zh': '地址',
    'ms': 'Alamat',
  },
  'order.col.deliveryDate': {
    'en': 'Delivery date',
    'zh': '配送日期',
    'ms': 'Tarikh penghantaran',
  },
  'order.col.pd': {
    'en': 'P/D',
    'zh': '取/送',
    'ms': 'P/D',
  },
  'order.col.product': {
    'en': 'Product',
    'zh': '产品',
    'ms': 'Produk',
  },
  'order.col.status': {
    'en': 'Status',
    'zh': '状态',
    'ms': 'Status',
  },
  'order.col.phone': {
    'en': 'Phone',
    'zh': '电话',
    'ms': 'Telefon',
  },
  'order.col.timeSlot': {
    'en': 'Time slot',
    'zh': '时段',
    'ms': 'Slot masa',
  },
  'order.col.paymentStatus': {
    'en': 'Payment status',
    'zh': '付款状态',
    'ms': 'Status bayaran',
  },
  'order.col.driver': {
    'en': 'Driver',
    'zh': '司机',
    'ms': 'Pemandu',
  },
  'order.field.unassignedDriver': {
    'en': 'Unassigned',
    'zh': '未分配',
    'ms': 'Belum ditugaskan',
  },
  'order.col.total': {
    'en': 'Total',
    'zh': '金额',
    'ms': 'Jumlah',
  },
  'order.col.action': {
    'en': 'Action',
    'zh': '操作',
    'ms': 'Tindakan',
  },
  'order.col.view': {
    'en': 'View',
    'zh': '查看',
    'ms': 'Lihat',
  },
  'order.field.paymentStatus': {
    'en': 'Payment status',
    'zh': '付款状态',
    'ms': 'Status bayaran',
  },
  'order.payment.paid': {
    'en': 'Paid',
    'zh': '已付款',
    'ms': 'Dibayar',
  },
  'order.payment.unpaid': {
    'en': 'Unpaid',
    'zh': '未付款',
    'ms': 'Belum bayar',
  },
  'order.payment.partial': {
    'en': 'Partial',
    'zh': '部分付款',
    'ms': 'Separa',
  },

  // Type chips
  'order.type.all': {
    'en': 'All',
    'zh': '全部',
    'ms': 'Semua',
  },
  'order.type.retail': {
    'en': 'Retail',
    'zh': '零售',
    'ms': 'Runcit',
  },
  'order.type.delivery': {
    'en': 'Delivery',
    'zh': '配送',
    'ms': 'Penghantaran',
  },
  'order.type.pickUp': {
    'en': 'PickUp',
    'zh': '自取',
    'ms': 'Ambil Sendiri',
  },
  'order.type.onSite': {
    'en': 'On-site',
    'zh': '现场',
    'ms': 'Di tapak',
  },
  'order.type.remote': {
    'en': 'Remote',
    'zh': '远程',
    'ms': 'Jauh',
  },
  'order.type.walkIn': {
    'en': 'Walk-in',
    'zh': '到店',
    'ms': 'Walk-in',
  },
  'order.type.pickupLabel': {
    'en': 'Pickup',
    'zh': '自取',
    'ms': 'Ambil',
  },

  // Status display
  'order.status.all': {
    'en': 'All statuses',
    'zh': '全部状态',
    'ms': 'Semua status',
  },
  'order.status.pending': {
    'en': 'Pending',
    'zh': '待处理',
    'ms': 'Menunggu',
  },
  'order.status.processing': {
    'en': 'Processing',
    'zh': '处理中',
    'ms': 'Memproses',
  },
  'order.status.readyToShip': {
    'en': 'Ready to Ship',
    'zh': '待派送',
    'ms': 'Sedia Dihantar',
  },
  'order.status.outOfDelivery': {
    'en': 'Out for Delivery',
    'zh': '派送中',
    'ms': 'Dalam Penghantaran',
  },
  'order.status.completed': {
    'en': 'Completed',
    'zh': '已完成',
    'ms': 'Selesai',
  },
  'order.status.cancelled': {
    'en': 'Cancelled',
    'zh': '已取消',
    'ms': 'Dibatalkan',
  },
  'order.inventory.frozenCancelDenied': {
    'en': 'Completed orders are locked. Only a manager or admin can cancel or void.',
    'zh': '已完成订单已锁定，仅经理或管理员可取消/作废。',
    'ms': 'Pesanan selesai dikunci. Hanya pengurus atau admin boleh batalkan.',
  },
  'order.inventory.frozenEditDenied': {
    'en': 'Completed orders are locked. Only a manager or admin can change prices.',
    'zh': '已完成订单已锁定，仅经理或管理员可改价。',
    'ms': 'Pesanan selesai dikunci. Hanya pengurus atau admin boleh ubah harga.',
  },

  // Timeline
  'order.timeline.confirmed': {
    'en': 'Order Confirmed',
    'zh': '订单已确认',
    'ms': 'Pesanan Disahkan',
  },
  'order.timeline.processing': {
    'en': 'Processing',
    'zh': '处理中',
    'ms': 'Memproses',
  },
  'order.timeline.ready': {
    'en': 'Ready for Delivery',
    'zh': '待派送',
    'ms': 'Sedia Penghantaran',
  },
  'order.timeline.out': {
    'en': 'Out for Delivery',
    'zh': '派送中',
    'ms': 'Dalam Penghantaran',
  },
  'order.timeline.completed': {
    'en': 'Completed',
    'zh': '已完成',
    'ms': 'Selesai',
  },

  // Actions
  'order.action.editCustomerAddress': {
    'en': 'Edit customer & address',
    'zh': '编辑客户与地址',
    'ms': 'Edit pelanggan & alamat',
  },
  'order.action.editProducts': {
    'en': 'Edit products',
    'zh': '编辑产品',
    'ms': 'Edit produk',
  },
  'order.action.editAddress': {
    'en': 'Edit Address',
    'zh': '编辑地址',
    'ms': 'Edit Alamat',
  },
  'order.action.assignDriver': {
    'en': 'Assign Driver',
    'zh': '分配司机',
    'ms': 'Tugaskan Pemandu',
  },
  'order.assign.selectOne': {
    'en': 'Select exactly one order to assign a driver.',
    'zh': '请只选择一笔订单以分配司机。',
    'ms': 'Pilih satu pesanan untuk menugaskan pemandu.',
  },
  'order.action.moreActions': {
    'en': 'More actions',
    'zh': '更多操作',
    'ms': 'Lagi tindakan',
  },
  'order.action.printReceipt': {
    'en': 'Print invoice or receipt',
    'zh': '打印发票或收据',
    'ms': 'Cetak invois atau resit',
  },
  'order.action.productionMenu': {
    'en': 'Production menu',
    'zh': '生产菜单',
    'ms': 'Menu pengeluaran',
  },
  'order.action.sendPurchaseReminder': {
    'en': 'Send special purchase reminder',
    'zh': '发送特殊采购提醒',
    'ms': 'Hantar peringatan pembelian khas',
  },
  'order.purchaseReminder.confirmTitle': {
    'en': 'Send purchase reminder?',
    'zh': '发送采购提醒？',
    'ms': 'Hantar peringatan pembelian?',
  },
  'order.purchaseReminder.confirmBody': {
    'en':
        'Notify all staff (except drivers) to buy flowers/materials for this order.',
    'zh': '通知全员（不含司机）为此订单采购花材/材料。',
    'ms':
        'Maklumkan semua staf (kecuali pemandu) untuk membeli bunga/bahan pesanan ini.',
  },
  'order.purchaseReminder.send': {
    'en': 'Send',
    'zh': '发送',
    'ms': 'Hantar',
  },
  'order.purchaseReminder.sent': {
    'en': 'Purchase reminder sent to {count} staff',
    'zh': '已向 {count} 位员工发送采购提醒',
    'ms': 'Peringatan pembelian dihantar kepada {count} staf',
  },
  'order.purchaseReminder.noRecipients': {
    'en': 'No staff recipients found for this company',
    'zh': '未找到可接收提醒的员工',
    'ms': 'Tiada penerima staf untuk syarikat ini',
  },
  'order.purchaseReminder.failed': {
    'en': 'Could not send purchase reminder',
    'zh': '发送采购提醒失败',
    'ms': 'Gagal menghantar peringatan pembelian',
  },
  'order.action.updateStatus': {
    'en': 'Update Status',
    'zh': '更新状态',
    'ms': 'Kemas Kini Status',
  },
  'order.action.deliveryOrder': {
    'en': 'Delivery Order',
    'zh': '配送单',
    'ms': 'Pesanan Penghantaran',
  },
  'order.action.whatsappCustomer': {
    'en': 'WhatsApp Customer',
    'zh': 'WhatsApp 客户',
    'ms': 'WhatsApp Pelanggan',
  },
  'order.action.startProcessing': {
    'en': 'Start Processing',
    'zh': '开始处理',
    'ms': 'Mula Memproses',
  },
  'order.action.readyToShip': {
    'en': 'Ready to Ship',
    'zh': '标记待派送',
    'ms': 'Sedia Dihantar',
  },

  // Filters & search
  'order.filter.statusHint': {
    'en': 'Status (all)',
    'zh': '状态（全部）',
    'ms': 'Status (semua)',
  },
  'order.filter.dateStart': {
    'en': 'Start:',
    'zh': '开始：',
    'ms': 'Mula:',
  },
  'order.filter.dateEnd': {
    'en': 'End:',
    'zh': '结束：',
    'ms': 'Akhir:',
  },
  'order.search.hint': {
    'en': 'Search name, address, product, order ID...',
    'zh': '搜索姓名、地址、产品、订单号…',
    'ms': 'Cari nama, alamat, produk, ID pesanan...',
  },
  'order.list.empty': {
    'en': 'No orders match your filters.',
    'zh': '没有符合筛选条件的订单。',
    'ms': 'Tiada pesanan sepadan dengan penapis.',
  },

  // Delete / export messages
  'order.delete.selectFirst': {
    'en': 'Select one or more orders to delete.',
    'zh': '请先选择要删除的订单。',
    'ms': 'Pilih satu atau lebih pesanan untuk dipadam.',
  },
  'order.delete.title': {
    'en': 'Delete selected orders?',
    'zh': '删除所选订单？',
    'ms': 'Padam pesanan terpilih?',
  },
  'order.delete.body': {
    'en':
        'Delete {count} order(s)?\n\nThey will be archived to deleted_orders for audit and removed from the order list.\n\n{preview}',
    'zh': '删除 {count} 个订单？\n\n将归档至 deleted_orders 供审计，并从列表中移除。\n\n{preview}',
    'ms':
        'Padam {count} pesanan?\n\nIa akan diarkibkan ke deleted_orders untuk audit dan dikeluarkan dari senarai.\n\n{preview}',
  },
  'order.delete.reasonLabel': {
    'en': 'Delete reason (optional)',
    'zh': '删除原因（可选）',
    'ms': 'Sebab padam (pilihan)',
  },
  'order.delete.success': {
    'en': 'Deleted {count} order(s). Archived to deleted_orders.',
    'zh': '已删除 {count} 个订单，已归档至 deleted_orders。',
    'ms': '{count} pesanan dipadam. Diarkibkan ke deleted_orders.',
  },
  'order.delete.failed': {
    'en': 'Delete failed: {error}',
    'zh': '删除失败：{error}',
    'ms': 'Padam gagal: {error}',
  },
  'order.export.noMatch': {
    'en': 'No orders match the current filters.',
    'zh': '当前筛选条件下没有订单。',
    'ms': 'Tiada pesanan sepadan dengan penapis semasa.',
  },
  'order.export.success': {
    'en': 'Exported {count} order(s). Check Downloads or Files app.',
    'zh': '已导出 {count} 个订单，请查看下载或文件应用。',
    'ms': '{count} pesanan dieksport. Semak Muat Turun atau aplikasi Fail.',
  },
  'order.export.failed': {
    'en': 'Export failed: {error}',
    'zh': '导出失败：{error}',
    'ms': 'Eksport gagal: {error}',
  },

  // Product line summary
  'order.product.qtyDeliveredPartial': {
    'en': 'Qty {qty} ({delivered} delivered)',
    'zh': '数量 {qty}（已送 {delivered}）',
    'ms': 'Kuantiti {qty} ({delivered} dihantar)',
  },
  'order.product.qtyAllDelivered': {
    'en': 'Qty {qty} (delivered)',
    'zh': '数量 {qty}（已送完）',
    'ms': 'Kuantiti {qty} (dihantar)',
  },
  'order.product.qtyOnly': {
    'en': 'Qty {qty}',
    'zh': '数量 {qty}',
    'ms': 'Kuantiti {qty}',
  },

  // Partial delivery
  'order.partial.notFound': {
    'en': 'Order not found',
    'zh': '找不到订单',
    'ms': 'Pesanan tidak dijumpai',
  },
  'order.partial.progress': {
    'en': 'Delivery progress',
    'zh': '配送进度',
    'ms': 'Kemajuan penghantaran',
  },
  'order.partial.runs': {
    'en': 'Delivery runs',
    'zh': '配送批次',
    'ms': 'Pusingan penghantaran',
  },
  'order.partial.recorded': {
    'en': 'Recorded',
    'zh': '已记录',
    'ms': 'Direkod',
  },
  'order.partial.deliverToday': {
    'en': 'Deliver today',
    'zh': '今日送达',
    'ms': 'Hantar hari ini',
  },
  'order.partial.noProducts': {
    'en': 'No products on this order.',
    'zh': '此订单没有产品。',
    'ms': 'Tiada produk pada pesanan ini.',
  },
  'order.partial.deliveredOf': {
    'en': 'Delivered {done} / {total}',
    'zh': '已送 {done} / {total}',
    'ms': 'Dihantar {done} / {total}',
  },
  'order.partial.fullyDelivered': {
    'en': 'Fully delivered',
    'zh': '已全部送达',
    'ms': 'Dihantar sepenuhnya',
  },
  'order.partial.allQty': {
    'en': 'All {qty}',
    'zh': '全部 {qty}',
    'ms': 'Semua {qty}',
  },
  'order.partial.nextDateOptional': {
    'en': 'Next delivery date (optional)',
    'zh': '下次配送日期（可选）',
    'ms': 'Tarikh penghantaran seterusnya (pilihan)',
  },
  'order.partial.keepSchedule': {
    'en': 'Keep current schedule',
    'zh': '保持当前安排',
    'ms': 'Kekalkan jadual semasa',
  },
  'order.partial.confirm': {
    'en': 'Confirm partial delivery',
    'zh': '确认部分送达',
    'ms': 'Sahkan penghantaran separa',
  },
  'order.partial.selectQty': {
    'en': 'Select at least one product quantity to deliver.',
    'zh': '请至少选择一个产品的送达数量。',
    'ms': 'Pilih sekurang-kurangnya satu kuantiti produk untuk dihantar.',
  },
  'order.partial.printSelectQty': {
    'en': 'Select at least one item quantity to print.',
    'zh': '请至少选择一个产品数量再打印。',
    'ms': 'Pilih sekurang-kurangnya satu kuantiti item untuk cetak.',
  },
  'order.partial.allCompleted': {
    'en': 'All items delivered. Order completed.',
    'zh': '全部产品已送达，订单已完成。',
    'ms': 'Semua item dihantar. Pesanan selesai.',
  },
  'order.partial.recordedCount': {
    'en': 'Recorded {count} item(s).',
    'zh': '已记录 {count} 个产品。',
    'ms': '{count} item direkod.',
  },
  'order.partial.stillRemaining': {
    'en': '{remaining} still to deliver.',
    'zh': '尚有 {remaining} 待送。',
    'ms': '{remaining} masih perlu dihantar.',
  },
  'order.partial.progressSummary': {
    'en': '{delivered} of {ordered} delivered{remainingSuffix}',
    'zh': '已送 {delivered} / {ordered}{remainingSuffix}',
    'ms': '{delivered} daripada {ordered} dihantar{remainingSuffix}',
  },
  'order.partial.remainingSuffix': {
    'en': ' · {remaining} left',
    'zh': ' · 剩 {remaining}',
    'ms': ' · {remaining} lagi',
  },
  'order.partial.itemRemaining': {
    'en': 'Delivered {done} / {total} · Remaining {remaining}',
    'zh': '已送 {done} / {total} · 剩 {remaining}',
    'ms': 'Dihantar {done} / {total} · Baki {remaining}',
  },
  'order.partial.runItems': {
    'en': '{label} · {count} item(s)',
    'zh': '{label} · {count} 项',
    'ms': '{label} · {count} item',
  },

  // Driver assignments
  'order.driver.title': {
    'en': 'Driver Assignments',
    'zh': '司机派单',
    'ms': 'Tugasan Pemandu',
  },
  'order.driver.noPermission': {
    'en': 'You do not have permission to view driver assignments.',
    'zh': '您没有查看司机派单的权限。',
    'ms': 'Anda tiada kebenaran untuk melihat tugasan pemandu.',
  },
  'order.driver.noDrivers': {
    'en': 'No active drivers found for this company.',
    'zh': '该公司暂无在职司机。',
    'ms': 'Tiada pemandu aktif untuk syarikat ini.',
  },
  'order.driver.filterFromDate': {
    'en': 'Filter from date',
    'zh': '筛选开始日期',
    'ms': 'Tapis dari tarikh',
  },
  'order.driver.filterToDate': {
    'en': 'Filter to date',
    'zh': '筛选结束日期',
    'ms': 'Tapis hingga tarikh',
  },
  'order.driver.allDeliveryDates': {
    'en': 'All delivery dates',
    'zh': '全部配送日期',
    'ms': 'Semua tarikh penghantaran',
  },
  'order.driver.dateFrom': {
    'en': 'From {date}',
    'zh': '从 {date}',
    'ms': 'Dari {date}',
  },
  'order.driver.dateUntil': {
    'en': 'Until {date}',
    'zh': '至 {date}',
    'ms': 'Hingga {date}',
  },
  'order.driver.clearDates': {
    'en': 'Clear dates',
    'zh': '清除日期',
    'ms': 'Kosongkan tarikh',
  },
  'order.driver.noRouteAddresses': {
    'en': 'No delivery addresses to route.',
    'zh': '没有可规划的配送地址。',
    'ms': 'Tiada alamat penghantaran untuk laluan.',
  },
  'order.driver.routeLimited': {
    'en': 'Opening first {count} stops in Google Maps.',
    'zh': '在 Google 地图中打开前 {count} 个站点。',
    'ms': 'Membuka {count} hentian pertama dalam Google Maps.',
  },
  'order.driver.mapsOpenFailed': {
    'en': 'Could not open Google Maps.',
    'zh': '无法打开 Google 地图。',
    'ms': 'Tidak dapat membuka Google Maps.',
  },
  'order.driver.loadOrdersFailed': {
    'en': 'Could not load orders: {error}',
    'zh': '无法加载订单：{error}',
    'ms': 'Tidak dapat memuatkan pesanan: {error}',
  },
  'order.driver.noOrdersForFilters': {
    'en': 'No orders assigned to this driver for the selected filters.',
    'zh': '当前筛选条件下该司机无派单。',
    'ms': 'Tiada pesanan ditugaskan kepada pemandu ini untuk penapis dipilih.',
  },
  'order.driver.assignedCount': {
    'en': 'Assigned orders ({count})',
    'zh': '已派订单（{count}）',
    'ms': 'Pesanan ditugaskan ({count})',
  },
  'order.driver.suggestedRoute': {
    'en': 'Suggested route',
    'zh': '建议路线',
    'ms': 'Laluan dicadangkan',
  },
  'order.driver.noAddressesOnOrders': {
    'en': 'Assigned orders have no delivery addresses.',
    'zh': '已派订单没有配送地址。',
    'ms': 'Pesanan ditugaskan tiada alamat penghantaran.',
  },
  'order.driver.openInMaps': {
    'en': 'Open in Google Maps',
    'zh': '在 Google 地图中打开',
    'ms': 'Buka dalam Google Maps',
  },

  // Deleted orders archive
  'order.deleted.title': {
    'en': 'Deleted Orders',
    'zh': '已删订单',
    'ms': 'Pesanan Dipadam',
  },
  'order.deleted.noPermission': {
    'en': 'You do not have permission to view deleted orders.',
    'zh': '您没有查看已删订单的权限。',
    'ms': 'Anda tiada kebenaran untuk melihat pesanan dipadam.',
  },
  'order.deleted.loadFailed': {
    'en': 'Failed to load deleted orders.',
    'zh': '加载已删订单失败。',
    'ms': 'Gagal memuatkan pesanan dipadam.',
  },
  'order.deleted.noMatch': {
    'en': 'No deleted orders match your filters.',
    'zh': '没有符合筛选条件的已删订单。',
    'ms': 'Tiada pesanan dipadam sepadan dengan penapis anda.',
  },
  'order.deleted.badge': {
    'en': 'DELETED',
    'zh': '已删除',
    'ms': 'DIPADAM',
  },
  'order.deleted.analyticsTotal': {
    'en': 'Total Deleted',
    'zh': '删除总数',
    'ms': 'Jumlah Dipadam',
  },
  'order.deleted.analyticsRevenue': {
    'en': 'Deleted Revenue',
    'zh': '删除金额',
    'ms': 'Hasil Dipadam',
  },
  'order.deleted.analyticsTopProduct': {
    'en': 'Top Deleted Product',
    'zh': '删除最多产品',
    'ms': 'Produk Paling Dipadam',
  },
  'order.deleted.analyticsTopDeleter': {
    'en': 'Most Active Deleter',
    'zh': '删除最多员工',
    'ms': 'Pemadam Paling Aktif',
  },
  'order.deleted.searchHint': {
    'en': 'Search Order ID or Customer',
    'zh': '搜索订单号或客户',
    'ms': 'Cari ID Pesanan atau Pelanggan',
  },
  'order.deleted.deletedFrom': {
    'en': 'Deleted from',
    'zh': '删除自',
    'ms': 'Dipadam dari',
  },
  'order.deleted.deletedTo': {
    'en': 'Deleted to',
    'zh': '删除至',
    'ms': 'Dipadam hingga',
  },
  'order.deleted.fromDate': {
    'en': 'From {date}',
    'zh': '从 {date}',
    'ms': 'Dari {date}',
  },
  'order.deleted.toDate': {
    'en': 'To {date}',
    'zh': '至 {date}',
    'ms': 'Hingga {date}',
  },
  'order.deleted.deletedByAll': {
    'en': 'Deleted by: All',
    'zh': '删除人：全部',
    'ms': 'Dipadam oleh: Semua',
  },
  'order.deleted.statusAll': {
    'en': 'Status: All',
    'zh': '状态：全部',
    'ms': 'Status: Semua',
  },
  'order.deleted.clearFilters': {
    'en': 'Clear filters',
    'zh': '清除筛选',
    'ms': 'Kosongkan penapis',
  },
  'order.deleted.colOrderId': {
    'en': 'Order ID',
    'zh': '订单号',
    'ms': 'ID Pesanan',
  },
  'order.deleted.colCustomer': {
    'en': 'Customer',
    'zh': '客户',
    'ms': 'Pelanggan',
  },
  'order.deleted.colOrderDate': {
    'en': 'Order Date',
    'zh': '订单日期',
    'ms': 'Tarikh Pesanan',
  },
  'order.deleted.colTotal': {
    'en': 'Total',
    'zh': '总额',
    'ms': 'Jumlah',
  },
  'order.deleted.colDeletedDate': {
    'en': 'Deleted Date',
    'zh': '删除日期',
    'ms': 'Tarikh Dipadam',
  },
  'order.deleted.colDeletedBy': {
    'en': 'Deleted By',
    'zh': '删除人',
    'ms': 'Dipadam Oleh',
  },
  'order.deleted.colReason': {
    'en': 'Reason',
    'zh': '原因',
    'ms': 'Sebab',
  },
  'order.deleted.colStatus': {
    'en': 'Status',
    'zh': '状态',
    'ms': 'Status',
  },
  'order.deleted.details': {
    'en': 'Details',
    'zh': '详情',
    'ms': 'Butiran',
  },
  'order.deleted.restore': {
    'en': 'Restore',
    'zh': '恢复',
    'ms': 'Pulihkan',
  },
  'order.deleted.deleteForever': {
    'en': 'Delete forever',
    'zh': '永久删除',
    'ms': 'Padam selama-lamanya',
  },
  'order.deleted.restoreTitle': {
    'en': 'Restore order?',
    'zh': '恢复订单？',
    'ms': 'Pulihkan pesanan?',
  },
  'order.deleted.restoreBody': {
    'en': 'Restore {orderId} to Active Orders?\n\nThe order will reappear in the order list.',
    'zh': '将 {orderId} 恢复至有效订单？\n\n订单将重新出现在订单列表中。',
    'ms': 'Pulihkan {orderId} ke Pesanan Aktif?\n\nPesanan akan muncul semula dalam senarai.',
  },
  'order.deleted.restoreSuccess': {
    'en': 'Order restored to Active Orders.',
    'zh': '订单已恢复至有效订单。',
    'ms': 'Pesanan dipulihkan ke Pesanan Aktif.',
  },
  'order.deleted.restoreFailed': {
    'en': 'Failed to restore order.',
    'zh': '恢复订单失败。',
    'ms': 'Gagal memulihkan pesanan.',
  },
  'order.deleted.permanentTitle': {
    'en': 'Permanently delete?',
    'zh': '永久删除？',
    'ms': 'Padam kekal?',
  },
  'order.deleted.permanentBody': {
    'en': 'This action cannot be undone.\n\nThe archived order will be removed permanently.',
    'zh': '此操作无法撤销。\n\n归档订单将被永久删除。',
    'ms': 'Tindakan ini tidak boleh dibatalkan.\n\nPesanan arkib akan dipadam kekal.',
  },
  'order.deleted.permanentButton': {
    'en': 'Delete permanently',
    'zh': '永久删除',
    'ms': 'Padam kekal',
  },
  'order.deleted.permanentSuccess': {
    'en': 'Archived order permanently deleted.',
    'zh': '归档订单已永久删除。',
    'ms': 'Pesanan arkib dipadam kekal.',
  },
  'order.deleted.permanentFailed': {
    'en': 'Failed to permanently delete order.',
    'zh': '永久删除失败。',
    'ms': 'Gagal memadam pesanan kekal.',
  },
  'order.deleted.pageInfo': {
    'en': 'Page {page} of {totalPages} ({count} orders)',
    'zh': '第 {page} / {totalPages} 页（{count} 笔订单）',
    'ms': 'Halaman {page} daripada {totalPages} ({count} pesanan)',
  },
  'order.deleted.detailTitle': {
    'en': 'Deleted Order Details',
    'zh': '已删订单详情',
    'ms': 'Butiran Pesanan Dipadam',
  },
  'order.deleted.detailShortTitle': {
    'en': 'Deleted Order',
    'zh': '已删订单',
    'ms': 'Pesanan Dipadam',
  },
  'order.deleted.missingRef': {
    'en': 'Missing archive reference.',
    'zh': '缺少归档引用。',
    'ms': 'Rujukan arkib tiada.',
  },
  'order.deleted.banner': {
    'en': 'This order was deleted and is not in Active Orders.',
    'zh': '此订单已删除，不在有效订单中。',
    'ms': 'Pesanan ini dipadam dan tiada dalam Pesanan Aktif.',
  },
  'order.deleted.originalStatus': {
    'en': 'Original status',
    'zh': '原状态',
    'ms': 'Status asal',
  },
  'order.deleted.deletedLabel': {
    'en': 'Deleted',
    'zh': '删除时间',
    'ms': 'Dipadam',
  },
  'order.deleted.deleteReason': {
    'en': 'Delete reason',
    'zh': '删除原因',
    'ms': 'Sebab padam',
  },
  'order.deleted.restoredLabel': {
    'en': 'Restored',
    'zh': '恢复时间',
    'ms': 'Dipulihkan',
  },
  'order.deleted.restoredBy': {
    'en': 'Restored by',
    'zh': '恢复人',
    'ms': 'Dipulihkan oleh',
  },
  'order.deleted.activityLog': {
    'en': 'Activity Log',
    'zh': '活动记录',
    'ms': 'Log Aktiviti',
  },
  'order.deleted.noActivity': {
    'en': 'No activity recorded.',
    'zh': '暂无活动记录。',
    'ms': 'Tiada aktiviti direkod.',
  },
  'order.deleted.restoreOrder': {
    'en': 'Restore Order',
    'zh': '恢复订单',
    'ms': 'Pulihkan Pesanan',
  },
  'order.deleted.permanentlyDelete': {
    'en': 'Permanently Delete',
    'zh': '永久删除',
    'ms': 'Padam Kekal',
  },
  'order.deleted.restoreBodyShort': {
    'en': 'This order will reappear in Active Orders after restore.',
    'zh': '恢复后此订单将重新出现在有效订单中。',
    'ms': 'Pesanan ini akan muncul semula dalam Pesanan Aktif selepas dipulihkan.',
  },
  'order.deleted.restoreSnack': {
    'en': 'Order restored.',
    'zh': '订单已恢复。',
    'ms': 'Pesanan dipulihkan.',
  },
  'order.deleted.permanentBodyShort': {
    'en': 'This action cannot be undone.',
    'zh': '此操作无法撤销。',
    'ms': 'Tindakan ini tidak boleh dibatalkan.',
  },

  // Production menu preview
  'order.production.title': {
    'en': 'Production Menu',
    'zh': '生产单',
    'ms': 'Menu Pengeluaran',
  },
  'order.production.notFound': {
    'en': 'Order not found.',
    'zh': '未找到订单。',
    'ms': 'Pesanan tidak dijumpai.',
  },
  'order.production.printThermal': {
    'en': 'Print thermal',
    'zh': '热敏打印',
    'ms': 'Cetak termal',
  },
  'order.production.sheetTitle': {
    'en': 'Production sheet',
    'zh': '生产单',
    'ms': 'Helaian pengeluaran',
  },
  'order.production.sheetHint': {
    'en': 'Separate from customer receipt — for shop floor use.',
    'zh': '与客户收据分开 — 供车间使用。',
    'ms': 'Berasingan dari resit pelanggan — untuk penggunaan bengkel.',
  },
  'order.production.orderLabel': {
    'en': 'Order',
    'zh': '订单',
    'ms': 'Pesanan',
  },
  'order.production.dateLabel': {
    'en': 'Date',
    'zh': '日期',
    'ms': 'Tarikh',
  },
  'order.production.customerLabel': {
    'en': 'Customer',
    'zh': '客户',
    'ms': 'Pelanggan',
  },
  'order.production.productsInOrder': {
    'en': 'Products in this order',
    'zh': '本订单产品',
    'ms': 'Produk dalam pesanan ini',
  },
  'order.production.noLineItems': {
    'en': 'No line items.',
    'zh': '无明细行。',
    'ms': 'Tiada item baris.',
  },
  'order.production.materialsRequired': {
    'en': 'Materials required',
    'zh': '所需物料',
    'ms': 'Bahan diperlukan',
  },
  'order.production.noRecipeMaterials': {
    'en': 'No recipe materials found. Add recipes on products first.',
    'zh': '未找到配方物料，请先为产品添加配方。',
    'ms': 'Tiada bahan resipi dijumpai. Tambah resipi pada produk dahulu.',
  },
  'order.production.noRecipeLinked': {
    'en': 'No recipe linked',
    'zh': '未关联配方',
    'ms': 'Tiada resipi dipautkan',
  },
  'order.production.webPrintHint': {
    'en': 'Web printing needs Chrome or Edge on HTTPS, and a BLE thermal printer. '
        'Tap the Bluetooth icon above to pair.',
    'zh': '网页打印需 HTTPS 下的 Chrome 或 Edge，以及 BLE 热敏打印机。'
        '点击上方蓝牙图标配对。',
    'ms': 'Cetakan web memerlukan Chrome atau Edge pada HTTPS, dan pencetak termal BLE. '
        'Ketik ikon Bluetooth di atas untuk ganding.',
  },
  'order.production.materialCol': {
    'en': 'Material',
    'zh': '物料',
    'ms': 'Bahan',
  },
  'order.production.costCol': {
    'en': 'Cost',
    'zh': '成本',
    'ms': 'Kos',
  },
  'order.production.totalMaterialCost': {
    'en': 'Total material cost',
    'zh': '物料总成本',
    'ms': 'Jumlah kos bahan',
  },
  'order.action.barTitle': {
    'en': 'Actions',
    'zh': '操作',
    'ms': 'Tindakan',
  },
  'order.action.cancelOrder': {
    'en': 'Cancel order',
    'zh': '取消订单',
    'ms': 'Batal pesanan',
  },
  'order.action.cancelOrderConfirm': {
    'en': 'Mark this order as cancelled?',
    'zh': '将此订单标为已取消？',
    'ms': 'Tandakan pesanan ini sebagai dibatalkan?',
  },
  'order.action.more': {
    'en': 'More',
    'zh': '更多',
    'ms': 'Lagi',
  },
  'order.action.pay': {
    'en': 'Pay {amount}',
    'zh': '付款 {amount}',
    'ms': 'Bayar {amount}',
  },
  'order.action.whatsapp': {
    'en': 'WhatsApp',
    'zh': 'WhatsApp',
    'ms': 'WhatsApp',
  },
  'order.bulk.assignDriver': {
    'en': 'Assign driver',
    'zh': '指派司机',
    'ms': 'Tugaskan pemandu',
  },
  'order.bulk.assignDriverConfirm': {
    'en': 'Assign to all selected',
    'zh': '指派给全部所选',
    'ms': 'Tugaskan kepada semua terpilih',
  },
  'order.bulk.assignDriverDenied': {
    'en': 'You do not have permission to assign drivers.',
    'zh': '您没有指派司机的权限。',
    'ms': 'Anda tiada kebenaran menugaskan pemandu.',
  },
  'order.bulk.assignDriverFailed': {
    'en': 'Could not assign driver: {error}',
    'zh': '指派司机失败：{error}',
    'ms': 'Gagal menugaskan pemandu: {error}',
  },
  'order.bulk.assignDriverTitle': {
    'en': 'Assign driver to selected orders',
    'zh': '为所选订单指派司机',
    'ms': 'Tugaskan pemandu kepada pesanan terpilih',
  },
  'order.bulk.driverAssigned': {
    'en': 'Driver assigned to {count} orders',
    'zh': '已为 {count} 笔订单指派司机',
    'ms': 'Pemandu ditugaskan kepada {count} pesanan',
  },
  'order.bulk.noDrivers': {
    'en': 'No drivers found for this company.',
    'zh': '未找到本公司的司机。',
    'ms': 'Tiada pemandu untuk syarikat ini.',
  },
  'order.bulk.noneSelected': {
    'en': 'Select orders below to apply bulk actions',
    'zh': '在下方勾选订单以进行批量操作',
    'ms': 'Pilih pesanan di bawah untuk tindakan pukal',
  },
  'order.bulk.pickDriver': {
    'en': 'Select a driver.',
    'zh': '请选择司机。',
    'ms': 'Pilih pemandu.',
  },
  'order.bulk.printThermalDelivery': {
    'en': 'Print thermal (full delivery)',
    'zh': '批量打印热敏配送单',
    'ms': 'Cetak thermal (penghantaran penuh)',
  },
  'order.bulk.printThermalFailed': {
    'en': '{count} failed — check Bluetooth printer.',
    'zh': '{count} 笔失败 — 请检查蓝牙打印机。',
    'ms': '{count} gagal — semak pencetak Bluetooth.',
  },
  'order.bulk.printThermalNone': {
    'en': 'No delivery/pickup orders selected. Retail orders are skipped.',
    'zh': '未选中配送/自取订单。零售订单已跳过。',
    'ms': 'Tiada pesanan delivery/pickup dipilih. Pesanan runcit dilangkau.',
  },
  'order.bulk.printThermalPrinting': {
    'en': 'Printing…',
    'zh': '打印中…',
    'ms': 'Mencetak…',
  },
  'order.bulk.printThermalResult': {
    'en': 'Printed {printed}/{total} delivery slips.',
    'zh': '已打印 {printed}/{total} 张配送热敏单。',
    'ms': 'Dicetak {printed}/{total} slip penghantaran.',
  },
  'order.bulk.printThermalSkippedRetail': {
    'en': 'Skipped {count} retail.',
    'zh': '已跳过 {count} 笔零售。',
    'ms': 'Dilangkau {count} runcit.',
  },
  'order.bulk.selectFirst': {
    'en': 'Select at least one order first.',
    'zh': '请先勾选至少一笔订单。',
    'ms': 'Pilih sekurang-kurangnya satu pesanan dahulu.',
  },
  'order.bulk.selectedCount': {
    'en': '{count} selected',
    'zh': '已选 {count} 笔',
    'ms': '{count} dipilih',
  },
  'order.bulk.selectedOfTotal': {
    'en': '{selected} of {total} selected',
    'zh': '已选 {selected} / 共 {total} 单',
    'ms': '{selected} / {total} dipilih',
  },
  'order.bulk.statusApplied': {
    'en': '{count} orders set to {status}',
    'zh': '已将 {count} 笔订单设为 {status}',
    'ms': '{count} pesanan ditetapkan kepada {status}',
  },
  'order.bulk.updateStatus': {
    'en': 'Update status',
    'zh': '更改状态',
    'ms': 'Kemas kini status',
  },
  'order.bulk.updateStatusDenied': {
    'en': 'You do not have permission to update order status.',
    'zh': '您没有更改订单状态的权限。',
    'ms': 'Anda tiada kebenaran mengemas kini status pesanan.',
  },
  'order.bulk.updateStatusFailed': {
    'en': 'Could not update status: {error}',
    'zh': '更改状态失败：{error}',
    'ms': 'Gagal mengemas kini status: {error}',
  },
  'order.bulk.updateStatusTitle': {
    'en': 'Update status for selected orders',
    'zh': '更改所选订单状态',
    'ms': 'Kemas kini status pesanan terpilih',
  },
  'order.card.applyHint': {
    'en': 'Applies to products that do not already have their own card.',
    'zh': '只会套用到还没有单独贺卡的商品。',
    'ms': 'Hanya digunakan pada produk yang belum ada kad sendiri.',
  },
  'order.card.copied': {
    'en': 'Message card copied',
    'zh': '已复制贺卡',
    'ms': 'Kad mesej disalin',
  },
  'order.card.copyTooltip': {
    'en': 'Copy message card',
    'zh': '复制贺卡',
    'ms': 'Salin kad mesej',
  },
  'order.card.empty': {
    'en': 'Message card is empty',
    'zh': '贺卡是空的',
    'ms': 'Kad mesej kosong',
  },
  'order.card.forProduct': {
    'en': 'Message card · {name}',
    'zh': '贺卡 · {name}',
    'ms': 'Kad mesej · {name}',
  },
  'order.card.title': {
    'en': 'Message Card',
    'zh': '贺卡',
    'ms': 'Kad mesej',
  },
  'order.col.customerRecipient': {
    'en': 'Customer / recipient',
    'zh': '客户 / 收件',
    'ms': 'Pelanggan / penerima',
  },
  'order.col.slot': {
    'en': 'Time',
    'zh': '时段',
    'ms': 'Slot',
  },
  'order.detail.addressOptional': {
    'en': 'Address (optional)',
    'zh': '地址（选填）',
    'ms': 'Alamat (pilihan)',
  },
  'order.detail.amountPaid': {
    'en': 'Paid',
    'zh': '已付',
    'ms': 'Telah dibayar',
  },
  'order.detail.balanceDue': {
    'en': 'Balance due',
    'zh': '余款',
    'ms': 'Baki tertunggak',
  },
  'order.detail.billingAddress': {
    'en': 'Billing address',
    'zh': '账单地址',
    'ms': 'Alamat bil',
  },
  'order.detail.copied': {
    'en': 'Order details copied',
    'zh': '已复制订单详情',
    'ms': 'Butiran pesanan disalin',
  },
  'order.detail.copyTooltip': {
    'en': 'Copy order details',
    'zh': '复制订单详情',
    'ms': 'Salin butiran pesanan',
  },
  'order.detail.customerPrefix': {
    'en': 'Customer',
    'zh': '客户',
    'ms': 'Pelanggan',
  },
  'order.detail.orderMethod': {
    'en': 'Order method',
    'zh': '配送方式',
    'ms': 'Kaedah pesanan',
  },
  'order.detail.progress': {
    'en': 'Progress',
    'zh': '进度',
    'ms': 'Kemajuan',
  },
  'order.detail.sectionDelivery': {
    'en': 'Delivery',
    'zh': '配送',
    'ms': 'Penghantaran',
  },
  'order.detail.shopifyOrder': {
    'en': 'Shopify Order:',
    'zh': 'Shopify 订单：',
    'ms': 'Pesanan Shopify:',
  },
  'order.detail.source': {
    'en': 'Source:',
    'zh': '来源：',
    'ms': 'Sumber:',
  },
  'order.detail.total': {
    'en': 'Total',
    'zh': '合计',
    'ms': 'Jumlah',
  },
  'order.detail.unpaidHint': {
    'en': 'Payment is not complete. Tap Pay to collect the balance.',
    'zh': '尚未付清。点付款收余款。',
    'ms': 'Pembayaran belum selesai. Ketik Bayar untuk kutip baki.',
  },
  'order.driver.assigned': {
    'en': 'Assigned',
    'zh': '已指派',
    'ms': 'Ditugaskan',
  },
  'order.driver.assignedDriver': {
    'en': 'Driver',
    'zh': '司机',
    'ms': 'Pemandu',
  },
  'order.driver.dateFromLabel': {
    'en': 'From',
    'zh': '从',
    'ms': 'Dari',
  },
  'order.driver.dateOnwards': {
    'en': 'Onwards',
    'zh': '往后',
    'ms': 'Seterusnya',
  },
  'order.driver.dateToLabel': {
    'en': 'To',
    'zh': '至',
    'ms': 'Hingga',
  },
  'order.driver.deliveryDateLabel': {
    'en': 'Delivery date',
    'zh': '配送日期',
    'ms': 'Tarikh penghantaran',
  },
  'order.driver.fromTodayOnwards': {
    'en': 'From today onwards',
    'zh': '从今天起',
    'ms': 'Dari hari ini',
  },
  'order.driver.resetToToday': {
    'en': 'Today',
    'zh': '今天',
    'ms': 'Hari ini',
  },
  'order.driver.unassigned': {
    'en': 'Unassigned',
    'zh': '未指派',
    'ms': 'Belum ditugaskan',
  },
  'order.field.addon': {
    'en': 'Add-on:',
    'zh': '加购：',
    'ms': 'Tambahan:',
  },
  'order.field.billingAddress': {
    'en': 'Billing Address:',
    'zh': '账单地址：',
    'ms': 'Alamat Bil:',
  },
  'order.field.cardMessage': {
    'en': 'Card message:',
    'zh': '贺卡内容：',
    'ms': 'Mesej kad:',
  },
  'order.field.remark': {
    'en': 'Remark:',
    'zh': '备注：',
    'ms': 'Catatan:',
  },
  'order.field.senderPhone': {
    'en': 'Sender phone:',
    'zh': '下单人电话：',
    'ms': 'Telefon pengirim:',
  },
  'order.filter.driverCount': {
    'en': 'Driver · {count}',
    'zh': '司机 · {count}',
    'ms': 'Pemandu · {count}',
  },
  'order.filter.driverHint': {
    'en': 'Driver (multi)',
    'zh': '司机（可多选）',
    'ms': 'Pemandu (berbilang)',
  },
  'order.filter.leftover': {
    'en': 'Leftover',
    'zh': '逾期未完成',
    'ms': 'Tertinggal',
  },
  'order.filter.readyByCount': {
    'en': 'Ready by · {count}',
    'zh': 'Ready by · {count}',
    'ms': 'Ready by · {count}',
  },
  'order.filter.readyByHint': {
    'en': 'Ready by (multi)',
    'zh': 'Ready by（可多选）',
    'ms': 'Ready by (berbilang)',
  },
  'order.filter.statusCount': {
    'en': 'Status · {count}',
    'zh': '状态 · {count}',
    'ms': 'Status · {count}',
  },
  'order.filter.time': {
    'en': 'Time',
    'zh': '时间',
    'ms': 'Masa',
  },
  'order.filter.timeClear': {
    'en': 'Clear time',
    'zh': '清除时间',
    'ms': 'Kosongkan masa',
  },
  'order.filter.timeEnd': {
    'en': 'To',
    'zh': '结束',
    'ms': 'Hingga',
  },
  'order.filter.timeHint': {
    'en': 'Delivery time',
    'zh': '配送时段（几点–几点）',
    'ms': 'Waktu penghantaran',
  },
  'order.filter.timeStart': {
    'en': 'From',
    'zh': '开始',
    'ms': 'Dari',
  },
  'order.list.count': {
    'en': '{count} orders',
    'zh': '{count} 单',
    'ms': '{count} pesanan',
  },
  'order.list.selectAll': {
    'en': 'Select all',
    'zh': '全选',
    'ms': 'Pilih semua',
  },
  'order.list.shopifyRef': {
    'en': 'Shopify {name}',
    'zh': 'Shopify {name}',
    'ms': 'Shopify {name}',
  },
  'order.preview.noProducts': {
    'en': 'No products on this order.',
    'zh': '此订单暂无商品。',
    'ms': 'Tiada produk untuk pesanan ini.',
  },
  'order.preview.productsTitle': {
    'en': 'Order products',
    'zh': '订单商品',
    'ms': 'Produk pesanan',
  },
  'order.production.qtyConfirm': {
    'en': 'Confirm quantity',
    'zh': '确认数量',
    'ms': 'Sahkan kuantiti',
  },
  'order.production.qtySaveFailed': {
    'en': 'Could not save quantity: {error}',
    'zh': '无法保存数量：{error}',
    'ms': 'Tidak dapat simpan kuantiti: {error}',
  },
  'order.readyBy.denied': {
    'en': 'You cannot assign Ready by.',
    'zh': '没有权限选择 Ready by。',
    'ms': 'Anda tidak boleh tetapkan Ready by.',
  },
  'order.readyBy.empty': {
    'en': 'No staff found for this company.',
    'zh': '本公司没有可选手员工。',
    'ms': 'Tiada kakitangan untuk syarikat ini.',
  },
  'order.readyBy.failed': {
    'en': 'Could not save Ready by: {error}',
    'zh': '无法保存 Ready by：{error}',
    'ms': 'Tidak dapat simpan Ready by: {error}',
  },
  'order.readyBy.hint': {
    'en': 'Who made this order ready. Does not change the driver.',
    'zh': '谁把这单做好。不会改司机。',
    'ms': 'Siapa yang sediakan pesanan. Tidak menukar pemandu.',
  },
  'order.readyBy.label': {
    'en': 'Ready by',
    'zh': 'Ready by',
    'ms': 'Ready by',
  },
  'order.readyBy.saved': {
    'en': 'Ready by updated',
    'zh': '已更新 Ready by',
    'ms': 'Ready by dikemas kini',
  },
  'order.readyBy.title': {
    'en': 'Ready by',
    'zh': '谁做好（Ready by）',
    'ms': 'Ready by',
  },
  'order.readyBy.unassigned': {
    'en': 'Ready by —',
    'zh': 'Ready by —',
    'ms': 'Ready by —',
  },
  'order.remark.printedDo': {
    'en': 'Printed DO',
    'zh': 'Printed DO',
    'ms': 'Printed DO',
  },
  'order.shopify.approve': {
    'en': 'Approve',
    'zh': '批准',
    'ms': 'Luluskan',
  },
  'order.shopify.approveBody': {
    'en':
        'Admit {shopify} into the official Order List. Florists can then start work.',
    'zh': '将 {shopify} 纳入正式订单列表，花艺师即可开始备货。',
    'ms':
        'Masukkan {shopify} ke senarai pesanan rasmi. Florist kemudian boleh mula kerja.',
  },
  'order.shopify.approveBulkBody': {
    'en': 'Admit {count} Shopify order(s) into the official Order List.',
    'zh': '将 {count} 笔 Shopify 订单纳入正式订单列表。',
    'ms':
        'Masukkan {count} pesanan Shopify ke senarai pesanan rasmi.',
  },
  'order.shopify.approveBulkSuccess': {
    'en': 'Approved {count} order(s).',
    'zh': '已批准 {count} 笔订单。',
    'ms': '{count} pesanan diluluskan.',
  },
  'order.shopify.approveBulkTitle': {
    'en': 'Approve selected Shopify orders?',
    'zh': '批准所选 Shopify 订单？',
    'ms': 'Luluskan pesanan Shopify yang dipilih?',
  },
  'order.shopify.approveFailed': {
    'en': 'Could not approve order. Try again.',
    'zh': '无法批准订单，请重试。',
    'ms': 'Tidak dapat meluluskan pesanan. Cuba lagi.',
  },
  'order.shopify.approvePartial': {
    'en':
        'Approved {approved}. {failed} failed and can be retried. Successful orders were not duplicated.',
    'zh': '已批准 {approved} 笔。{failed} 笔失败，可重试。成功的订单不会重复创建。',
    'ms':
        '{approved} diluluskan. {failed} gagal dan boleh dicuba semula. Pesanan berjaya tidak diduakan.',
  },
  'order.shopify.approveSelected': {
    'en': 'Approve selected ({count})',
    'zh': '批准所选 ({count})',
    'ms': 'Luluskan dipilih ({count})',
  },
  'order.shopify.approveSuccess': {
    'en': 'Order approved and added to Order List.',
    'zh': '已批准并加入正式订单列表。',
    'ms': 'Pesanan diluluskan dan ditambah ke senarai pesanan.',
  },
  'order.shopify.approveTitle': {
    'en': 'Approve Shopify order?',
    'zh': '批准此 Shopify 订单？',
    'ms': 'Luluskan pesanan Shopify?',
  },
  'order.shopify.clearSelection': {
    'en': 'Clear selection',
    'zh': '清除选择',
    'ms': 'Kosongkan pilihan',
  },
  'order.shopify.delete': {
    'en': 'Delete',
    'zh': '删除',
    'ms': 'Padam',
  },
  'order.shopify.deleteBody': {
    'en':
        'Remove {shopify} from the review queue. It will not be added to the official Order List.',
    'zh': '将 {shopify} 从审批队列移除，不会加入正式订单列表。',
    'ms':
        'Buang {shopify} dari giliran semakan. Ia tidak akan ditambah ke senarai pesanan rasmi.',
  },
  'order.shopify.deleteBulkBody': {
    'en':
        'Remove {count} Shopify order(s) from the review queue. They will not be added to the official Order List.',
    'zh': '将 {count} 笔 Shopify 订单从审批队列移除，不会加入正式订单列表。',
    'ms':
        'Buang {count} pesanan Shopify dari giliran semakan. Ia tidak akan ditambah ke senarai pesanan rasmi.',
  },
  'order.shopify.deleteBulkSuccess': {
    'en': 'Deleted {count} order(s).',
    'zh': '已删除 {count} 笔订单。',
    'ms': '{count} pesanan dipadam.',
  },
  'order.shopify.deleteBulkTitle': {
    'en': 'Delete selected Shopify orders?',
    'zh': '删除所选 Shopify 订单？',
    'ms': 'Padam pesanan Shopify yang dipilih?',
  },
  'order.shopify.deleteFailed': {
    'en': 'Could not delete order. Try again.',
    'zh': '无法删除订单，请重试。',
    'ms': 'Tidak dapat memadam pesanan. Cuba lagi.',
  },
  'order.shopify.deletePartial': {
    'en':
        'Deleted {deleted}. {failed} failed and can be retried.',
    'zh': '已删除 {deleted} 笔。{failed} 笔失败，可重试。',
    'ms':
        '{deleted} dipadam. {failed} gagal dan boleh dicuba semula.',
  },
  'order.shopify.deleteSelected': {
    'en': 'Delete selected ({count})',
    'zh': '删除所选 ({count})',
    'ms': 'Padam dipilih ({count})',
  },
  'order.shopify.deleteSuccess': {
    'en': 'Shopify order removed from review.',
    'zh': '已从审批队列删除。',
    'ms': 'Pesanan Shopify dibuang dari semakan.',
  },
  'order.shopify.deleteTitle': {
    'en': 'Delete Shopify order?',
    'zh': '删除此 Shopify 订单？',
    'ms': 'Padam pesanan Shopify?',
  },
  'order.shopify.empty': {
    'en': 'No Shopify orders in this view.',
    'zh': '此视图没有 Shopify 订单。',
    'ms': 'Tiada pesanan Shopify dalam paparan ini.',
  },
  'order.shopify.filterAll': {
    'en': 'All Shopify',
    'zh': '全部 Shopify',
    'ms': 'Semua Shopify',
  },
  'order.shopify.filterPending': {
    'en': 'Pending review ({count})',
    'zh': '待审批 ({count})',
    'ms': 'Menunggu semakan ({count})',
  },
  'order.shopify.financial.authorized': {
    'en': 'Authorized',
    'zh': '已授权',
    'ms': 'Dibenarkan',
  },
  'order.shopify.financial.paid': {
    'en': 'Paid',
    'zh': '已付款',
    'ms': 'Dibayar',
  },
  'order.shopify.financial.partially_paid': {
    'en': 'Partially paid',
    'zh': '部分付款',
    'ms': 'Dibayar sebahagian',
  },
  'order.shopify.financial.partially_refunded': {
    'en': 'Partially refunded',
    'zh': '部分退款',
    'ms': 'Dipulangkan sebahagian',
  },
  'order.shopify.financial.pending': {
    'en': 'Pending',
    'zh': '待付款',
    'ms': 'Menunggu bayaran',
  },
  'order.shopify.financial.refunded': {
    'en': 'Refunded',
    'zh': '已退款',
    'ms': 'Dipulangkan',
  },
  'order.shopify.financial.unknown': {
    'en': 'Unknown payment',
    'zh': '付款状态未知',
    'ms': 'Bayaran tidak diketahui',
  },
  'order.shopify.financial.unpaid': {
    'en': 'Unpaid',
    'zh': '未付款',
    'ms': 'Belum dibayar',
  },
  'order.shopify.financial.voided': {
    'en': 'Voided',
    'zh': '已作废',
    'ms': 'Dibatalkan',
  },
  'order.shopify.loadFailed': {
    'en': 'Failed to load Shopify orders.',
    'zh': '加载 Shopify 订单失败。',
    'ms': 'Gagal memuatkan pesanan Shopify.',
  },
  'order.shopify.noPermission': {
    'en': 'You do not have permission to view orders.',
    'zh': '您没有查看订单的权限。',
    'ms': 'Anda tiada kebenaran untuk melihat pesanan.',
  },
  'order.shopify.open': {
    'en': 'Details',
    'zh': '详情',
    'ms': 'Butiran',
  },
  'order.shopify.openOfficial': {
    'en': 'Open order',
    'zh': '打开订单',
    'ms': 'Buka pesanan',
  },
  'order.shopify.paid': {
    'en': 'Paid',
    'zh': '已付款',
    'ms': 'Dibayar',
  },
  'order.shopify.searchHint': {
    'en': 'Search Shopify #, customer…',
    'zh': '搜索 Shopify #、客户…',
    'ms': 'Cari Shopify #, pelanggan…',
  },
  'order.shopify.status.approved': {
    'en': 'Approved',
    'zh': '已批准',
    'ms': 'Diluluskan',
  },
  'order.shopify.status.pending': {
    'en': 'Pending review',
    'zh': '待审批',
    'ms': 'Menunggu semakan',
  },
  'order.shopify.status.quarantined': {
    'en': 'Needs check',
    'zh': '需核对',
    'ms': 'Perlu semak',
  },
  'order.shopify.status.rejected': {
    'en': 'Rejected',
    'zh': '已拒绝',
    'ms': 'Ditolak',
  },
  'order.shopify.subtitle': {
    'en': '{count} order(s)',
    'zh': '{count} 笔订单',
    'ms': '{count} pesanan',
  },
  'order.shopify.title': {
    'en': 'Shopify Order Review',
    'zh': 'Shopify 订单审批',
    'ms': 'Semakan Pesanan Shopify',
  },
  'order.shopify.unpaid': {
    'en': 'Unpaid',
    'zh': '未付款',
    'ms': 'Belum dibayar',
  },
  'order.status.pickedUp': {
    'en': 'Picked Up',
    'zh': '已自取',
    'ms': 'Telah Diambil',
  },
  'order.status.readyForPickup': {
    'en': 'Ready for Pickup',
    'zh': '待自取',
    'ms': 'Sedia Diambil',
  },
  'order.timeline.pickedUp': {
    'en': 'Picked Up',
    'zh': '已自取',
    'ms': 'Telah Diambil',
  },
  'order.timeline.readyPickup': {
    'en': 'Ready for Pickup',
    'zh': '待自取',
    'ms': 'Sedia Diambil',
  },
  'order.whatsapp.businessOpenFailed': {
    'en': 'Could not open WhatsApp Business.',
    'zh': '无法打开 WhatsApp Business。',
    'ms': 'Tidak dapat membuka WhatsApp Business.',
  },
  'order.whatsapp.importSuccess': {
    'en': 'Order imported. Review delivery details, then payment.',
    'zh': '订单已导入。请核对配送资料，然后付款。',
    'ms': 'Pesanan diimport. Semak butiran penghantaran, kemudian bayaran.',
  },
  'order.whatsapp.parseFailed': {
    'en':
        'Could not read an order from the message. Paste a WhatsApp Business message with customer or product details.',
    'zh': '无法从消息读取订单。请粘贴包含客户或商品信息的 WhatsApp Business 消息。',
    'ms':
        'Tidak dapat membaca pesanan daripada mesej. Tampal mesej WhatsApp Business dengan butiran pelanggan atau produk.',
  },
  'order.whatsapp.pasteDialogHintEmpty': {
    'en': 'Clipboard is empty. Paste the WhatsApp Business message here, then tap OK.',
    'zh': '剪贴板为空。请粘贴 WhatsApp Business 消息，然后点确定。',
    'ms': 'Papan keratan kosong. Tampal mesej WhatsApp Business di sini, kemudian ketik OK.',
  },
  'order.whatsapp.pasteDialogHintReview': {
    'en': 'Review the message below, edit if needed, then tap OK.',
    'zh': '请核对下方消息，如需可编辑，然后点确定。',
    'ms': 'Semak mesej di bawah, sunting jika perlu, kemudian ketik OK.',
  },
  'order.whatsapp.pasteDialogTitle': {
    'en': 'WhatsApp Business',
    'zh': 'WhatsApp Business',
    'ms': 'WhatsApp Business',
  },
  'order.whatsapp.phoneInvalid': {
    'en': 'Customer phone number is missing or invalid.',
    'zh': '客户电话号码缺失或无效。',
    'ms': 'Nombor telefon pelanggan tiada atau tidak sah.',
  },
};
