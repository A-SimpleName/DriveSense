class Account {
  final String firstName;
  final String lastName;
  final String email;
  final String password;
  final DateTime? birthdate;

  Account({
    required this.firstName,
    required this.lastName,
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
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'password': password,
      'birthdate': formattedBirthdate,
    };
  }

  factory Account.fromJson(Map<String, dynamic> json) {
    return Account(
      firstName: json['firstName'] ?? json['fName'] ?? '',
      lastName: json['lastName'] ?? json['lName'] ?? '',
      email: json['email'] ?? '',
      password: json['password'] ?? '',
      birthdate: json['birthdate'] != null
          ? DateTime.parse(json['birthdate'])
          : null,
    );
  }
}
