// screens/orders_screen.dart
// User's full order history with tap-to-track.

import 'package:flutter/material.dart';
import '../models/food.dart';
import '../services/order_service.dart';
import 'order_tracking_screen.dart';

class OrdersScreen extends StatelessWidget {
  final String userId;
  const OrdersScreen({super.key, required this.userId});

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
        title: Text('My Orders',
            style: theme.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w900)),
      ),
      body: StreamBuilder<List<Order>>(
        stream: OrderService().userOrdersStream(userId).cast<List<Order>>(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: cs.primary));
          }
          final orders = snap.data ?? [];
          if (orders.isEmpty) {
            return _buildEmpty(cs, theme);
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            physics: const BouncingScrollPhysics(),
            itemCount: orders.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (ctx, idx) => _OrderCard(order: orders[idx]),
          );
        },
      ),
    );
  }

  Widget _buildEmpty(ColorScheme cs, ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
                color: cs.primaryContainer, shape: BoxShape.circle),
            child:
                Icon(Icons.receipt_long_outlined, color: cs.primary, size: 44),
          ),
          const SizedBox(height: 20),
          Text('No orders yet',
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Text('Your order history will appear here.',
              style: TextStyle(color: Colors.grey.shade500)),
        ],
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Order order;
  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final status = order.status;
    final isActive =
        status != OrderStatus.delivered && status != OrderStatus.cancelled;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => OrderTrackingScreen(order: order)),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
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
            // Header row
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
                      if (order.createdAt != null)
                        Text(
                          _formatDate(order.createdAt!),
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: const Color(0xFF9E9E9E)),
                        ),
                    ],
                  ),
                ),
                // Status badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _statusColor(status, cs).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(status.emoji, style: const TextStyle(fontSize: 12)),
                      const SizedBox(width: 5),
                      Text(
                        status.label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _statusColor(status, cs),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),

            // Items preview
            Text(
              order.items
                  .map((i) => '${i.quantity}× ${i.food.name}')
                  .join(', '),
              style: theme.textTheme.bodySmall?.copyWith(
                color: const Color(0xFF6E6E6E),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 10),

            // Total + track button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'R${order.total.toStringAsFixed(2)}',
                  style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      color: cs.primary),
                ),
                if (isActive)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: cs.primaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.location_on_rounded,
                            size: 14, color: cs.primary),
                        const SizedBox(width: 4),
                        Text('Track Order',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: cs.primary)),
                      ],
                    ),
                  )
                else
                  Text(
                    '${order.itemCount} item${order.itemCount == 1 ? '' : 's'}',
                    style:
                        const TextStyle(color: Color(0xFF9E9E9E), fontSize: 13),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(OrderStatus status, ColorScheme cs) {
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
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}  '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
