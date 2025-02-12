import 'package:crossonic/utils/exceptions.dart';

class InvalidServerException extends UnexpectedResponseException {
  const InvalidServerException(super.message);
}
