import '../../ui.dart';

class AppTextField extends StatelessWidget {
  const AppTextField({
    required this.controller,
    super.key,
    this.labelText,
    this.hintText,
    this.helperText,
    this.prefixText,
    this.prefixIcon,
    this.keyboardType,
    this.textInputAction,
    this.onSubmitted,
    this.onChanged,
    this.obscureText = false,
    this.minLines,
    this.maxLines = 1,
    this.enabled = true,
    this.filled = true,
    this.errorText,
    this.focusNode,
    this.autofocus = false,
    this.autofillHints,
    this.textCapitalization = TextCapitalization.none,
    this.suffixIcon,
    this.autocorrect = true,
    this.enableSuggestions = true,
    this.smartDashesType,
    this.smartQuotesType,
    this.enableIMEPersonalizedLearning = true,
  });

  final TextEditingController controller;
  final String? labelText;
  final String? hintText;
  final String? helperText;
  final String? prefixText;
  final Widget? prefixIcon;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;
  final bool obscureText;
  final int? minLines;
  final int maxLines;
  final bool enabled;
  final bool filled;

  /// Inline validation message rendered beneath the field. When non-null the
  /// field also announces itself as errored to assistive tech.
  final String? errorText;
  final FocusNode? focusNode;
  final bool autofocus;

  /// Enables platform autofill (e.g. `AutofillHints.telephoneNumber`,
  /// `AutofillHints.oneTimeCode` for SMS OTP auto-population).
  final Iterable<String>? autofillHints;
  final TextCapitalization textCapitalization;
  final Widget? suffixIcon;
  final bool autocorrect;
  final bool enableSuggestions;
  final SmartDashesType? smartDashesType;
  final SmartQuotesType? smartQuotesType;
  final bool enableIMEPersonalizedLearning;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      autofocus: autofocus,
      autofillHints: autofillHints,
      textCapitalization: textCapitalization,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onSubmitted: onSubmitted,
      onChanged: onChanged,
      obscureText: obscureText,
      autocorrect: autocorrect,
      enableSuggestions: enableSuggestions,
      smartDashesType: smartDashesType,
      smartQuotesType: smartQuotesType,
      enableIMEPersonalizedLearning: enableIMEPersonalizedLearning,
      minLines: minLines,
      maxLines: maxLines,
      enabled: enabled,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        // Hide helper text while an error shows so the two never stack and
        // shift the layout of everything below the field.
        helperText: errorText == null ? helperText : null,
        errorText: errorText,
        prefixText: prefixText,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        filled: filled,
        fillColor: filled ? context.colors.background : null,
      ),
    );
  }
}
