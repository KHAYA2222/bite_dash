// screens/driver_dashboard.dart
// Driver's home — available orders, active delivery, earnings history.

import 'package:flutter/material.dart';
import '../models/food.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../services/order_service.dart';

class DriverDashboard extends StatefulWidget {
  final AuthProvider authProvider;
  const DriverDashboard({super.key, required this.authProvider});

  @override
  State<DriverDashboard> createState() => _DriverDashboardState();
}

class _DriverDashboardState extends State<DriverDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  UserModel get driver => widget.authProvider.currentUser!;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Sign Out',
            style: TextStyle(fontWeight: FontWeight.w800)),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
    if (confirmed == true) await widget.authProvider.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: cs.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Driver Dashboard',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w900)),
            Text(driver.name,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: cs.primary, fontWeight: FontWeight.w600)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: _signOut,
            color: const Color(0xFF6E6E6E),
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          labelColor: cs.primary,
          unselectedLabelColor: const Color(0xFF9E9E9E),
          indicatorColor: cs.primary,
          labelStyle: const TextStyle(
              fontWeight: FontWeight.w700, fontFamily: 'Nunito'),
          tabs: const [
            Tab(icon: Icon(Icons.inbox_outlined, size: 20), text: 'Available'),
            Tab(
                icon: Icon(Icons.delivery_dining_rounded, size: 20),
                text: 'Active'),
            Tab(icon: Icon(Icons.history_rounded, size: 20), text: 'Earnings'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _AvailableOrdersTab(driver: driver),
          _ActiveDeliveryTab(driver: driver),
          _EarningsTab(driver: driver),
        ],
      ),
    );
  }
}

// ── Tab 1: Available orders to claim ─────────────────────────────────────────

class _AvailableOrdersTab extends StatelessWidget {
  final UserModel driver;
  const _AvailableOrdersTab({required this.driver});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return StreamBuilder<List<Order>>(
      stream: OrderService().availableOrdersStream(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: cs.primary));
        }
        final orders = snap.data ?? [];
        if (orders.isEmpty) {
          return _EmptyState(
            icon: Icons.inbox_outlined,
            title: 'No orders available',
            subtitle:
                'Check back soon — orders will appear here once confirmed',
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          physics: const BouncingScrollPhysics(),
          itemCount: orders.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (_, i) =>
              _AvailableOrderCard(order: orders[i], driver: driver),
        );
      },
    );
  }
}

class _AvailableOrderCard extends StatefulWidget {
  final Order order;
  final UserModel driver;
  const _AvailableOrderCard({required this.order, required this.driver});

  @override
  State<_AvailableOrderCard> createState() => _AvailableOrderCardState();
}

class _AvailableOrderCardState extends State<_AvailableOrderCard> {
  bool _claiming = false;

  Future<void> _claim() async {
    setState(() => _claiming = true);
    final ok = await OrderService().claimOrder(
      widget.order.id,
      widget.driver.id,
      widget.driver.name,
    );
    if (!mounted) return;
    setState(() => _claiming = false);
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Order ${widget.order.orderNumber ?? ""} claimed!',
            style: const TextStyle(fontFamily: 'Nunito')),
        backgroundColor: Theme.of(context).colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.all(16),
      ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Could not claim — order may have been taken.',
            style: TextStyle(fontFamily: 'Nunito')),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.all(16),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final order = widget.order;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.primaryContainer, width: 1.5),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(order.orderNumber ?? order.id.substring(0, 8),
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w900)),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('R${order.total.toStringAsFixed(2)}',
                    style: TextStyle(
                        fontWeight: FontWeight.w900,
                        color: cs.primary,
                        fontSize: 14)),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Items summary
          Text(
            order.items.map((i) => '${i.quantity}× ${i.food.name}').join(', '),
            style: const TextStyle(color: Color(0xFF6E6E6E), fontSize: 13),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 10),

          // Delivery address
          Row(children: [
            Icon(Icons.location_on_rounded, size: 15, color: cs.primary),
            const SizedBox(width: 5),
            Expanded(
              child: Text(
                order.deliveryAddress.isNotEmpty
                    ? order.deliveryAddress
                    : 'No address saved',
                style:
                    const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ]),
          const SizedBox(height: 14),

          // Payment badge + claim button
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: order.paymentMethod == 'cod'
                      ? Colors.orange.withOpacity(0.12)
                      : cs.primaryContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  order.paymentMethod == 'cod'
                      ? 'Cash on delivery'
                      : 'Paid online',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: order.paymentMethod == 'cod'
                          ? Colors.orange.shade800
                          : cs.primary),
                ),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: _claiming ? null : _claim,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(100, 40),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                ),
                child: _claiming
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('Accept',
                        style: TextStyle(fontWeight: FontWeight.w800)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Tab 2: Active delivery ────────────────────────────────────────────────────

class _ActiveDeliveryTab extends StatelessWidget {
  final UserModel driver;
  const _ActiveDeliveryTab({required this.driver});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return StreamBuilder<List<Order>>(
      stream: OrderService().driverActiveOrdersStream(driver.id),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: cs.primary));
        }
        final orders = snap.data ?? [];
        if (orders.isEmpty) {
          return _EmptyState(
            icon: Icons.delivery_dining_rounded,
            title: 'No active deliveries',
            subtitle: 'Accept an order from the Available tab to get started',
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          physics: const BouncingScrollPhysics(),
          itemCount: orders.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (_, i) => _ActiveDeliveryCard(order: orders[i]),
        );
      },
    );
  }
}

class _ActiveDeliveryCard extends StatefulWidget {
  final Order order;
  const _ActiveDeliveryCard({required this.order});

  @override
  State<_ActiveDeliveryCard> createState() => _ActiveDeliveryCardState();
}

class _ActiveDeliveryCardState extends State<_ActiveDeliveryCard> {
  bool _updating = false;

  Future<void> _updateStatus(OrderStatus status) async {
    setState(() => _updating = true);
    await OrderService().updateOrderStatus(widget.order.id, status);
    if (mounted) setState(() => _updating = false);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final order = widget.order;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.primary.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(order.orderNumber ?? order.id.substring(0, 8),
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w900)),
                    Text(order.customerName,
                        style: const TextStyle(
                            color: Color(0xFF9E9E9E), fontSize: 12)),
                  ],
                ),
              ),
              Text(order.status.emoji, style: const TextStyle(fontSize: 24)),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),

          // Delivery address — the most important info
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cs.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.location_on_rounded, color: cs.primary, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Deliver to',
                          style: TextStyle(
                              fontSize: 11,
                              color: cs.primary,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text(
                        order.deliveryAddress.isNotEmpty
                            ? order.deliveryAddress
                            : 'No address on file',
                        style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: cs.onPrimaryContainer),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Customer phone if available
          if (order.customerEmail.isNotEmpty)
            Row(children: [
              Icon(Icons.email_outlined, size: 15, color: Colors.grey.shade400),
              const SizedBox(width: 6),
              Text(order.customerEmail,
                  style:
                      const TextStyle(fontSize: 12, color: Color(0xFF9E9E9E))),
            ]),

          // Payment reminder for COD
          if (order.paymentMethod == 'cod') ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Row(children: [
                const Icon(Icons.money_rounded, color: Colors.orange, size: 16),
                const SizedBox(width: 8),
                Text(
                  'Collect R${order.total.toStringAsFixed(2)} cash on delivery',
                  style: const TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.w700,
                      fontSize: 12),
                ),
              ]),
            ),
          ],
          const SizedBox(height: 16),

          // Status action buttons
          if (!_updating)
            _buildActions(order.status, cs)
          else
            const Center(
                child: Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: CircularProgressIndicator(strokeWidth: 2),
            )),
        ],
      ),
    );
  }

  Widget _buildActions(OrderStatus current, ColorScheme cs) {
    OrderStatus? next;
    String nextLabel = '';

    if (current == OrderStatus.confirmed) {
      next = OrderStatus.onTheWay;
      nextLabel = 'Picked up — Start Delivery';
    } else if (current == OrderStatus.onTheWay) {
      next = OrderStatus.delivered;
      nextLabel = 'Mark as Delivered';
    }

    if (next == null) return const SizedBox.shrink();

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => _updateStatus(next!),
        icon: Text(next.emoji, style: const TextStyle(fontSize: 16)),
        label: Text(nextLabel,
            style: const TextStyle(fontWeight: FontWeight.w800)),
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 48),
          backgroundColor: next == OrderStatus.delivered
              ? const Color(0xFF2E7D32)
              : cs.primary,
        ),
      ),
    );
  }
}

// ── Tab 3: Earnings ───────────────────────────────────────────────────────────

class _EarningsTab extends StatelessWidget {
  final UserModel driver;
  const _EarningsTab({required this.driver});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return StreamBuilder<List<Order>>(
      stream: OrderService().driverCompletedOrdersStream(driver.id),
      builder: (context, snap) {
        final orders = snap.data ?? [];
        final totalEarnings = orders.fold(0.0, (sum, o) => sum + o.deliveryFee);
        final totalDeliveries = orders.length;

        return ListView(
          padding: const EdgeInsets.all(16),
          physics: const BouncingScrollPhysics(),
          children: [
            // Stats cards
            Row(children: [
              Expanded(
                child: _StatBox(
                  label: 'Deliveries',
                  value: '$totalDeliveries',
                  icon: Icons.delivery_dining_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatBox(
                  label: 'Earnings',
                  value: 'R${totalEarnings.toStringAsFixed(2)}',
                  icon: Icons.payments_outlined,
                ),
              ),
            ]),
            const SizedBox(height: 20),

            if (orders.isEmpty)
              _EmptyState(
                icon: Icons.receipt_long_outlined,
                title: 'No deliveries yet',
                subtitle: 'Completed deliveries will appear here',
              )
            else ...[
              Text('Delivery history',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              ...orders.map((order) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _CompletedOrderRow(order: order, cs: cs),
                  )),
            ],
          ],
        );
      },
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _StatBox(
      {required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: cs.primaryContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: cs.primary, size: 20),
          ),
          const SizedBox(height: 10),
          Text(value,
              style:
                  const TextStyle(fontWeight: FontWeight.w900, fontSize: 22)),
          Text(label,
              style: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 12)),
        ],
      ),
    );
  }
}

class _CompletedOrderRow extends StatelessWidget {
  final Order order;
  final ColorScheme cs;
  const _CompletedOrderRow({required this.order, required this.cs});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2))
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: cs.primaryContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child:
                const Center(child: Text('🎉', style: TextStyle(fontSize: 16))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(order.orderNumber ?? order.id.substring(0, 8),
                    style: const TextStyle(fontWeight: FontWeight.w800)),
                Text(order.customerName,
                    style: const TextStyle(
                        color: Color(0xFF9E9E9E), fontSize: 12)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('R${order.deliveryFee.toStringAsFixed(2)}',
                  style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: cs.primary,
                      fontSize: 15)),
              Text('delivery fee',
                  style:
                      const TextStyle(color: Color(0xFF9E9E9E), fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Shared ────────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _EmptyState(
      {required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 80),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
                color: cs.primaryContainer, shape: BoxShape.circle),
            child: Icon(icon, color: cs.primary, size: 38),
          ),
          const SizedBox(height: 20),
          Text(title,
              style:
                  const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
          const SizedBox(height: 8),
          Text(subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Color(0xFF9E9E9E), fontSize: 13, height: 1.5)),
        ],
      ),
    );
  }
}
