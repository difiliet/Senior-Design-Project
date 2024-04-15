import 'package:applicants/DataModels/userSettings.dart';
import 'package:applicants/JsonModels/userLogEntry.dart';
import 'package:applicants/SQLite/databaseHelper.dart';
import 'package:applicants/pages/history/viewHistoryDate.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

class HistoryPage extends StatefulWidget {
  final String username;
  final UserSettings currentUserSettings;
  const HistoryPage(this.username, this.currentUserSettings, {super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  late Future<List<UserLogEntry>> logEntryList;
  bool predictionsEnabled = false;
  Color primaryColorValue = Colors.blue;
  Color secondaryColorValue = Colors.white;

  @override
  void initState() {
    super.initState();
    logEntryList = getUserLogEntries(widget.username);
    initializeDateFormatting();

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
          child: FutureBuilder<List<UserLogEntry>>(
            future: logEntryList,
            builder: (BuildContext context, AsyncSnapshot<List<UserLogEntry>> userLogEntries) {
              if (userLogEntries.hasData && userLogEntries.data!.isNotEmpty) {
                int amountOfEntries = userLogEntries.data!.length;
                
                // Sort the date times
                DateFormat datebaseformat = DateFormat("yyyy-MM-dd");
                userLogEntries.data!.sort((firstEntry, secondEntry) {
                  DateTime firstEntryDateTime = datebaseformat.parse(firstEntry.entryDateTime);
                  DateTime secondEntryDateTime = datebaseformat.parse(secondEntry.entryDateTime);
                  return firstEntryDateTime.compareTo(secondEntryDateTime);
                });

                List<String> datesListed = [];
                List<Widget> pageContent = [];
                // Create the history of the log entries
                for (int index = amountOfEntries - 1; index >= 0; index--) {
                  String rawDateText = userLogEntries.data![index].entryDateTime;
                  List<String> dateTextSplit = rawDateText.split('-');
                  String locale = Localizations.localeOf(context).languageCode;
                  DateTime dateValue = DateTime(int.parse(dateTextSplit[0]), int.parse(dateTextSplit[1]), int.parse(dateTextSplit[2].split(' ')[0]));
                  String dateText = DateFormat.yMMMMd(locale).format(dateValue);

                  if (!datesListed.contains(dateText)) {
                    datesListed.add(dateText);
                 
                    pageContent.add(Padding(
                      padding: const EdgeInsets.only(left: 20, top: 0, right: 20, bottom: 1),
                      child: Container(
                        color: secondaryColorValue,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Expanded(child: Padding(
                              padding: const EdgeInsets.only(left: 8.0),
                              child: Text(dateText),
                            )),
                            IconButton(
                              icon: const Icon(Icons.visibility),
                              onPressed: () 
                              {
                                Navigator.push(
                                  context, 
                                  MaterialPageRoute(
                                    builder: (context) => ViewHistoryDatePage(widget.username, rawDateText, widget.currentUserSettings)
                                  )
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    );
                  }
                }

                // Add show more if needed
                if (amountOfEntries != userLogEntries.data!.length) {
                  pageContent.add(const SizedBox(height: 20,));
                  pageContent.add(
                    ElevatedButton(
                      child: const Text("Show All"),
                      onPressed: () 
                      {
                          
                      },
                    )
                  );
                }

                Widget pageContentWrapper = Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: pageContent,
                );

                // Make scrollable if list is big
                if (amountOfEntries > 20) {
                  pageContentWrapper = SingleChildScrollView(child: pageContentWrapper,);
                }

                return pageContentWrapper;
                
              } else {
                // For when the user does not have any workout history
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [Padding(
                    padding: const EdgeInsets.only(left: 20, top: 0, right: 20, bottom: 1),
                    child: Container(
                      color: secondaryColorValue,
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(child: Padding(
                            padding: EdgeInsets.only(left: 8.0),
                            child: Text(
                              'Enter workout information to have a workout history', 
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 35, fontWeight: FontWeight.bold)
                            ),
                          )),
                        ]
                      )
                    )
                  ),]
                );
              }
            },
          ),
        ),
      ),
    );
  }
}

Future<List<UserLogEntry>> getUserLogEntries(String username) async {
  final db = DatabaseHelper();

  List<UserLogEntry> list = await db.getLogEntries('${username}EntryLog');
  return list;
}