import 'package:flutter/material.dart';

/// Accessible card widget with proper semantics and keyboard navigation
class AccessibleCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final String? semanticLabel;
  final String? semanticHint;
  final Color? backgroundColor;
  final EdgeInsetsGeometry? padding;
  final double? elevation;
  final bool selected;

  const AccessibleCard({
    super.key,
    required this.child,
    this.onTap,
    this.semanticLabel,
    this.semanticHint,
    this.backgroundColor,
    this.padding,
    this.elevation,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    Widget card = Card(
      color: backgroundColor ?? (selected ? Theme.of(context).primaryColor.withOpacity(0.1) : null),
      elevation: elevation ?? (selected ? 8.0 : 2.0),
      child: Padding(
        padding: padding ?? EdgeInsets.all(16.0),
        child: child,
      ),
    );

    if (onTap != null) {
      card = InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8.0),
        child: card,
      );
    }

    return Semantics(
      label: semanticLabel,
      hint: semanticHint,
      button: onTap != null,
      selected: selected,
      child: card,
    );
  }
}

/// Accessible button with proper contrast and focus indicators
class AccessibleButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? textColor;
  final String? semanticLabel;
  final bool isDestructive;
  final bool isLoading;

  const AccessibleButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.backgroundColor,
    this.textColor,
    this.semanticLabel,
    this.isDestructive = false,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveBackgroundColor = backgroundColor ?? 
        (isDestructive ? Colors.red : theme.primaryColor);
    final effectiveTextColor = textColor ?? 
        (ThemeData.estimateBrightnessForColor(effectiveBackgroundColor) == Brightness.dark 
            ? Colors.white : Colors.black);

    return Semantics(
      label: semanticLabel ?? text,
      button: true,
      enabled: onPressed != null && !isLoading,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: effectiveBackgroundColor,
          foregroundColor: effectiveTextColor,
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: isLoading
            ? SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(effectiveTextColor),
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 18),
                    SizedBox(width: 8),
                  ],
                  Text(text),
                ],
              ),
      ),
    );
  }
}

/// Accessible text field with proper labels and error handling
class AccessibleTextField extends StatelessWidget {
  final String label;
  final String? hint;
  final String? errorText;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final TextInputType? keyboardType;
  final bool obscureText;
  final bool required;
  final int? maxLines;
  final String? semanticLabel;

  const AccessibleTextField({
    super.key,
    required this.label,
    this.hint,
    this.errorText,
    this.controller,
    this.onChanged,
    this.keyboardType,
    this.obscureText = false,
    this.required = false,
    this.maxLines = 1,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel ?? '$label${required ? ' (required)' : ''}',
      textField: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              text: label,
              style: Theme.of(context).textTheme.bodyMedium,
              children: [
                if (required)
                  TextSpan(
                    text: ' *',
                    style: TextStyle(color: Colors.red),
                  ),
              ],
            ),
          ),
          SizedBox(height: 8),
          TextField(
            controller: controller,
            onChanged: onChanged,
            keyboardType: keyboardType,
            obscureText: obscureText,
            maxLines: maxLines,
            decoration: InputDecoration(
              hintText: hint,
              errorText: errorText,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: Theme.of(context).primaryColor,
                  width: 2,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: Colors.red,
                  width: 2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Accessible dropdown with proper semantics
class AccessibleDropdown<T> extends StatelessWidget {
  final String label;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final String? hint;
  final bool required;
  final String? semanticLabel;

  const AccessibleDropdown({
    super.key,
    required this.label,
    this.value,
    required this.items,
    this.onChanged,
    this.hint,
    this.required = false,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel ?? '$label${required ? ' (required)' : ''}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              text: label,
              style: Theme.of(context).textTheme.bodyMedium,
              children: [
                if (required)
                  TextSpan(
                    text: ' *',
                    style: TextStyle(color: Colors.red),
                  ),
              ],
            ),
          ),
          SizedBox(height: 8),
          DropdownButtonFormField<T>(
            value: value,
            items: items,
            onChanged: onChanged,
            hint: hint != null ? Text(hint!) : null,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: Theme.of(context).primaryColor,
                  width: 2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Accessible slider with proper labels and value announcements
class AccessibleSlider extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final int? divisions;
  final ValueChanged<double>? onChanged;
  final String Function(double)? valueFormatter;
  final String? semanticLabel;

  const AccessibleSlider({
    super.key,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    this.divisions,
    this.onChanged,
    this.valueFormatter,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    final formattedValue = valueFormatter?.call(value) ?? value.toStringAsFixed(1);
    
    return Semantics(
      label: semanticLabel ?? '$label: $formattedValue',
      slider: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Text(
                formattedValue,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
            label: formattedValue,
          ),
        ],
      ),
    );
  }
}

/// Accessible progress indicator with proper announcements
class AccessibleProgressIndicator extends StatelessWidget {
  final double? value;
  final String? label;
  final String? semanticLabel;
  final Color? backgroundColor;
  final Color? valueColor;

  const AccessibleProgressIndicator({
    super.key,
    this.value,
    this.label,
    this.semanticLabel,
    this.backgroundColor,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = value != null ? (value! * 100).round() : null;
    final effectiveLabel = semanticLabel ?? 
        (label != null && percentage != null 
            ? '$label: $percentage percent complete'
            : label ?? 'Loading');

    return Semantics(
      label: effectiveLabel,
      value: percentage?.toString(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label != null) ...[
            Text(
              label!,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            SizedBox(height: 8),
          ],
          LinearProgressIndicator(
            value: value,
            backgroundColor: backgroundColor,
            valueColor: valueColor != null 
                ? AlwaysStoppedAnimation<Color>(valueColor!)
                : null,
          ),
          if (percentage != null) ...[
            SizedBox(height: 4),
            Text(
              '$percentage%',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}

/// Accessible tab bar with proper navigation
class AccessibleTabBar extends StatelessWidget {
  final List<Tab> tabs;
  final TabController? controller;
  final ValueChanged<int>? onTap;
  final bool isScrollable;

  const AccessibleTabBar({
    super.key,
    required this.tabs,
    this.controller,
    this.onTap,
    this.isScrollable = false,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      child: TabBar(
        tabs: tabs.map((tab) => Semantics(
          button: true,
          label: tab.text ?? 'Tab',
          child: tab,
        )).toList(),
        controller: controller,
        onTap: onTap,
        isScrollable: isScrollable,
        indicatorColor: Theme.of(context).primaryColor,
        labelColor: Theme.of(context).primaryColor,
        unselectedLabelColor: Colors.grey,
      ),
    );
  }
}

/// Accessible list tile with proper semantics
class AccessibleListTile extends StatelessWidget {
  final Widget? leading;
  final Widget? title;
  final Widget? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final String? semanticLabel;
  final bool selected;
  final bool enabled;

  const AccessibleListTile({
    super.key,
    this.leading,
    this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.semanticLabel,
    this.selected = false,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      button: onTap != null,
      selected: selected,
      enabled: enabled,
      child: ListTile(
        leading: leading,
        title: title,
        subtitle: subtitle,
        trailing: trailing,
        onTap: enabled ? onTap : null,
        selected: selected,
        enabled: enabled,
        selectedTileColor: Theme.of(context).primaryColor.withOpacity(0.1),
      ),
    );
  }
}

/// Accessible icon button with proper semantics
class AccessibleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String tooltip;
  final Color? color;
  final double? size;
  final String? semanticLabel;

  const AccessibleIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    required this.tooltip,
    this.color,
    this.size,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel ?? tooltip,
      button: true,
      enabled: onPressed != null,
      child: IconButton(
        icon: Icon(icon),
        onPressed: onPressed,
        tooltip: tooltip,
        color: color,
        iconSize: size,
      ),
    );
  }
}

/// Accessible switch with proper labels
class AccessibleSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  final String label;
  final String? semanticLabel;

  const AccessibleSwitch({
    super.key,
    required this.value,
    this.onChanged,
    required this.label,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel ?? '$label: ${value ? 'enabled' : 'disabled'}',
      toggled: value,
      child: SwitchListTile(
        title: Text(label),
        value: value,
        onChanged: onChanged,
      ),
    );
  }
}