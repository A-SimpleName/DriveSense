class LoginAndRegister {
  static String redirectToHome({String? token}) {
    return token == null ? 'RegisterPage' : 'HomePage';
  }
}