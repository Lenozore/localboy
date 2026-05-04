import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/driver_provider.dart';

class TripsTab extends StatefulWidget {
  const TripsTab({super.key});

  @override
  State<TripsTab> createState() => _TripsTabState();
}

class _TripsTabState extends State<TripsTab> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DriverProvider>();
    final trips = provider.trips;

    final active = trips.where((t) => t['status'] == 'active' || t['status'] == 'driver_assigned').toList();
    final completed = trips.where((t) => t['status'] == 'completed').toList();
    final cancelled = trips.where((t) => t['status'] == 'cancelled').toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('My Trips', style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              labelColor: const Color(0xFF1B5E20),
              unselectedLabelColor: Colors.white70,
              labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerHeight: 0,
              tabs: [
                Tab(text: 'Active (${active.length})'),
                Tab(text: 'Done (${completed.length})'),
                Tab(text: 'Cancelled (${cancelled.length})'),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTripList(active, 'No active trips', 'New trips will appear when assigned'),
          _buildTripList(completed, 'No completed trips', 'Complete your first trip to see it here'),
          _buildTripList(cancelled, 'No cancelled trips', 'That\'s great — keep going!'),
        ],
      ),
    );
  }

  Widget _buildTripList(List<dynamic> trips, String emptyTitle, String emptySubtitle) {
    if (trips.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64, height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFF2E7D32).withValues(alpha: 0.06),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.route_rounded, size: 28, color: Color(0xFF2E7D32)),
            ),
            const SizedBox(height: 14),
            Text(emptyTitle, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(emptySubtitle, style: TextStyle(fontSize: 13, color: Colors.grey[400])),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => context.read<DriverProvider>().fetchTrips(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: trips.length,
        itemBuilder: (context, index) {
          final trip = trips[index];
          final isCompleted = trip['status'] == 'completed';
          final isActive = trip['status'] == 'active';

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 3))],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Status icon
                  Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(
                      color: (isCompleted ? const Color(0xFF2E7D32) : isActive ? const Color(0xFF1565C0) : Colors.red).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      isCompleted ? Icons.check_circle_rounded : isActive ? Icons.navigation_rounded : Icons.cancel_rounded,
                      color: isCompleted ? const Color(0xFF2E7D32) : isActive ? const Color(0xFF1565C0) : Colors.red,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(trip['booking_code'] ?? 'Trip',
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                        const SizedBox(height: 2),
                        Text('${trip['trip_date']} • ${trip['start_time']}',
                            style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('₹${trip['driver_payout'] ?? 0}',
                          style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF2E7D32), fontSize: 17)),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: (isCompleted ? const Color(0xFF2E7D32) : isActive ? const Color(0xFF1565C0) : Colors.red).withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          (trip['status'] as String).replaceAll('_', ' '),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: isCompleted ? const Color(0xFF2E7D32) : isActive ? const Color(0xFF1565C0) : Colors.red,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
