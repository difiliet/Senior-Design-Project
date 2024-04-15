import 'package:applicants/DataModels/userSettings.dart';
import 'package:applicants/JsonModels/user.dart';
import 'package:applicants/SQLite/databaseHelper.dart';
import 'package:applicants/pages/login.dart';
import 'package:flutter/material.dart';

class SettingsPage extends StatefulWidget {
  final String username;
  final UserSettings currentUserSettings;
  const SettingsPage(this.username, this.currentUserSettings, {super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  static const colorSelection = ['Blue', 'White', 'Green', 'Red', 'Orange'];
  String primaryColorString = 'Blue';
  String secondaryColorString = 'white';
  bool predictionsEnabled = false;
  Color primaryColorValue = Colors.blue;
  Color secondaryColorValue = Colors.white;

  bool firstLoad = true;

  late Future<User> userSettings;

  @override
  void initState() {
    super.initState();
    userSettings = getUserSettings(widget.username);

    predictionsEnabled = widget.currentUserSettings.predictionsEnabled;
    primaryColorValue = widget.currentUserSettings.primaryColor;
    secondaryColorValue = widget.currentUserSettings.secondaryColor;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          color: primaryColorValue,
          child: FutureBuilder<User>(
            future: userSettings,
            builder: (BuildContext context, AsyncSnapshot<User> userSettingsContents) {
              List<Widget> pageContent = [];
              if (userSettingsContents.hasData) {
                List<List<Widget>> contentRow = [];

                // Only do this on the first load of the page
                if (firstLoad) {
                  predictionsEnabled = userSettingsContents.data!.predictionsEnabled ?? false;
                  primaryColorString = userSettingsContents.data!.primaryColor ?? 'Blue';
                  secondaryColorString = userSettingsContents.data!.secondaryColor ?? 'White';
                  primaryColorValue = UserSettings.getPrimaryColorValue(userSettingsContents.data!.primaryColor);
                  secondaryColorValue = UserSettings.getSecondaryColorValue(userSettingsContents.data!.secondaryColor);
                  firstLoad = false;
                }

                // Update cached user settings
                widget.currentUserSettings.predictionsEnabled = userSettingsContents.data!.predictionsEnabled ?? false;
                widget.currentUserSettings.primaryColor = UserSettings.getPrimaryColorValue(userSettingsContents.data!.primaryColor);
                widget.currentUserSettings.secondaryColor = UserSettings.getSecondaryColorValue(userSettingsContents.data!.secondaryColor);
                
                // Prediction row
                contentRow.add(
                  [
                    const Expanded(child: Padding(
                      padding: EdgeInsets.only(left: 8.0),
                      child: Text('Enable Predictions:'),
                    )),
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: Switch(
                        value: predictionsEnabled,
                        activeColor: Colors.green,
                        onChanged: (bool value) async {
                          bool valueChanged = true;
                          if (value) {
                            AlertDialog predictionPopup = createPredictionPopup(context, widget.username, value, primaryColorString, secondaryColorString);
                            valueChanged = await showDialog(context: context, builder: (context) => predictionPopup);
                          } else {
                            await updateUserSettings(widget.username, value, primaryColorString, secondaryColorString);
                          }
                          setState(() {
                            if (valueChanged) {
                              userSettings = getUserSettings(widget.username);
                              predictionsEnabled = value;
                            }
                          });
                        },
                      )
                    )
                  ]
                );

                // Primary Color row
                contentRow.add(
                  [
                    const Expanded(child: Padding(
                      padding: EdgeInsets.only(left: 8.0),
                      child: Text('Primary Color:'),
                    )),
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: DropdownButton(
                        value: primaryColorString,
                        onChanged: (newValue) async {
                          await updateUserSettings(widget.username, predictionsEnabled, newValue!, secondaryColorString);
                          setState(() {
                            userSettings = getUserSettings(widget.username);
                            primaryColorString = newValue;
                            primaryColorValue = UserSettings.getPrimaryColorValue(newValue);
                          });
                        },
                        items: colorSelection.map((color) {
                          return DropdownMenuItem(
                            value: color,
                            child: Text(color),
                          );
                        }).toList(),
                      ),
                    )
                  ]
                );

                // Secondary Color row
                contentRow.add(
                  [
                    const Expanded(child: Padding(
                      padding: EdgeInsets.only(left: 8.0),
                      child: Text('Secondary Color:'),
                    )),
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: DropdownButton(
                        value: secondaryColorString,
                        onChanged: (newValue) async {
                          await updateUserSettings(widget.username, predictionsEnabled, primaryColorString, newValue!);
                          setState(() {
                            userSettings = getUserSettings(widget.username);
                            secondaryColorString = newValue;
                            secondaryColorValue = UserSettings.getPrimaryColorValue(newValue);
                          });
                        },
                        items: colorSelection.map((color) {
                          return DropdownMenuItem(
                            value: color,
                            child: Text(color),
                          );
                        }).toList(),
                      ),
                    ),
                  ]
                );

                // Generate the full page content
                for (int index = 0; index < contentRow.length; index++) {
                  List<Widget> optionContent = contentRow[index].toList();
                  pageContent.add(
                    Padding(
                      padding: const EdgeInsets.only(left: 20, top: 0, right: 20, bottom: 1),
                      child: Container(
                        color: secondaryColorValue,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: optionContent,
                        ),
                      ),
                    )
                  );
                }
              }

              // Spacer
              pageContent.add(const SizedBox(height: 20,));
              
              // Logout button
              pageContent.add(
                Container(
                  color: secondaryColorValue,
                  child: IconButton(
                    icon: const Icon(Icons.logout, color: Colors.red,),
                    color: secondaryColorValue,
                    onPressed: () 
                      {
                        Navigator.push(
                          context, 
                          MaterialPageRoute(
                            builder: (context) => const LoginPage()
                          )
                        );
                      },
                  ),
                )
              );
              
              // Return the page content
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: pageContent.toList(),
              );
            }
          ),
        ),
      ),
    );
  }
}

AlertDialog createPredictionPopup(BuildContext context, String username, bool predictionsEnabled, String primaryColor, String secondaryColor) {
  final formKey = GlobalKey<FormState>();

  Color primaryColorValue = UserSettings.getPrimaryColorValue(primaryColor);
  Color secondaryColorValue = UserSettings.getSecondaryColorValue(secondaryColor);
  
  AlertDialog deletePopup = AlertDialog(
    title: const Center(child: Text('Enable prediction', style: TextStyle(fontWeight: FontWeight.bold)),),
    contentPadding: const EdgeInsets.all(8.0),
    content: Form(
      key: formKey,
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Are you sure you want to turn on the overload prediction?\nThese values will not be exact and are only estimations.'),
          SizedBox(height: 8,),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () { 
          Navigator.pop(context, false); 
        },
        style: ButtonStyle(
          backgroundColor: MaterialStatePropertyAll(primaryColorValue),
        ),
        child: Text(
          "No",
          style: TextStyle(color: secondaryColorValue),
        ),
      ),
      TextButton(
        onPressed: () async {
          Navigator.pop(context, true);
          final db = DatabaseHelper();
          await db.updateUserSettings(username, predictionsEnabled ? 1 : 0, primaryColor, secondaryColor);
        },
        style: ButtonStyle(
          backgroundColor: MaterialStatePropertyAll(primaryColorValue),
        ),
        child: Text(
          "Yes",
          style: TextStyle(color: secondaryColorValue),
        ),
      ),
    ],
  );

  return deletePopup;
}

Future<User> getUserSettings(String username) async {
  final db = DatabaseHelper();

  User userSettings = await db.getUserSettings(username);
  return userSettings;
}

Future<int> updateUserSettings(String username, bool predictionsEnabled, String primaryColor, String secondaryColor) async {
  final db = DatabaseHelper();

  int result = await db.updateUserSettings(username, predictionsEnabled ? 1 : 0, primaryColor, secondaryColor);
  return result;
}