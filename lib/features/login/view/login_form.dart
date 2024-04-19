import 'package:crossonic/features/login/login.dart';
import 'package:crossonic/features/login/state/login_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:formz/formz.dart';

class LoginForm extends StatelessWidget {
  const LoginForm({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<LoginBloc, LoginState>(
      listener: (context, state) {
        if (state.status.isFailure) {
          final String message;
          switch (state.error) {
            case LoginError.connection:
              message = 'Cannot connect to server';
            case LoginError.credentials:
              message = 'Wrong username or password';
            case LoginError.none:
            case LoginError.unexpected:
              message = 'An unexpected error occured';
          }
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(message)));
          context.read<LoginBloc>().add(const LoginErrorReset());
        }
      },
      child: Builder(builder: (context) {
        final bloc = context.read<LoginBloc>();
        return Align(
          alignment: const Alignment(0, -1 / 3),
          child: SizedBox(
            width: 430,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Login', style: Theme.of(context).textTheme.displayMedium),
                const SizedBox(height: 60),
                _LoginInput(
                  bloc: bloc,
                  inputName: "server_url",
                  labelText: "Server URL",
                  errorText: "invalid server URL",
                ),
                const SizedBox(height: 20),
                _LoginInput(
                  bloc: bloc,
                  inputName: "username",
                  labelText: "Username",
                  errorText: "required",
                ),
                const SizedBox(height: 20),
                _LoginInput(
                  bloc: bloc,
                  inputName: "password",
                  labelText: "Password",
                  errorText: "required1",
                  obscureText: true,
                ),
                const SizedBox(height: 40),
                _LoginButton(),
              ],
            ),
          ),
        );
      }),
    );
  }
}

class _LoginInput extends StatefulWidget {
  final LoginBloc bloc;
  final String inputName;
  final String labelText;
  final String errorText;
  final bool obscureText;
  const _LoginInput({
    required this.inputName,
    required this.bloc,
    required this.labelText,
    required this.errorText,
    this.obscureText = false,
  });
  @override
  State<_LoginInput> createState() => _LoginInputState();
}

class _LoginInputState extends State<_LoginInput> with RestorationMixin {
  final _controller = RestorableTextEditingController();

  String _lastValue = "";

  void _updateValue() {
    if (_controller.value.text != _lastValue) {
      widget.bloc
          .add(LoginInputChanged(widget.inputName, _controller.value.text));
      _lastValue = _controller.value.text;
    }
  }

  _LoginInputState() {
    _controller.addListener(_updateValue);
  }

  @override
  Widget build(BuildContext context) {
    _updateValue();
    return BlocBuilder<LoginBloc, LoginState>(
      buildWhen: (previous, current) {
        switch (widget.inputName) {
          case "server_url":
            return previous.serverURL != current.serverURL;
          case "username":
            return previous.username != current.username;
          case "password":
            return previous.password != current.password;
        }
        return true;
      },
      builder: (context, state) {
        return TextField(
          controller: _controller.value,
          autofillHints: const [AutofillHints.url],
          obscureText: widget.obscureText,
          decoration: InputDecoration(
            labelText: widget.labelText,
            border: const OutlineInputBorder(),
            icon: const Icon(Icons.link),
            errorText:
                state.serverURL.displayError != null ? widget.errorText : null,
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  String? get restorationId => "login_${widget.inputName}";

  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    registerForRestoration(_controller, "login_${widget.inputName}_controller");
  }
}

class _LoginButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LoginBloc, LoginState>(
      builder: (context, state) {
        return state.status.isInProgress
            ? const CircularProgressIndicator()
            : ElevatedButton(
                style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 50, vertical: 20)),
                onPressed: state.isValid
                    ? () {
                        context.read<LoginBloc>().add(const LoginSubmitted());
                      }
                    : null,
                child: const Text('Login'),
              );
      },
    );
  }
}
