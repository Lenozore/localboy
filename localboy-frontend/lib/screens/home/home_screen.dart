import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';
import '../../models/poi.dart';
import '../booking/create_booking_screen.dart';
import '../trip/my_bookings_screen.dart';
import '../trip/trip_planner_screen.dart';
import '../auth/welcome_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Position? _currentPosition;
  bool _locationLoading = true;
  String? _locationError;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _requestLocationAndLoadPois();
  }

  Future<void> _requestLocationAndLoadPois() async {
    setState(() => _locationLoading = true);

    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _locationError = 'Location services are disabled';
          _locationLoading = false;
        });
        _loadDefaultPois();
        return;
      }

      // Check permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _locationError = 'Location permission denied';
            _locationLoading = false;
          });
          _loadDefaultPois();
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _locationError = 'Location permission permanently denied';
          _locationLoading = false;
        });
        _loadDefaultPois();
        return;
      }

      // Get position
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium),
      );

      setState(() {
        _currentPosition = position;
        _locationLoading = false;
      });

      // Fetch nearby POIs
      if (mounted) {
        await context.read<BookingProvider>().fetchNearbyPois(
              position.latitude,
              position.longitude,
            );
      }
    } catch (e) {
      setState(() {
        _locationError = 'Failed to get location';
        _locationLoading = false;
      });
      _loadDefaultPois();
    }
  }

  Future<void> _loadDefaultPois() async {
    if (mounted) {
      await context.read<BookingProvider>().fetchPois(city: 'Goa');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildHomeTab(),
          const MyBookingsScreen(),
          _buildProfileTab(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.explore), label: 'Explore'),
          NavigationDestination(icon: Icon(Icons.luggage), label: 'My Trips'),
          NavigationDestination(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _buildHomeTab() {
    final authProvider = context.watch<AuthProvider>();
    final bookingProvider = context.watch<BookingProvider>();
    final pois = bookingProvider.nearbyPois.isNotEmpty
        ? bookingProvider.nearbyPois
        : bookingProvider.pois;

    return CustomScrollView(
      slivers: [
        // App Bar
        SliverAppBar(
          expandedHeight: 140,
          floating: true,
          pinned: true,
          backgroundColor: const Color(0xFF1565C0),
          flexibleSpace: FlexibleSpaceBar(
            title: Text(
              'Hey ${authProvider.user?.name?.split(' ').first ?? 'Traveller'} 👋',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            background: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF1565C0), Color(0xFF002171)],
                ),
              ),
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined),
              onPressed: () {},
            ),
          ],
        ),

        // Location status
        if (_currentPosition != null)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                children: [
                  const Icon(Icons.location_on, color: Color(0xFF1565C0), size: 18),
                  const SizedBox(width: 4),
                  Text(
                    'Showing places near you',
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                ],
              ),
            ),
          ),

        // Book a Trip CTA
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Ready for adventure?',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Book a guided trip with a local',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const TripPlannerScreen(),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF1565C0),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                          ),
                          child: const Text('Book Now'),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.directions_car, size: 64, color: Colors.white24),
                ],
              ),
            ),
          ),
        ),

        // Section Header
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Places to Explore',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text('See All'),
                ),
              ],
            ),
          ),
        ),

        // Loading state
        if (_locationLoading || bookingProvider.isLoading)
          const SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              ),
            ),
          )
        // POI List
        else if (pois.isEmpty)
          SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  'No places found nearby.\nTry again later.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[500]),
                ),
              ),
            ),
          )
        else
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => _buildPoiCard(pois[index]),
              childCount: pois.length,
            ),
          ),

        // Bottom padding
        const SliverToBoxAdapter(child: SizedBox(height: 80)),
      ],
    );
  }

  Widget _buildPoiCard(Poi poi) {
    final imageUrl = (poi.photoUrls != null && poi.photoUrls!.isNotEmpty)
        ? poi.photoUrls!.first
        : poi.imageUrl;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Card(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 2,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            SizedBox(
              height: 180,
              width: double.infinity,
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  color: Colors.grey[200],
                  child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                ),
                errorWidget: (_, __, ___) => Container(
                  color: Colors.grey[200],
                  child: const Icon(Icons.image_not_supported, size: 48, color: Colors.grey),
                ),
              ),
            ),
            // Info
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          poi.name,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1565C0).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          poi.category[0].toUpperCase() + poi.category.substring(1),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1565C0),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    poi.description,
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 14, color: Colors.grey[500]),
                      const SizedBox(width: 4),
                      Text(
                        '${poi.avgVisitMinutes} min visit',
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                      if (poi.distanceKm != null) ...[
                        const SizedBox(width: 16),
                        Icon(Icons.place, size: 14, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Text(
                          '${poi.distanceKm!.toStringAsFixed(1)} km away',
                          style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileTab() {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 16),
          // Avatar
          Center(
            child: CircleAvatar(
              radius: 48,
              backgroundColor: const Color(0xFF1565C0).withValues(alpha: 0.1),
              backgroundImage: user?.avatarUrl != null
                  ? NetworkImage(user!.avatarUrl!)
                  : null,
              child: user?.avatarUrl == null
                  ? Text(
                      (user?.name?.isNotEmpty == true ? user!.name![0] : '?').toUpperCase(),
                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              user?.name ?? 'Profile',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ),
          if (user?.email != null)
            Center(
              child: Text(
                user!.email!,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ),
          if (user?.phone != null)
            Center(
              child: Text(
                user!.phone!,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ),
          const SizedBox(height: 24),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('Trip History'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => setState(() => _currentIndex = 1),
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: const Text('Help & Support'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {},
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout', style: TextStyle(color: Colors.red)),
            onTap: () async {
              await authProvider.logout();
              if (mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
    );
  }
}