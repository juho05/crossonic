import 'dart:async';

import 'package:flutter/material.dart';

class SearchInput extends StatefulWidget {
  final void Function(String query) onSearch;
  final void Function()? onTapOutside;
  final void Function()? onClearButtonPressed;
  final Duration debounce;
  final String? restorationId;

  const SearchInput({
    super.key,
    required this.onSearch,
    this.debounce = const Duration(milliseconds: 500),
    this.restorationId,
    this.onTapOutside,
    this.onClearButtonPressed,
  });

  @override
  State<SearchInput> createState() => _SearchInputState();
}

class _SearchInputState extends State<SearchInput> with RestorationMixin {
  final _controller = RestorableTextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        _controller.value.selection = TextSelection(
          baseOffset: 0,
          extentOffset: _controller.value.text.length,
        );
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller.value.text.isNotEmpty) {
      final search = _controller.value.text;
      widget.onSearch(search);
      setState(() {
        _isEmpty = search.isEmpty;
      });
    }
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  bool _isEmpty = true;
  Timer? _searchDebounce;

  void _updateSearch(String search) {
    _searchDebounce?.cancel();

    if (_isEmpty != search.isEmpty) {
      setState(() {
        _isEmpty = search.isEmpty;
      });
    }

    if (_isEmpty) {
      widget.onSearch(search);
      return;
    }
    _searchDebounce = Timer(widget.debounce, () => widget.onSearch(search));
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller.value,
      focusNode: _focusNode,
      decoration: InputDecoration(
        labelText: "Search",
        suffixIcon: _isEmpty
            ? const Icon(Icons.search)
            : IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _controller.value.clear();
                  _updateSearch("");
                  _focusNode.unfocus();
                  if (widget.onClearButtonPressed != null) {
                    widget.onClearButtonPressed!();
                  }
                },
              ),
      ),
      restorationId: widget.restorationId != null
          ? "${widget.restorationId}_text_field"
          : null,
      onChanged: _updateSearch,
      onTapOutside: (event) {
        _focusNode.unfocus();
        if (widget.onTapOutside != null) {
          widget.onTapOutside!();
        }
      },
    );
  }

  @override
  String? get restorationId => widget.restorationId;

  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    registerForRestoration(
        _controller, "${widget.restorationId ?? "search_input"}_controller");
  }
}
