// lib/theme/button_styles.dart
import 'package:chatbot/theme/borders.dart';
import 'package:chatbot/theme/constants.dart';
import 'package:flutter/material.dart';
import 'colors.dart';

class AppButtonStyles {
  static ButtonStyle get elevated => ButtonStyle(
        backgroundColor: MaterialStateProperty.resolveWith<Color>(
          (states) {
            if (states.contains(MaterialState.pressed)) {
              return AppColors.primaryPressed.withOpacity(0.8);
            }
            return AppColors.primary;
          },
        ),
        surfaceTintColor: MaterialStateProperty.resolveWith<Color>(
          (states) {
            if (states.contains(MaterialState.pressed)) {
              return Colors.white10;
            }
            return Colors.white38;
          },
        ),
        foregroundColor: MaterialStateProperty.all(Colors.white),
        elevation: MaterialStateProperty.resolveWith<double>(
          (states) => states.contains(MaterialState.pressed) ? 1 : 12,
        ),
        shadowColor: MaterialStateProperty.resolveWith<Color>(
          (states) => AppColors.primary.withOpacity(
            states.contains(MaterialState.pressed) ? 0.3 : 0.6,
          ),
        ),
        padding: MaterialStateProperty.all(
          const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
        shape: MaterialStateProperty.resolveWith<OutlinedBorder>(
          (states) {
            return GradientBorder(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: states.contains(MaterialState.pressed) // ボタンが押されているかの判定
                    ? [
                        // 押されているときの色
                        Color.fromRGBO(169, 243, 233, 0.5), // 1つ目の色（上部）
                        Color.fromRGBO(26, 59, 55, 0.5), // 2つ目の色（下部）
                      ]
                    : [
                        // 押されていないときの色
                        Color.fromRGBO(169, 243, 233, 0.7), // 1つ目の色（上部）
                        Color.fromRGBO(26, 59, 55, 0.7), // 2つ目の色（下部）
                      ],
              ),
              borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
              width: AppSpacing.borderWidth,
            );
          },
        ),
      );
}
