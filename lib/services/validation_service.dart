class ValidationService {
  static bool isValidEmail(String email) {
    if (email.isEmpty) return false;
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  static bool isValidPassword(String password) {
    if (password.isEmpty) return false;
    if (password.length < 6) return false;
    return password.contains(RegExp(r'[A-Z]')) &&
        password.contains(RegExp(r'[0-9]'));
  }

  static bool isValidNoteTitle(String title) {
    return title.isNotEmpty && title.length <= 100;
  }
}