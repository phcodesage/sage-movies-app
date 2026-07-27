import 'package:flutter/material.dart';

enum ToastType { success, info, warning, error }

class ToastService {
  static void show(
    BuildContext context, {
    required String message,
    String? title,
    ToastType type = ToastType.success,
    Duration duration = const Duration(milliseconds: 2400),
  }) {
    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return;

    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (context) => _ToastWidget(
        message: message,
        title: title,
        type: type,
        onDismiss: () {
          if (entry.mounted) {
            entry.remove();
          }
        },
        duration: duration,
      ),
    );

    overlay.insert(entry);
  }

  static void showSuccess(BuildContext context, String message, {String? title}) {
    show(context, message: message, title: title, type: ToastType.success);
  }

  static void showInfo(BuildContext context, String message, {String? title}) {
    show(context, message: message, title: title, type: ToastType.info);
  }

  static void showWarning(BuildContext context, String message, {String? title}) {
    show(context, message: message, title: title, type: ToastType.warning);
  }

  static void showError(BuildContext context, String message, {String? title}) {
    show(context, message: message, title: title, type: ToastType.error);
  }
}

class _ToastWidget extends StatefulWidget {
  final String message;
  final String? title;
  final ToastType type;
  final VoidCallback onDismiss;
  final Duration duration;

  const _ToastWidget({
    required this.message,
    this.title,
    required this.type,
    required this.onDismiss,
    required this.duration,
  });

  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.4),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _controller.forward();

    Future.delayed(widget.duration, () {
      if (mounted) {
        _controller.reverse().then((_) {
          widget.onDismiss();
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color get _accentColor {
    switch (widget.type) {
      case ToastType.success:
        return const Color(0xFFE50914); // Netflix Red
      case ToastType.info:
        return const Color(0xFF0071EB);
      case ToastType.warning:
        return const Color(0xFFFFB800);
      case ToastType.error:
        return const Color(0xFFFF3B30);
    }
  }

  IconData get _icon {
    switch (widget.type) {
      case ToastType.success:
        return Icons.check_circle_rounded;
      case ToastType.info:
        return Icons.info_rounded;
      case ToastType.warning:
        return Icons.warning_amber_rounded;
      case ToastType.error:
        return Icons.error_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top + 12;

    return Positioned(
      top: topPadding,
      left: 16,
      right: 16,
      child: Material(
        color: Colors.transparent,
        child: SlideTransition(
          position: _slideAnimation,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF18181F).withOpacity(0.95),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _accentColor.withOpacity(0.4), width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: _accentColor.withOpacity(0.25),
                    blurRadius: 16,
                    spreadRadius: 1,
                    offset: const Offset(0, 4),
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.6),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _accentColor.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(_icon, color: _accentColor, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (widget.title != null) ...[
                          Text(
                            widget.title!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                        ],
                        Text(
                          widget.message,
                          style: TextStyle(
                            color: widget.title != null ? Colors.white70 : Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      _controller.reverse().then((_) => widget.onDismiss());
                    },
                    child: const Padding(
                      padding: EdgeInsets.all(4.0),
                      child: Icon(Icons.close_rounded, color: Colors.white38, size: 16),
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
