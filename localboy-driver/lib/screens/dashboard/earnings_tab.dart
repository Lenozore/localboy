import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/driver_provider.dart';

class EarningsTab extends StatefulWidget {
  const EarningsTab({super.key});

  @override
  State<EarningsTab> createState() => _EarningsTabState();
}

class _EarningsTabState extends State<EarningsTab> {
  String _period = 'month';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DriverProvider>().fetchPayments();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DriverProvider>();
    final payments = provider.payments;

    final totalEarned = payments.fold<double>(0, (sum, p) {
      if (p['payment_type'] == 'driver_payout' && p['status'] == 'completed') {
        return sum + (p['amount'] as num).toDouble();
      }
      return sum;
    });

    final pendingPayments = payments.where(
      (p) => p['payment_type'] == 'driver_payout' && p['status'] == 'pending',
    ).toList();

    final completedPayments = payments.where(
      (p) => p['payment_type'] == 'driver_payout' && p['status'] == 'completed',
    ).toList();

    final pendingAmount = pendingPayments.fold<double>(0, (sum, p) => sum + (p['amount'] as num).toDouble());

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: CustomScrollView(
        slivers: [
          // Premium Header
          SliverAppBar(
            expandedHeight: 260,
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
                    colors: [Color(0xFF1B5E20), Color(0xFF2E7D32), Color(0xFF43A047)],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Earnings',
                            style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 24),

                        // Big number
                        Text('₹${totalEarned.toInt()}',
                            style: const TextStyle(color: Colors.white, fontSize: 42, fontWeight: FontWeight.w800)),
                        Text('Total earnings',
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 14)),

                        const SizedBox(height: 20),

                        // Period selector
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              _periodChip('Today', 'today'),
                              _periodChip('Week', 'week'),
                              _periodChip('Month', 'month'),
                              _periodChip('All', 'all'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Summary cards
          SliverToBoxAdapter(
            child: Transform.translate(
              offset: const Offset(0, -20),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _summaryCard('Pending', '₹${pendingAmount.toInt()}', Icons.schedule_rounded, Colors.orange),
                    const SizedBox(width: 12),
                    _summaryCard('Trips', '${completedPayments.length}', Icons.check_circle_rounded, const Color(0xFF2E7D32)),
                    const SizedBox(width: 12),
                    _summaryCard('Avg/Trip', completedPayments.isNotEmpty
                        ? '₹${(totalEarned / completedPayments.length).toInt()}'
                        : '₹0', Icons.trending_up_rounded, const Color(0xFF1565C0)),
                  ],
                ),
              ),
            ),
          ),

          // Pending Payouts
          if (pendingPayments.isNotEmpty) ...[
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: Row(
                  children: [
                    Icon(Icons.pending_actions_rounded, size: 18, color: Colors.orange),
                    SizedBox(width: 6),
                    Text('Pending Payouts', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _buildPayoutCard(pendingPayments[index], isPending: true),
                childCount: pendingPayments.length,
              ),
            ),
          ],

          // Completed Payouts
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
              child: Row(
                children: [
                  const Icon(Icons.receipt_long_rounded, size: 18, color: Color(0xFF2E7D32)),
                  const SizedBox(width: 6),
                  const Text('Recent Transactions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  const Spacer(),
                  Text('${completedPayments.length} total', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                ],
              ),
            ),
          ),

          if (payments.isEmpty)
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    Icon(Icons.account_balance_wallet_outlined, size: 48, color: Colors.grey[300]),
                    const SizedBox(height: 12),
                    Text('No transactions yet', style: TextStyle(color: Colors.grey[400], fontSize: 16)),
                  ],
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _buildPayoutCard(completedPayments[index], isPending: false),
                childCount: completedPayments.length,
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _periodChip(String label, String value) {
    final isSelected = _period == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _period = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? const Color(0xFF1B5E20) : Colors.white70,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _summaryCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: color)),
            Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[500])),
          ],
        ),
      ),
    );
  }

  Widget _buildPayoutCard(dynamic payment, {required bool isPending}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: isPending ? Border.all(color: Colors.orange.withValues(alpha: 0.3)) : null,
      ),
      child: Row(
        children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              color: (isPending ? Colors.orange : const Color(0xFF2E7D32)).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isPending ? Icons.schedule_rounded : Icons.check_circle_rounded,
              color: isPending ? Colors.orange : const Color(0xFF2E7D32),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Trip payout',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                Text(
                  isPending ? 'Processing...' : 'Completed',
                  style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                ),
              ],
            ),
          ),
          Text(
            '₹${payment['amount']}',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: isPending ? Colors.orange : const Color(0xFF2E7D32),
            ),
          ),
        ],
      ),
    );
  }
}
