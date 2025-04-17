import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';

class FormPageBody extends StatelessWidget {
  final GlobalKey<FormBuilderState> formKey;
  final List<Widget> children;
  final Map<String, dynamic> initialValues;

  const FormPageBody({
    super.key,
    required this.formKey,
    required this.children,
    this.initialValues = const {},
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final cardMode =
          constraints.maxWidth > 800 && constraints.maxHeight > 570;
      final theme = Theme.of(context);
      final child = Center(
        child: Padding(
          padding: EdgeInsets.all(cardMode ? 8.0 : 0),
          child: ClipRRect(
            borderRadius:
                cardMode ? BorderRadius.circular(15) : BorderRadius.zero,
            child: Material(
              color: cardMode
                  ? theme.brightness == Brightness.dark
                      ? theme.colorScheme.surfaceContainerLow
                      : theme.colorScheme.surfaceContainer
                  : null,
              child: Padding(
                padding: cardMode
                    ? EdgeInsets.symmetric(
                        vertical: constraints.maxHeight < 625 ? 12 : 32,
                        horizontal: 48)
                    : const EdgeInsets.all(16),
                child: SizedBox(
                  width: 430,
                  child: FormBuilder(
                    key: formKey,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    initialValue: initialValues,
                    child: AutofillGroup(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        spacing: 16,
                        children: children,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      if (cardMode) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 58),
          child: child,
        );
      }
      return SingleChildScrollView(
        child: child,
      );
    });
  }
}
