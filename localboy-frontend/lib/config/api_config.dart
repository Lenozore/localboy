class ApiConfig {
  // Change this to your computer's IP when testing on physical device
  // On emulator: use 10.0.2.2
  // On physical device: use your laptop's IP (find with ipconfig/ifconfig)
  static const String baseUrl = 'http://10.0.2.2:3000/api';
  
  // Endpoints
  static const String login = '/auth/send-otp';
  static const String verifyOtp = '/auth/verify-otp';
  static const String pois = '/pois';
  static const String bookings = '/bookings';
  static const String myBookings = '/bookings/my-bookings';
}