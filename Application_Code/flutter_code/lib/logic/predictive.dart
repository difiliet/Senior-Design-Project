import 'package:applicants/JsonModels/userLogEntry.dart';

Map<String, dynamic> getValuesFromEntry(UserLogEntry entry) {
  return {
    'entryId': entry.entryId,
    'reps': entry.repetitions,
    'weight': entry.weight,
    'datetime': entry.entryDateTime
  };
}

Map<String, List<Map<String, dynamic>>> processData(List<UserLogEntry>? data) {
  // if (entries != null) {
    Map<String, List<Map<String, dynamic>>> repsAndWeight = {};
    for (var entry in data!) {
      if (repsAndWeight.containsKey(entry.workoutType)){
        repsAndWeight[entry.workoutType]!.add(getValuesFromEntry(entry));
      } else {
        repsAndWeight[entry.workoutType] = [getValuesFromEntry(entry)];
      }
    }
    return repsAndWeight;
  }

// Returns a dict of each movement in repsAndWeight and the new target weight.
Map<String, List<int>> predict(Map<String, List<Map<String, dynamic>>> data) {
  Map<String, List<Map<String, dynamic>>> repsAndWeight = data;
  Map<String, List<int>> targets = {};
  if (repsAndWeight.isEmpty) {
    return targets; // Returns {} if no data to evaluate
  } else {
    repsAndWeight.forEach((exercise, entries) {
      // TODO Evaluate purely off of the previous workout
      // TODO: Account for lost strength in a previous workout
      // TODO: See issue below. Create a variable for "first workout of the day" and handle issues accordingly.
      // TODO: Implement a weight increase when the repcount hits maximum reps. Eg:
      //  if repcount == max{
      //    weight += 5
      //  } else{
      //    reps += 1
      //  }
      if (entries.length == 1) {
        targets[exercise] = [entries[0]['reps'] + 1];
      }
      else if (entries.length > 1) {
        List<int> repsForLastWorkout = [];
        // Make sure that the predictions are not based off of today in the case that the user logs off mid workout
        DateTime lastDate = DateTime.now();
        DateTime todayDateTime = DateTime.now();
        DateTime todayDate = DateTime(todayDateTime.year, todayDateTime.month, todayDateTime.day);
        for (Map<String, dynamic> entry in entries.reversed) {
          DateTime entryDateTime = DateTime.parse(entry['datetime']);
          DateTime entryDate = DateTime(entryDateTime.year, entryDateTime.month, entryDateTime.day);
          if (entryDate != todayDate) {
            lastDate = entryDate;
            break;
          }
        }

        // DateTime lastEntryDateTime = DateTime.parse(entries.last['datetime']);
        // DateTime lastDate = DateTime(lastEntryDateTime.year, lastEntryDateTime.month, lastEntryDateTime.day);
        for (Map<String, dynamic> entry in entries){ //This may cause issues if you log your workout because previous date will be the one you just did 5 minutes ago
          DateTime entryDateTime = DateTime.parse(entry['datetime']);
          DateTime entryDate = DateTime(entryDateTime.year, entryDateTime.month, entryDateTime.day);
          if (entryDate == lastDate) {
            if (entry['reps'] == null) {
              repsForLastWorkout.add(0);
            } else {
              repsForLastWorkout.add(entry['reps'] + 1);
            }
          }
        }
        targets[exercise] = repsForLastWorkout;
      }
      // TODO: Handle the case that the user does one more set than the previous workout
    });
    return targets;
  }
}

Map<String, DateTime> lastDateOfEachMovement(Map<String, List<Map<String, dynamic>>> data) {
  Map<String, DateTime> lastDates = {};
  if (data.isEmpty) {
    return lastDates; // Returns {} if no data to evaluate
  } else {
    data.forEach((exercise, entries) {
      DateTime lastEntryDateTime = DateTime.parse(entries.last['datetime']);
      DateTime lastDate = DateTime(lastEntryDateTime.year, lastEntryDateTime.month, lastEntryDateTime.day);
      lastDates[exercise] = lastDate;
    });
    return lastDates;
  }
}

// bool checkIfSameDayAsPredictive(DateTime lastDate) {
//   DateTime todayDateTime = DateTime.now();
//   DateTime todayDate = DateTime(todayDateTime.year, todayDateTime.month, todayDateTime.day);
//   if (todayDate == lastDate) {
//     return true;
//   }
//   return false;
// }