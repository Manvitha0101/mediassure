import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dashboard_screen.dart';

class SignupScreen extends StatefulWidget {
const SignupScreen({super.key});

@override
State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
final emailController = TextEditingController();
final passwordController = TextEditingController();
final nameController = TextEditingController();

bool isLoading = false;

@override
void dispose() {
emailController.dispose();
passwordController.dispose();
nameController.dispose();
super.dispose();
}

Future<void> registerUser() async {
final email = emailController.text.trim();
final password = passwordController.text.trim();
final name = nameController.text.trim();


// ✅ Validation
if (email.isEmpty || password.isEmpty || name.isEmpty) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text("All fields required")),
  );
  return;
}

if (password.length < 6) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text("Password must be at least 6 characters")),
  );
  return;
}

setState(() => isLoading = true);

try {
  final userCredential = await FirebaseAuth.instance
      .createUserWithEmailAndPassword(
    email: email,
    password: password,
  );

  final uid = userCredential.user!.uid;

  // ✅ Store in Firestore
  await FirebaseFirestore.instance.collection('users').doc(uid).set({
    'name': name,
    'email': email,
    'createdAt': Timestamp.now(),
  });

  if (!mounted) return;

  Navigator.pushReplacement(
    context,
    MaterialPageRoute(
      builder: (_) => const DashboardScreen(),
    ),
  );
} on FirebaseAuthException catch (e) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(e.message ?? "Signup failed")),
  );
} catch (e) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text("Something went wrong")),
  );
}

if (mounted) setState(() => isLoading = false);


}

@override
Widget build(BuildContext context) {
return Scaffold(
appBar: AppBar(title: const Text("Create Account")),
body: SingleChildScrollView(
padding: const EdgeInsets.all(20),
child: Column(
children: [
TextField(
controller: nameController,
decoration: const InputDecoration(labelText: "Name"),
),
const SizedBox(height: 12),


        TextField(
          controller: emailController,
          decoration: const InputDecoration(labelText: "Email"),
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 12),

        TextField(
          controller: passwordController,
          decoration: const InputDecoration(labelText: "Password"),
          obscureText: true,
        ),

        const SizedBox(height: 20),

        ElevatedButton(
          onPressed: isLoading ? null : registerUser,
          child: isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text("Sign Up"),
        ),
      ],
    ),
  ),
);


}
}
