import 'package:crossonic/data/repositories/auth/auth_repository.dart';
import 'package:crossonic/data/repositories/auth/auth_repository_opensubsonic.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

List<SingleChildWidget> get providers => [
      ChangeNotifierProvider(
        create: (context) => AuthRepositoryOpenSubsonic() as AuthRepository,
      )
    ];
