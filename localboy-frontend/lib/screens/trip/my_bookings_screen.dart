import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/booking_provider.dart';
import '../../models/booking.dart';
import '../trip/trip_details_screen.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BookingProvider>().fetchBookings();
    });
  }

  @override
  Widget build(BuildContext context) {
    final bookingProvider = context.watch<BookingProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Trips'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: bookingProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : bookingProvider.bookings.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.luggage_outlined, size: 64, color: Colors.grey[300]),
                      const SizedBox(height: 12),
                      Text(
                        'No trips yet',
                        style: TextStyle(fontSize: 18, color: Colors.grey[500]),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Book your first trip to explore Goa!',
                        style: TextStyle(fontSize: 14, color: Colors.grey[400]),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () => bookingProvider.fetchBookings(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: bookingProvider.bookings.length,
                    itemBuilder: (context, index) {
                      return _buildTripCard(bookingProvider.bookings[index]);
                    },
                  ),
                ),
    );
  }

  Widget _buildTripCard(Booking booking) {
    final statusColor = _getStatusColor(booking.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TripDetailsScreen(bookingId: booking.id),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    booking.bookingCode ?? 'Trip',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1565C0),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      booking.status.replaceAll('_', ' ').toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              Row(
                children: [
                  Icon(Icons.calendar_today, size: 14, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('MMM dd, yyyy').format(booking.tripDate),
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.access_time, size: 14, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(
                    booking.startTime,
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                ],
              ),

              if (booking.touristCharge != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      booking.tripType == 'full_day' ? 'Full Day' : 'Half Day',
                      style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                    ),
                    const Spacer(),
                    Text(
                      '₹${booking.touristCharge!.toInt()}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending': return Colors.orange;
      case 'confirmed': return const Color(0xFF1565C0);
      case 'driver_assigned': return Colors.teal;
      case 'active': return const Color(0xFF2E7D32);
      case 'completed': return Colors.green;
      case 'cancelled': return Colors.red;
      default: return Colors.grey;
    }
  }
}