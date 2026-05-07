import 'package:domain_auth/domain_auth.dart';
import 'package:domain_common/domain_common.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';

part 'login_bloc.freezed.dart';
part 'login_event.dart';
part 'login_state.dart';

@injectable
class LoginBloc extends Bloc<LoginEvent, LoginState> {
  LoginBloc(this._loginUseCase) : super(const LoginState()) {
    on<_InitEvent>(_initEvent);
    on<_SubmittedEvent>(_submittedEvent);
  }

  final LoginUseCase _loginUseCase;

  void _initEvent(_InitEvent event, Emitter<LoginState> emit) {
    emit(event.state);
  }

  Future<void> _submittedEvent(
    _SubmittedEvent event,
    Emitter<LoginState> emit,
  ) async {
    emit(
      state.copyWith(
        submitState: const SubmitLoginState.loading(),
        alertState: const AlertState.idle(),
      ),
    );

    final params = LoginParams(email: event.email, password: event.password);
    final result = await _loginUseCase(params);

    switch (result.failure) {
      case NoFailure():
        emit(
          state.copyWith(
            submitState: SubmitLoginState.done(result: result),
            alertState: const AlertState.done(),
          ),
        );
      default:
        emit(
          state.copyWith(
            submitState: SubmitLoginState.error(failure: result.failure),
            alertState: const AlertState.error(),
          ),
        );
    }
  }
}
