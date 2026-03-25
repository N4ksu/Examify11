import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../shared/providers/auth_provider.dart';
import '../../shared/models/user.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool remember = true;
  bool hidePassword = true;

  void _login() async {
    if (_formKey.currentState!.validate()) {
      final success = await ref
          .read(authProvider.notifier)
          .login(_emailController.text, _passwordController.text);

      if (!mounted) return;

      if (success) {
        final user = ref.read(authProvider).user;
        if (user?.role == UserRole.teacher) {
          context.go('/teacher');
        } else {
          context.go('/student');
        }
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Widget outlinedText({
    required String text,
    required double size,
    required Color fillColor,
    required Color strokeColor,
    required double strokeWidth,
    FontWeight weight = FontWeight.w900,
    String? fontFamily,
    double letterSpacing = 0,
  }) {
    return Stack(
      children: [
        Text(
          text,
          style: TextStyle(
            fontFamily: fontFamily,
            fontSize: size,
            fontWeight: weight,
            letterSpacing: letterSpacing,
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = strokeWidth
              ..color = strokeColor,
          ),
        ),
        Text(
          text,
          style: TextStyle(
            fontFamily: fontFamily,
            fontSize: size,
            fontWeight: weight,
            letterSpacing: letterSpacing,
            color: fillColor,
          ),
        ),
      ],
    );
  }

  Widget buildField({
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    bool obscureText = false,
    Widget? trailing,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(
          color: Colors.black,
          width: 1.6,
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 8),
          Container(
            width: 28,
            height: 28,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: Colors.black,
              size: 16,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 1.2,
            height: 24,
            color: Colors.black,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Theme(
              data: Theme.of(context).copyWith(
                textSelectionTheme:
                    const TextSelectionThemeData(selectionColor: Colors.transparent),
              ),
              child: TextFormField(
                controller: controller,
                obscureText: obscureText,
                keyboardType: keyboardType,
                validator: validator,
                cursorColor: Colors.black,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
                decoration: InputDecoration(
                  isDense: true,
                  hintText: hint,
                  hintStyle: const TextStyle(
                    color: Color(0xFF555555),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                  border: InputBorder.none,
                  filled: true,
                  fillColor: Colors.white,
                  focusedBorder: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ),
          if (trailing != null)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: trailing,
            ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/login_bg.png',
              fit: BoxFit.cover,
            ),
          ),

          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 4.8, sigmaY: 4.8),
              child: Container(
                color: Colors.black.withOpacity(0.07),
              ),
            ),
          ),

          Positioned(
            top: 28,
            left: 34,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Image.asset(
                  'assets/jmc_logo.png',
                  height: 48,
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    outlinedText(
                      text: 'JOSE MARIA COLLEGE',
                      size: 13.5,
                      fontFamily: 'OldEnglish',
                      fillColor: Colors.white,
                      strokeColor: const Color(0xFFB327FF),
                      strokeWidth: 1.4,
                      letterSpacing: 0.2,
                    ),
                    const SizedBox(height: 1),
                    Padding(
                      padding: const EdgeInsets.only(left: 52),
                      child: outlinedText(
                        text: 'FOUNDATION, INC.',
                        size: 6.6,
                        fillColor: const Color(0xFFFF2E2E),
                        strokeColor: Colors.white,
                        strokeWidth: 0.8,
                        weight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Padding(
                      padding: const EdgeInsets.only(left: 11),
                      child: outlinedText(
                        text: 'Assured • Consistent • Quality Education',
                        size: 5.9,
                        fillColor: const Color(0xFF4E30FF),
                        strokeColor: Colors.white,
                        strokeWidth: 0.7,
                        weight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Container(
                width: 340,
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFF21A6FF),
                    width: 1.2,
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFF5754D9).withOpacity(0.72),
                      const Color(0xFFD564BF).withOpacity(0.68),
                      const Color(0xFF5E436D).withOpacity(0.74),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.18),
                      blurRadius: 14,
                      offset: const Offset(0, 7),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset(
                            'assets/cite_logo.png',
                            height: 100,
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'XExamify',
                            style: TextStyle(
                              color: Color(0xFF5A285A),
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 16),

                          if (authState.error != null) ...[
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text(
                                authState.error!,
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],

                          buildField(
                            controller: _emailController,
                            icon: Icons.person,
                            hint: 'Email',
                            keyboardType: TextInputType.emailAddress,
                            validator: (v) =>
                                v == null || v.isEmpty ? 'Enter email' : null,
                          ),
                          const SizedBox(height: 12),

                          buildField(
                            controller: _passwordController,
                            icon: Icons.lock,
                            hint: 'Password',
                            obscureText: hidePassword,
                            trailing: IconButton(
                              padding: EdgeInsets.zero,
                              splashRadius: 18,
                              onPressed: () {
                                setState(() {
                                  hidePassword = !hidePassword;
                                });
                              },
                              icon: Icon(
                                hidePassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: Colors.black,
                                size: 16,
                              ),
                            ),
                            validator: (v) => v == null || v.isEmpty
                                ? 'Enter password'
                                : null,
                          ),

                          const SizedBox(height: 10),

                          Row(
                            children: [
                              SizedBox(
                                width: 28,
                                height: 28,
                                child: Checkbox(
                                  value: remember,
                                  onChanged: (v) {
                                    setState(() {
                                      remember = v ?? false;
                                    });
                                  },
                                  activeColor: Colors.black,
                                  checkColor: Colors.white,
                                  side: const BorderSide(
                                    color: Colors.black,
                                    width: 1.4,
                                  ),
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                              ),
                              const SizedBox(width: 10),
                              const Text(
                                'Remember me',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),

                          SizedBox(
                            width: 120,
                            height: 36,
                            child: ElevatedButton(
                              onPressed: authState.isLoading ? null : _login,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFA0005E),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24),
                                ),
                              ),
                              child: authState.isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.3,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text(
                                      'Log in',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                            ),
                          ),

                          const SizedBox(height: 14),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                "Don't have account? ",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              GestureDetector(
                                onTap: () => context.go('/register'),
                                child: outlinedText(
                                  text: 'Sign up',
                                  size: 11,
                                  fillColor: const Color(0xFFD91A7A),
                                  strokeColor: const Color.fromARGB(255, 146, 92, 121),
                                  strokeWidth: 1.0,
                                  weight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}