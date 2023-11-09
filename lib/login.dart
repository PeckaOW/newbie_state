import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'main.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final _formKey = GlobalKey<FormState>();
  String _email = '';
  String _password = '';

  void _login() async {
    // Check if the form is valid
    if (_formKey.currentState != null && _formKey.currentState!.validate()) {
      // Call save on the form to save the form fields to the state variables
      _formKey.currentState!.save();
      try {
        await _auth.signInWithEmailAndPassword(
            email: _email, password: _password);
        print('complete');
        Navigator.push(
            context, MaterialPageRoute(builder: (context) => ToDoPage()));
        // Navigate to your home screen
        // Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => HomeScreen()));
      } on FirebaseAuthException catch (e) {
        // Handle error by showing a message to the user
        final snackBar = SnackBar(
            content: Text(e.message ?? 'An error occurred during login.'));
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Login')),
      body: Form(
        key: _formKey,
        child: Column(
          children: <Widget>[
            TextFormField(
              decoration: InputDecoration(labelText: 'Email'),
              validator: (value) =>
                  value != null && value.isEmpty ? 'Enter your email' : null,
              onSaved: (value) => _email = value ?? '',
            ),
            TextFormField(
              decoration: InputDecoration(labelText: 'Password'),
              obscureText: true,
              validator: (value) =>
                  value != null && value.isEmpty ? 'Enter your password' : null,
              onSaved: (value) => _password = value ?? '',
            ),
            ElevatedButton(
              onPressed: _login,
              child: Text('Login'),
            ),
          ],
        ),
      ),
    );
  }
}
