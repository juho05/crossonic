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
      child: Align(
        alignment: const Alignment(0, -1 / 3),
        child: SizedBox(
          width: 430,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Login', style: Theme.of(context).textTheme.displayMedium),
              const SizedBox(height: 60),
              _ServerURLInput(),
              const SizedBox(height: 20),
              _UsernameInput(),
              const SizedBox(height: 20),
              _PasswordInput(),
              const SizedBox(height: 40),
              _LoginButton(),
            ],
          ),
        ),
      ),
    );
  }
}

class _ServerURLInput extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LoginBloc, LoginState>(
      buildWhen: (previous, current) => previous.serverURL != current.serverURL,
      builder: (context, state) {
        return TextField(
          onChanged: (serverURL) =>
              context.read<LoginBloc>().add(LoginServerURLChanged(serverURL)),
          autofillHints: const [AutofillHints.url],
          decoration: InputDecoration(
            labelText: 'Server URL',
            border: const OutlineInputBorder(),
            icon: const Icon(Icons.link),
            errorText: state.serverURL.displayError != null
                ? 'invalid server URL'
                : null,
          ),
        );
      },
    );
  }
}

class _UsernameInput extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LoginBloc, LoginState>(
      buildWhen: (previous, current) => previous.username != current.username,
      builder: (context, state) {
        return TextField(
          onChanged: (username) =>
              context.read<LoginBloc>().add(LoginUsernameChanged(username)),
          autofillHints: const [AutofillHints.username],
          decoration: InputDecoration(
            labelText: 'Username',
            border: const OutlineInputBorder(),
            icon: const Icon(Icons.person),
            errorText: state.username.displayError != null ? 'required' : null,
          ),
        );
      },
    );
  }
}

class _PasswordInput extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LoginBloc, LoginState>(
      buildWhen: (previous, current) => previous.password != current.password,
      builder: (context, state) {
        return TextField(
          onChanged: (password) =>
              context.read<LoginBloc>().add(LoginPasswordChanged(password)),
          autofillHints: const [AutofillHints.password],
          obscureText: true,
          decoration: InputDecoration(
            labelText: 'Password',
            border: const OutlineInputBorder(),
            icon: const Icon(Icons.password),
            errorText: state.password.displayError != null ? 'required' : null,
          ),
        );
      },
    );
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
