import 'package:flutter/material.dart';
import 'package:hirematrix/views/screens/recruiter/utils/app_constants.dart';

class HireMatrixLogo extends StatelessWidget {
  final double height;
  final bool showText;
  final String? imageUrl;
  final Color? color;

  const HireMatrixLogo({
    super.key,
    this.height = 40,
    this.showText = true,
    this.imageUrl,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final logoWidget = imageUrl != null && imageUrl!.isNotEmpty
        ? Image.network(
            imageUrl!,
            height: height,
            errorBuilder: (context, error, stackTrace) {
              return Icon(
                Icons.business_center_rounded,
                size: height,
                color: color ?? AppColors.getPrimary(isDark),
              );
            },
          )
        : Image.asset(
            'assets/hirematrix_logo.png',
            height: height,
            errorBuilder: (context, error, stackTrace) {
              return Icon(
                Icons.business_center_rounded,
                size: height,
                color: color ?? AppColors.getPrimary(isDark),
              );
            },
          );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        logoWidget,
        if (showText) ...[
          const SizedBox(width: 10),
          Text(
            'HireMatrix',
            style: TextStyle(
              fontSize: height * 0.6,
              fontWeight: FontWeight.w900,
              color: color ?? AppColors.getText(isDark),
              letterSpacing: -0.5,
            ),
          ),
        ],
      ],
    );
  }
}
