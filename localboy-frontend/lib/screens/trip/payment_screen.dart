import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/api_service.dart';
import 'booking_confirmation_screen.dart';

class PaymentScreen extends StatefulWidget {
  final String bookingId;
  final double amount;
  final String tripTitle;
  final String date;
  final int guests;
  final String? orderId;

  const PaymentScreen({
    super.key,
    required this.bookingId,
    required this.amount,
    required this.tripTitle,
    required this.date,
    required this.guests,
    this.orderId,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final ApiService _api = ApiService();
  bool _isLoading = false;
  String _selectedMethod = 'upi';

  // UPI payment methods
  final List<Map<String, dynamic>> _upiApps = [
    {'name': 'Google Pay', 'package': 'com.google.android.apps.nbu.paisa.user', 'icon': Icons.g_mobiledata},
    {'name': 'PhonePe', 'package': 'com.phonepe.app', 'icon': Icons.phone_android},
    {'name': 'Paytm', 'package': 'net.one97.paytm', 'icon': Icons.account_balance_wallet},
    {'name': 'Any UPI App', 'package': '', 'icon': Icons.payment},
  ];

  Future<void> _payWithUPI(String? appPackage) async {
    setState(() => _isLoading = true);

    try {
      // Create order on backend first
      final orderData = await _api.createPaymentOrder(
        bookingId: widget.bookingId,
        amount: widget.amount,
      );

      final orderId = orderData['order_id'] ?? widget.orderId ?? 'order_${widget.bookingId}';

      // Build UPI URI
      // Replace with your actual merchant UPI VPA
      const merchantVpa = 'merchant@upi'; // TODO: Replace with your UPI VPA
      const merchantName = 'Localboy';
      final amountStr = widget.amount.toStringAsFixed(2);
      final txnNote = 'Payment for ${widget.tripTitle}';
      final txnRef = orderId;

      final upiUri = Uri(
        scheme: 'upi',
        host: 'pay',
        queryParameters: {
          'pa': merchantVpa,
          'pn': merchantName,
          'am': amountStr,
          'cu': 'INR',
          'tn': txnNote,
          'tr': txnRef,
        },
      );

      // Try to launch UPI app
      if (await canLaunchUrl(upiUri)) {
        final result = await launchUrl(upiUri);
        if (result) {
          // After returning from UPI app, ask user to confirm
          if (mounted) {
            setState(() => _isLoading = false);
            _showPaymentConfirmDialog(orderId);
          }
        } else {
          throw Exception('Could not launch UPI app');
        }
      } else {
        throw Exception('No UPI app found on this device');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showPaymentConfirmDialog(String orderId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Payment Status'),
        content: const Text(
          'Did you complete the payment successfully in the UPI app?',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Payment cancelled')),
              );
            },
            child: const Text('No, Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _confirmPayment(orderId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1565C0),
              foregroundColor: Colors.white,
            ),
            child: const Text('Yes, Paid'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmPayment(String orderId) async {
    setState(() => _isLoading = true);

    try {
      await _api.verifyPayment(
        orderId: orderId,
        paymentId: 'upi_${DateTime.now().millisecondsSinceEpoch}',
        signature: 'upi_payment',
      );

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => BookingConfirmationScreen(
              bookingId: widget.bookingId,
              tripTitle: widget.tripTitle,
              date: widget.date,
              guests: widget.guests,
              amount: widget.amount,
            ),
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Verification error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Trip summary card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1565C0), Color(0xFF0D47A1)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.tripTitle,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _summaryRow(Icons.calendar_today, widget.date),
                  const SizedBox(height: 6),
                  _summaryRow(Icons.group, '${widget.guests} guest(s)'),
                  const Divider(color: Colors.white30, height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total',
                        style: TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                      Text(
                        '₹${widget.amount.toStringAsFixed(0)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Payment method selection
            const Text(
              'Pay with UPI',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Choose your preferred UPI app',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
            const SizedBox(height: 16),

            // UPI app grid
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 2.5,
              children: _upiApps.map((app) {
                return InkWell(
                  onTap: _isLoading ? null : () => _payWithUPI(app['package']),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(app['icon'], color: const Color(0xFF1565C0)),
                        const SizedBox(width: 8),
                        Text(
                          app['name'],
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 24),

            if (_isLoading)
              const Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 12),
                    Text('Processing payment...'),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.white70),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(color: Colors.white70, fontSize: 14)),
      ],
    );
  }
}
