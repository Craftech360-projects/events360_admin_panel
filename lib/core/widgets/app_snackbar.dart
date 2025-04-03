import 'package:events360_admin/core/constants/constants.dart';
import 'package:events360_admin/core/themes/app_colors.dart';
import 'package:flutter/material.dart';

void showSnackBar(BuildContext context, String content) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      showCloseIcon: true,
      dismissDirection: DismissDirection.horizontal,
      backgroundColor: AppColors.lightWhite,
      content: Text(
        content,
        style: const TextStyle(
          fontFamily: "Satoshi",
          fontSize: 17,
          fontWeight: FontWeight.w500,
          color: AppColors.blueGreyDark,
        ),
      ),
      shape: RoundedRectangleBorder(borderRadius: Constants.br8),
      padding: const EdgeInsets.all(14),
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(18),
    ),
  );
}
