import 'package:flutter/material.dart';

class CustomToggleSwitch extends StatefulWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final double? width;
  final double? height;

  const CustomToggleSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.width = 65,
    this.height = 25
  });

  @override
  State<CustomToggleSwitch> createState() => _CustomToggleSwitchState();
}

class _CustomToggleSwitchState extends State<CustomToggleSwitch> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => widget.onChanged(!widget.value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: widget.value ? const Color(0xFF67BC25) : Colors.white,
            width: 1,
          ),
          // Matches the green and grey from your images
          color: widget.value ? const Color(0xFF67BC25) : const Color(0xFFD9D9D9),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          curve: Curves.decelerate,
          alignment: widget.value ? Alignment.centerRight : Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.all(3.0),
            child: Container(
              width: 18,
              height: 18,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ),
    );
  }
}