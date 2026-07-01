import 'strings/common_strings.dart';
import 'strings/order_strings.dart';
import 'strings/product_strings.dart';
import 'strings/pos_strings.dart';
import 'strings/customer_strings.dart';
import 'strings/invoice_strings.dart';
import 'strings/report_strings.dart';
import 'strings/admin_strings.dart';
import 'strings/dashboard_strings.dart';
import 'strings/brand_strings.dart';
import 'strings/billing_strings.dart';
import 'strings/branch_strings.dart';

/// Merged translation catalog for the app.
const Map<String, Map<String, String>> kAppStrings = {
  ...commonStrings,
  ...orderStrings,
  ...productStrings,
  ...posStrings,
  ...customerStrings,
  ...invoiceStrings,
  ...reportStrings,
  ...adminStrings,
  ...dashboardStrings,
  ...brandStrings,
  ...billingStrings,
  ...branchStrings,
};
