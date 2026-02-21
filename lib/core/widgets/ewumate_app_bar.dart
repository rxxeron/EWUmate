import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'main_shell.dart';

class EWUmateAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool showMenu;
  final bool showBack;
  final VoidCallback? onBack;
  final PreferredSizeWidget? bottom;

  const EWUmateAppBar({
    super.key,
    required this.title,
    this.actions,
    this.showMenu = false,
    this.showBack = false,
    this.onBack,
    this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    // Logic to determine leading widget
    Widget? leading;
    
    // If showMenu is forced or if we are at a root and showBack isn't forced
    if (showMenu) {
      leading = IconButton(
        icon: const Icon(Icons.menu, color: Colors.white),
        onPressed: () => MainShell.scaffoldKey.currentState?.openDrawer(),
      );
    } else if (showBack || context.canPop()) {
      leading = IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: onBack ??
            () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/dashboard');
              }
            },
      );
    } else {
      // Default fallback: show menu if nothing else
      leading = IconButton(
        icon: const Icon(Icons.menu, color: Colors.white),
        onPressed: () => MainShell.scaffoldKey.currentState?.openDrawer(),
      );
    }

    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: leading,
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
      actions: actions,
      bottom: bottom,
      centerTitle: false,
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0));
}
