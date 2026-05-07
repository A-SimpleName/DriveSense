class Account {
  final String fName;
  final String lName;
  final String email;
  final String password;
  final DateTime? birthdate;
  
  Account({
    required this.fName,
    required this.lName,
    required this.email,
    required this.password,
    this.birthdate,
  });

  Map<String, dynamic> toJson() {
    final DateTime? value = birthdate;
    final String? formattedBirthdate = value == null
        ? null
        : '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';

    return {
      "fname": fName,
      "lname": lName,
      "email": email,
      "password": password,
      "birthdate": formattedBirthdate,
    };
  }

    factory Account.fromJson(Map<String, dynamic> json) {
    return Account(
      fName: json["fname"] ?? '',
      lName: json["lname"] ?? '',
      email: json["email"] ?? '',
      password: json["password"] ?? '',
      birthdate: json["birthdate"] != null
          ? DateTime.parse(json["birthdate"])
          : null,
    );
  }
}