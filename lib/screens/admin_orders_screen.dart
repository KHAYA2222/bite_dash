// screens/admin_orders_screen.dart
// Admin dashboard — see all orders in real time, update status.
// Access: Profile → Admin Orders (only shows when user email matches admin list)

import 'package:flutter/material.dart';
import '../models/food.dart';
import '../services/order_service.dart';

class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Admin — Orders',
            style: theme.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w900)),
        bottom: TabBar(
          controller: _tabs,
          labelColor: cs.primary,
          unselectedLabelColor: const Color(0xFF9E9E9E),
          indicatorColor: cs.primary,
          labelStyle: const TextStyle(
              fontWeight: FontWeight.w700, fontFamily: 'Nunito'),
          tabs: const [
            Tab(text: 'Active'),
            Tab(text: 'All Orders'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _OrdersList(activeOnly: true),
          _OrdersList(activeOnly: false),
        ],
      ),
    );
  }
}

class _OrdersList extends StatelessWidget {
  final bool activeOnly;
  const _OrdersList({required this.activeOnly});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return StreamBuilder<List<Order>>(
      stream: OrderService().allOrdersStream().map((items) => items.cast<Order>()),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: cs.primary));
        }

        var orders = snap.data ?? [];
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
    await OrderService().updateOrderStatus(widget.order.id, status);
    await OrderService().markOrderRead(widget.order.id);
    if (mounted) setState(() => _updating = false);
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
        border: order.status == OrderStatus.pending
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
          // ── Header ─────────────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.orderNumber ?? order.id.substring(0, 8),
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w900),
                    ),
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
                      Text(
                        _formatDate(order.createdAt!),
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: const Color(0xFF9E9E9E)),
                      ),
                  ],
                ),
              ),
              _StatusBadge(status: status),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),

          // ── Items ───────────────────────────────────────────────────────
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

          // ── Totals ──────────────────────────────────────────────────────
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
            Row(
              children: [
                Icon(Icons.location_on_outlined,
                    size: 14, color: Colors.grey.shade400),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    order.deliveryAddress,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),

          // ── Status action buttons ────────────────────────────────────────
          if (status != OrderStatus.delivered &&
              status != OrderStatus.cancelled)
            _updating
                ? const Center(
                    child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ))
                : _buildActionButtons(status, cs),
        ],
      ),
    );
  }

  Widget _buildActionButtons(OrderStatus current, ColorScheme cs) {
    // Show only the logical next step(s)
    final nextSteps = <OrderStatus>[];
    switch (current) {
      case OrderStatus.pending:
        nextSteps.addAll([OrderStatus.confirmed, OrderStatus.cancelled]);
        break;
      case OrderStatus.confirmed:
        nextSteps.addAll([OrderStatus.preparing, OrderStatus.cancelled]);
        break;
      case OrderStatus.preparing:
        nextSteps.add(OrderStatus.onTheWay);
        break;
      case OrderStatus.onTheWay:
        nextSteps.add(OrderStatus.delivered);
        break;
      default:
        break;
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: nextSteps.map((status) {
        final isCancel = status == OrderStatus.cancelled;
        return GestureDetector(
          onTap: () => _updateStatus(status),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
            decoration: BoxDecoration(
              color: isCancel ? cs.error.withOpacity(0.1) : cs.primaryContainer,
              borderRadius: BorderRadius.circular(12),
              border: isCancel
                  ? Border.all(color: cs.error.withOpacity(0.3))
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(status.emoji, style: const TextStyle(fontSize: 14)),
                const SizedBox(width: 6),
                Text(
                  'Mark ${status.label}',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: isCancel ? cs.error : cs.primary,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  String _formatDate(DateTime dt) {
    final months = [
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
    return '${dt.day} ${months[dt.month - 1]}  '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

class _StatusBadge extends StatelessWidget {
  final OrderStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = _color(cs);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
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

  Color _color(ColorScheme cs) {
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
