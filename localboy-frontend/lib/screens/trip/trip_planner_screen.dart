import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import 'payment_screen.dart';

class TripPlannerScreen extends StatefulWidget {
  const TripPlannerScreen({super.key});

  @override
  State<TripPlannerScreen> createState() => _TripPlannerScreenState();
}

class _TripPlannerScreenState extends State<TripPlannerScreen> {
  final ApiService _api = ApiService();
  String _tripType = 'half_day';
  DateTime _tripDate = DateTime.now().add(const Duration(days: 1));
  String _startTime = '09:00';
  final _addressController = TextEditingController(text: '');

  bool _isPlanning = false;
  Map<String, dynamic>? _plan;
  Map<String, dynamic>? _pricing;
  List<dynamic> _stops = [];

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _planTrip() async {
    if (_addressController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your pickup location')),
      );
      return;
    }

    setState(() => _isPlanning = true);

    try {
      // Default to North Goa coordinates
      const lat = 15.4909;
      const lng = 73.7732;

      final response = await _api.post('/trips/plan', data: {
        'start_lat': lat,
        'start_lng': lng,
        'trip_type': _tripType,
        'start_time': _startTime,
      });

      setState(() {
        _plan = response.data['plan'];
        _pricing = response.data['pricing'];
        _stops = (_plan?['stops'] as List?) ?? [];
        _isPlanning = false;
      });
    } catch (e) {
      setState(() => _isPlanning = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to plan trip: $e')),
        );
      }
    }
  }

  void _removeStop(int index) {
    setState(() {
      _stops.removeAt(index);
    });
    _recalculatePrice();
  }

  Future<void> _recalculatePrice() async {
    if (_stops.isEmpty) return;

    try {
      final response = await _api.post('/trips/recalculate', data: {
        'trip_type': _tripType,
        'distance_km': _plan?['totalDistanceKm'] ?? 0,
        'stop_count': _stops.length,
      });
      setState(() => _pricing = response.data);
    } catch (e) {
      // Keep existing pricing on error
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _tripDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (picked != null) setState(() => _tripDate = picked);
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 9, minute: 0),
    );
    if (picked != null) {
      setState(() {
        _startTime =
            '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      });
    }
  }

  void _proceedToPayment() {
    if (_stops.isEmpty || _pricing == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentScreen(
          tripType: _tripType,
          tripDate: DateFormat('yyyy-MM-dd').format(_tripDate),
          startTime: _startTime,
          pickupAddress: _addressController.text,
          stops: _stops,
          pricing: _pricing!,
          totalDistanceKm: _plan?['totalDistanceKm'] ?? 0,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Plan Your Trip'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Trip Type Selector
            const Text(
              'Trip Duration',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildTripTypeCard(
                    'half_day',
                    'Half Day',
                    '3-4 hours',
                    Icons.wb_sunny_outlined,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTripTypeCard(
                    'full_day',
                    'Full Day',
                    '7-8 hours',
                    Icons.wb_sunny,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Date & Time
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: _selectDate,
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 18),
                          const SizedBox(width: 8),
                          Text(DateFormat('MMM dd').format(_tripDate)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: _selectTime,
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.access_time, size: 18),
                          const SizedBox(width: 8),
                          Text(_startTime),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Pickup Address
            TextField(
              controller: _addressController,
              decoration: InputDecoration(
                labelText: 'Pickup Location / Hotel',
                prefixIcon: const Icon(Icons.hotel),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Plan Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isPlanning ? null : _planTrip,
                icon: _isPlanning
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.auto_awesome),
                label: Text(_isPlanning ? 'AI Planning...' : 'Plan My Trip with AI'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1565C0),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Results
            if (_stops.isNotEmpty) ...[
              const Text(
                'Your AI-Planned Route',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                '${_stops.length} stops • ${_plan?['totalDistanceKm']?.toStringAsFixed(1)} km • ~${_plan?['estimatedDurationMinutes']} min',
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
              const SizedBox(height: 12),

              // Stop List
              ...List.generate(_stops.length, (i) => _buildStopCard(i)),

              const SizedBox(height: 16),

              // Pricing Card
              if (_pricing != null) _buildPricingCard(),

              const SizedBox(height: 16),

              // Book & Pay Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _proceedToPayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    'Book & Pay ₹${_pricing?['totalTouristCharge'] ?? 0}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildTripTypeCard(String type, String title, String subtitle, IconData icon) {
    final isSelected = _tripType == type;
    return GestureDetector(
      onTap: () => setState(() => _tripType = type),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? const Color(0xFF1565C0) : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected ? const Color(0xFF1565C0).withValues(alpha: 0.05) : null,
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? const Color(0xFF1565C0) : Colors.grey, size: 28),
            const SizedBox(height: 6),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected ? const Color(0xFF1565C0) : Colors.black87,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStopCard(int index) {
    final stop = _stops[index];
    final poi = stop['poi'];

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF1565C0),
          foregroundColor: Colors.white,
          child: Text('${index + 1}'),
        ),
        title: Text(
          poi?['name'] ?? 'Stop ${index + 1}',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${poi?['category'] ?? ''} • ${stop['estimatedArrival'] ?? ''} • ${stop['durationMinutes'] ?? 60} min',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
          onPressed: () => _removeStop(index),
        ),
      ),
    );
  }

  Widget _buildPricingCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Price Breakdown',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _pricingRow('Base fare', '₹${_pricing?['baseFare'] ?? 0}'),
          _pricingRow('Distance (${_pricing?['distanceKm']} km)', '₹${_pricing?['perKmCharge'] ?? 0}'),
          _pricingRow('Stops (${_pricing?['stopCount']})', '₹${_pricing?['perStopCharge'] ?? 0}'),
          const Divider(),
          _pricingRow('Subtotal', '₹${_pricing?['subtotal'] ?? 0}'),
          _pricingRow('Service fee (15%)', '₹${_pricing?['platformFee'] ?? 0}'),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text(
                '₹${_pricing?['totalTouristCharge'] ?? 0}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E7D32),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _pricingRow(String label, String amount) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Text(amount),
        ],
      ),
    );
  }
}
