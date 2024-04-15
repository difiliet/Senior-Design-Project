import 'dart:math';
import 'package:applicants/DataModels/userSettings.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:applicants/JsonModels/userLogEntry.dart';
import 'package:applicants/SQLite/databaseHelper.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:linalg/linalg.dart';

class WorkoutData {
  WorkoutData(this.day, this.value);
  String day;
  double value;
  double? expected;
}

enum Aggregate { count, average }

class QueryInformation {
  QueryInformation(this.workoutType, this.valueType, this.aggregate, this.fromDate, this.toDate);
  String workoutType;
  String valueType;
  Aggregate aggregate;
  String toDate;
  String fromDate;
}

final List<String> valueTypeList = ["Repetitions", "Time", "Weight"];

class ChartPage extends StatefulWidget {
  final String username;
  final UserSettings currentUserSettings;
  const ChartPage(this.username, this.currentUserSettings, {super.key});

  @override
  State<ChartPage> createState() => _ChartPageState();
}

class _ChartPageState extends State<ChartPage> {
  late Future<List<UserLogEntry>> logEntryList;
  late QueryInformation queryInfo;
  bool predictionsEnabled = false;
  Color primaryColor = Colors.blue;
  Color secondaryColor = Colors.white;

  @override
  void initState() {
    super.initState();
    queryInfo = QueryInformation('', valueTypeList[0], Aggregate.count, '', '');
    if (queryInfo.fromDate == '' && queryInfo.toDate == '') {
      DateTime dateTime = DateTime.now();
      queryInfo.fromDate = DateFormat('yyyy-MM-dd').format(dateTime.subtract(const Duration(days: 7)));
      queryInfo.toDate = DateFormat('yyyy-MM-dd').format(dateTime);
    }

    /*if (queryInfo.workoutType == '') {
      queryInfo.workoutType == 'Bench';
    }*/
    logEntryList = getUserLogEntriesBetweenDates(widget.username, queryInfo.fromDate, queryInfo.toDate);
    initializeDateFormatting();

    predictionsEnabled = widget.currentUserSettings.predictionsEnabled;
    primaryColor = widget.currentUserSettings.primaryColor;
    secondaryColor = widget.currentUserSettings.secondaryColor;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          color: primaryColor,
          child: FutureBuilder<List<UserLogEntry>>(
            future: logEntryList,
            builder: (BuildContext context, AsyncSnapshot<List<UserLogEntry>> userLogEntries) {
              if (userLogEntries.hasData && userLogEntries.data!.isNotEmpty) {
                int amountOfEntries = userLogEntries.data!.length;
                List<WorkoutData> chartData = [];
                List<int> dateValueCount = [];
                bool isAverage = queryInfo.aggregate == Aggregate.average ? true : false;

                // Sort the date times
                DateFormat datebaseformat = DateFormat("yyyy-MM-dd");
                userLogEntries.data!.sort((firstEntry, secondEntry) {
                  DateTime firstEntryDateTime = datebaseformat.parse(firstEntry.entryDateTime);
                  DateTime secondEntryDateTime = datebaseformat.parse(secondEntry.entryDateTime);
                  return firstEntryDateTime.compareTo(secondEntryDateTime);
                });

                // Find the workout types that were done on the selected day
                List<String> workoutTypes = [];
                for (int index = 0; index < amountOfEntries; index++) {
                  String workoutType = userLogEntries.data![index].workoutType;
                  if (!workoutTypes.contains(workoutType)) {
                    workoutTypes.add(workoutType);
                  }
                }

                // Create the chart data
                for (int index = 0; index < amountOfEntries; index++) {
                  String dateText = getDateText(userLogEntries.data![index].entryDateTime, context);

                  // Create graph for specific data
                  double? value;
                  if (userLogEntries.data![index].workoutType == queryInfo.workoutType) {
                    if (queryInfo.valueType == valueTypeList[0] && userLogEntries.data![index].repetitions != null) {
                      value = (userLogEntries.data![index].repetitions)!.toDouble();
                    } else if (queryInfo.valueType == valueTypeList[1] && userLogEntries.data![index].time != null) {
                      value = (userLogEntries.data![index].time)!.toDouble();
                    } else if (queryInfo.valueType == valueTypeList[2] && userLogEntries.data![index].weight != null) {
                      value = (userLogEntries.data![index].weight)!.toDouble();
                    }
                  }

                  // Find if the date has already been add
                  int indexFound = -1;
                  for (int chartDataIndex = 0; chartDataIndex < chartData.length && indexFound < 0; chartDataIndex++)
                  {
                    if (chartData[chartDataIndex].day == dateText) {
                      indexFound = chartDataIndex;
                    } 
                  }

                  // Add date or value depending on the current list
                  if (indexFound != -1 && value != null) {
                    chartData[indexFound].value = chartData[indexFound].value + value;
                    if (isAverage) dateValueCount[indexFound] = dateValueCount[indexFound] + 1;
                  } else if (value != null) {
                    chartData.add(WorkoutData(dateText, value));
                    if (isAverage) dateValueCount.add(1);
                  }
                }

                // If average calculate the average
                for (int index = 0; index < chartData.length && isAverage; index++)
                {
                  chartData[index].value = chartData[index].value / dateValueCount[index];
                }

                // Create expected values
                if (predictionsEnabled) {
                  List<double> trainingValues = [];
                  List<double> counterList = [];
                  for (int chartDataIndex = 0; chartDataIndex < chartData.length; chartDataIndex++)
                  {
                    trainingValues.add(chartData[chartDataIndex].value);
                    counterList.add(chartDataIndex.toDouble()+1);
                  }
                  List<double> regressionValues = [];
                  regressionValues = calculatePolynomialRegression(trainingValues, counterList);
                  for (int chartDataIndex = 0; chartDataIndex < regressionValues.length; chartDataIndex++)
                  {
                    chartData[chartDataIndex].expected = regressionValues[chartDataIndex];
                  }
                }

                // Create the chart series
                List<CartesianSeries<WorkoutData, String>> chartSeries = [];
                chartSeries.add(ColumnSeries<WorkoutData, String>(
                  name: 'Actual Value',
                  color: Colors.blue,
                  opacity: .5,
                  dataSource: chartData,
                  xValueMapper: (WorkoutData workout, _) => workout.day,
                  yValueMapper: (WorkoutData workout, _) => workout.value,
                ));

                // Display expected values
                if (predictionsEnabled) {
                  chartSeries.add(LineSeries<WorkoutData, String>(
                    name: 'Expected Value',
                    color: Colors.green,
                    width: 4,
                    dataSource: chartData,
                    xValueMapper: (WorkoutData workout, _) => workout.day,
                    yValueMapper: (WorkoutData workout, _) => workout.expected,
                  ));
                }

                // Create the chart
                return Padding(
                  padding: const EdgeInsets.all(30.0),
                  child: Column(
                    children: [
                      Expanded(
                        child: SfCartesianChart(
                          title: ChartTitle(
                            text: '${queryInfo.workoutType} ${queryInfo.valueType} (${queryInfo.aggregate == Aggregate.count ? 'Count' : 'Average'})'
                          ),
                          backgroundColor: secondaryColor,
                          primaryXAxis: const CategoryAxis(
                            title: AxisTitle(
                                text: 'Date',
                            )
                          ),
                          primaryYAxis: NumericAxis(
                            title: AxisTitle(
                              text: queryInfo.valueType
                            )
                          ),
                          legend: const Legend(
                            isVisible: true,
                            ),
                          series: chartSeries,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 20),
                        child: ElevatedButton(
                          child: Text(
                            "Change Chart",
                            style: TextStyle(color: primaryColor),
                          ),
                          onPressed: () async {
                            // Generate change chart popup
                            AlertDialog changeChartPopup = createChangeChartPopup(context, false, workoutTypes, queryInfo);
                            await showDialog<void>(context: context, builder: (context) => changeChartPopup);
                            setState(() {
                              logEntryList = getUserLogEntriesBetweenDates(widget.username, queryInfo.fromDate, queryInfo.toDate);
                            });
                          },
                        ),
                      ),
                    ]
                  ),
                );
              } else {
                return Container();
              }
            }),
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

Future<List<UserLogEntry>> getUserLogEntriesBetweenDates(String username, String fromDateString, String toDateString) async {
  final db = DatabaseHelper();

  List<UserLogEntry> list = await db.getLogEntriesBetweenDates('${username}EntryLog', fromDateString, toDateString);
  return list;
}

String getDateText(String databaseDateTime, BuildContext context) {
  String rawDateText = databaseDateTime;
  List<String> dateTextSplit = rawDateText.split('-');
  String locale = Localizations.localeOf(context).languageCode;
  DateTime dateValue = DateTime(int.parse(dateTextSplit[0]), int.parse(dateTextSplit[1]), int.parse(dateTextSplit[2].split(' ')[0]));
  String dateText = DateFormat.yMMMMd(locale).format(dateValue);
  return dateText;
}

AlertDialog createChangeChartPopup(BuildContext context, bool initial, List<String> workoutList, QueryInformation queryInfo) {
  final formKey = GlobalKey<FormState>();
  final fromDate = TextEditingController();
  final toDate = TextEditingController();
  
  DateTime toDateTime = DateTime.now();
  DateTime fromDateTime = toDateTime.subtract(const Duration(days: 7));
  toDate.text = DateFormat.yMd().format(toDateTime);
  fromDate.text = DateFormat.yMd().format(fromDateTime);
  
  String? currentSelectedWorkout = queryInfo.workoutType.isEmpty ? workoutList[0] : queryInfo.workoutType;
  final ValueNotifier<List<String>> workoutTypeNotifier = ValueNotifier<List<String>>(workoutList);
  String? currentSelectedValue = queryInfo.valueType;
  final ValueNotifier<List<String>> valueTypeNotifier = ValueNotifier<List<String>>(valueTypeList);
  Aggregate aggregate = queryInfo.aggregate == Aggregate.count ? Aggregate.count: Aggregate.average;
  final ValueNotifier<bool> isAverageNotifier = ValueNotifier(false);
  
  AlertDialog chartPopup = AlertDialog(
    title: const Center(child: Text('Change Chart', style: TextStyle(fontWeight: FontWeight.bold)),),
    backgroundColor: Colors.white,
    contentPadding: const EdgeInsets.all(8.0),
    content: Form(
      key: formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Workout selector
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
          // Value selector
          const SizedBox(height: 10,),
          ValueListenableBuilder(
            valueListenable: valueTypeNotifier,
            builder: (BuildContext context, List<String> list, Widget? child) {
              return DropdownButton<String>(
                value: currentSelectedValue,
                isDense: true,
                onChanged: (newValue) {
                  currentSelectedValue = newValue;
                  valueTypeNotifier.notifyListeners();
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
          // Aggregate Radio buttons
          const SizedBox(height: 20,),
          const Text(
            'Aggregate:', 
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 10,),
          ValueListenableBuilder(
            valueListenable: isAverageNotifier,
            builder: (BuildContext context, bool isAverage, Widget? child) {
              return Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      const Text('Count'),
                      Radio(
                        value: Aggregate.count,
                        groupValue: aggregate,
                        onChanged: (newValue) {
                          aggregate = newValue!;
                          isAverageNotifier.notifyListeners();
                        },
                      ),
                      const Text('Average'),
                      Radio(
                        value: Aggregate.average,
                        groupValue: aggregate,
                        onChanged: (newValue) {
                          aggregate = newValue!;
                          isAverageNotifier.notifyListeners();
                        },
                      ),
                    ],
                  ),
                ]
              );
            },
          ),
          // From Date Field
          TextFormField(
            controller: fromDate,
            validator: (value) {
              if (value == null) {
                return "Date and time must be entered";
              }
              DateTime ? dateTime = DateFormat('MM/DD/yyyy').tryParse(value);
              if (dateTime == null) {
                return "Date and time is not in correct format";
              }
              return null;
            },
            decoration: const InputDecoration(
              border: InputBorder.none,
              label: Text("From"),
            ),
          ),
          // To Date Field
          TextFormField(
            controller: toDate,
            validator: (value) {
              if (value == null) {
                return "Date and time must be entered";
              }
              DateTime ? dateTime = DateFormat('MM/DD/yyyy').tryParse(value);
              if (dateTime == null) {
                return "Date and time is not in correct format";
              } else if (dateTime.isBefore(DateFormat('MM/DD/yyyy').parse(fromDate.text))) {
                return "From date must be before To date";
              }
              return null;
            },
            decoration: const InputDecoration(
              border: InputBorder.none,
              label: Text("To"),
            ),
          ),
        ],
      ),
    ),
    actions: [
      !initial ? TextButton(
        onPressed: () async { Navigator.pop(context); },
        style: const ButtonStyle(
          backgroundColor: MaterialStatePropertyAll(Colors.blue),
        ),
        child: const Text(
          "Cancel",
          style: TextStyle(color: Colors.white),
        ),
      ) : const SizedBox(),
      TextButton(
        onPressed: () async {
          if (formKey.currentState!.validate()) {
            queryInfo.workoutType = currentSelectedWorkout!;
            queryInfo.valueType = currentSelectedValue!;
            queryInfo.aggregate = aggregate;
            queryInfo.fromDate = dateStringToDatabase(fromDate.text);
            queryInfo.toDate = dateStringToDatabase(toDate.text);
            Navigator.pop(context);
          }
        },
        style: const ButtonStyle(
          backgroundColor: MaterialStatePropertyAll(Colors.blue),
        ),
        child: const Text(
          "Create",
          style: TextStyle(color: Colors.white),
        ),
      ),
    ],
  );

  return chartPopup;
}

String dateStringToDatabase(String dateString) {
  DateTime dateTime = DateFormat('MM/DD/yyyy').parse(dateString);
  return DateFormat('yyyy-MM-dd').format(dateTime);
}

List<double> calculatePolynomialRegression(List<double> trainingValues, List<double> expectedFor) {
  if (trainingValues.isEmpty) {
    return trainingValues;
  } else {
    double n = trainingValues.length.toDouble();
    double sumXi = 0.0, sumXi2 = 0.0, sumXi3 = 0.0, sumXi4 = 0.0, sumYi = 0.0, sumXiYi = 0.0, sumXi2Yi = 0.0;

    trainingValues.asMap().forEach((index, e) {
      sumXi += index;
      sumXi2 += pow(index, 2);
      sumXi3 += pow(index, 3);
      sumXi4 += pow(index, 4);
      sumYi += e;
      sumXiYi += (index * e);
      sumXi2Yi += (pow(index, 2)) * e;
    });
    
    final Matrix a = Matrix([
      [n, sumXi, sumXi2],
      [sumXi, sumXi2, sumXi3],
      [sumXi2, sumXi3, sumXi4]
    ]);
    final Vector b = Vector.column([sumYi, sumXiYi, sumXi2Yi]);
    
    // Can not do inverse if determinant is 0
    if (a.det() == 0) {
      return trainingValues;
    }
    Vector resultMatrix = ((a.inverse()) * b).toVector();

    List<double> expectedValues = [];
    for (double element in expectedFor) {
      double expected = (resultMatrix.transpose() * Vector.column([1, element, element * element]))[0][0];
      expected = (expected * 10).roundToDouble() / 10;
      expectedValues.add(expected);
    }
    return expectedValues;
  }
}