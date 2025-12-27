import 'package:flutter/material.dart';

class HoverContainer extends StatefulWidget {
  final Widget child;
  final double? width;
  final EdgeInsets? padding;
  final Color? color;
  final BorderRadius? borderRadius;
  final List<BoxShadow>? boxShadow;

  const HoverContainer({
    super.key,
    required this.child,
    this.width,
    this.padding,
    this.color,
    this.borderRadius,
    this.boxShadow,
  });

  @override
  HoverContainerState createState() => HoverContainerState();
}

class HoverContainerState extends State<HoverContainer> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        transform: Matrix4.translationValues(0, _isHovering ? -5 : 0, 0),
        padding: widget.padding ?? EdgeInsets.all(15),
        width: widget.width,
        decoration: BoxDecoration(
          borderRadius: widget.borderRadius ?? BorderRadius.circular(10),
          color: widget.color ?? Colors.blueGrey,
          boxShadow: widget.boxShadow?.map((shadow) {
            return BoxShadow(
              color: shadow.color,
              blurRadius: _isHovering
                  ? shadow.blurRadius * 2
                  : shadow.blurRadius,
              offset: _isHovering
                  ? Offset(shadow.offset.dx, shadow.offset.dy * 2)
                  : shadow.offset,
              spreadRadius: _isHovering
                  ? (shadow.spreadRadius + 2)
                  : shadow.spreadRadius,
            );
          }).toList(),
        ),
        child: widget.child,
      ),
    );
  }
}

// // Usage:
// HoverContainer(
//   width: taskCardWidth,
//   color: Colors.blueGrey,
//   boxShadow: [
//     BoxShadow(
//       color: AppColors.warmOrangeColor,
//       blurRadius: 4,
//       offset: Offset(2, 2),
//     ),
//   ],
//   child: Text('Task #1', style: kRegular),
// ),
