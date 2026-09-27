String? validateEmail(String? value) {
  if (value == null || value.isEmpty) return '이메일을 입력해 주세요';
  if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value)) {
    return '올바른 이메일 형식을 입력해 주세요';
  }
  return null;
}
