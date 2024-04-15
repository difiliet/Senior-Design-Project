// To parse this JSON data, do
//
//     final users = usersFromMap(jsonString);

import 'dart:convert';

User userFromMap(String str) => User.fromMap(json.decode(str));

String userToMap(User data) => json.encode(data.toMap());

class User {
    final int? userId;
    final String username;
    String password;
    final bool? predictionsEnabled;
    final String? primaryColor;
    final String? secondaryColor;

    User({
        this.userId,
        required this.username,
        required this.password,
        this.predictionsEnabled,
        this.primaryColor,
        this.secondaryColor,
    });

    factory User.fromMap(Map<String, dynamic> json) => User(
        userId: json["userId"],
        username: json["username"],
        password: json["password"],
        predictionsEnabled: json["predictionsEnabled"] == 1 ? true : false,
        primaryColor: json["primaryColor"],
        secondaryColor: json["secondaryColor"],
    );

    Map<String, dynamic> toMap() => {
        "userId": userId,
        "username": username,
        "password": password,
        "predictionsEnabled": (predictionsEnabled ?? false) ? 1 : 0,
        "primaryColor": primaryColor ?? "Blue",
        "secondaryColor": secondaryColor ?? "White",
    };
}
