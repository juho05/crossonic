import 'package:crossonic/ui/common/toast.dart';
import 'package:crossonic/utils/exceptions.dart';
import 'package:crossonic/utils/result.dart';
import 'package:flutter/material.dart';

void toastResult(BuildContext context, Result result,
    [String? successMessage]) {
  if (result is Err && context.mounted) {
    switch (result.error) {
      case ConnectionException():
        Toast.show(context, "Failed to contact server");
      default:
        Toast.show(context, "An unexpected error occured");
    }
  } else if (successMessage != null) {
    Toast.show(context, successMessage);
  }
}

void printIfErr(BuildContext context, Result result) {
  if (result is Err && context.mounted) {
    switch (result.error) {
      case ConnectionException():
        Toast.show(context, "Failed to contact server");
      default:
        Toast.show(context, "An unexpected error occured");
    }
  }
}
