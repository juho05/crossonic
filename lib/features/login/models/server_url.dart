import 'package:formz/formz.dart';

enum ServerURLValidationError { empty }

class ServerURL extends FormzInput<String, ServerURLValidationError> {
  const ServerURL.pure() : super.pure('');
  const ServerURL.dirty([super.value = '']) : super.dirty();

  @override
  ServerURLValidationError? validator(String value) {
    if (value.isEmpty) return ServerURLValidationError.empty;
    // TODO: check URL syntax and protocol
    return null;
  }
}
