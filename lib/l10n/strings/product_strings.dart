/// Product & material catalog UI strings.
const Map<String, Map<String, String>> productStrings = {
  'product.list.title': {
    'en': 'Product',
    'zh': '产品',
    'ms': 'Produk',
  },
  'product.list.heading': {
    'en': 'Product List',
    'zh': '产品列表',
    'ms': 'Senarai Produk',
  },
  'product.list.empty': {
    'en': 'No products yet',
    'zh': '暂无产品',
    'ms': 'Tiada produk lagi',
  },
  'product.list.allowZeroOn': {
    'en': 'Allow zero-stock sale',
    'zh': '开启零库存可售',
    'ms': 'Benarkan jualan stok sifar',
  },
  'product.list.allowZeroOff': {
    'en': 'Disallow zero-stock sale',
    'zh': '关闭零库存可售',
    'ms': 'Lumpuhkan jualan stok sifar',
  },
  'product.list.allowZeroUpdated': {
    'en': 'Updated {count} product(s)',
    'zh': '已更新 {count} 个商品',
    'ms': '{count} produk dikemas kini',
  },
  'product.list.allowZeroFailed': {
    'en': 'Update failed: {error}',
    'zh': '更新失败：{error}',
    'ms': 'Kemas kini gagal: {error}',
  },
  'product.list.importButton': {
    'en': 'Import Excel / CSV',
    'zh': '批量导入',
    'ms': 'Import Excel / CSV',
  },
  'product.list.importTitle': {
    'en': 'Import products',
    'zh': '导入商品',
    'ms': 'Import produk',
  },
  'product.list.importFile': {
    'en': 'File: {name}',
    'zh': '文件：{name}',
    'ms': 'Fail: {name}',
  },
  'product.list.importSummary': {
    'en': '{total} rows · {ready} ready · {errors} with errors',
    'zh': '共 {total} 行 · {ready} 可导入 · {errors} 行有错误',
    'ms': '{total} baris · {ready} sedia · {errors} ralat',
  },
  'product.list.importSkipErrors': {
    'en': 'Rows with errors will be skipped.',
    'zh': '有错误的行将被跳过。',
    'ms': 'Baris dengan ralat akan dilangkau.',
  },
  'product.list.importPreview': {
    'en': 'Preview',
    'zh': '预览',
    'ms': 'Pratonton',
  },
  'product.list.importMore': {
    'en': '…and {count} more',
    'zh': '…还有 {count} 个',
    'ms': '…dan {count} lagi',
  },
  'product.list.importConfirm': {
    'en': 'Import',
    'zh': '导入',
    'ms': 'Import',
  },
  'product.list.importing': {
    'en': 'Importing…',
    'zh': '导入中…',
    'ms': 'Mengimport…',
  },
  'product.list.importCreated': {
    'en': 'Created {count} product(s).',
    'zh': '已创建 {count} 个商品。',
    'ms': '{count} produk dicipta.',
  },
  'product.list.importSkippedDuplicates': {
    'en': 'Skipped {count} duplicate SKU(s).',
    'zh': '跳过 {count} 个重复 SKU。',
    'ms': 'Langkau {count} SKU pendua.',
  },
  'product.list.importFailedCount': {
    'en': '{count} failed.',
    'zh': '{count} 个失败。',
    'ms': '{count} gagal.',
  },
  'product.list.importFailed': {
    'en': 'Import failed: {error}',
    'zh': '导入失败：{error}',
    'ms': 'Import gagal: {error}',
  },
  'product.list.importReadFailed': {
    'en': 'Could not read the selected file.',
    'zh': '无法读取所选文件。',
    'ms': 'Tidak dapat membaca fail dipilih.',
  },
  'product.list.importHint': {
    'en': 'Upload .xlsx or .csv with columns: Name, SKU, '
        'Price, Category (optional).',
    'zh': '上传 .xlsx 或 .csv，列：名称、SKU、价格、分类（可选）。',
    'ms': 'Muat naik .xlsx atau .csv dengan lajur: Name, SKU, '
        'Price, Category (pilihan).',
  },
  'product.list.exportButton': {
    'en': 'Export CSV',
    'zh': '导出 CSV',
    'ms': 'Eksport CSV',
  },
  'product.list.exportTooltip': {
    'en': 'Export products to CSV',
    'zh': '导出商品为 CSV',
    'ms': 'Eksport produk ke CSV',
  },
  'product.list.importTooltip': {
    'en': 'Import products from Excel / CSV',
    'zh': '从 Excel / CSV 批量导入商品',
    'ms': 'Import produk dari Excel / CSV',
  },
  'product.list.exportNoMatch': {
    'en': 'No products to export for the current filter.',
    'zh': '当前筛选条件下没有可导出的商品。',
    'ms': 'Tiada produk untuk dieksport bagi penapis semasa.',
  },
  'product.list.exportedSnack': {
    'en': 'Exported {count} product(s).',
    'zh': '已导出 {count} 个商品。',
    'ms': '{count} produk dieksport.',
  },
  'product.list.exportFailed': {
    'en': 'Export failed: {error}',
    'zh': '导出失败：{error}',
    'ms': 'Eksport gagal: {error}',
  },
  'product.create.title': {
    'en': 'Create Product',
    'zh': '创建产品',
    'ms': 'Cipta Produk',
  },
  'product.edit.title': {
    'en': 'Edit Product',
    'zh': '编辑产品',
    'ms': 'Edit Produk',
  },
  'product.form.subtitle': {
    'en': 'Add product details for POS, orders, and reports.',
    'zh': '填写产品信息，用于收银、订单与报表。',
    'ms': 'Isi butiran produk untuk POS, pesanan dan laporan.',
  },
  'product.form.section.details': {
    'en': 'Product details',
    'zh': '产品信息',
    'ms': 'Butiran produk',
  },
  'product.form.section.photo': {
    'en': 'Photo',
    'zh': '图片',
    'ms': 'Foto',
  },
  'product.form.nameHint': {
    'en': 'Enter product name',
    'zh': '输入产品名称',
    'ms': 'Masukkan nama produk',
  },
  'product.form.skuHint': {
    'en': 'Stock keeping unit',
    'zh': '库存单位编码',
    'ms': 'Unit stok',
  },
  'product.form.priceHint': {
    'en': '0.00',
    'zh': '0.00',
    'ms': '0.00',
  },
  'product.form.category': {
    'en': 'Product category',
    'zh': '产品分类',
    'ms': 'Kategori produk',
  },
  'product.form.categoryHint': {
    'en': 'Product category',
    'zh': '产品分类',
    'ms': 'Kategori produk',
  },
  'product.form.name': {
    'en': 'Product Name',
    'zh': '产品名称',
    'ms': 'Nama Produk',
  },
  'product.form.sku': {
    'en': 'SKU',
    'zh': 'SKU',
    'ms': 'SKU',
  },
  'product.form.price': {
    'en': 'Price',
    'zh': '价格',
    'ms': 'Harga',
  },
  'product.form.isActive': {
    'en': 'Is Active',
    'zh': '是否启用',
    'ms': 'Aktif',
  },
  'product.form.allowZeroStock': {
    'en': 'Allow sale at zero stock',
    'zh': '零库存仍可销售',
    'ms': 'Benarkan jualan stok sifar',
  },
  'product.form.allowZeroStockHint': {
    'en': 'When on, POS can sell this product even if stock is 0 (stock may go negative).',
    'zh': '开启后，库存为 0 时 POS 仍可下单销售（库存可能变为负数）。',
    'ms': 'Apabila dihidupkan, POS boleh jual walaupun stok 0 (stok boleh negatif).',
  },
  'product.stock.allowZeroBadge': {
    'en': 'Zero-stock OK',
    'zh': '可零库存售',
    'ms': 'Stok sifar OK',
  },
  'product.form.uploadPhoto': {
    'en': 'Upload Photo',
    'zh': '上传图片',
    'ms': 'Muat naik foto',
  },
  'product.form.importHint': {
    'en': 'Upload .xlsx or .csv with columns: Name, SKU, '
        'Price, Category (optional).',
    'zh': '上传 .xlsx 或 .csv，列：名称、SKU、价格、分类（可选）。',
    'ms': 'Muat naik .xlsx atau .csv dengan lajur: Name, SKU, '
        'Price, Category (pilihan).',
  },
  'product.select.title': {
    'en': 'Select Products',
    'zh': '选择产品',
    'ms': 'Pilih Produk',
  },
  'product.select.missingOrderRef': {
    'en': 'Order reference missing. Go back and tap Create Order again.',
    'zh': '缺少订单引用。请返回并重新创建订单。',
    'ms': 'Rujukan pesanan tiada. Kembali dan cipta pesanan semula.',
  },
  'product.select.loadError': {
    'en': 'Cannot load products: {error}',
    'zh': '无法加载产品：{error}',
    'ms': 'Tidak dapat memuatkan produk: {error}',
  },
  'product.select.noActive': {
    'en': 'No active products for your company.',
    'zh': '贵公司暂无启用中的产品。',
    'ms': 'Tiada produk aktif untuk syarikat anda.',
  },
  'product.select.noMatch': {
    'en': 'No products match your search or filter.',
    'zh': '没有符合搜索或筛选的产品。',
    'ms': 'Tiada produk sepadan dengan carian atau penapis.',
  },
  'product.select.customPrompt': {
    'en': 'Have a custom product?',
    'zh': '有定制产品？',
    'ms': 'Ada produk khusus?',
  },
  'product.select.customName': {
    'en': 'Custom product name',
    'zh': '定制产品名称',
    'ms': 'Nama produk khusus',
  },
  'product.select.remark': {
    'en': 'Remark',
    'zh': '备注',
    'ms': 'Catatan',
  },
  'product.select.remarkTitle': {
    'en': 'Any remark?',
    'zh': '有备注吗？',
    'ms': 'Ada catatan?',
  },
  'product.select.remarkSaveError': {
    'en': 'Could not save remark: {error}',
    'zh': '无法保存备注：{error}',
    'ms': 'Tidak dapat menyimpan catatan: {error}',
  },
  'product.select.remarkItemMissing': {
    'en': 'Line item is not ready yet. Close and try adding the product again.',
    'zh': '产品明细尚未就绪，请关闭后重新添加产品。',
    'ms': 'Item belum sedia. Tutup dan cuba tambah produk semula.',
  },
  'product.select.addedToCart': {
    'en': 'Added to cart',
    'zh': '已加入购物车',
    'ms': 'Ditambah ke troli',
  },
  'product.select.createCustom': {
    'en': 'Create',
    'zh': '创建',
    'ms': 'Cipta',
  },
  'product.select.chooseMethod': {
    'en': 'Please select the order method',
    'zh': '请选择订单方式',
    'ms': 'Sila pilih kaedah pesanan',
  },
  'product.select.orderLoadError': {
    'en': 'Cannot load order: {error}',
    'zh': '无法加载订单：{error}',
    'ms': 'Tidak dapat memuatkan pesanan: {error}',
  },
  'product.select.cartLoadError': {
    'en': 'Cannot load cart: {error}',
    'zh': '无法加载购物车：{error}',
    'ms': 'Tidak dapat memuatkan troli: {error}',
  },
  'product.select.orderNotFound': {
    'en': 'Order not found. Go back and create the order again.',
    'zh': '找不到订单。请返回重新创建。',
    'ms': 'Pesanan tidak dijumpai. Kembali dan cipta semula.',
  },
  'product.select.retail': {
    'en': 'Retail',
    'zh': '零售',
    'ms': 'Runcit',
  },
  'product.select.deliveryPickUp': {
    'en': 'Delivery / Pick Up',
    'zh': '配送 / 自取',
    'ms': 'Penghantaran / Ambil',
  },
  'product.select.searchHint': {
    'en': 'Search name, SKU, category',
    'zh': '搜索名称、SKU、分类',
    'ms': 'Cari nama, SKU, kategori',
  },
  'product.select.category': {
    'en': 'Category',
    'zh': '分类',
    'ms': 'Kategori',
  },
  'product.select.addError': {
    'en': 'Cannot add product: {error}',
    'zh': '无法添加产品：{error}',
    'ms': 'Tidak dapat menambah produk: {error}',
  },
  'product.select.cartSummary': {
    'en': '{count} items · {total}',
    'zh': '{count} 件 · {total}',
    'ms': '{count} item · {total}',
  },
  'product.select.addCustomProduct': {
    'en': 'Add custom product',
    'zh': '添加自定义产品',
    'ms': 'Tambah produk tersuai',
  },
  'product.select.emptyCart': {
    'en': 'Add products from the grid above',
    'zh': '请先从上方选择产品',
    'ms': 'Tambah produk dari grid di atas',
  },
  'product.delete.title': {
    'en': 'Delete product?',
    'zh': '删除产品？',
    'ms': 'Padam produk?',
  },
  'product.delete.body': {
    'en':
        'Permanently delete "{name}"?\n\nThis cannot be undone. Existing orders '
        'keep their line items.',
    'zh': '永久删除「{name}」？\n\n此操作不可撤销。已有订单的行项目会保留。',
    'ms':
        'Padam "{name}" secara kekal?\n\nTindakan ini tidak boleh dibatalkan. '
        'Pesanan sedia ada kekal item barisnya.',
  },
  'product.delete.success': {
    'en': 'Deleted "{name}".',
    'zh': '已删除「{name}」。',
    'ms': '"{name}" dipadam.',
  },
  'product.delete.failed': {
    'en': 'Delete failed: {error}',
    'zh': '删除失败：{error}',
    'ms': 'Padam gagal: {error}',
  },
  'product.delete.tooltip': {
    'en': 'Delete product',
    'zh': '删除产品',
    'ms': 'Padam produk',
  },
  'product.permission.noEdit': {
    'en': 'Only administrators can edit products.',
    'zh': '仅管理员可编辑产品。',
    'ms': 'Hanya pentadbir boleh edit produk.',
  },
  'product.permission.noCreate': {
    'en': 'You do not have permission to create products.',
    'zh': '您没有创建产品的权限。',
    'ms': 'Anda tiada kebenaran mencipta produk.',
  },
  'product.snack.selectCategory': {
    'en': 'Select a product category first.',
    'zh': '请先选择产品分类。',
    'ms': 'Pilih kategori produk dahulu.',
  },
  'product.snack.invalidPhotoUrl': {
    'en': 'Upload returned an invalid photo URL. Try again.',
    'zh': '上传返回无效图片链接，请重试。',
    'ms': 'Muat naik mengembalikan URL foto tidak sah. Cuba lagi.',
  },
  'product.snack.photoUploaded': {
    'en': 'Photo uploaded — tap Create to save product',
    'zh': '图片已上传 — 点击创建保存产品',
    'ms': 'Foto dimuat naik — ketik Cipta untuk simpan produk',
  },
  'product.snack.saveFailed': {
    'en': 'Save failed: {error}',
    'zh': '保存失败：{error}',
    'ms': 'Simpan gagal: {error}',
  },
  'product.snack.photoNotSavedCreate': {
    'en': 'Product created but photo was not saved. Use Upload Photo on Product List.',
    'zh': '产品已创建但图片未保存。请在产品列表上传图片。',
    'ms': 'Produk dicipta tetapi foto tidak disimpan. Muat naik dari senarai produk.',
  },
  'product.snack.photoNotSavedUpdate': {
    'en': 'Product updated but photo was not saved. Try Upload Photo again.',
    'zh': '产品已更新但图片未保存。请重新上传图片。',
    'ms': 'Produk dikemas kini tetapi foto tidak disimpan. Cuba muat naik semula.',
  },
  'product.snack.createdWithPhoto': {
    'en': 'Product created with photo',
    'zh': '产品已创建（含图片）',
    'ms': 'Produk dicipta dengan foto',
  },
  'product.snack.created': {
    'en': 'Product created',
    'zh': '产品已创建',
    'ms': 'Produk dicipta',
  },
  'product.snack.updatedWithPhoto': {
    'en': 'Product updated with photo',
    'zh': '产品已更新（含图片）',
    'ms': 'Produk dikemas kini dengan foto',
  },
  'product.snack.updated': {
    'en': 'Product updated',
    'zh': '产品已更新',
    'ms': 'Produk dikemas kini',
  },
  'product.category.manageTitle': {
    'en': 'Manage Categories',
    'zh': '管理分类',
    'ms': 'Urus Kategori',
  },
  'product.category.newCategory': {
    'en': 'New category',
    'zh': '新分类',
    'ms': 'Kategori baharu',
  },
  'product.category.hintExample': {
    'en': 'e.g. Hand Bouquet',
    'zh': '例如：Hand Bouquet',
    'ms': 'cth. Hand Bouquet',
  },
  'product.category.deleteBodyInUseCount': {
    'en': '{count} product(s) still use "{name}". They will keep this '
        'category, but it will be removed from the picker.',
    'zh': '仍有 {count} 个产品使用「{name}」。它们会保留该分类，但选择器中将移除。',
    'ms': '{count} produk masih guna "{name}". Mereka kekal kategori ini, '
        'tetapi akan dikeluarkan dari pemilih.',
  },
  'product.category.empty': {
    'en': 'No categories yet. Add one above.',
    'zh': '暂无分类，请在上方添加。',
    'ms': 'Tiada kategori lagi. Tambah di atas.',
  },
  'product.category.deleteTitle': {
    'en': 'Delete category?',
    'zh': '删除分类？',
    'ms': 'Padam kategori?',
  },
  'product.category.deleteBodyInUse': {
    'en': 'Products using "{name}" will keep this category, but it will be '
        'removed from the picker.',
    'zh': '使用「{name}」的产品会保留该分类，但选择器中将移除。',
    'ms': 'Produk yang guna "{name}" kekal kategori ini, tetapi akan '
        'dikeluarkan dari pemilih.',
  },
  'product.category.deleteBody': {
    'en': 'Remove "{name}" from the category list?',
    'zh': '从分类列表移除「{name}」？',
    'ms': 'Buang "{name}" dari senarai kategori?',
  },
  'product.category.companyLine': {
    'en': 'Company: {label}',
    'zh': '公司：{label}',
    'ms': 'Syarikat: {label}',
  },
  'product.category.scopeHint': {
    'en': 'Managing categories for {label} only.',
    'zh': '仅管理 {label} 的分类。',
    'ms': 'Mengurus kategori untuk {label} sahaja.',
  },
  'product.category.scopeHintCompany': {
    'en': 'Managing categories for the selected company only.',
    'zh': '仅管理所选公司的分类。',
    'ms': 'Mengurus kategori untuk syarikat terpilih sahaja.',
  },

  // Materials
  'material.list.title': {
    'en': 'Materials',
    'zh': '物料',
    'ms': 'Bahan',
  },
  'material.list.heading': {
    'en': 'Material List',
    'zh': '物料列表',
    'ms': 'Senarai Bahan',
  },
  'material.list.empty': {
    'en': 'No materials yet',
    'zh': '暂无物料',
    'ms': 'Tiada bahan lagi',
  },
  'material.line.unit': {
    'en': 'Unit: {unit}',
    'zh': '单位：{unit}',
    'ms': 'Unit: {unit}',
  },
  'material.line.sku': {
    'en': 'SKU: {sku}',
    'zh': 'SKU：{sku}',
    'ms': 'SKU: {sku}',
  },
  'material.line.cost': {
    'en': 'Cost: {cost}',
    'zh': '成本：{cost}',
    'ms': 'Kos: {cost}',
  },
  'material.create.title': {
    'en': 'Add Material',
    'zh': '添加物料',
    'ms': 'Tambah Bahan',
  },
  'material.edit.title': {
    'en': 'Edit Material',
    'zh': '编辑物料',
    'ms': 'Edit Bahan',
  },
  'material.form.name': {
    'en': 'Material name',
    'zh': '物料名称',
    'ms': 'Nama bahan',
  },
  'material.form.unit': {
    'en': 'Unit',
    'zh': '单位',
    'ms': 'Unit',
  },
  'material.form.categoryOptional': {
    'en': 'Category (optional)',
    'zh': '分类（可选）',
    'ms': 'Kategori (pilihan)',
  },
  'material.form.skuOptional': {
    'en': 'SKU (optional)',
    'zh': 'SKU（可选）',
    'ms': 'SKU (pilihan)',
  },
  'material.form.costOptional': {
    'en': 'Cost per unit (optional)',
    'zh': '单位成本（可选）',
    'ms': 'Kos seunit (pilihan)',
  },
  'material.delete.title': {
    'en': 'Delete material?',
    'zh': '删除物料？',
    'ms': 'Padam bahan?',
  },
  'material.delete.body': {
    'en': 'Remove "{name}" from the material list?',
    'zh': '从物料列表移除「{name}」？',
    'ms': 'Buang "{name}" dari senarai bahan?',
  },
  'material.delete.button': {
    'en': 'Delete material',
    'zh': '删除物料',
    'ms': 'Padam bahan',
  },
  'material.snack.created': {
    'en': 'Material created.',
    'zh': '物料已创建。',
    'ms': 'Bahan dicipta.',
  },
  'material.snack.saved': {
    'en': 'Material saved.',
    'zh': '物料已保存。',
    'ms': 'Bahan disimpan.',
  },

  'product.stock.onHand': {
    'en': 'Stock: {qty}',
    'zh': '库存：{qty}',
    'ms': 'Stok: {qty}',
  },
  'product.stock.stockInTitle': {
    'en': 'Stock in',
    'zh': '入库',
    'ms': 'Stok masuk',
  },
  'product.stock.stockOutTitle': {
    'en': 'Stock out',
    'zh': '出库',
    'ms': 'Stok keluar',
  },
  'product.stock.currentQty': {
    'en': 'Current stock: {qty}',
    'zh': '当前库存：{qty}',
    'ms': 'Stok semasa: {qty}',
  },
  'product.stock.qty': {
    'en': 'Quantity',
    'zh': '数量',
    'ms': 'Kuantiti',
  },
  'product.stock.qtyRequired': {
    'en': 'Enter a quantity greater than zero.',
    'zh': '请输入大于零的数量。',
    'ms': 'Masukkan kuantiti lebih daripada sifar.',
  },
  'product.stock.noteOptional': {
    'en': 'Note (optional)',
    'zh': '备注（可选）',
    'ms': 'Nota (pilihan)',
  },
  'product.stock.stockInConfirm': {
    'en': 'Confirm stock in',
    'zh': '确认入库',
    'ms': 'Sahkan stok masuk',
  },
  'product.stock.stockOutConfirm': {
    'en': 'Confirm stock out',
    'zh': '确认出库',
    'ms': 'Sahkan stok keluar',
  },
};
