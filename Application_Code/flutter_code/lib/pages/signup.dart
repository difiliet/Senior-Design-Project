import 'package:applicants/SQLite/databaseHelper.dart';
import 'package:applicants/pages/login.dart';
import 'package:flutter/material.dart';
import 'package:applicants/JsonModels/user.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpState();
}

class _SignUpState extends State<SignUpPage> {
  final formKey = GlobalKey<FormState>();
  final username = TextEditingController();
  final password = TextEditingController();
  final confirmPassword = TextEditingController();
  bool isVisable = false;
  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  
                  const ListTile(
                    title: Text(
                      "Create a new account",
                      style: TextStyle(fontSize: 35, fontWeight: FontWeight.bold), 
                    ),
                  ),

                  // Username field
                  Container(
                    margin: const EdgeInsets.all(8),
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
                    margin: const EdgeInsets.all(8),
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
                        icon: const Icon(Icons.lock),
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

                  // Confirm Password field
                  Container(
                    margin: const EdgeInsets.all(8),
                    padding: 
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.blue.withOpacity(.3)),
                    child: TextFormField(
                      controller: confirmPassword,
                      validator: (value) {
                        if (value!.isEmpty) {
                          return "password is required";
                        } else if (password.text != confirmPassword.text) {
                          return "Passwords must match";
                        }
                        return null;
                      },
                      obscureText: !isVisable,
                      decoration: InputDecoration(
                        icon: const Icon(Icons.lock),
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

                  // Sign up button
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
                          final db = DatabaseHelper();

                          db.signup(User(username: username.text, password: password.text)).whenComplete(() {
                            Navigator.push(
                              context, 
                              MaterialPageRoute(
                                builder: (context) => const LoginPage()
                              )
                            );
                          });
                        }
                      },
                      child: const Text(
                        "SIGN UP",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),

                  // Login button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Already have an account?"),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context, 
                            MaterialPageRoute(
                              builder: (context) => const LoginPage()
                            )
                          );
                        },
                        child: const Text("Login")
                      )
                    ],
                  ),


                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}