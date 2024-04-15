// To parse this JSON data, do
//
//     final userLog = userLogFromJson(jsonString);

import 'dart:convert';

UserLogEntry userLogEntryFromMap(String str) => UserLogEntry.fromMap(json.decode(str));

String userLogEntryToMap(UserLogEntry data) => json.encode(data.toMap());

class UserLogEntry {
    final int? entryId;
    final String entryDateTime;
    final String workoutType;
    final int? repetitions;
    final int? time;
    final double? weight;
    final String? notes;

    UserLogEntry({
        this.entryId,
        required this.entryDateTime,
        required this.workoutType,
        this.repetitions,
        this.time,
        this.weight,
        this.notes,
    });

    factory UserLogEntry.fromMap(Map<String, dynamic> json) => UserLogEntry(
        entryId: json["entryId"],
        entryDateTime: json["entryDateTime"],
        workoutType: json["workoutType"],
        repetitions: json["repetitions"],
        time: json["time"],
        weight: json["weight"]?.toDouble(),
        notes: json["notes"],
    );

    Map<String, dynamic> toMap() => {
        "entryId": entryId,
        "entryDateTime": entryDateTime,
        "workoutType": workoutType,
        "repetitions": repetitions,
        "time": time,
        "weight": weight,
        "notes": notes,
    };
}