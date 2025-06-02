import 'package:flutter/material.dart';
import '/services/auth_service.dart';

class EmployeeLogin extends StatefulWidget {
  @override
  _EmployeeLoginState createState() => _EmployeeLoginState();
}

class _EmployeeLoginState extends State<EmployeeLogin> with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  late AnimationController _controller;
  late Animation<double> _fadeIn;
  late Animation<Offset> _slideIn;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500),
    );

    _fadeIn = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _slideIn = Tween<Offset>(begin: Offset(0, 0.2), end: Offset.zero)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
   
    super.dispose();
  }

  void _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final name = _nameController.text.trim();
  

    if (email.isEmpty || password.isEmpty ||  name.isEmpty ) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('⚠️ Please fill in all fields')),
      );
      return;
    }

    final user = await AuthService().signIn(email, password);
    if (user != null) {
      Navigator.pushNamed(
        context,
        '/employee-dashboard',
        arguments: {
          'employeeName': name,
        },
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Login failed')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Employee Dashboard"),
        backgroundColor: Color(0xFF0047BB),
      ),
      body: Center(
        child: FadeTransition(
          opacity: _fadeIn,
          child: SlideTransition(
            position: _slideIn,
            child: Card(
              elevation: 6,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              margin: EdgeInsets.symmetric(horizontal: 24),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: 400),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.badge, size: 50, color:Color(0xFF0047BB)),
                      SizedBox(height: 16),
                      Text("Employee Login",
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0047BB)
)),
                      SizedBox(height: 16),
                      TextField(
  controller: _emailController,
  decoration: InputDecoration(labelText: "Email"),
  keyboardType: TextInputType.emailAddress,
  autocorrect: false,
),

TextField(
  controller: _passwordController,
  obscureText: true,
  decoration: InputDecoration(labelText: "Password"),
  autocorrect: false,
),

TextField(
  controller: _nameController,
  decoration: InputDecoration(labelText: "Full Name"),
  textCapitalization: TextCapitalization.words,
),

                      SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: _login,
                        icon: Icon(Icons.login),
                        label: Text("Continue"),
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
