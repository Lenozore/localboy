import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/driver_provider.dart';
import '../dashboard/driver_dashboard.dart';
import '../registration/document_upload_screen.dart';

class DriverOtpScreen extends StatefulWidget {
  final String phone;
  final String role;

  const DriverOtpScreen({super.key, required this.phone, required this.role});

  @override
  State<DriverOtpScreen> createState() => _DriverOtpScreenState();
}

class _DriverOtpScreenState extends State<DriverOtpScreen> {
  final List<TextEditingController> _controllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  @override
  void dispose() {
    for (var c in _controllers) { c.dispose(); }
    for (var f in _focusNodes) { f.dispose(); }
    super.dispose();
  }

  String get _otp => _controllers.map((c) => c.text).join();

  Future<void> _verify() async {
    if (_otp.length != 6) return;

    final provider = context.read<DriverProvider>();
    final result = await provider.verifyOtp(widget.phone, _otp);

    if (result != null && mounted) {
      final isNew = result['is_new_user'] == true;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => isNew ? DocumentUploadScreen(role: widget.role) : const DriverDashboard(),
        ),
        (route) => false,
      );
    } else if (mounted && provider.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.error!)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<DriverProvider>().isLoading;

    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, foregroundColor: Colors.black87),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            const Text('Verification', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Enter the code sent to ${widget.phone}', style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(6, (i) => SizedBox(
                width: 48, height: 56,
                child: TextField(
                  controller: _controllers[i],
                  focusNode: _focusNodes[i],
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(1)],
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 2)),
                  ),
                  onChanged: (v) {
                    if (v.isNotEmpty && i < 5) _focusNodes[i + 1].requestFocus();
                    if (v.isEmpty && i > 0) _focusNodes[i - 1].requestFocus();
                    if (_otp.length == 6) _verify();
                  },
                ),
              )),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity, height: 56,
              child: ElevatedButton(
                onPressed: isLoading ? null : _verify,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: isLoading
                    ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Verify', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
