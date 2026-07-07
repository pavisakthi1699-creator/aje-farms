// ignore_for_file: use_key_in_widget_constructors

import "../../ui.dart";

void showSnack(BuildContext context, String message) {
  AppFeedback.tap();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      behavior: SnackBarBehavior.floating,
    ),
  );
}
