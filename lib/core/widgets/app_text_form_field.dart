import 'package:astrologer_app/core/utils/size_config.dart';
import 'package:flutter/material.dart';


class AppTextFormField extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final String? labelText;
  final TextInputType keyboardType;
  final bool obscureText;
  final Widget? prefixIcon;
  final bool isPassword;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final int maxLines;
  final bool enabled;
  final double? verticalPadding;

  const AppTextFormField({
    super.key,
    required this.controller,
    required this.hintText,
    this.labelText,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.prefixIcon,
    this.suffixIcon,
    this.isPassword= false,
    this.validator,
    this.onChanged,
    this.maxLines = 1,
    this.verticalPadding = 18,
    this.enabled = true,
  });

  @override
  State<AppTextFormField> createState() => _AppTextFormFieldState();
}

class _AppTextFormFieldState extends State<AppTextFormField> {
   late bool _obscureText;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.isPassword;
  }
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TextFormField(
      controller: widget.controller,
      keyboardType: widget.keyboardType,
      obscureText: widget.obscureText,
      validator: widget.validator,
      onChanged: widget.onChanged,
      maxLines: widget.maxLines,
      enabled: widget.enabled,
      style: theme.textTheme.bodyMedium, // uses #6C7278
      decoration: InputDecoration(
        hintText: widget.hintText,
        labelText: widget.labelText,
        hintStyle: theme.textTheme.bodyMedium,
        labelStyle: theme.textTheme.bodyMedium,
        prefixIcon: widget.prefixIcon,
       suffixIcon: widget.isPassword
            ? IconButton(
                icon: Icon(
                  _obscureText
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
                onPressed: () {
                  setState(() {
                    _obscureText = !_obscureText;
                  });
                },
              )
            : null,

        contentPadding: EdgeInsets.symmetric(
          horizontal: FigmaSize.w(24),
          vertical: FigmaSize.h(widget.verticalPadding!),
        ),

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(FigmaSize.w(5)),
          borderSide: BorderSide(
            color: Colors.grey.shade300,
          ),
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(FigmaSize.w(5)),
          borderSide: BorderSide(
            color: theme.colorScheme.primary,
            width: 1.5,
          ),
        ),

        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(FigmaSize.w(5)),
          borderSide: const BorderSide(
            color: Colors.red,
          ),
        ),

        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(FigmaSize.w(12)),
          borderSide: const BorderSide(
            color: Colors.red,
            width: 1.5,
          ),
        ),
      ),
    );
  }
}
