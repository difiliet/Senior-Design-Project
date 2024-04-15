import 'package:flutter/material.dart';
import 'package:applicants/JsonModels/userLogEntry.dart';

class UserSettings {
  bool predictionsEnabled;
  Color primaryColor;
  Color secondaryColor;
  List<UserLogEntry>? data;
  Map<String, List<int>> predictive;
  Map<String, DateTime> lastDate;


  UserSettings({
      required this.predictionsEnabled,
      required this.primaryColor,
      required this.secondaryColor,
      required this.data,
      required this.predictive,
      required this.lastDate,
  });

  static Color getPrimaryColorValue(String ? colorName) {
    Color returnColor;
    if (colorName == 'Blue') {
      returnColor = Colors.blue;
    } else if (colorName == 'White') {
      returnColor = Colors.white;
    } else if (colorName == 'Green') {
      returnColor = Colors.green;
    }else if (colorName == 'Red') {
      returnColor = Colors.red;
    }else if (colorName == 'Orange') {
      returnColor = Colors.orange;
    } else {
      returnColor = Colors.blue;
    }
    return returnColor;
  }

  static Color getSecondaryColorValue(String ? colorName) {
    Color returnColor;
    if (colorName == 'Blue') {
      returnColor = Colors.lightBlue;
    } else if (colorName == 'White') {
      returnColor = Colors.white;
    } else if (colorName == 'Green') {
      returnColor = Colors.lightGreen;
    }else if (colorName == 'Red') {
      returnColor = Colors.red;
    }else if (colorName == 'Orange') {
      returnColor = Colors.orange;
    } else {
      returnColor = Colors.white;
    }
    return returnColor;
  }

  // static Future<Map<String, List<Map<String, dynamic>>>> getWorkoutData() {

  // }
}