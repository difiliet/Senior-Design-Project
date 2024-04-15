import 'package:applicants/DataModels/userSettings.dart';
import 'package:applicants/pages/history/history.dart';
import 'package:applicants/pages/login.dart';
import 'package:applicants/pages/cal.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'pages/entry.dart';
import 'pages/chart.dart';
import 'pages/settings.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
  return ChangeNotifierProvider(
      create: (context) => MyAppState(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Applicant\'s App',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        ),
        home: const LoginPage(),
      ),
    );
  }
}

class MyAppState extends ChangeNotifier {

}

class MainPage extends StatefulWidget {
  final String username;
  final UserSettings currentUserSettings;
  final int selectedPage;
  const MainPage(this.username, this.currentUserSettings, {this.selectedPage = 0, super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

// Menu
class _MainPageState extends State<MainPage> {
  var selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    selectedIndex = widget.selectedPage;
  }

  @override
  Widget build(BuildContext context) {
    Widget page;
    switch (selectedIndex) {
      case 0:
        page = EntryPage(widget.username, widget.currentUserSettings);
        break;
      case 1:
        page = ChartPage(widget.username, widget.currentUserSettings);
        break;
      case 2:
        page = HistoryPage(widget.username, widget.currentUserSettings);
        break;
      case 3:
        page = CalendarPage(widget.username, widget.currentUserSettings);
        break;
      case 4:
        page = SettingsPage(widget.username, widget.currentUserSettings);
        break;
      default:
        throw UnimplementedError('no widget for $selectedIndex');
    }

    return LayoutBuilder(builder: (context, constraints) {
      return Scaffold(
        body: Row(
          children: [
            SafeArea(
              child: NavigationRail(
                extended: constraints.maxWidth >= 600,
                destinations: const [
                  NavigationRailDestination(
                    icon: Icon(Icons.home),
                    label: Text('Home'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.bar_chart),
                    label: Text('Charts'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.view_timeline),
                    label: Text('History'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.calendar_today),
                    label: Text("Calendar")
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.settings),
                    label: Text('Settings'),
                  ),
                ],
                selectedIndex: selectedIndex,
                onDestinationSelected: (value) {
                  setState(() {
                    selectedIndex = value;
                  });
                },
              ),
            ),
            Expanded(
              child: Container(
                color: Theme.of(context).colorScheme.primaryContainer,
                child: page,
              ),
            ),
          ],
        ),
      );
    });
  }
}