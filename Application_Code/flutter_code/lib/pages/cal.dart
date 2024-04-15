import 'package:applicants/DataModels/userSettings.dart';
import 'package:applicants/JsonModels/userLogEntry.dart';
import 'package:applicants/SQLite/databaseHelper.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

class CalendarPage extends StatefulWidget {
  final String username;
  final UserSettings currentUserSettings;
  const CalendarPage(this.username, this.currentUserSettings, {super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  late Future<List<UserLogEntry>> logEntryList;
  List<UserLogEntry>? entries;
  bool predictionsEnabled = false;
  Color primaryColor = Colors.blue;
  Color secondaryColor = Colors.white;

  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  String calTitle = "Your History";
  Map<DateTime, List<dynamic>> events = {
    DateTime.utc(2024, 3, 1): ['Event 1'],
    DateTime.utc(2024, 3, 7): ['Event 2'],
    DateTime.utc(2024, 3, 14): ['Event 3', 'Event 4'],
  };
  late final ValueNotifier<List<dynamic>> _selectedEvents = ValueNotifier([]);

  @override
  void initState() {
    super.initState();
    initializeDateFormatting();
    logEntryList = getUserLogEntries(widget.username);
    _selectedDay = _focusedDay;
    logEntryList.then((fetchedEntries) {
      setState(() {
        entries = fetchedEntries;
        _selectedEvents.value = _getEventsForDay(_selectedDay!);
      });
    });
    predictionsEnabled = widget.currentUserSettings.predictionsEnabled;
    primaryColor = widget.currentUserSettings.primaryColor;
    secondaryColor = widget.currentUserSettings.secondaryColor;
  }

  List<dynamic> _getEventsForDay(DateTime day) {
    // Return a list of events for the given day (may be empty)
    if (entries != null) {
      return entries!
        .where((entry) =>
          DateTime.parse(entry.entryDateTime).year == day.year &&
          DateTime.parse(entry.entryDateTime).month == day.month &&
          DateTime.parse(entry.entryDateTime).day == day.day)
        .map((entry) => entry)
        .toList();
    }
    return [];
    // return events[day] ?? [];
  }

  @override
  // Consider "CalendarBuilders"
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: primaryColor,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Container(
            color: secondaryColor,
            child: FutureBuilder<List<UserLogEntry>>(
              future: logEntryList,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                } else {
            
                  return Column(
                    children: [
                      TableCalendar(
                        firstDay: DateTime.utc(2010, 10, 16),
                        lastDay: DateTime.utc(2030, 3, 14),
                        focusedDay: _focusedDay,
                        calendarFormat: _calendarFormat,
                        eventLoader: _getEventsForDay,
                        selectedDayPredicate: (day) {
                          // Use `selectedDayPredicate` to determine which day is currently selected.
                          // If this returns true, then `day` will be marked as selected.
            
                          // Using `isSameDay` is recommended to disregard
                          // the time-part of compared DateTime objects.
                          return isSameDay(_selectedDay, day);
                        },
                        onDaySelected: (selectedDay, focusedDay) {
                          if (!isSameDay(_selectedDay, selectedDay)) {
                            // Call `setState()` when updating the selected day
                            setState(() {
                              _selectedDay = selectedDay;
                              _focusedDay = focusedDay;
                              _selectedEvents.value = _getEventsForDay(selectedDay);
                            });
                          }
                        },
                        // eventLoader: _getEventsForDay,
                        calendarStyle: CalendarStyle(
                            selectedDecoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.5), // Adjust opacity here
                              shape: BoxShape.circle,
                              // borderRadius: BorderRadius.circular(100), // Make it a circle
                            ),
                            todayDecoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.5), // Adjust opacity here
                              shape: BoxShape.circle,
                              // borderRadius: BorderRadius.circular(100), // Make it a circle
                            ),
                            markersMaxCount: 5,
                            markersAlignment: Alignment.bottomCenter,
                            markerDecoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.5),
                              shape: BoxShape.circle,
                            ),
                        ),
                        onFormatChanged: (format) {
                          // if (_calendarFormat != format) {
                            setState(() {
                              _calendarFormat = format;
                            });
                          // }
                        },
                        onPageChanged: (focusedDay) {
                          _focusedDay = focusedDay;
                        },
                      ),
                      const SizedBox(height: 8.0),
                      Expanded(
                        child: ValueListenableBuilder<List<dynamic>>(
                          valueListenable: _selectedEvents,
                          builder: (context, value, _) {
                            return ListView.builder(
                              itemCount: value.length,
                              itemBuilder: (context, index) {
                              return Container(
                                margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
                                decoration: BoxDecoration(
                                  border: Border.all(),
                                  borderRadius: BorderRadius.circular(12)
                                ),
                                child: ListTile(
                                  //onTap: () => print("Clicked"),
                                  title: Text('${value[index].workoutType}'),
                                  subtitle: Text(getDisplayValues(value[index].repetitions, value[index].time, value[index].weight)),
                                  trailing: Text(getDisplayDateTime(context, value[index].entryDateTime))
                                ),
                              );
                            });
                          }),
                      )
                    ],
                  );
                }
              },
              ),
          ),
        ),
      )
      
    );
  }
}

Future<List<UserLogEntry>> getUserLogEntries(String username) async {
  final db = DatabaseHelper();

  List<UserLogEntry> list = await db.getLogEntries('${username}EntryLog');
  return list;
}

String getDisplayDateTime(BuildContext context, String databaseDateTime) {
  String rawDateText = databaseDateTime;
  List<String> dateTextSplit = rawDateText.split('-');
  String locale = Localizations.localeOf(context).languageCode;
  DateTime dateValue = DateTime(int.parse(dateTextSplit[0]), int.parse(dateTextSplit[1]), int.parse(dateTextSplit[2].split(' ')[0]));
  String dateText = DateFormat.yMMMMd(locale).format(dateValue);
  return dateText;
}

String getDisplayValues(int ? repetitions, int ? time, double ? weight) {
  String displayString = '';
  if (repetitions != null) {
    displayString += 'Repetitions: $repetitions ';
  }
  if (time != null) {
    displayString += 'Time: $time ';
  }
  if (weight != null) {
    displayString += 'Weight: $weight ';
  }
  return displayString;
}