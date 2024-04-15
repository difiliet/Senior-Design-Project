import 'package:applicants/DataModels/userSettings.dart';
import 'package:applicants/JsonModels/userLogEntry.dart';
import 'package:applicants/SQLite/databaseHelper.dart';
import 'package:applicants/main.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ViewHistoryDatePage extends StatefulWidget {
  final String username;
  final String date;
  final UserSettings currentUserSettings;
  const ViewHistoryDatePage(this.username, this.date, this.currentUserSettings, {super.key});

  @override
  State<ViewHistoryDatePage> createState() => _ViewHistoryDatePageState();
}

class _ViewHistoryDatePageState extends State<ViewHistoryDatePage> {
  late Future<List<UserLogEntry>> logEntryList;
  
  @override
  void initState() {
    super.initState();
    logEntryList = getUserLogEntriesForDate(widget.username, widget.date.substring(0, widget.date.indexOf(' ')));
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: FutureBuilder<List<UserLogEntry>>(
          future: logEntryList,
          builder: (BuildContext context, AsyncSnapshot<List<UserLogEntry>> userLogEntries) {
            if (userLogEntries.hasData) {
              int amountOfEntries = userLogEntries.data!.length;
        
              // Find the workout types that were done on the selected day
              List<String> workoutTypes = [];
              for (int index = 0; index < amountOfEntries; index++) {
                String workoutType = userLogEntries.data![index].workoutType;
                if (!workoutTypes.contains(workoutType)) {
                  workoutTypes.add(workoutType);
                }
              }
        
              List<Widget> pageContent = []; 
              // Create a table for each workout type
              for (int index = 0; index < workoutTypes.length; index++)
              {
                
                List<DataRow> workoutTypeRow = [];
                for(int inner = 0; inner < amountOfEntries; inner++)
                {
                  // Create the table rows
                  if (userLogEntries.data![inner].workoutType == workoutTypes[index]) {
                    final int entryId = userLogEntries.data![inner].entryId ?? 0;
                    
                    // Create edit button
                    IconButton editButton = IconButton(
                      onPressed: () async {
                        final entryDateTime = TextEditingController();
                        final workoutType = TextEditingController();
                        final repetitions = TextEditingController();
                        final time = TextEditingController();
                        final weight = TextEditingController();
                        final notes = TextEditingController();

                        // Set current values
                        DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
                        DateTime databaseDateTime = dateFormat.parse(userLogEntries.data![inner].entryDateTime);
                        String stringDateTime = DateFormat.yMd().add_jm().format(databaseDateTime).replaceAll(RegExp(r'\s+'), " ");
                        setState(() {
                          entryDateTime.text = stringDateTime;
                          workoutType.text = userLogEntries.data![inner].workoutType;
                          repetitions.text = '${userLogEntries.data![inner].repetitions ?? ''}';
                          time.text = '${userLogEntries.data![inner].time ?? ''}';
                          weight.text = '${userLogEntries.data![inner].weight ?? ''}';
                          notes.text = userLogEntries.data![inner].notes ?? '';
                        });

                        // Generate edit popup
                        AlertDialog editPopup = createEditPopup(context, widget.username, entryDateTime, workoutType, repetitions, time, weight, notes, entryId);
                        await showDialog<void>(context: context, builder: (context) => editPopup);
                        setState(() {
                          logEntryList = getUserLogEntriesForDate(widget.username, widget.date.substring(0, widget.date.indexOf(' ')));
                        });
                      }, 
                      icon: const Icon(Icons.edit)
                    );

                    // Delete button
                    IconButton deleteButton = IconButton(
                      onPressed: () async {
                        AlertDialog deletePopup = createDeletePopup(context, widget.username, entryId);
                        await showDialog<void>(context: context, builder: (context) => deletePopup);
                        setState(() {
                          logEntryList = getUserLogEntriesForDate(widget.username, widget.date.substring(0, widget.date.indexOf(' ')));
                        });
                      }, 
                      icon: const Icon(Icons.delete, color: Colors.red,)
                    );

                    // Display data
                    DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
                    DateTime databaseDateTime = dateFormat.parse(userLogEntries.data![inner].entryDateTime);
                    String entryTime = DateFormat.jm().format(databaseDateTime).replaceAll(RegExp(r'\s+'), " ");
                    workoutTypeRow.add(DataRow(
                      cells: [
                        DataCell(Text(entryTime)),
                        DataCell(Text('${userLogEntries.data![inner].repetitions ?? ''}')),
                        DataCell(Text('${userLogEntries.data![inner].time ?? ''}')),
                        DataCell(Text('${userLogEntries.data![inner].weight ?? ''}')),
                        DataCell(Text(userLogEntries.data![inner].notes ?? '')),
                        DataCell(editButton),
                        DataCell(deleteButton),
                      ]
                    ));
                  }
                }
        
                // Title of the table
                pageContent.add(Text(
                  workoutTypes[index], 
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 35, fontWeight: FontWeight.bold)
                ));
        
                // Generate the table
                pageContent.add(DataTable(
                    columns: const [
                      DataColumn(label: Text('Date and Time'),),
                      DataColumn(label: Text('Repetitions'),),
                      DataColumn(label: Text('Time'),),
                      DataColumn(label: Text('Weight'),),
                      DataColumn(label: Text('Notes'),),
                      DataColumn(label: Text(''),),
                      DataColumn(label: Text(''),),
                    ],
                    rows: workoutTypeRow
                  )
                );
              }

              // Go back button
              pageContent.add(const SizedBox(height: 20,));
              pageContent.add(Container(
                height: 50,
                width: MediaQuery.of(context).size.width * .3,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.blue
                ),
                child: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context, 
                      MaterialPageRoute(
                        builder: (context) => MainPage(widget.username, widget.currentUserSettings, selectedPage: 2)
                      )
                    );
                  },
                  child: const Text(
                    "Go Back To History Page",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ));
              
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: pageContent,
              );
              
            } else {
              return Container(
                height: 50,
                width: MediaQuery.of(context).size.width * .3,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.blue
                ),
                child: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context, 
                      MaterialPageRoute(
                        builder: (context) => MainPage(widget.username, widget.currentUserSettings, selectedPage: 2)
                      )
                    );
                  },
                  child: const Text(
                    "Go Back To History Page",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              );
            }
          }
        )
      )
    );
  }
}

Future<List<UserLogEntry>> getUserLogEntriesForDate(String username, String dateString) async {
  final db = DatabaseHelper();

  List<UserLogEntry> list = await db.getLogEntriesForDate('${username}EntryLog', dateString);
  return list;
}

AlertDialog createEditPopup(BuildContext context, String username, TextEditingController entryDateTime, TextEditingController workoutType, TextEditingController repetitions, TextEditingController time, TextEditingController weight, TextEditingController notes, int entryId) {
  final formKey = GlobalKey<FormState>();
  
  AlertDialog editPopup = AlertDialog(
    title: const Center(child: Text('Edit Entry', style: TextStyle(fontWeight: FontWeight.bold)),),
    backgroundColor: Colors.white,
    contentPadding: const EdgeInsets.all(8.0),
    content: Form(
      key: formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Date field
          TextFormField(
            controller: entryDateTime,
            validator: (value) {
              if (value == null) {
                return "Date and time must be entered";
              }
              DateTime ? dateTime1 = DateFormat('MM/DD/yyyy hh:mm a').tryParse(value);
              DateTime ? dateTime2 = DateFormat('MM/DD/yyyy hh:mm:ss').tryParse(value);
              if (dateTime1 == null && dateTime2 == null) {
                return "Date and time is not in correct format";
              }
              return null;
            },
            decoration: const InputDecoration(
              border: InputBorder.none,
              label: Text("Date and Time"),
            ),
          ),
          // Workout field
          TextFormField(
            controller: workoutType,
            validator: (value) {
              if (value!.isEmpty) {
                return "Workout Type is required";
              }
              return null;
            },
            decoration: const InputDecoration(
              border: InputBorder.none,
              label: Text("Workout Type"),
            ),
          ),
          // Repetitions field
          TextFormField(
            controller: repetitions,
            validator: (value) {
              if (value!.isNotEmpty && (int.tryParse(value) ?? -1) < 0) {
                return "Repetitions must be a positive number";
              }
              return null;
            },
            decoration: const InputDecoration(
              border: InputBorder.none,
              label: Text("Repetitions"),
            ),
          ),
          // Time field
          TextFormField(
            controller: time,
            validator: (value) {
              if (value!.isNotEmpty && (int.tryParse(value) ?? -1) < 0) {
                return "Repetitions must be a positive number";
              }
              return null;
            },
            decoration: const InputDecoration(
              border: InputBorder.none,
              label: Text("Time"),
            ),
          ),
          // Weight field
          TextFormField(
            controller: weight,
            validator: (value) {
              if (value!.isNotEmpty && (double.tryParse(value) ?? -1) < 0) {
                return "Repetitions must be a positive number";
              }
              return null;
            },
            decoration: const InputDecoration(
              border: InputBorder.none,
              label: Text("Weight"),
            ),
          ),
          // Notes field
          TextFormField(
            controller: notes,
            validator: (value) {
              return null;
            },
            decoration: const InputDecoration(
              border: InputBorder.none,
              label: Text("Notes"),
            ),
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () { Navigator.pop(context); },
        style: const ButtonStyle(
          backgroundColor: MaterialStatePropertyAll(Colors.blue),
        ),
        child: const Text(
          "Cancel",
          style: TextStyle(color: Colors.white),
        ),
      ),
      TextButton(
        onPressed: () async {
          if (formKey.currentState!.validate()) {
            String databaseDateTimeString = entryDateTime.text;
            int minutesColon = databaseDateTimeString.indexOf(' ');
            int secondsColon = databaseDateTimeString.indexOf(' ', minutesColon + 1);
            databaseDateTimeString = '${databaseDateTimeString.substring(0, secondsColon)}:00${databaseDateTimeString.substring(secondsColon)}';
            DateTime databaseDateTime = DateFormat('MM/DD/yyyy hh:mm:ss a').tryParse(databaseDateTimeString) ?? DateFormat('MM/DD/yyyy hh:mm:ss').parse(databaseDateTimeString);

            Navigator.pop(context);
            final db = DatabaseHelper();
            await db.updateLogEntry('${username}EntryLog', databaseDateTime, workoutType.text, int.tryParse(repetitions.text), int.tryParse(time.text), double.tryParse(weight.text), notes.text, entryId);
          }
        },
        style: const ButtonStyle(
          backgroundColor: MaterialStatePropertyAll(Colors.blue),
        ),
        child: const Text(
          "Save",
          style: TextStyle(color: Colors.white),
        ),
      ),
    ],
  );

  return editPopup;
}

AlertDialog createDeletePopup(BuildContext context, String username, int entryId) {
  final formKey = GlobalKey<FormState>();
  
  AlertDialog deletePopup = AlertDialog(
    title: const Center(child: Text('Delete Entry', style: TextStyle(fontWeight: FontWeight.bold)),),
    contentPadding: const EdgeInsets.all(8.0),
    content: Form(
      key: formKey,
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Are you sure you want to delete this entry?\n\nOnce deleted the entry cannot be recovered.'),
          SizedBox(height: 8,),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () { Navigator.pop(context); },
        style: const ButtonStyle(
          backgroundColor: MaterialStatePropertyAll(Colors.blue),
        ),
        child: const Text(
          "No",
          style: TextStyle(color: Colors.white),
        ),
      ),
      TextButton(
        onPressed: () async {
          Navigator.pop(context);
          final db = DatabaseHelper();
          await db.deleteLogEntry('${username}EntryLog', entryId);
        },
        style: const ButtonStyle(
          backgroundColor: MaterialStatePropertyAll(Colors.blue),
        ),
        child: const Text(
          "Yes",
          style: TextStyle(color: Colors.white),
        ),
      ),
    ],
  );

  return deletePopup;
}