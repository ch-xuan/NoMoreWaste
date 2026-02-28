import 'package:flutter/material.dart';
import '../../../core/widgets/nmw_text_field.dart';
import '../../../data/models/user_role.dart';
import '../../../core/services/image_service.dart';

class UnifiedAuthScreen extends StatefulWidget {
  const UnifiedAuthScreen({
    super.key,
    required this.onLogin,
    required this.onSignUp,
    required this.onForgotPassword,
    required this.onGoogleLogin,
  });

  final Future<void> Function({
    required String email,
    required String password,
  }) onLogin;

  final Future<void> Function({
    required String fullNameOrOrg,
    required String email,
    required String password,
    required String phone,
    required UserRole role,
    String? verificationDocBase64,
    String? verificationDocFilename,
    int? verificationDocSize,
  }) onSignUp;

  final Future<void> Function(String email) onForgotPassword;
  final Future<void> Function() onGoogleLogin;

  @override
  State<UnifiedAuthScreen> createState() => _UnifiedAuthScreenState();
}

class _UnifiedAuthScreenState extends State<UnifiedAuthScreen> {
  bool isLogin = true;

  // Step 1: Details
  final _fullNameOrOrg = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _phone = TextEditingController();

  // Step 2 & 3: Role & Docs
  UserRole? _selectedRole;
  final _imageService = ImageService();
  String? _verificationDocBase64;
  String? _verificationDocFilename;
  int? _verificationDocSize;
  
  bool _isProcessingImage = false;
  bool _obscure = true;
  bool _loading = false;

  // Flow State
  // 0: Details, 1: Role Select, 2: Verification Doc
  int _signupStep = 0; 

  @override
  void dispose() {
    _fullNameOrOrg.dispose();
    _email.dispose();
    _password.dispose();
    _phone.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────
  // Validation helpers
  // ─────────────────────────────────────────────
  String? _validateEmail(String v) {
    final value = v.trim();
    final emailRegex = RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+");
    if (value.isEmpty) return 'Email is required.';
    if (!emailRegex.hasMatch(value)) return 'Please enter a valid email address.';
    return null;
  }

  String? _validatePassword(String v) {
    if (v.isEmpty) return 'Password is required.';
    if (v.length < 7) return 'Password must be at least 7 characters.';
    final letters = RegExp(r'[A-Za-z]').allMatches(v).length;
    final hasNumber = RegExp(r'\d').hasMatch(v);
    final hasSpecial = RegExp(r'[^A-Za-z0-9]').hasMatch(v);
    if (letters < 3) return 'Password must include at least 3 letters.';
    if (!hasNumber) return 'Password must include at least 1 number.';
    if (!hasSpecial) return 'Password must include at least 1 special character.';
    return null;
  }

  String? _validateRequired(String v, String label) {
    if (v.trim().isEmpty) return '$label is required.';
    return null;
  }

  String? _validatePhone(String v) {
    final value = v.trim();
    if (value.isEmpty) return 'Phone number is required.';
    if (value.length < 8) return 'Please enter a valid phone number.';
    return null;
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  String _friendlyError(Object e) {
    final msg = e.toString();
    if (msg.contains('email-already-in-use')) return 'This email is already registered.';
    if (msg.contains('wrong-password') || msg.contains('invalid-credential')) return 'Incorrect email or password.';
    if (msg.contains('user-not-found')) return 'No account found for this email.';
    if (msg.contains('invalid-email')) return 'Invalid email format.';
    if (msg.contains('weak-password')) return 'Password is too weak.';
    if (msg.contains('cancelled') || msg.contains('canceled')) return 'Sign-in cancelled.';
    return 'Something went wrong. Please try again.';
  }

  // ─────────────────────────────────────────────
  // Flow Actions
  // ─────────────────────────────────────────────

  void _nextSignupStep() {
    if (_signupStep == 0) {
      // Validate Step 1
      final nameErr = _validateRequired(_fullNameOrOrg.text, 'Name');
      if (nameErr != null) { _toast(nameErr); return; }
      
      final emailErr = _validateEmail(_email.text);
      if (emailErr != null) { _toast(emailErr); return; }

      final passErr = _validatePassword(_password.text);
      if (passErr != null) { _toast(passErr); return; }

      final phoneErr = _validatePhone(_phone.text);
      if (phoneErr != null) { _toast(phoneErr); return; }

      setState(() => _signupStep = 1);
    } else if (_signupStep == 1) {
      if (_selectedRole == null) {
        _toast('Please select a role to continue.');
        return;
      }
      setState(() => _signupStep = 2);
    }
  }

  void _prevSignupStep() {
    if (_signupStep > 0) {
      setState(() => _signupStep--);
    }
  }

  Future<void> _submitLogin() async {
    final emailErr = _validateEmail(_email.text);
    if (emailErr != null) { _toast(emailErr); return; }

    final passErr = _validateRequired(_password.text, 'Password');
    if (passErr != null) { _toast(passErr); return; }

    setState(() => _loading = true);
    try {
      await widget.onLogin(
        email: _email.text.trim(),
        password: _password.text,
      );
    } catch (e) {
      _toast(_friendlyError(e));
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submitSignup() async {
    if (_signupStep < 2) {
      _nextSignupStep();
      return;
    }

    if (_verificationDocBase64 == null) {
      _toast('Please upload the required verification document.');
      return;
    }

    setState(() => _loading = true);
    try {
      await widget.onSignUp(
        fullNameOrOrg: _fullNameOrOrg.text.trim(),
        email: _email.text.trim(),
        password: _password.text,
        phone: _phone.text.trim(),
        role: _selectedRole!,
        verificationDocBase64: _verificationDocBase64,
        verificationDocFilename: _verificationDocFilename,
        verificationDocSize: _verificationDocSize,
      );
    } catch (e) {
      _toast(_friendlyError(e));
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _forgotPassword() async {
    final emailErr = _validateEmail(_email.text);
    if (emailErr != null) {
      _toast(emailErr);
      return;
    }

    setState(() => _loading = true);
    try {
      await widget.onForgotPassword(_email.text.trim());
      _toast('Password reset email sent. Check your inbox.');
    } catch (e) {
      _toast(_friendlyError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _googleLogin() async {
    setState(() => _loading = true);
    try {
      await widget.onGoogleLogin();
    } catch (e) {
      _toast(_friendlyError(e));
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickDocument() async {
    setState(() => _isProcessingImage = true);
    try {
      final file = await _imageService.pickImage();
      if (file != null) {
        final bytes = await file.readAsBytes();
        final base64 = await _imageService.compressAndConvert(file);
        if (!mounted) return;
        setState(() {
          _verificationDocBase64 = base64;
          _verificationDocFilename = file.name;
          _verificationDocSize = bytes.length;
        });
        _toast('Document uploaded successfully!');
      }
    } catch (e) {
      _toast(e.toString().replaceAll('Exception: ', ''));
    } finally {
      setState(() => _isProcessingImage = false);
    }
  }

  // ─────────────────────────────────────────────
  // UI Builders
  // ─────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final bg = const Color(0xFFF7FAF9);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        leading: (!isLogin && _signupStep > 0 && !_loading) 
          ? IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, size: 18),
              onPressed: _prevSignupStep,
            )
          : null,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                const Text(
                  'Welcome!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1B7F5A),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  isLogin ? 'Sign in to your account' : 'Create a new account',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 24),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: const [
                      BoxShadow(
                        blurRadius: 20,
                        offset: Offset(0, 8),
                        color: Color(0x0A000000),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Only show tabs if we are on step 0 of signup or on login
                      if (isLogin || _signupStep == 0) ...[
                        _SegmentedTabs(
                          leftText: 'Login',
                          rightText: 'Sign Up',
                          isLeftSelected: isLogin,
                          onChanged: (login) {
                            setState(() {
                              isLogin = login;
                              _signupStep = 0; // Reset signup on tab switch
                            });
                          },
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Form Content
                      if (isLogin) 
                        _buildLoginForm()
                      else 
                        _buildSignupContent(),

                      const SizedBox(height: 20),

                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _loading ? null : (isLogin ? _submitLogin : _submitSignup),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF1B7F5A), // Leaf green default
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: _loading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : Text(
                                  isLogin 
                                    ? 'Login' 
                                    : (_signupStep < 2 ? 'Continue' : 'Create Account'),
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                        ),
                      ),

                      // Google Login only on initial screens
                      if (isLogin || _signupStep == 0) ...[
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(child: Divider(color: Colors.black.withOpacity(0.1))),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Text(
                                'OR',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black.withOpacity(0.3),
                                ),
                              ),
                            ),
                            Expanded(child: Divider(color: Colors.black.withOpacity(0.1))),
                          ],
                        ),
                        const SizedBox(height: 20),
                        OutlinedButton.icon(
                          onPressed: _loading ? null : _googleLogin,
                          icon: Image.asset('assets/icons/google.png', height: 20, width: 20),
                          label: const Text('Continue with Google', style: TextStyle(fontWeight: FontWeight.bold)),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            side: BorderSide(color: Colors.black.withOpacity(0.1)),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginForm() {
    return Column(
      children: [
        NmwTextField(
          controller: _email,
          label: 'Email',
          hint: 'your@email.com',
          keyboardType: TextInputType.emailAddress,
          prefixIcon: Icons.email_outlined,
        ),
        const SizedBox(height: 16),
        NmwTextField(
          controller: _password,
          label: 'Password',
          hint: '••••••••',
          prefixIcon: Icons.lock_outline,
          obscureText: _obscure,
          suffixIcon: IconButton(
            onPressed: () => setState(() => _obscure = !_obscure),
            icon: Icon(
              _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              size: 20,
            ),
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: _loading ? null : _forgotPassword,
            child: const Text('Forgot password?'),
          ),
        ),
      ],
    );
  }

  Widget _buildSignupContent() {
    if (_signupStep == 0) {
      return Column(
        children: [
          NmwTextField(
            controller: _fullNameOrOrg,
            label: 'Full Name / Organization Name',
            hint: 'Enter your name',
            prefixIcon: Icons.person_outline,
          ),
          const SizedBox(height: 16),
          NmwTextField(
            controller: _email,
            label: 'Email',
            hint: 'your@email.com',
            keyboardType: TextInputType.emailAddress,
            prefixIcon: Icons.email_outlined,
          ),
          const SizedBox(height: 16),
          NmwTextField(
            controller: _phone,
            label: 'Phone Number',
            hint: '+60 12-345 6789',
            keyboardType: TextInputType.phone,
            prefixIcon: Icons.phone_outlined,
          ),
          const SizedBox(height: 16),
          NmwTextField(
            controller: _password,
            label: 'Password',
            hint: '••••••••',
            prefixIcon: Icons.lock_outline,
            obscureText: _obscure,
            suffixIcon: IconButton(
              onPressed: () => setState(() => _obscure = !_obscure),
              icon: Icon(
                _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                size: 20,
              ),
            ),
          ),
        ],
      );
    } else if (_signupStep == 1) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Choose your role',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            'How would you like to use NoMoreWaste?',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 20),
          _RoleOptionCard(
            role: UserRole.donor,
            title: 'Donor',
            subtitle: 'Donate surplus food (e.g. restaurant, cafe)',
            iconAsset: 'assets/icons/donor_shop.png',
            iconBg: const Color(0xFFDEF7EC),
            borderColor: const Color(0xFF9AE6B4),
            isSelected: _selectedRole == UserRole.donor,
            onTap: () => setState(() => _selectedRole = UserRole.donor),
          ),
          const SizedBox(height: 12),
          _RoleOptionCard(
            role: UserRole.ngo,
            title: 'NGO / Charity',
            subtitle: 'Request and distribute food to those in need',
            iconAsset: 'assets/icons/ngo_love.png',
            iconBg: const Color(0xFFFFEDD5),
            borderColor: const Color(0xFFFCD9BD),
            isSelected: _selectedRole == UserRole.ngo,
            onTap: () => setState(() => _selectedRole = UserRole.ngo),
          ),
          const SizedBox(height: 12),
          _RoleOptionCard(
            role: UserRole.volunteer,
            title: 'Volunteer',
            subtitle: 'Help transport food from donors to NGOs',
            iconAsset: 'assets/icons/volunteer_truck.png',
            iconBg: const Color(0xFFDBEAFE),
            borderColor: const Color(0xFFC3DAFE),
            isSelected: _selectedRole == UserRole.volunteer,
            onTap: () => setState(() => _selectedRole = UserRole.volunteer),
          ),
        ],
      );
    } else if (_signupStep == 2) {
      String getDocLabel() {
        switch (_selectedRole!) {
          case UserRole.donor: return 'Business License / Hygiene Rating';
          case UserRole.ngo: return 'NGO Registration Certificate';
          case UserRole.volunteer: return 'Volunteer ID / Proof of Identity';
        }
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Verify your identity',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            'Please provide the following document for verification to join as a ${_selectedRole!.label}',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 24),
          
          Text(
            getDocLabel(),
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _loading || _isProcessingImage ? null : _pickDocument,
            icon: _isProcessingImage 
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : Icon(
                  _verificationDocBase64 != null ? Icons.check_circle : Icons.upload_file,
                  color: _verificationDocBase64 != null ? Colors.green : Colors.black87,
                ),
            label: Text(
              _verificationDocBase64 != null 
                  ? 'Document Uploaded' 
                  : 'Tap to Upload',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: _verificationDocBase64 != null ? Colors.green : Colors.black87,
              ),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 24),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              side: BorderSide(
                width: 2,
                color: _verificationDocBase64 != null 
                    ? Colors.green 
                    : Colors.black.withOpacity(0.1),
              ),
              backgroundColor: _verificationDocBase64 != null 
                  ? Colors.green.withOpacity(0.05) 
                  : Colors.grey.shade50,
            ),
          ),
        ],
      );
    }
    return const SizedBox();
  }
}

class _RoleOptionCard extends StatelessWidget {
  const _RoleOptionCard({
    required this.role,
    required this.title,
    required this.subtitle,
    required this.iconAsset,
    required this.iconBg,
    required this.borderColor,
    required this.isSelected,
    required this.onTap,
  });

  final UserRole role;
  final String title;
  final String subtitle;
  final String iconAsset;
  final Color iconBg;
  final Color borderColor;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? borderColor.withOpacity(0.2) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? borderColor.withOpacity(0.8) : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              height: 48,
              width: 48,
              decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
              padding: const EdgeInsets.all(10),
              child: Image.asset(iconAsset, fit: BoxFit.contain),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                ],
              ),
            ),
            if (isSelected) 
              Icon(Icons.check_circle, color: borderColor.withOpacity(0.8)),
          ],
        ),
      ),
    );
  }
}

class _SegmentedTabs extends StatelessWidget {
  const _SegmentedTabs({
    required this.leftText,
    required this.rightText,
    required this.isLeftSelected,
    required this.onChanged,
  });

  final String leftText;
  final String rightText;
  final bool isLeftSelected;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F2F4),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          Expanded(
            child: _SegButton(
              text: leftText,
              selected: isLeftSelected,
              onTap: () => onChanged(true),
            ),
          ),
          Expanded(
            child: _SegButton(
              text: rightText,
              selected: !isLeftSelected,
              onTap: () => onChanged(false),
            ),
          ),
        ],
      ),
    );
  }
}

class _SegButton extends StatelessWidget {
  const _SegButton({
    required this.text,
    required this.selected,
    required this.onTap,
  });

  final String text;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          boxShadow: selected
              ? const [
                  BoxShadow(
                    blurRadius: 10,
                    offset: Offset(0, 4),
                    color: Color(0x12000000),
                  ),
                ]
              : null,
        ),
        child: Text(
          text,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black.withOpacity(selected ? 0.9 : 0.5),
          ),
        ),
      ),
    );
  }
}
