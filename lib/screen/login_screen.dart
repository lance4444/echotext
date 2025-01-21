import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:only_audio/screen/chat_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _auth = FirebaseAuth.instance;
  final _formKey = GlobalKey<FormState>();
  
  var _isLogin = true;
  var _isLoading = false;
  var _userEmail = '';
  var _userPassword = '';

  void _submit() async {
    final isValid = _formKey.currentState!.validate();

    if (!isValid) {
      return;
    }

    _formKey.currentState!.save();

    setState(() {
      _isLoading = true;
    });

    try {
      if (_isLogin) {
        final userCredential = await _auth.signInWithEmailAndPassword(
          email: _userEmail,
          password: _userPassword,
        );
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              userId: userCredential.user!.uid,
              userName: _userEmail.split('@')[0], // Use email username as display name
            ),
          ),
        );
      } else {
        final userCredential = await _auth.createUserWithEmailAndPassword(
          email: _userEmail,
          password: _userPassword,
        );
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              userId: userCredential.user!.uid,
              userName: _userEmail.split('@')[0],
            ),
          ),
        );
      }
    } on FirebaseAuthException catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message ?? 'Authentication failed'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Echo Text'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Email Address',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  textCapitalization: TextCapitalization.none,
                  validator: (value) {
                    if (value == null || 
                        value.trim().isEmpty || 
                        !value.contains('@')) {
                      return 'Please enter a valid email address';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    _userEmail = value!;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.trim().length < 6) {
                      return 'Password must be at least 6 characters long';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    _userPassword = value!;
                  },
                ),
                const SizedBox(height: 12),
                if (_isLoading)
                  const CircularProgressIndicator()
                else
                  Column(
                    children: [
                      ElevatedButton(
                        onPressed: _submit,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(200, 50),
                        ),
                        child: Text(_isLogin ? 'Login' : 'Sign Up'),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _isLogin = !_isLogin;
                          });
                        },
                        child: Text(_isLogin
                            ? 'Create an account'
                            : 'I already have an account'),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
