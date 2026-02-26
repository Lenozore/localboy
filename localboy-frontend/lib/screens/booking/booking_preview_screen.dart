import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/booking_provider.dart';
import 'booking_success_screen.dart';

class BookingPreviewScreen extends StatelessWidget {
  final DateTime tripDate;
  final String startTime;
  final String packageType;
  final String hotelAddress;
  final double hotelLat;
  final double hotelLng;

  const BookingPreviewScreen({
    super.key,
    required this.tripDate,
    required this.startTime,
    required this.packageType,
    required this.hotelAddress,
    required this.hotelLat,
    required this.hotelLng,
  });

  String get packageName =>
      packageType == 'half_day' ? 'Half Day (4 hours)' : 'Full Day (8 hours)';

  double get price => packageType == 'half_day' ? 1499.0 : 2499.0;

  Future<void> _confirmBooking(BuildContext context) async {
    final provider = context.read<BookingProvider>();

    final booking = await provider.createBooking(
      tripDate: tripDate,
      startTime: startTime,
      packageType: packageType,
      hotelAddress: hotelAddress,
      hotelLat: hotelLat,
      hotelLng: hotelLng,
    );

    if (!context.mounted) return;

    if (booking != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => BookingSuccessScreen(booking: booking),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? 'Failed to create booking'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirm Booking'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Trip Details',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Divider(height: 24),
                        _buildDetailRow(
                          'Date',
                          DateFormat('EEEE, MMM dd, yyyy').format(tripDate),
                        ),
                        const SizedBox(height: 12),
                        _buildDetailRow('Time', startTime),
                        const SizedBox(height: 12),
                        _buildDetailRow('Package', packageName),
                        const SizedBox(height: 12),
                        _buildDetailRow('Hotel', hotelAddress),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'What to Expect',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Divider(height: 24),
                        _buildFeature(
                          Icons.route,
                          'We\'ll select 3-4 best places for you',
                        ),
                        _buildFeature(
                          Icons.directions_car,
                          'Dedicated cab for the entire trip',
                        ),
                        _buildFeature(
                          Icons.person,
                          'Driver acts as your guide',
                        ),
                        _buildFeature(
                          Icons.map,
                          'Optimized route to save time',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Price Breakdown',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Divider(height: 24),
                        _buildPriceRow('Base Fare', price),
                        _buildPriceRow('Taxes', 0),
                        const Divider(height: 24),
                        _buildPriceRow(
                          'Total',
                          price,
                          isTotal: true,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              child: Consumer<BookingProvider>(
                builder: (context, provider, _) {
                  return ElevatedButton(
                    onPressed: provider.isLoading
                        ? null
                        : () => _confirmBooking(context),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: provider.isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            'Confirm & Pay ₹${price.toStringAsFixed(0)}',
                            style: const TextStyle(fontSize: 16),
                          ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFeature(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.green),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, double amount, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            '₹${amount.toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: isTotal ? 18 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}