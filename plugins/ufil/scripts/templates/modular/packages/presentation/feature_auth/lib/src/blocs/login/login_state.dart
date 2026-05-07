part of 'login_bloc.dart';

@freezed
abstract class LoginState with _$LoginState {
  const factory LoginState({
    @Default(SubmitLoginState.idle()) SubmitLoginState submitState,
    @Default(AlertState.idle()) AlertState alertState,
  }) = _LoginState;
}

/// Sub-state for the login submission. Uniform shape across all variants:
/// every variant carries `result` and `failure` so consumers can read the
/// last successful payload OR the failure regardless of which variant is
/// active. Result already contains its own `Failure failure` field, but the
/// sub-state ALSO mirrors `failure` for ergonomic access in error variants.
@freezed
abstract class SubmitLoginState with _$SubmitLoginState {
  const factory SubmitLoginState.idle({
    @Default(LoginResult()) LoginResult result,
    @Default(Failure.noFailure()) Failure failure,
  }) = _SubmitLoginIdleState;

  const factory SubmitLoginState.loading({
    @Default(LoginResult()) LoginResult result,
    @Default(Failure.noFailure()) Failure failure,
  }) = SubmitLoginLoadingState;

  const factory SubmitLoginState.done({
    @Default(LoginResult()) LoginResult result,
    @Default(Failure.noFailure()) Failure failure,
  }) = SubmitLoginDoneState;

  const factory SubmitLoginState.error({
    @Default(LoginResult()) LoginResult result,
    @Default(Failure.noFailure()) Failure failure,
  }) = SubmitLoginErrorState;
}

@freezed
abstract class AlertState with _$AlertState {
  const factory AlertState.idle() = _AlertIdleState;
  const factory AlertState.error() = AlertErrorState;
  const factory AlertState.done() = AlertDoneState;
}
