part of 'login_bloc.dart';

@freezed
abstract class LoginEvent with _$LoginEvent {
  const factory LoginEvent.init({
    @Default(LoginState()) LoginState state,
  }) = _InitEvent;

  const factory LoginEvent.submitted({
    required String email,
    required String password,
  }) = _SubmittedEvent;
}
