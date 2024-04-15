import 'dart:io';
import 'package:applicants/DataModels/userSettings.dart';
import 'package:flutter/material.dart';
import 'package:applicants/SQLite/databaseHelper.dart';
import 'package:intl/intl.dart';
import 'package:applicants/JsonModels/userLogEntry.dart';

const WORKOUT_TRACKER_LOC = 'C:/dev/Application_Code/workout_tracking_code/dist/Workout_Tracker/Workout_Tracker.exe';

enum MeasurementType { reps, time }

class EntryPage extends StatefulWidget {
  final String username;
  final UserSettings currentUserSettings;
  const EntryPage(this.username, this.currentUserSettings, {super.key});

  @override
  State<EntryPage> createState() => _EntryPageState();
}

class _EntryPageState extends State<EntryPage> {
  final formKey = GlobalKey<FormState>();
  final entryDateTime = TextEditingController();
  final workoutType = TextEditingController();
  final repetitions = TextEditingController();
  final time = TextEditingController();
  final weight = TextEditingController();
  final notes = TextEditingController();
  MeasurementType ? type = MeasurementType.reps;

  bool predictionsEnabled = false;
  Color primaryColorValue = Colors.blue;
  Color secondaryColorValue = Colors.white;

  Future<void> showDateTimePicker(
    {
      required BuildContext context,
      DateTime? initialDate,
    }
  ) async {
    initialDate ??= DateTime.now();
    DateTime firstDate = initialDate.subtract(const Duration(days: 365 * 100));
    DateTime lastDate = firstDate.add(const Duration(days: 365 * 200));

    final DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );

    if (selectedDate != null && context.mounted)
    {
      final TimeOfDay? selectedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(initialDate),
      );

      if (selectedTime != null) {
        DateTime selectedDateTime = DateTime(
          selectedDate.year,
          selectedDate.month,
          selectedDate.day,
          selectedTime.hour,
          selectedTime.minute,
        );

        setState(() {
          entryDateTime.text = DateFormat.yMd().add_jm().format(selectedDateTime).replaceAll(RegExp(r'\s+'), " ");
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    entryDateTime.text = DateFormat.yMd().add_jm().format(DateTime.now()).replaceAll(RegExp(r'\s+'), " ");
    workoutType.addListener(_onWorkoutTypeChanged);
    predictionsEnabled = widget.currentUserSettings.predictionsEnabled;
    primaryColorValue = widget.currentUserSettings.primaryColor;
    secondaryColorValue = widget.currentUserSettings.secondaryColor;
  }

  void _onWorkoutTypeChanged() {
    String currentWorkoutType = workoutType.text;
    var overloadMap = widget.currentUserSettings.predictive;
      if (overloadMap.containsKey(currentWorkoutType)) {
        int i = getIndexOfWorkoutType(currentWorkoutType, widget.currentUserSettings.data!);
        int maxLen = overloadMap[currentWorkoutType]!.length;
        if (i < maxLen) {
          if (overloadMap[currentWorkoutType]?[i] != 0) {
            setState(() {
              repetitions.text = "Recommended: ${overloadMap[currentWorkoutType]![i]}";
            });
          }
        }
      } else {
        setState(() {
          repetitions.clear();
        });
      }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        color: primaryColorValue,
        child: Form(
          key: formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    icon: Icon(Icons.camera_alt, color: primaryColorValue,),
                    label: Text(
                      "Auto Track", 
                      style: TextStyle(color: primaryColorValue),
                    ),
                    onPressed: () async {
                      AlertDialog autoTrackPopup = createAutoTrackPopup();
                      await showDialog(context: context, builder: (context) => autoTrackPopup);
                      setState(() {
                        
                      });
                    },
                  ),
                ],
              ),
          
              // Date and Time
              Container(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            SizedBox(
                              width: 200,
                              child: TextField(
                                controller: entryDateTime,
                                obscureText: false,
                                style: TextStyle(color: secondaryColorValue),
                                decoration: InputDecoration(
                                  labelText: 'Date and Time',
                                  labelStyle: TextStyle(color: secondaryColorValue),
                                  border: OutlineInputBorder(
                                    borderSide: BorderSide(color: secondaryColorValue)
                                  ),
                                  enabledBorder: OutlineInputBorder(      
                                    borderSide: BorderSide(color: secondaryColorValue),   
                                  ),  
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: secondaryColorValue),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            ElevatedButton(
                              onPressed: () => showDateTimePicker(context: context),
                              style: ElevatedButton.styleFrom(
                                shape: const CircleBorder(),
                                padding: const EdgeInsets.all(20),
                                backgroundColor: secondaryColorValue,
                              ),
                              child: Icon(Icons.calendar_today, color: primaryColorValue),
                            ),
                          ],
                        ),
                        
                      ],
                    ),
                  ],
                ),
              ),
          
          
              // Workout type field
              Container(
                margin: const EdgeInsets.all(8),
                width: MediaQuery.of(context).size.width * .5,
                padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: secondaryColorValue,
                ),
                child: TextFormField(
                  controller: workoutType,
                  validator: (value) {
                    if (value!.isEmpty) {
                      return "Workout Type is required";
                    }
                    return null;
                  },
                  decoration: const InputDecoration(
                    icon: Icon(Icons.content_paste),
                    border: InputBorder.none,
                    label: Text("Workout Type"),
                  ),
                ),
              ),
              
              // Repetitions field
              Container(
                margin: const EdgeInsets.all(8),
                width: MediaQuery.of(context).size.width * .5,
                padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: secondaryColorValue,
                ),
                child: TextFormField(
                  controller: repetitions,
                  onTap: () {
                    setState(() {
                      repetitions.clear();
                    });
                  },
                  validator: (value) {
                    if (value!.isNotEmpty && (int.tryParse(value) ?? -1) < 0) {
                      return "Repetitions must be a positive number";
                    }
                    return null;
                  },
                  decoration: const InputDecoration(
                    icon: Icon(Icons.numbers),
                    border: InputBorder.none,
                    label: Text("Repetitions"),
                  ),
                ),
              ),
          
              // Time field
              Container(
                margin: const EdgeInsets.all(8),
                width: MediaQuery.of(context).size.width * .5,
                padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: secondaryColorValue,
                ),
                child: TextFormField(
                  controller: time,
                  validator: (value) {
                    if (value!.isNotEmpty && (int.tryParse(value) ?? -1) < 0) {
                      return "Repetitions must be a positive number";
                    }
                    return null;
                  },
                  decoration: const InputDecoration(
                    icon: Icon(Icons.timer),
                    border: InputBorder.none,
                    label: Text("Time"),
                  ),
                ),
              ),
          
              // Weight field
              Container(
                margin: const EdgeInsets.all(8),
                width: MediaQuery.of(context).size.width * .5,
                padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: secondaryColorValue,
                ),
                child: TextFormField(
                  controller: weight,
                  validator: (value) {
                    if (value!.isNotEmpty && (double.tryParse(value) ?? -1) < 0) {
                      return "Weight must be a positive number";
                    }
                    return null;
                  },
                  decoration: const InputDecoration(
                    icon: Icon(Icons.h_mobiledata),
                    border: InputBorder.none,
                    label: Text("Weight"),
                  ),
                ),
              ),
          
              // Notes field
              Container(
                margin: const EdgeInsets.all(8),
                width: MediaQuery.of(context).size.width * .5,
                padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: secondaryColorValue,
                ),
                child: TextFormField(
                  controller: notes,
                  validator: (value) {
                    return null;
                  },
                  decoration: const InputDecoration(
                    icon: Icon(Icons.notes),
                    border: InputBorder.none,
                    label: Text("Notes"),
                  ),
                ),
              ),
          
              const SizedBox(height: 8,),
          
              // Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    child: Text(
                      "Save",
                      style: TextStyle(color: primaryColorValue),
                    ),
                    onPressed: () async {
                      if (formKey.currentState!.validate()) {
                        String databaseDateTimeString = entryDateTime.text;
                        int minutesColon = databaseDateTimeString.indexOf(' ');
                        int secondsColon = databaseDateTimeString.indexOf(' ', minutesColon + 1);
                        databaseDateTimeString = '${databaseDateTimeString.substring(0, secondsColon)}:00${databaseDateTimeString.substring(secondsColon)}';
                        
                        DateTime databaseDateTime = DateFormat('MM/DD/yyyy hh:mm:ss a').tryParse(databaseDateTimeString) ?? DateFormat('MM/DD/yyyy hh:mm:ss').parse(databaseDateTimeString);
                        DateFormat sqlDateFormat = DateFormat('yyyy-MM-dd hh:mm:ss');
                        databaseDateTimeString = sqlDateFormat.format(databaseDateTime);
          
                        UserLogEntry logEntry = UserLogEntry(
                          entryDateTime: databaseDateTimeString,
                          workoutType: workoutType.text,
                          repetitions: int.tryParse(repetitions.text),
                          time: int.tryParse(time.text),
                          weight: double.tryParse(weight.text),
                          notes: (notes.text == '') ? null : notes.text,
                        );
          
                        final db = DatabaseHelper();
                        await db.createLogEntry('${widget.username}EntryLog', logEntry);
                        
                        // Let user know log was saved
                        AlertDialog savePopup = createSavePopup();
                        await showDialog(context: context, builder: (context) => savePopup);
                      }
                    },
                  ),
                  const SizedBox(width: 20),
                  ElevatedButton(
                    child: Text(
                      "Clear",
                      style: TextStyle(color: primaryColorValue),
                    ),
                    onPressed: () {
                      setState(() {
                        entryDateTime.text = DateFormat.yMd().add_jm().format(DateTime.now()).replaceAll(RegExp(r' '), ' ');
                        workoutType.text = '';
                        repetitions.text = '';
                        time.text = '';
                        weight.text = '';
                        notes.text = '';
                      });
                    },
                  ),
                ],
              ),
          
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    // Clean up the controller when the widget is disposed
    workoutType.dispose();
    super.dispose();
  }


  int getIndexOfWorkoutType(String workoutType, List<UserLogEntry> data) {
    List<UserLogEntry> thisWorkoutTypeEntries = [];
    for (UserLogEntry entry in data) {
      if (entry.workoutType == workoutType) {
        thisWorkoutTypeEntries.add(entry);
      }
    }
    DateTime todayDateTime = DateTime.now();
    DateTime todayDate = DateTime(todayDateTime.year, todayDateTime.month, todayDateTime.day);

    int i = 0;
    for (UserLogEntry entry in thisWorkoutTypeEntries) {
      DateTime entryDateTime = DateTime.parse(entry.entryDateTime);
      DateTime entryDate = DateTime(entryDateTime.year, entryDateTime.month, entryDateTime.day);
      if (entryDate == todayDate) {
        i += 1;
      }
    }

    return i;
  }

  AlertDialog createSavePopup() {
    final formKey = GlobalKey<FormState>();

    AlertDialog savePopup = AlertDialog(
      title: const Center(child: Text('Entry Saved', style: TextStyle(fontWeight: FontWeight.bold)),),
      contentPadding: const EdgeInsets.all(8.0),
      content: Form(
        key: formKey,
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Your entry has successfully saved'),
            SizedBox(height: 8,),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () { 
            Navigator.pop(context); 
          },
          style: ButtonStyle(
            backgroundColor: MaterialStatePropertyAll(primaryColorValue),
          ),
          child: Text(
            "Ok",
            style: TextStyle(color: secondaryColorValue),
          ),
        ),
      ],
    );

    return savePopup;
  }

  AlertDialog createAutoTrackPopup() {
    final formKey = GlobalKey<FormState>();
    notes.text = '';

    List<String> workoutList = ['Curl', 'Squat'];
    String? currentSelectedWorkout = workoutList[0];
    final ValueNotifier<List<String>> workoutTypeNotifier = ValueNotifier<List<String>>(workoutList);

    AlertDialog autoTrackPopup = AlertDialog(
      title: const Center(child: Text('Auto Track Options', style: TextStyle(fontWeight: FontWeight.bold)),),
      contentPadding: const EdgeInsets.all(8.0),
      content: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Workout selector
            const SizedBox(height: 10,),
            const SizedBox(height: 10,),
            ValueListenableBuilder(
              valueListenable: workoutTypeNotifier,
              builder: (BuildContext context, List<String> list, Widget? child) {
                return DropdownButton<String>(
                  value: currentSelectedWorkout,
                  isDense: true,
                  onChanged: (newValue) {
                    currentSelectedWorkout = newValue;
                    workoutTypeNotifier.notifyListeners();
                  },
                  items: list.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                );
              }
            ),
            // Weight field
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextFormField(
                controller: weight,
                validator: (value) {
                  if (value!.isNotEmpty && (double.tryParse(value) ?? -1) < 0) {
                    return "Weight must be a positive number";
                  }
                  return null;
                },
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  label: Text("Weight"),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
          TextButton(
          onPressed: () {
            Navigator.pop(context); 
          },
          style: ButtonStyle(
            backgroundColor: MaterialStatePropertyAll(primaryColorValue),
          ),
          child: Text(
            "Cancel",
            style: TextStyle(color: secondaryColorValue),
          ),
        ),
        TextButton(
          onPressed: () async {
            workoutType.text = currentSelectedWorkout!;
            
            int workoutNumber = workoutList.indexOf(currentSelectedWorkout!) + 1;

            // Run tracking
            ProcessResult results = await Process.run(WORKOUT_TRACKER_LOC, ['$workoutNumber']);
            if (results.stdout.runtimeType == String) {
              String result = results.stdout;

              // Calculate the total number of repetitions
              int startReps = result.indexOf('[') + 1;
              int endReps = result.indexOf(']');
              String repetitionsValues = result.substring(startReps, endReps);
              List<String> repList = repetitionsValues.split(', ');
              int total = 0;
              for (int index = 0; index < repList.length; index++)
              {
                total = total + int.parse(repList[index]);
              }
              repetitions.text = total.toString();

              // Display the specific repetitions for the left and right sides
              if (repList.length > 1) {
                notes.text = 'Repetitions were ${repList[0]} for the left arm and ${repList[1]} for the right arm';
              }

              // Determine time
              String seconds = result.substring(endReps + 1).trim();
              time.text = seconds;
            }

            Navigator.pop(context); 
          },
          style: ButtonStyle(
            backgroundColor: MaterialStatePropertyAll(primaryColorValue),
          ),
          child: Text(
            "Track",
            style: TextStyle(color: secondaryColorValue),
          ),
        ),
      ],
    );

    return autoTrackPopup;
  }
}


