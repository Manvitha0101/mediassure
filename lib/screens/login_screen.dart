import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'dashboard_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

 void _onLogin() async {
final email = _emailController.text.trim();
final password = _passwordController.text.trim();

// ✅ Validation
if (email.isEmpty || password.isEmpty) {
ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(content: Text("Email and Password cannot be empty")),
);
return;
}

setState(() => _isLoading = true);

try {
final userCredential = await FirebaseAuth.instance
.signInWithEmailAndPassword(
email: email,
password: password,
);


if (!mounted) return;

if (userCredential.user != null) {
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(
      builder: (_) => const DashboardScreen(),
    ),
  );
}


} on FirebaseAuthException catch (e) {
String message = "Login failed";


if (e.code == 'user-not-found') {
  message = "No user found for this email";
} else if (e.code == 'wrong-password') {
  message = "Incorrect password";
} else if (e.code == 'invalid-email') {
  message = "Invalid email format";
}

ScaffoldMessenger.of(context)
    .showSnackBar(SnackBar(content: Text(message)));


} catch (e) {
ScaffoldMessenger.of(context)
.showSnackBar(const SnackBar(content: Text("Something went wrong")));
}

if (mounted) {
setState(() => _isLoading = false);
}
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 56),
              _LoginHeader(),
              const SizedBox(height: 40),
              _LoginForm(
                emailController: _emailController,
                passwordController: _passwordController,
                obscurePassword: _obscurePassword,
                onToggleObscure: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
              const SizedBox(height: 12),
              _ForgotPasswordLink(),
              const SizedBox(height: 32),
              PrimaryButton(
                label: 'Login',
                onPressed: _onLogin,
                isLoading: _isLoading,
              ),
              const SizedBox(height: 40),
              _CreateAccountRow(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoginHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0ABFBC), Color(0xFF087F7D)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.favorite_rounded,
              color: Colors.white, size: 28),
        ),
        const SizedBox(height: 28),
        Text('Welcome Back', style: AppTextStyles.headingLarge),
        const SizedBox(height: 6),
        Text(
          'Sign in to continue managing your health',
          style: AppTextStyles.bodyMedium,
        ),
      ],
    );
  }
}

class _LoginForm extends StatelessWidget {
  const _LoginForm({
    required this.emailController,
    required this.passwordController,
    required this.obscurePassword,
    required this.onToggleObscure,
  });

  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final VoidCallback onToggleObscure;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppTextField(
          controller: emailController,
          label: 'Email Address',
          hint: 'you@example.com',
          keyboardType: TextInputType.emailAddress,
          prefixIcon: Icons.mail_outline_rounded,
        ),
        const SizedBox(height: 20),
        AppTextField(
          controller: passwordController,
          label: 'Password',
          hint: '••••••••',
          obscureText: obscurePassword,
          prefixIcon: Icons.lock_outline_rounded,
          suffixIcon: IconButton(
            icon: Icon(
              obscurePassword
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              color: AppColors.textSecondary,
              size: 20,
            ),
            onPressed: onToggleObscure,
          ),
        ),
      ],
    );
  }
}

class _ForgotPasswordLink extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: () {},
        style: TextButton.styleFrom(
          foregroundColor: AppColors.teal,
          padding: EdgeInsets.zero,
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Text(
          'Forgot password?',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.teal,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _CreateAccountRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text("Don't have an account? ", style: AppTextStyles.bodyMedium),
        TextButton(
          onPressed: () {},
          style: TextButton.styleFrom(
            foregroundColor: AppColors.teal,
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            'Create Account',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.teal,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}