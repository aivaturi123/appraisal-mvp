import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'auth/login_screen.dart';
import 'auth/employee_login.dart';
import 'auth/manager_login.dart';
import 'screens/employee/employee_dashboard.dart';
import 'screens/employee/self_evaluation_form.dart';
import 'screens/manager/manager_dashboard.dart';
import 'screens/manager/evaluate_employee.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(EmployeeEvalApp());
}

class EmployeeEvalApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Employee Evaluation System',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Color(0xFF0047BB),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      initialRoute: '/',
      onGenerateRoute: (settings) {
        try {
          // Helper function to safely convert arguments
          Map<String, dynamic> getSafeArgs(dynamic rawArgs) {
            if (rawArgs == null) return <String, dynamic>{};
            
            if (rawArgs is Map<String, dynamic>) {
              return rawArgs;
            } else if (rawArgs is Map) {
              return Map<String, dynamic>.from(
                rawArgs.map((key, value) => MapEntry(key.toString(), value))
              );
            }
            return <String, dynamic>{};
          }

          final args = getSafeArgs(settings.arguments);

          switch (settings.name) {
            case '/':
              return MaterialPageRoute(builder: (_) => LoginScreen());

            case '/employee-login':
              return MaterialPageRoute(builder: (_) => EmployeeLogin());

            case '/manager-login':
              return MaterialPageRoute(builder: (_) => ManagerLogin());

            case '/employee-dashboard':
              return MaterialPageRoute(
                builder: (_) => EmployeeDashboard(
                  employeeName: args['employeeName'] ?? 'Unknown Employee'
                ),
              );

            case '/self-evaluation':
              return MaterialPageRoute(
                builder: (_) => SelfEvaluationForm(
                  employeeName: args['employeeName'] ?? 'Unknown Employee'
                ),
              );

            case '/manager-dashboard':
              return MaterialPageRoute(builder: (_) => ManagerDashboard());

            case '/evaluate-employee':
              if (args.isNotEmpty) {
                return MaterialPageRoute(
                  builder: (_) => EvaluateEmployeeScreen(evaluation: args),
                );
              } else {
                return MaterialPageRoute(
                  builder: (_) => Scaffold(
                    body: Center(
                      child: Text('❌ Invalid arguments for evaluate-employee')
                    ),
                  ),
                );
              }

            default:
              return MaterialPageRoute(
                builder: (_) => Scaffold(
                  body: Center(child: Text('Unknown route: ${settings.name}')),
                ),
              );
          }
        } catch (e) {
          print('Route error: $e'); // For debugging
          return MaterialPageRoute(
            builder: (_) => Scaffold(
              body: Center(child: Text('❌ Route error: $e')),
            ),
          );
        }
      },
    );
  }
}