import 'package:flutter/material.dart';
import 'package:om_ai/resources/st_res.dart';

class StStyles {

  static const TextStyle baseTextStyle = TextStyle(
    fontFamily: 'IBM Plex Sans',
    fontSize: 12,
    fontWeight: FontWeight.normal,
    height: 1.5,
  );

  static const TextStyle titleText = TextStyle(
      fontWeight: FontWeight.w400, fontSize: 18, color: StColors.black);

  static const TextStyle valueText = TextStyle(
      fontWeight: FontWeight.w400, fontSize: 14, color: StColors.black);

  static const TextStyle text16 = TextStyle(
      fontWeight: FontWeight.w400, fontSize: 16, color: StColors.black);

  static const TextStyle bottomIcon = TextStyle(
      fontWeight: FontWeight.w400, fontSize: 12, color: StColors.white);

  static const TextStyle screenTitleText = TextStyle(
      fontWeight: FontWeight.w600, fontSize: 20, color: StColors.white);

  static const TextStyle regularText24 =
      TextStyle(fontWeight: FontWeight.w400, fontSize: 24);

  static const TextStyle subValue = TextStyle(
      fontWeight: FontWeight.w400, fontSize: 14, color: StColors.stOrange);

  static const TextStyle boldText15 = TextStyle(
      fontWeight: FontWeight.w600, fontSize: 15, color: StColors.black);

  static const TextStyle boldText18 = TextStyle(
      fontWeight: FontWeight.w600, fontSize: 18, color: StColors.black);

  static TextStyle boldText16 = const TextStyle(
      fontWeight: FontWeight.w600, fontSize: 16, color: StColors.colorPrimary);

  static const double bannerHeight = 140;

  static OutlineInputBorder outLineBorder = OutlineInputBorder(
    borderSide: const BorderSide(width: 1, color: StColors.gray),
    borderRadius: BorderRadius.circular(10.0),
  );

  static OutlineInputBorder focusBorder = OutlineInputBorder(
    borderSide: const BorderSide(color: StColors.stOrange),
    borderRadius: BorderRadius.circular(4.0),
  );

  static BoxDecoration dropdownContainer = BoxDecoration(
      color: StColors.lightGray, borderRadius: BorderRadius.circular(04.0));

  static ButtonStyle confirmButton = ElevatedButton.styleFrom(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4.0)),
    foregroundColor: StColors.white,
    backgroundColor: StColors.colorPrimary,
  );

  static ShapeBorder dialogShape =
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0));

  static const TextStyle textRegular16 = TextStyle(
      fontWeight: FontWeight.w400, fontSize: 16, color: StColors.black);
}
