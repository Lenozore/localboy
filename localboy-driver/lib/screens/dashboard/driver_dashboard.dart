import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/driver_provider.dart';
import '../auth/driver_login_screen.dart';
import 'trips_tab.dart';
import 'earnings_tab.dart';
import 'messages_tab.dart';

class DriverDashboard extends StatefulWidget {
  const DriverDashboard({super.key});

  @override
  State<DriverDashboard> createState() => _DriverDashboardState();
}

class _DriverDashboardState extends State<DriverDashboard> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DriverProvider>().fetchTrips();
      context.read<DriverProvider>().fetchPayments();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildHomeTab(),
          const TripsTab(),
          const EarningsTab(),
          const MessagesTab(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 20, offset: const Offset(0, -4))],
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (i) => setState(() => _currentIndex = i),
          backgroundColor: Colors.white,
          indicatorColor: const Color(0xFF2E7D32).withValues(alpha: 0.12),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.dashboard_rounded), selectedIcon: Icon(Icons.dashboard_rounded, color: Color(0xFF2E7D32)), label: 'Home'),
            NavigationDestination(icon: Icon(Icons.route_rounded), selectedIcon: Icon(Icons.route_rounded, color: Color(0xFF2E7D32)), label: 'Trips'),
            NavigationDestination(icon: Icon(Icons.account_balance_wallet_rounded), selectedIcon: Icon(Icons.account_balance_wallet_rounded, color: Color(0xFF2E7D32)), label: 'Earnings'),
            NavigationDestination(icon: Icon(Icons.chat_bubble_outline_rounded), selectedIcon: Icon(Icons.chat_bubble_rounded, color: Color(0xFF2E7D32)), label: 'Chat'),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeTab() {
    final provider = context.watch<DriverProvider>();
    final user = provider.user;
    final trips = provider.trips;
    final payments = provider.payments;

    final activeTrips = trips.where((t) => t['status'] == 'active' || t['status'] == 'driver_assigned').toList();
    final completedCount = trips.where((t) => t['status'] == 'completed').length;
    final totalEarned = payments.fold<double>(0, (sum, p) {
      if (p['payment_type'] == 'driver_payout' && p['status'] == 'completed') {
        return sum + (p['amount'] as num).toDouble();
      }
      return sum;
    });

    return CustomScrollView(
      slivers: [
        // Premium App Bar with gradient
        SliverAppBar(
          expandedHeight: 200,
          floating: false,
          pinned: true,
          backgroundColor: const Color(0xFF1B5E20),
          automaticallyImplyLeading: false,
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF1B5E20), Color(0xFF2E7D32), Color(0xFF388E3C)],
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 60),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top row
                      Row(
                        children: [
                          Container(
                            width: 48, height: 48,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.15),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                            ),
                            child: Center(
                              child: Text(
                                (user?['name']?.toString().isNotEmpty == true ? user!['name'][0] : 'D').toUpperCase(),
                                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Good ${_getGreeting()}!',
                                  style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13),
                                ),
                                Text(
                                  user?['name']?.toString() ?? 'Driver',
                                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                          ),
                          // Online toggle
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.greenAccent, shape: BoxShape.circle)),
                                const SizedBox(width: 6),
                                const Text('Online', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          actions: [
            IconButton(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.logout_rounded, size: 20),
              ),
              onPressed: () async {
                await provider.logout();
                if (mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const DriverLoginScreen()),
                    (route) => false,
                  );
                }
              },
            ),
            const SizedBox(width: 8),
          ],
        ),

        // Stats Row
        SliverToBoxAdapter(
          child: Transform.translate(
            offset: const Offset(0, -30),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 20, offset: const Offset(0, 6))],
                ),
                child: Row(
                  children: [
                    _premiumStat('${activeTrips.length}', 'Active', const Color(0xFF1565C0), Icons.play_circle_fill_rounded),
                    _divider(),
                    _premiumStat('$completedCount', 'Done', const Color(0xFF2E7D32), Icons.check_circle_rounded),
                    _divider(),
                    _premiumStat('₹${totalEarned.toInt()}', 'Earned', const Color(0xFFE65100), Icons.account_balance_wallet_rounded),
                    _divider(),
                    _premiumStat('4.8', 'Rating', const Color(0xFFF9A825), Icons.star_rounded),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Quick Actions
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                _quickAction('My Docs', Icons.folder_rounded, const Color(0xFF5C6BC0), () {}),
                const SizedBox(width: 12),
                _quickAction('History', Icons.history_rounded, const Color(0xFF26A69A), () => setState(() => _currentIndex = 1)),
                const SizedBox(width: 12),
                _quickAction('Support', Icons.headset_mic_rounded, const Color(0xFFEF5350), () {}),
              ],
            ),
          ),
        ),

        // Active Trips Section
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: Row(
              children: [
                Container(
                  width: 4, height: 18,
                  decoration: BoxDecoration(color: const Color(0xFF2E7D32), borderRadius: BorderRadius.circular(2)),
                ),
                const SizedBox(width: 8),
                const Text('Active Trips', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                const Spacer(),
                if (activeTrips.isNotEmpty)
                  Text('${activeTrips.length} trip${activeTrips.length > 1 ? 's' : ''}',
                      style: TextStyle(color: Colors.grey[500], fontSize: 13)),
              ],
            ),
          ),
        ),

        if (activeTrips.isNotEmpty)
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => _buildPremiumTripCard(activeTrips[index]),
              childCount: activeTrips.length,
            ),
          )
        else
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey[100]!),
              ),
              child: Column(
                children: [
                  Container(
                    width: 64, height: 64,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2E7D32).withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.route_rounded, size: 30, color: Color(0xFF2E7D32)),
                  ),
                  const SizedBox(height: 16),
                  const Text('No active trips', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text('New trip requests will appear here',
                      style: TextStyle(fontSize: 13, color: Colors.grey[400])),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2E7D32).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.notifications_active_rounded, color: Color(0xFF2E7D32), size: 16),
                        SizedBox(width: 6),
                        Text("You'll be notified", style: TextStyle(color: Color(0xFF2E7D32), fontSize: 12, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'morning';
    if (hour < 17) return 'afternoon';
    return 'evening';
  }

  Widget _premiumStat(String value, String label, Color color, IconData icon) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: color)),
            Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[500], fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _divider() => Container(width: 1, height: 40, color: Colors.grey[200]);

  Widget _quickAction(String label, IconData icon, Color color, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 26),
              const SizedBox(height: 6),
              Text(label, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumTripCard(dynamic trip) {
    final isActive = trip['status'] == 'active';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 14, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isActive
                    ? [const Color(0xFF2E7D32).withValues(alpha: 0.06), const Color(0xFF2E7D32).withValues(alpha: 0.02)]
                    : [const Color(0xFF1565C0).withValues(alpha: 0.06), const Color(0xFF1565C0).withValues(alpha: 0.02)],
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: (isActive ? const Color(0xFF2E7D32) : const Color(0xFF1565C0)).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isActive ? Icons.navigation_rounded : Icons.schedule_rounded,
                    color: isActive ? const Color(0xFF2E7D32) : const Color(0xFF1565C0),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(trip['booking_code'] ?? 'Trip',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 2),
                      Text(
                        '${trip['trip_date']} • ${trip['start_time']}',
                        style: TextStyle(color: Colors.grey[500], fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isActive ? Colors.green : Colors.blue,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isActive ? '🔴 LIVE' : 'ASSIGNED',
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),

          // Body
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    _tripDetail(Icons.place_rounded, trip['pickup_address'] ?? 'Pickup location', Colors.red),
                    const SizedBox(width: 16),
                    _tripDetail(Icons.straighten_rounded, '${trip['total_distance_km'] ?? '—'} km', const Color(0xFF1565C0)),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E7D32).withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.payments_rounded, color: Color(0xFF2E7D32), size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Your payout: ₹${trip['driver_payout'] ?? 0}',
                        style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF2E7D32), fontSize: 15),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      if (isActive) {
                        context.read<DriverProvider>().completeTrip(trip['id']);
                      } else {
                        context.read<DriverProvider>().startTrip(trip['id']);
                      }
                    },
                    icon: Icon(isActive ? Icons.check_circle_rounded : Icons.play_arrow_rounded),
                    label: Text(isActive ? 'Complete Trip' : 'Start Trip',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isActive ? const Color(0xFF1565C0) : const Color(0xFF2E7D32),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tripDetail(IconData icon, String text, Color color) {
    return Expanded(
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Expanded(child: Text(text, style: TextStyle(fontSize: 12, color: Colors.grey[600]), overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }
}
