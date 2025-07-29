# path\_provider\_linux

*This is copied from https://github.com/flutter/packages/tree/792b70bb2782c98c6a5b3de64583b5940f5badfa/packages/path_provider/path_provider_linux to hardcode
the application ID to work around incorrect paths when using AppImages.*

The linux implementation of [`path_provider`][1].

## Usage

This package is [endorsed][2], which means you can simply use `path_provider`
normally. This package will be automatically included in your app when you do,
so you do not need to add it to your `pubspec.yaml`.

However, if you `import` this package to use any of its APIs directly, you
should add it to your `pubspec.yaml` as usual.

[1]: https://pub.dev/packages/path_provider
[2]: https://flutter.dev/to/endorsed-federated-plugin
