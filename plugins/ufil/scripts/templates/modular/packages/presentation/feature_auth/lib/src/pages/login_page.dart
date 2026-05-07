import 'package:auto_route/auto_route.dart';
import 'package:domain_auth/domain_auth.dart';
import 'package:feature_auth/src/blocs/login/login_bloc.dart';
import 'package:feature_auth/src/config/feature_auth_route.gr.dart';
import 'package:feature_auth/src/di/di.dart';
import 'package:feature_common/feature_common.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:injectable/injectable.dart';

@Injectable(as: LoginRouteProvider)
class LoginRouteProviderImpl implements LoginRouteProvider {
  @override
  PageRouteInfo route() {
    return const LoginRoute();
  }
}

@RoutePage()
class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<LoginBloc>()..add(const LoginEvent.init()),
      child: const _LoginView(),
    );
  }
}

class _LoginView extends StatefulWidget {
  const _LoginView();

  @override
  State<_LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<_LoginView> {
  final _emailController = TextEditingController(text: 'demo@example.com');
  final _passwordController = TextEditingController(text: 'password');

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: BlocConsumer<LoginBloc, LoginState>(
        listenWhen: (prev, curr) => prev.alertState != curr.alertState,
        listener: (context, state) {
          switch (state.alertState) {
            case AlertErrorState():
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    state.submitState.failure.toString(),
                  ),
                ),
              );
            case AlertDoneState():
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Welcome ${state.submitState.result.user.name}',
                  ),
                ),
              );
            case _AlertIdleState():
              break;
          }
        },
        builder: (context, state) {
          final isLoading = state.submitState is SubmitLoginLoadingState;
          return Padding(
            padding: EdgeInsets.all(16.dm),
            child: Column(
              spacing: 12.h,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Password'),
                ),
                FilledButton(
                  onPressed: isLoading
                      ? null
                      : () {
                          context.read<LoginBloc>().add(
                                LoginEvent.submitted(
                                  email: _emailController.text,
                                  password: _passwordController.text,
                                ),
                              );
                        },
                  child: Text(isLoading ? 'Loading...' : 'Sign In'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
