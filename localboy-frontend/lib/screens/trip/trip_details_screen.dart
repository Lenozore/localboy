import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/booking_provider.dart';
import '../../models/booking.dart';

class TripDetailsScreen extends StatefulWidget {
  final String bookingId;

  const TripDetailsScreen({super.key, required this.bookingId});

  @override
  State<TripDetailsScreen> createState() => _TripDetailsScreenState();
}

class _TripDetailsScreenState extends State<TripDetailsScreen> {
  Booking? _booking;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBookingDetails();
  }

  Future<void> _loadBookingDetails() async {
    final provider = context.read<BookingProvider>();
    final booking = await provider.getBookingDetails(widget.bookingId);

    if (mounted) {
      setState(() {
        _booking = booking;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Trip Details'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_booking == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Trip Details'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text('Failed to load booking details'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trip Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // Share booking details
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadBookingDetails,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Status Card
            _buildStatusCard(),
            const SizedBox(height: 16),

            // Booking Info Card
            _buildBookingInfoCard(),
            const SizedBox(height: 16),

            // Itinerary Card
            if (_booking!.itinerary != null && _booking!.itinerary!.isNotEmpty)
              _buildItineraryCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (_booking!.status) {
      case 'pending':
        statusColor = Colors.orange;
        statusIcon = Icons.pending;
        statusText = 'Pending Confirmation';
        break;
      case 'confirmed':
        statusColor = Colors.blue;
        statusIcon = Icons.check_circle;
        statusText = 'Confirmed';
        break;
      case 'in_progress':
        statusColor = Colors.green;
        statusIcon = Icons.directions_car;
        statusText = 'Trip in Progress';
        break;
      case 'completed':
        statusColor = Colors.grey;
        statusIcon = Icons.done_all;
        statusText = 'Completed';
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.info;
        statusText = 'Unknown';
    }

    return Card(
      color: statusColor.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(statusIcon, color: statusColor, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Booking Code: ${_booking!.bookingCode}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Booking Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(height: 24),
            _buildInfoRow(
              Icons.calendar_today,
              'Date',
              DateFormat('EEEE, MMM dd, yyyy').format(_booking!.tripDate),
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              Icons.access_time,
              'Start Time',
              _booking!.startTime,
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              Icons.card_travel,
              'Package',
              _booking!.tripType == 'half_day'
                  ? 'Half Day (4 hours)'
                  : 'Full Day (8 hours)',
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              Icons.location_on,
              'Pickup Location',
              _booking!.pickupAddress ?? 'Not set',
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              Icons.payments,
              'Total Amount',
              '₹${(_booking!.touristCharge ?? 0).toStringAsFixed(0)}',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildItineraryCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Your Itinerary',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_booking!.itinerary!.length} stops',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _booking!.itinerary!.length,
              itemBuilder: (context, index) {
                final stop = _booking!.itinerary![index];
                final poiName = stop.poi?.name ?? 'Stop ${index + 1}';
                final poiCategory = stop.poi?.category ?? '';
                final poiDescription = stop.poi?.description ?? '';
                final arrivalTime = stop.estimatedArrival ?? '';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Stop number indicator
                      Column(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${index + 1}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                          if (index < _booking!.itinerary!.length - 1)
                            Container(
                              width: 2,
                              height: 40,
                              color: Colors.grey[300],
                            ),
                        ],
                      ),
                      const SizedBox(width: 12),
                      // Stop details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              poiName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (poiCategory.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  poiCategory[0].toUpperCase() + poiCategory.substring(1),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(context).colorScheme.primary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            if (arrivalTime.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Row(
                                  children: [
                                    Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                                    const SizedBox(width: 4),
                                    Text(
                                      'ETA: $arrivalTime',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            if (poiDescription.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  poiDescription,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[500],
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}