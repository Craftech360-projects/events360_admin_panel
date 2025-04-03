import 'package:cached_network_image/cached_network_image.dart';
import 'package:events360_admin/core/constants/constants.dart';
import 'package:events360_admin/core/themes/app_colors.dart';
import 'package:flutter/material.dart';

PreferredSizeWidget commonBackbtn(
  BuildContext context, {
  required String title,
  String? userName,
  String? userImage,
  VoidCallback? onProfileTap,
  bool showBackBtn = false,
  bool showSearchIcon = true,
  bool showUserDetails = false,
  required List<PopupMenuEntry<String>> menuItems,
  required void Function(String) onMenuSelected,
}) {
  return AppBar(
    automaticallyImplyLeading: false,
    titleSpacing: 5,
    title: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (showBackBtn)
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: AppColors.white,
            ),
          ),
        Constants.w16,
        if (showUserDetails)
          GestureDetector(
            onTap: onProfileTap,
            child: Row(
              children: [
                CircleAvatar(
                  backgroundImage: userImage != null && userImage.isNotEmpty
                      ? CachedNetworkImageProvider(userImage)
                      : null,
                  radius: 20,
                ),
                Constants.w8,
                Text(
                  userName ?? '',
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 18,
                    color: AppColors.white,
                  ),
                ),
              ],
            ),
          )
        else
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
          ),
      ],
    ),
    actions: [
      if (showSearchIcon)
        const Icon(
          Icons.search,
          size: 30,
          color: AppColors.white,
        ),
      Constants.w8,
      PopupMenuButton<String>(
        icon: const Icon(
          Icons.more_vert,
          size: 30,
          color: AppColors.white,
        ),
        onSelected: onMenuSelected,
        itemBuilder: (BuildContext context) => menuItems,
      ),
    ],
  );
}
