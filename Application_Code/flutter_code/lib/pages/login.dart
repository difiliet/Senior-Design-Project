import 'package:applicants/DataModels/userSettings.dart';
import 'package:applicants/SQLite/databaseHelper.dart';
import 'package:applicants/logic/predictive.dart';
import 'package:applicants/main.dart';
import 'package:applicants/pages/signup.dart';
import 'package:flutter/material.dart';
import 'package:applicants/JsonModels/user.dart';
import 'package:applicants/JsonModels/userLogEntry.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  late Future<List<UserLogEntry>> logEntryList;
  List<UserLogEntry>? entries;
  Map<String, List<int>>? predictive;
  Map<String, DateTime>? lastDatesOfEachExercise;
  final db = DatabaseHelper();
  final formKey = GlobalKey<FormState>();
  int loginAttempts = 0;
  final username = TextEditingController();
  final password = TextEditingController();
  bool isVisable = false;

  login() async {
    bool response = await db.login(User(username: username.text, password: password.text));
    
    if (response) {
      User userInformation = await db.getUserSettings(username.text);
      if (!mounted) return;
      List<UserLogEntry> fetchedEntries = await getUserLogEntries(username.text);
      entries = fetchedEntries;
      predictive = predict(processData(entries));
      lastDatesOfEachExercise = lastDateOfEachMovement(processData(entries));
      UserSettings passUserSettings = UserSettings(
        predictionsEnabled: userInformation.predictionsEnabled!, 
        primaryColor: UserSettings.getPrimaryColorValue(userInformation.primaryColor!), 
        secondaryColor: UserSettings.getPrimaryColorValue(userInformation.secondaryColor!),
        data: entries,
        predictive: predictive!,
        lastDate: lastDatesOfEachExercise!
      );

      Navigator.pushReplacement(
        context, 
        MaterialPageRoute(
          builder: (context) => MainPage(username.text, passUserSettings)
        )
      );
    } else {
      setState(() {
        loginAttempts += 1;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Form(
              key: formKey,
              child: Column(
                children: [

                  // Username field
                  Container(
                    margin: EdgeInsets.all(8),
                    padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.blue.withOpacity(.3)
                    ),
                    child: TextFormField(
                      controller: username,
                      validator: (value) {
                        if (value!.isEmpty) {
                          return "username is required";
                        }
                        return null;
                      },
                      decoration: const InputDecoration(
                        icon: Icon(Icons.person),
                        border: InputBorder.none,
                        label: Text("Username"),
                      ),
                    ),
                  ),

                  // Password field
                  Container(
                    margin: EdgeInsets.all(8),
                    padding: 
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.blue.withOpacity(.3)),
                    child: TextFormField(
                      controller: password,
                      validator: (value) {
                        if (value!.isEmpty) {
                          return "password is required";
                        }
                        return null;
                      },
                      obscureText: !isVisable,
                      decoration: InputDecoration(
                        icon: Icon(Icons.lock),
                        border: InputBorder.none,
                        hintText: "Password",
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(() {
                              isVisable = !isVisable;
                            });
                          },
                          icon: Icon(isVisable ? Icons.visibility : Icons.visibility_off)
                        )
                      ),
                    ),
                  ),

                  // Login button
                  Container(
                    height: 60,
                    width: MediaQuery.of(context).size.width * .3,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.blue
                    ),
                    child: TextButton(
                      onPressed: () {
                        if (formKey.currentState!.validate()) {
                          login();
                        }
                      },
                      child: const Text(
                        "LOGIN",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),

                  // Sign up button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Don't have an account?"),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context, 
                            MaterialPageRoute(
                              builder: (context) => const SignUpPage()
                            )
                          );
                        },
                        child: const Text("Sign up")
                      )
                    ],
                  ),

                  (loginAttempts > 0) ? const Text("Username or password is incorrect", style: TextStyle(color: Colors.red)) : const SizedBox(),

                ]
              ),
            ),
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