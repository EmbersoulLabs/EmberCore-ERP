import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '/theme/ember_brand.dart';

/// Shared [InputDecoration] for EmberCore business forms.
InputDecoration emberFormInputDecoration(
  BuildContext context, {
  required String labelText,
  String? hintText,
}) {
  const radius = BorderRadius.all(Radius.circular(EmberBrand.radiusMd));
  return InputDecoration(
    labelText: labelText,
    hintText: hintText,
    labelStyle: GoogleFonts.inter(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: EmberBrand.textSecondary,
    ),
    hintStyle: GoogleFonts.inter(
      fontSize: 14,
      color: EmberBrand.textSecondary,
    ),
    filled: true,
    fillColor: EmberBrand.background,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: const OutlineInputBorder(
      borderRadius: radius,
      borderSide: BorderSide(color: EmberBrand.border),
    ),
    enabledBorder: const OutlineInputBorder(
      borderRadius: radius,
      borderSide: BorderSide(color: EmberBrand.border),
    ),
    focusedBorder: const OutlineInputBorder(
      borderRadius: radius,
      borderSide: BorderSide(color: EmberBrand.electricBlue, width: 1.5),
    ),
    errorBorder: const OutlineInputBorder(
      borderRadius: radius,
      borderSide: BorderSide(color: EmberBrand.error),
    ),
    focusedErrorBorder: const OutlineInputBorder(
      borderRadius: radius,
      borderSide: BorderSide(color: EmberBrand.error, width: 1.5),
    ),
  );
}

TextStyle emberFormFieldTextStyle(BuildContext context) {
  return GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: EmberBrand.textPrimary,
  );
}

/// Primary save/create button styling aligned with billing and settings pages.
ButtonStyle emberPrimaryButtonStyle(BuildContext context) {
  return FilledButton.styleFrom(
    backgroundColor: EmberBrand.electricBlue,
    foregroundColor: Colors.white,
    minimumSize: const Size.fromHeight(48),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(EmberBrand.radiusMd),
    ),
    textStyle: GoogleFonts.interTight(
      fontSize: 16,
      fontWeight: FontWeight.w600,
    ),
  );
}

ButtonStyle emberSecondaryButtonStyle(BuildContext context) {
  return OutlinedButton.styleFrom(
    foregroundColor: EmberBrand.navy,
    minimumSize: const Size.fromHeight(48),
    side: const BorderSide(color: EmberBrand.border),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(EmberBrand.radiusMd),
    ),
    textStyle: GoogleFonts.interTight(
      fontSize: 16,
      fontWeight: FontWeight.w600,
    ),
  );
}
