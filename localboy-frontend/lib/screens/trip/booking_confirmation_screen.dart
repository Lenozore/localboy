import 'package:flutter/material.dart';

class BookingConfirmationScreen extends StatelessWidget {
  final String bookingId;
  final String tripTitle;
  final String date;
  final int guests;
  final double amount;

  const BookingConfirmationScreen({
    super.key,
    required this.bookingId,
    required this.tripTitle,
    required this.date,
    required this.guests,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Success Icon
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      size: 56,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Booking Confirmed!',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your trip has been booked successfully',
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Booking Code Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Booking ID',
                          style: TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          bookingId,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1565C0),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 12),
                        _infoRow(Icons.tour, 'Trip', tripTitle),
                        const SizedBox(height: 8),
                        _infoRow(Icons.calendar_today, 'Date', date),
                        const SizedBox(height: 8),
                        _infoRow(Icons.group, 'Guests', '$guests guest(s)'),
                        const SizedBox(height: 8),
                        _infoRow(Icons.payments, 'Paid', '₹${amount.toStringAsFixed(0)}'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'A driver will be assigned soon.\nYou\'ll be notified when they accept.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Go Home Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.popUntil(context, (route) => route.isFirst);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF2E7D32),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Back to Home',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey),
        const SizedBox(width: 8),
        Text('$label:', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
        const Spacer(),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }
}
