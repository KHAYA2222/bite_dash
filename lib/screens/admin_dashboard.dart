import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
// screens/admin_dashboard.dart
// Full admin dashboard — Orders, Menu, Stats.
// Only accessible when user.isAdmin == true (set in Firestore).

import 'package:flutter/material.dart';
import '../models/food.dart';
import '../providers/auth_provider.dart';
import '../services/food_service.dart';
import '../services/order_service.dart';
import 'admin_menu_screen.dart';

class AdminDashboard extends StatefulWidget {
  final AuthProvider authProvider;
  const AdminDashboard({super.key, required this.authProvider});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: cs.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Admin Dashboard',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w900)),
            Text(
              widget.authProvider.currentUser?.email ?? '',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: cs.primary, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabs,
          labelColor: cs.primary,
          unselectedLabelColor: const Color(0xFF9E9E9E),
          indicatorColor: cs.primary,
          labelStyle: const TextStyle(
              fontWeight: FontWeight.w700, fontFamily: 'Nunito', fontSize: 13),
          tabs: const [
            Tab(
                icon: Icon(Icons.receipt_long_outlined, size: 20),
                text: 'Orders'),
            Tab(
                icon: Icon(Icons.restaurant_menu_rounded, size: 20),
                text: 'Menu'),
            Tab(
                icon: Icon(Icons.delivery_dining_rounded, size: 20),
                text: 'Drivers'),
            Tab(icon: Icon(Icons.bar_chart_rounded, size: 20), text: 'Stats'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          const _OrdersTab(),
          const AdminMenuScreen(),
          const _DriversTab(),
          _StatsTab(),
        ],
      ),
    );
  }
}

// ── Orders tab (reuses existing admin orders list) ────────────────────────────

class _OrdersTab extends StatefulWidget {
  const _OrdersTab();

  @override
  State<_OrdersTab> createState() => _OrdersTabState();
}

class _OrdersTabState extends State<_OrdersTab>
    with SingleTickerProviderStateMixin {
  late TabController _inner;

  @override
  void initState() {
    super.initState();
    _inner = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _inner.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        Container(
          color: Colors.white,
          child: TabBar(
            controller: _inner,
            labelColor: cs.primary,
            unselectedLabelColor: const Color(0xFF9E9E9E),
            indicatorColor: cs.primary,
            labelStyle: const TextStyle(
                fontWeight: FontWeight.w700,
                fontFamily: 'Nunito',
                fontSize: 13),
            tabs: const [
              Tab(text: 'Active'),
              Tab(text: 'All Orders'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _inner,
            children: [
              _OrdersList(activeOnly: true),
              _OrdersList(activeOnly: false),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Stats tab ─────────────────────────────────────────────────────────────────

class _StatsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return StreamBuilder<List<Order>>(
      stream: OrderService().allOrdersStream(),
      builder: (context, snap) {
        final orders = (snap.data ?? []).whereType<Order>().toList();
        final total = orders.fold(0.0, (s, o) => s + o.total);
        final active = orders
            .where((o) =>
                o.status != OrderStatus.delivered &&
                o.status != OrderStatus.cancelled)
            .length;
        final delivered =
            orders.where((o) => o.status == OrderStatus.delivered).length;
        final cancelled =
            orders.where((o) => o.status == OrderStatus.cancelled).length;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Revenue card
              _StatHeroCard(
                label: 'Total Revenue',
                value: 'R${total.toStringAsFixed(2)}',
                icon: Icons.payments_outlined,
                color: cs.primary,
              ),
              const SizedBox(height: 16),
              // Grid of smaller stats
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.4,
                children: [
                  _StatCard(
                      label: 'Total Orders',
                      value: '${orders.length}',
                      icon: Icons.receipt_long_outlined,
                      color: Colors.blue),
                  _StatCard(
                      label: 'Active',
                      value: '$active',
                      icon: Icons.pending_outlined,
                      color: Colors.orange),
                  _StatCard(
                      label: 'Delivered',
                      value: '$delivered',
                      icon: Icons.check_circle_outline_rounded,
                      color: cs.primary),
                  _StatCard(
                      label: 'Cancelled',
                      value: '$cancelled',
                      icon: Icons.cancel_outlined,
                      color: cs.error),
                ],
              ),
              const SizedBox(height: 20),
              // Recent orders
              Text('Recent Orders',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              ...orders.take(5).map((o) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _RecentOrderRow(order: o, cs: cs),
                  )),
            ],
          ),
        );
      },
    );
  }
}

class _StatHeroCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatHeroCard(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.75)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.8), fontSize: 13)),
              Text(value,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w900)),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: const TextStyle(
                      fontWeight: FontWeight.w900, fontSize: 22)),
              Text(label,
                  style:
                      const TextStyle(color: Color(0xFF9E9E9E), fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}

class _RecentOrderRow extends StatelessWidget {
  final Order order;
  final ColorScheme cs;

  const _RecentOrderRow({required this.order, required this.cs});

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
              blurRadius: 8,
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
            child: Center(
              child: Text(order.status.emoji,
                  style: const TextStyle(fontSize: 16)),
            ),
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
          Text('R${order.total.toStringAsFixed(2)}',
              style: TextStyle(fontWeight: FontWeight.w800, color: cs.primary)),
        ],
      ),
    );
  }
}

// ── Drivers tab ───────────────────────────────────────────────────────────────

class _DriversTab extends StatelessWidget {
  const _DriversTab();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final db = FirebaseFirestore.instance;

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream:
          db.collection('users').where('role', isEqualTo: 'driver').snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: cs.primary));
        }
        final drivers = snap.data?.docs ?? [];

        return Column(
          children: [
            // Invite / assign driver info
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cs.primaryContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(children: [
                Icon(Icons.info_outline_rounded, color: cs.primary, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'To add a driver, go to Firebase Console → Firestore → users → find their document → set role: "driver"',
                    style: TextStyle(
                        color: cs.onPrimaryContainer,
                        fontSize: 12,
                        height: 1.5),
                  ),
                ),
              ]),
            ),
            if (drivers.isEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.delivery_dining_rounded,
                          size: 56, color: cs.primary),
                      const SizedBox(height: 16),
                      const Text('No drivers yet',
                          style: TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 18)),
                      const SizedBox(height: 8),
                      const Text('Assign the driver role in Firestore',
                          style: TextStyle(color: Color(0xFF9E9E9E))),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  physics: const BouncingScrollPhysics(),
                  itemCount: drivers.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) {
                    final d = drivers[i].data();
                    return Container(
                      padding: const EdgeInsets.all(16),
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
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: cs.primary,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                (d['name'] as String? ?? '?')[0].toUpperCase(),
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 18),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(d['name'] as String? ?? 'Unknown',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 15)),
                                Text(d['email'] as String? ?? '',
                                    style: const TextStyle(
                                        color: Color(0xFF9E9E9E),
                                        fontSize: 12)),
                                if (d['phone'] != null)
                                  Text(d['phone'] as String,
                                      style: const TextStyle(
                                          color: Color(0xFF9E9E9E),
                                          fontSize: 12)),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: cs.primaryContainer,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text('Active',
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: cs.primary)),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }
}

// ── Orders list (used by _OrdersTab) ─────────────────────────────────────────

class _OrdersList extends StatelessWidget {
  final bool activeOnly;
  const _OrdersList({required this.activeOnly});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return StreamBuilder<List<Order>>(
      stream: OrderService().allOrdersStream(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: cs.primary));
        }
        var orders = (snap.data ?? []).whereType<Order>().toList();
        if (activeOnly) {
          orders = orders
              .where((o) =>
                  o.status != OrderStatus.delivered &&
                  o.status != OrderStatus.cancelled)
              .toList();
        }
        if (orders.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox_outlined, size: 56, color: cs.primary),
                const SizedBox(height: 16),
                Text(
                  activeOnly ? 'No active orders' : 'No orders yet',
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 18),
                ),
              ],
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          physics: const BouncingScrollPhysics(),
          itemCount: orders.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (ctx, idx) => _AdminOrderCard(order: orders[idx]),
        );
      },
    );
  }
}

// ── Admin order card ──────────────────────────────────────────────────────────

class _AdminOrderCard extends StatefulWidget {
  final Order order;
  const _AdminOrderCard({required this.order});

  @override
  State<_AdminOrderCard> createState() => _AdminOrderCardState();
}

class _AdminOrderCardState extends State<_AdminOrderCard> {
  bool _updating = false;

  Future<void> _updateStatus(OrderStatus status) async {
    setState(() => _updating = true);
    final success =
        await OrderService().updateOrderStatus(widget.order.id, status);
    if (!mounted) return;
    if (success) {
      await OrderService().markOrderRead(widget.order.id);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Row(children: [
          const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
          const SizedBox(width: 10),
          Text('Order marked as ${status.label}',
              style: const TextStyle(
                  fontFamily: 'Nunito', fontWeight: FontWeight.w600)),
        ]),
        backgroundColor: const Color(0xFF2E7D32),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Row(children: [
          Icon(Icons.error_outline_rounded, color: Colors.white, size: 18),
          SizedBox(width: 10),
          Text('Update failed', style: TextStyle(fontFamily: 'Nunito')),
        ]),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ));
    }
    setState(() => _updating = false);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final order = widget.order;
    final status = order.status;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: status == OrderStatus.pending
            ? Border.all(color: Colors.orange, width: 2)
            : null,
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
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(order.orderNumber ?? order.id.substring(0, 8),
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 2),
                    Text(
                      order.customerName.isNotEmpty
                          ? '${order.customerName} · ${order.customerEmail}'
                          : order.customerEmail,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: const Color(0xFF9E9E9E)),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (order.createdAt != null)
                      Text(_fmt(order.createdAt!),
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: const Color(0xFF9E9E9E))),
                  ],
                ),
              ),
              _StatusBadge(status: status),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          ...order.items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Text('${item.quantity}×',
                        style: TextStyle(
                            fontWeight: FontWeight.w800, color: cs.primary)),
                    const SizedBox(width: 8),
                    Expanded(child: Text(item.food.name)),
                    Text('R${item.totalPrice.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
              )),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
              Text('R${order.total.toStringAsFixed(2)}',
                  style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 17,
                      color: cs.primary)),
            ],
          ),
          if (order.deliveryAddress.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(children: [
              Icon(Icons.location_on_outlined,
                  size: 14, color: Colors.grey.shade400),
              const SizedBox(width: 4),
              Expanded(
                child: Text(order.deliveryAddress,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                    overflow: TextOverflow.ellipsis),
              ),
            ]),
          ],
          const SizedBox(height: 16),
          if (status != OrderStatus.delivered &&
              status != OrderStatus.cancelled)
            _updating
                ? const Center(
                    child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: CircularProgressIndicator(strokeWidth: 2)))
                : _buildActions(status, cs),
        ],
      ),
    );
  }

  Widget _buildActions(OrderStatus current, ColorScheme cs) {
    final next = <OrderStatus>[];
    switch (current) {
      case OrderStatus.pending:
        next.addAll([OrderStatus.confirmed, OrderStatus.cancelled]);
        break;
      case OrderStatus.confirmed:
        next.addAll([OrderStatus.preparing, OrderStatus.cancelled]);
        break;
      case OrderStatus.preparing:
        next.add(OrderStatus.onTheWay);
        break;
      case OrderStatus.onTheWay:
        next.add(OrderStatus.delivered);
        break;
      default:
        break;
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: next.map((s) {
        final cancel = s == OrderStatus.cancelled;
        return GestureDetector(
          onTap: () => _updateStatus(s),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
            decoration: BoxDecoration(
              color: cancel ? cs.error.withOpacity(0.1) : cs.primaryContainer,
              borderRadius: BorderRadius.circular(12),
              border:
                  cancel ? Border.all(color: cs.error.withOpacity(0.3)) : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(s.emoji, style: const TextStyle(fontSize: 14)),
                const SizedBox(width: 6),
                Text('Mark ${s.label}',
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: cancel ? cs.error : cs.primary)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  String _fmt(DateTime dt) {
    final m = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${dt.day} ${m[dt.month - 1]}  ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

// ── Status badge ──────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final OrderStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = _col(cs);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(status.emoji, style: const TextStyle(fontSize: 11)),
          const SizedBox(width: 4),
          Text(status.label,
              style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }

  Color _col(ColorScheme cs) {
    switch (status) {
      case OrderStatus.pending:
        return Colors.orange;
      case OrderStatus.confirmed:
        return cs.primary;
      case OrderStatus.preparing:
        return Colors.blue;
      case OrderStatus.onTheWay:
        return Colors.purple;
      case OrderStatus.delivered:
        return cs.primary;
      case OrderStatus.cancelled:
        return cs.error;
    }
  }
}
