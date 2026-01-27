class LoginAndRegister {

  /*  later used to check if the user has a valid token saved on the device,
      to avoid having to log in every time */
  static String redirectToHome({String? token}) {
    return token == null ? 'RegisterPage' : 'MainPage';
  }
}