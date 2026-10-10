String? validateEmail(String? value) {
  value = value?.trim();
  if (value == null || value.isEmpty) return '이메일을 입력해 주세요';
  if (value.length > 255) return '이메일은 255자 이내로 입력해 주세요';
  if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value)) {
    return '올바른 이메일 형식을 입력해 주세요';
  }
  return null;
}

String? validateNickname(String? value) {
  final nickname = value?.trim() ?? '';
  if (nickname.isEmpty) return '닉네임을 입력해 주세요';
  if (nickname.length < 2 || nickname.length > 50) {
    return '닉네임은 2~50자로 입력해 주세요';
  }
  return null;
}

String? validatePassword(String? value) {
  if (value == null || value.trim().isEmpty) return '비밀번호를 입력해 주세요';
  if (value.length < 8 || value.length > 64) {
    return '비밀번호는 8~64자로 입력해 주세요';
  }
  return null;
}
