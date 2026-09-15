import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/scaffold_provider.dart';
import '../theme/ewu_theme_extension.dart';

class EWUmateAppBar extends ConsumerWidget implements PreferredSizeWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.ewuColors;

    // Logic to determine leading widget
    Widget? leading;
    
    // If showMenu is forced or if we are at a root and showBack isn't forced
    if (showMenu) {
      leading = IconButton(
        icon: Icon(Icons.menu_rounded, color: colors.textPrimary),
        onPressed: () => ref.read(scaffoldKeyProvider).currentState?.openDrawer(),
      );
    } else if (showBack || context.canPop()) {
      leading = IconButton(
        icon: Icon(Icons.arrow_back_rounded, color: colors.textPrimary),
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
        icon: Icon(Icons.menu_rounded, color: colors.textPrimary),
        onPressed: () => ref.read(scaffoldKeyProvider).currentState?.openDrawer(),
      );
    }

    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: leading,
      title: Text(
        title,
        style: GoogleFonts.sora(
          color: colors.textPrimary,
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
