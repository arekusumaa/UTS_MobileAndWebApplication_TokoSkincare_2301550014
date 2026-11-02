import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

enum ButtonType { primary, secondary, disabled }

class CustomButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final ButtonType type;
  final IconData? icon;
  final double? width;
  final bool isLoading;

  const CustomButton({
    super.key,
    required this.label,
    this.onPressed,
    this.type = ButtonType.primary,
    this.icon,
    this.width,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDisabled = type == ButtonType.disabled || onPressed == null;

    Color backgroundColor;
    Color foregroundColor;
    Border? border;

    switch (type) {
      case ButtonType.primary:
        backgroundColor = AppColors.primary;
        foregroundColor = Colors.white;
        border = null;
        break;
      case ButtonType.secondary:
        backgroundColor = Colors.white;
        foregroundColor = AppColors.primary;
        border = Border.all(color: AppColors.primary);
        break;
      case ButtonType.disabled:
        backgroundColor = AppColors.border;
        foregroundColor = AppColors.textSecondary;
        border = null;
        break;
    }

    return SizedBox(
      width: width ?? double.infinity,
      height: 48,
      child: Material(
        color: isDisabled ? AppColors.border : backgroundColor,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: isDisabled || isLoading ? null : onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: type == ButtonType.secondary ? border : null,
            ),
            child: Center(
              child: isLoading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: foregroundColor,
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (icon != null) ...[
                          Icon(icon, color: foregroundColor, size: 18),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: isDisabled ? AppColors.textSecondary : foregroundColor,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
