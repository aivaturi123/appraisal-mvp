import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  String? selectedRole;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
      lowerBound: 0.0,
      upperBound: 0.1,
    );

    _scaleAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _navigateToDashboard(String role) {
    if (role == 'employee') {
      Navigator.pushNamed(context, '/employee-login');
    } else if (role == 'manager') {
      Navigator.pushNamed(context, '/manager-login');
    }
  }

  Widget buildRoleButton(String role, IconData icon, Color color) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        _navigateToDashboard(role);
      },
      child: ScaleTransition(
        scale: Tween(begin: 1.0, end: 0.95).animate(_scaleAnimation),
        child: AnimatedContainer(
          duration: Duration(milliseconds: 200),
          margin: EdgeInsets.symmetric(vertical: 12),
          padding: EdgeInsets.symmetric(vertical: 18, horizontal: 24),
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 241, 234, 234),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 12,
                offset: Offset(0, 6),
              ),
            ],
            border: Border.all(color: color.withOpacity(0.4)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 26),
              SizedBox(width: 16),
              Text(
                role == 'employee' ? 'Login as Employee' : 'Login as Manager',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: Color.fromARGB(255, 255, 255, 255),
    body: Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 35),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/vdart_logo.png',
              width: 300,
              height: 200,
              fit: BoxFit.contain,
            ),
            SizedBox(height: 20),
            Text(
              'VDart Digital Performance Portal',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0047BB),
              ),
            ),
            SizedBox(height: 40),
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 280),
              child: Column(
                children: [
                  buildRoleButton('employee', Icons.person_outline, Colors.teal),
                  buildRoleButton('manager', Icons.supervisor_account_outlined, Colors.deepPurple),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
}
