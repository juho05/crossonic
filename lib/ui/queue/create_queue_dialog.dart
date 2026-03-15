import 'package:auto_route/auto_route.dart';
import 'package:crossonic/ui/common/buttons.dart';
import 'package:crossonic/ui/common/dialogs/dialog.dart';
import 'package:crossonic/ui/queue/create_queue_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class CreateQueueDialog {
  static Future<void> show(BuildContext context) async {
    final viewModel = CreateQueueViewModel(audioHandler: context.read());
    await showDialog(
      context: context,
      builder: (context) => CrossonicDialog(
        maxWidth: 560,
        child: _CreateQueueDialogContent(viewModel: viewModel),
      ),
    );
    viewModel.dispose();
  }
}

class _CreateQueueDialogContent extends StatefulWidget {
  final CreateQueueViewModel _viewModel;

  const _CreateQueueDialogContent({required CreateQueueViewModel viewModel})
    : _viewModel = viewModel;

  @override
  State<_CreateQueueDialogContent> createState() =>
      _CreateQueueDialogContentState();
}

class _CreateQueueDialogContentState extends State<_CreateQueueDialogContent> {
  final FocusScopeNode _textFieldFocusScope = FocusScopeNode();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return FocusScope(
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is KeyUpEvent &&
            event.logicalKey == LogicalKeyboardKey.enter) {
          _submit(context);
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: ListenableBuilder(
        listenable: widget._viewModel,
        builder: (context, _) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            spacing: 8,
            children: [
              Text(
                "Create queue",
                overflow: TextOverflow.ellipsis,
                style: textTheme.headlineSmall,
              ),
              FocusScope(
                node: _textFieldFocusScope,
                onKeyEvent: (node, event) {
                  if (event is KeyUpEvent &&
                      event.logicalKey == LogicalKeyboardKey.enter) {
                    node.unfocus();
                    return KeyEventResult.handled;
                  }
                  return KeyEventResult.ignored;
                },
                child: TextField(
                  onTapOutside: (event) => _textFieldFocusScope.unfocus(),
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    label: Text("Name"),
                  ),
                  onChanged: (value) => widget._viewModel.name = value.trim(),
                ),
              ),
              const Divider(height: 1),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Button(
                    onPressed: widget._viewModel.isValid
                        ? () => _submit(context)
                        : null,
                    child: const Text("Create"),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _submit(BuildContext context) async {
    if (!widget._viewModel.isValid) return;
    await widget._viewModel.create();
    if (!context.mounted) return;
    context.pop();
  }
}
