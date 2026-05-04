import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:geocoding/geocoding.dart';
import 'booking_preview_screen.dart';

class CreateBookingScreen extends StatefulWidget {
  const CreateBookingScreen({super.key});

  @override
  State<CreateBookingScreen> createState() => _CreateBookingScreenState();
}

class _CreateBookingScreenState extends State<CreateBookingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _hotelAddressController = TextEditingController();

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String _packageType = 'half_day';
  bool _isGeocoding = false;

  @override
  void dispose() {
    _hotelAddressController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 9, minute: 0),
    );

    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _previewBooking() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a date')),
      );
      return;
    }
    if (_selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a time')),
      );
      return;
    }

    // Geocode the hotel address to get lat/lng
    setState(() => _isGeocoding = true);

    double hotelLat = 15.2993; // Goa default fallback
    double hotelLng = 74.1240;

    try {
      final locations = await locationFromAddress(_hotelAddressController.text);
      if (locations.isNotEmpty) {
        hotelLat = locations.first.latitude;
        hotelLng = locations.first.longitude;
      }
    } catch (e) {
      // Geocoding failed — use Goa defaults and continue
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not locate address, using default Goa location'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isGeocoding = false);
    }

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BookingPreviewScreen(
          tripDate: _selectedDate!,
          startTime: '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}',
          packageType: _packageType,
          hotelAddress: _hotelAddressController.text,
          hotelLat: hotelLat,
          hotelLng: hotelLng,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Your Trip'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Date Selection
            Card(
              child: ListTile(
                leading: const Icon(Icons.calendar_today),
                title: const Text('Trip Date'),
                subtitle: Text(
                  _selectedDate != null
                      ? DateFormat('MMM dd, yyyy').format(_selectedDate!)
                      : 'Select date',
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: _selectDate,
              ),
            ),
            const SizedBox(height: 12),

            // Time Selection
            Card(
              child: ListTile(
                leading: const Icon(Icons.access_time),
                title: const Text('Start Time'),
                subtitle: Text(
                  _selectedTime != null
                      ? _selectedTime!.format(context)
                      : 'Select time',
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: _selectTime,
              ),
            ),
            const SizedBox(height: 12),

            // Package Type
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Package Type',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    RadioListTile<String>(
                      title: const Text('Half Day (4 hours)'),
                      subtitle: const Text('₹1,499'),
                      value: 'half_day',
                      groupValue: _packageType,
                      onChanged: (value) {
                        setState(() {
                          _packageType = value!;
                        });
                      },
                    ),
                    RadioListTile<String>(
                      title: const Text('Full Day (8 hours)'),
                      subtitle: const Text('₹2,499'),
                      value: 'full_day',
                      groupValue: _packageType,
                      onChanged: (value) {
                        setState(() {
                          _packageType = value!;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Hotel Address
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Hotel Address',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _hotelAddressController,
                      decoration: InputDecoration(
                        hintText: 'Enter your hotel address',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon: const Icon(Icons.location_on),
                      ),
                      maxLines: 2,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter hotel address';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Preview Button
            ElevatedButton(
              onPressed: _isGeocoding ? null : _previewBooking,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isGeocoding
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text(
                      'Preview Booking',
                      style: TextStyle(fontSize: 16),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}