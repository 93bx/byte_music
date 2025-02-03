import 'package:byte_player/utils/nav.dart';
import 'package:flutter/material.dart';
import 'package:byte_player/services/api_service.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  SignInPageState createState() => SignInPageState();
}

class SignInPageState extends State<SignInPage> {
  bool _isSigningIn = false;

  Future<void> _handleSignIn() async {
    setState(() => _isSigningIn = true);

    try {
      bool isAuthenticated = await ApiService.authenticate() != null;
      if (isAuthenticated) {
        if (mounted){
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => Nav())
          );
        }
      } else {
        print('Authentication failed or canceled.');
      }
    } catch (e) {
      print('Error Signin in: $e');
    } finally {
      setState(() => _isSigningIn = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _isSigningIn
          ? CircularProgressIndicator()
          : ElevatedButton(onPressed: _handleSignIn, child: Text('Sign In')),
      )
    );
  }
}
