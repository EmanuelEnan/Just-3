import 'package:flutter/material.dart';

String poppinsFontFamily = 'Poppins';

//font Weights
FontWeight regularFont = FontWeight.w400;

FontWeight regularBoldFont = FontWeight.w500;
FontWeight semiBoldFont = FontWeight.w600;
FontWeight boldFont = FontWeight.w700;
FontWeight extraBoldFont = FontWeight.w800;

//App Text Size start
final kLargeHeading = TextStyle(
  fontSize: 60,
  fontWeight: boldFont,
  height: 1.25,
  fontFamily: poppinsFontFamily,
  // color: AppColors.kTextPrimaryColor,
);

final kSemiLargeHeading = TextStyle(
  fontSize: 30,
  fontWeight: boldFont,
  height: 1.25,
  fontFamily: poppinsFontFamily,
  // color: AppColors.kTextPrimaryColor,
);

final kHeading = TextStyle(
  fontSize: 20,
  fontWeight: semiBoldFont,
  height: 1.25,
  fontFamily: poppinsFontFamily,
  // color: AppColors.kTextPrimaryColor,
);

final kSemiHeading = TextStyle(
  fontSize: 18,
  fontWeight: regularBoldFont,
  height: 1.25,
  fontFamily: poppinsFontFamily,
  // color: AppColors.kTextPrimaryColor,
);

final kRegular = TextStyle(
  fontSize: 16,
  fontWeight: regularFont,
  height: 1.25,
  fontFamily: poppinsFontFamily,
  // color: AppColors.kTextPrimaryColor,
);
