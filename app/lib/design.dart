import 'dart:ui';

import 'package:material_ui/material_ui.dart';

import 'design_tokens.dart';

abstract final class MH {
  // The values are generated from the repository's shared design contract.
  static const canvas = DesignTokens.canvas,
      surface = DesignTokens.surface,
      ink = DesignTokens.ink,
      secondary = DesignTokens.secondary,
      accent = DesignTokens.accent,
      accentSoft = DesignTokens.accentSoft,
      border = DesignTokens.border,
      orb = DesignTokens.orb,
      muted = DesignTokens.muted,
      surfaceTint = DesignTokens.surfaceTint;
  // Text buttons that start a line keep their label on the content edge.
  static final flushText = TextButton.styleFrom(padding: EdgeInsets.zero);
  // One value size for dropdowns, matching text fields.
  static const field = TextStyle(fontFamily: 'Inter', fontSize: 14, color: ink);
  static ThemeData theme() => ThemeData(
    // Deliberately one control style on every target; never adaptive OS widgets.
    platform: TargetPlatform.android,
    useMaterial3: true,
    fontFamily: 'Inter',
    scaffoldBackgroundColor: canvas,
    colorScheme: const ColorScheme.light(
      primary: ink,
      onPrimary: surface,
      primaryContainer: accentSoft,
      onPrimaryContainer: ink,
      secondary: accent,
      onSecondary: surface,
      secondaryContainer: accentSoft,
      onSecondaryContainer: ink,
      tertiary: accent,
      surface: surface,
      onSurface: ink,
      onSurfaceVariant: secondary,
      outline: border,
      outlineVariant: border,
      surfaceTint: accent,
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(fontSize: 14, color: ink, height: 1.6),
      bodyMedium: TextStyle(fontSize: 13, color: ink, height: 1.5),
      bodySmall: TextStyle(fontSize: 11, color: secondary, height: 1.5),
      titleLarge: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w500,
        letterSpacing: -.8,
        color: ink,
      ),
      titleMedium: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w500,
        color: ink,
      ),
      titleSmall: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: ink,
      ),
    ),
    splashFactory: NoSplash.splashFactory,
    dividerColor: border,
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
      labelStyle: const TextStyle(color: secondary, fontSize: 13),
      hintStyle: const TextStyle(color: muted, fontSize: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: accent, width: 1.4),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: ink,
        foregroundColor: Colors.white,
        minimumSize: const Size(44, 44),
        padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 12),
        textStyle: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: secondary,
        minimumSize: const Size(44, 44),
        side: const BorderSide(color: border),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        textStyle: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: ink,
        minimumSize: const Size(44, 44),
        textStyle: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: surface,
      selectedColor: accentSoft,
      labelStyle: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 12,
        color: secondary,
      ),
      side: const BorderSide(color: border),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    sliderTheme: const SliderThemeData(
      activeTrackColor: accent,
      inactiveTrackColor: accentSoft,
      thumbColor: accent,
      trackHeight: 3,
      // The track lines up with the labels above it.
      padding: EdgeInsets.symmetric(vertical: 16),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: ink,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      contentTextStyle: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 13,
        color: Colors.white,
      ),
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(color: ink.withValues(alpha: .08), blurRadius: 16),
        ],
      ),
      textStyle: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 11,
        color: secondary,
      ),
    ),
  );
}

class GlassSurface extends StatelessWidget {
  const GlassSurface({
    super.key,
    required this.child,
    this.padding = EdgeInsets.zero,
    this.radius = 20,
    this.blur = false,
    this.color,
  });
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final bool blur;
  final Color? color;
  @override
  Widget build(BuildContext context) {
    final content = DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        gradient: color == null
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: .94),
                  MH.surfaceTint.withValues(alpha: .79),
                ],
              )
            : null,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: MH.border.withValues(alpha: .9)),
      ),
      child: Padding(padding: padding, child: child),
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: MH.ink.withValues(alpha: .045),
            blurRadius: 24,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: blur
            ? BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: content,
              )
            : content,
      ),
    );
  }
}

class Eyebrow extends StatelessWidget {
  const Eyebrow(this.text, {super.key});
  final String text;
  @override
  Widget build(BuildContext context) => Text(
    text.toUpperCase(),
    style: const TextStyle(
      fontSize: 9,
      fontWeight: FontWeight.w500,
      letterSpacing: 1.7,
      color: MH.muted,
    ),
  );
}

class Brand extends StatelessWidget {
  const Brand({super.key, this.large = false});
  final bool large;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(
        Icons.people_outline_rounded,
        size: large ? 25 : 22,
        color: MH.accent,
      ),
      const SizedBox(width: 7),
      Text.rich(
        TextSpan(
          children: [
            const TextSpan(
              text: 'meet',
              style: TextStyle(fontWeight: FontWeight.w400),
            ),
            const TextSpan(
              text: 'halfway',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        style: TextStyle(
          fontSize: large ? 20 : 18,
          letterSpacing: -.8,
          color: MH.ink,
        ),
      ),
    ],
  );
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {super.key, this.subtitle, this.trailing});
  final String title;
  final String? subtitle;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 27,
                fontWeight: FontWeight.w500,
                letterSpacing: -1.1,
                height: 1.25,
              ),
            ),
          ),
          ?trailing,
        ],
      ),
      if (subtitle != null) ...[
        const SizedBox(height: 9),
        Text(
          subtitle!,
          style: const TextStyle(
            fontSize: 12,
            color: MH.secondary,
            height: 1.6,
          ),
        ),
      ],
    ],
  );
}

class EmptyState extends StatelessWidget {
  const EmptyState(
    this.title,
    this.message, {
    super.key,
    this.icon = Icons.people_outline_rounded,
    this.action,
  });
  final String title, message;
  final IconData icon;
  final Widget? action;
  @override
  Widget build(BuildContext context) => GlassSurface(
    padding: const EdgeInsets.all(28),
    child: Column(
      children: [
        Icon(icon, size: 36, color: MH.accent.withValues(alpha: .65)),
        const SizedBox(height: 15),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 9),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 12,
            color: MH.secondary,
            height: 1.7,
          ),
        ),
        if (action != null) ...[const SizedBox(height: 18), action!],
      ],
    ),
  );
}

/// Equal-width buttons in one row, stacked full width when the row would
/// squeeze each below [minWidth].
class ButtonRow extends StatelessWidget {
  const ButtonRow({
    super.key,
    required this.children,
    this.minWidth = 120,
    this.maxWidth = 220,
  });
  final List<Widget> children;
  final double minWidth, maxWidth;
  static const gap = 8.0;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final count = children.length;
      final scale = MediaQuery.textScalerOf(context).scale(1);
      if (box.maxWidth < minWidth * scale * count + gap * (count - 1)) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final (i, child) in children.indexed) ...[
              if (i > 0) const SizedBox(height: gap),
              child,
            ],
          ],
        );
      }
      return Align(
        alignment: AlignmentDirectional.centerStart,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: maxWidth * scale * count + gap * (count - 1),
          ),
          child: Row(
            children: [
              for (final (i, child) in children.indexed) ...[
                if (i > 0) const SizedBox(width: gap),
                Expanded(child: child),
              ],
            ],
          ),
        ),
      );
    },
  );
}

/// Shared field chrome, selection handles and edit menu on every target.
TextField sharedTextField({
  Key? key,
  TextEditingController? controller,
  int? maxLength,
  int? minLines,
  int? maxLines = 1,
  TextStyle? style,
  InputDecoration? decoration,
  ValueChanged<String>? onSubmitted,
  TextInputType? keyboardType,
  TextCapitalization textCapitalization = TextCapitalization.none,
}) => TextField(
  key: key,
  controller: controller,
  maxLength: maxLength,
  minLines: minLines,
  maxLines: maxLines,
  style: style,
  decoration: decoration,
  onSubmitted: onSubmitted,
  keyboardType: keyboardType,
  textCapitalization: textCapitalization,
  selectionControls: materialTextSelectionHandleControls,
  contextMenuBuilder: (context, state) {
    const labels = {
      'cut': 'Cut',
      'copy': 'Copy',
      'paste': 'Paste',
      'selectAll': 'Select all',
    };
    final items = state.contextMenuButtonItems
        .where((item) => labels.containsKey(item.kind.name))
        .toList();
    if (items.isEmpty) return const SizedBox.shrink();
    final anchors = state.contextMenuAnchors;
    return TextSelectionToolbar(
      anchorAbove: anchors.primaryAnchor,
      anchorBelow: anchors.secondaryAnchor ?? anchors.primaryAnchor,
      children: [
        for (final item in items)
          TextButton(
            onPressed: item.onPressed,
            child: Text(labels[item.kind.name]!),
          ),
      ],
    );
  },
);
