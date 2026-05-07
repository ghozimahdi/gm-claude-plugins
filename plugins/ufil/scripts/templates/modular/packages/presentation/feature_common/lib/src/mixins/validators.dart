mixin Validators {
  bool isEmailValid(String email) {
    final RegExp emailValidatorRegExp = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailValidatorRegExp.hasMatch(email) && email.isNotEmpty;
  }

  bool isPasswordValid(String password) {
    bool hasMinLength = password.length >= 6;
    return hasMinLength;
  }

  bool isSingaporeMobileValid(String mobile) {
    final RegExp singaporeMobileRegExp = RegExp(r'^[89]\d{7}$');
    return singaporeMobileRegExp.hasMatch(mobile);
  }

  String? validateNotEmpty(String? value) {
    return (value == null || value.isEmpty) ? 'required field' : null;
  }
}
