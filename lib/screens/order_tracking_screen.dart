// screens/order_tracking_screen.dart
// Real-time order status tracker shown immediately after placing an order.

import 'package:flutter/material.dart';
import '../models/food.dart';
import '../services/order_service.dart';

class OrderTrackingScreen extends StatelessWidget {
  final Order order;
  const OrderTrackingScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Order?>(
      stream: OrderService().orderStream(order.id).cast<Order?>(),
      initialData: order,
      builder: (context, snap) {
        final current = snap.data ?? order;
        return _TrackingView(order: current);
      },
    );
  }
}

class _TrackingView extends StatelessWidget {
  final Order order;
  const _TrackingView({required this.order});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final status = order.status;
    final isCancelled = status == OrderStatus.cancelled;
    final isDelivered = status == OrderStatus.delivered;

    return Scaffold(
      backgroundColor: cs.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Track Order',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w900)),
            if (order.orderNumber != null)
              Text(order.orderNumber!,
                  style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.primary, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Status hero ────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isCancelled
                      ? [cs.error, cs.error.withOpacity(0.8)]
                      : isDelivered
                          ? [const Color(0xFF1B5E20), cs.primary]
                          : [cs.primary, const Color(0xFF1B5E20)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [
                  Text(status.emoji, style: const TextStyle(fontSize: 52)),
                  const SizedBox(height: 12),
                  Text(
                    status.label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    status.description,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Progress stepper ───────────────────────────────────────────
            if (!isCancelled) ...[
              _buildStepper(cs, theme),
              const SizedBox(height: 24),
            ],

            // ── Order summary card ─────────────────────────────────────────
            _InfoCard(
              title: 'Order Summary',
              icon: Icons.receipt_long_outlined,
              child: Column(
                children: [
                  ...order.items.map((item) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: cs.primaryContainer,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Text(
                                  '${item.quantity}×',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12,
                                    color: cs.primary,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(item.food.name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600)),
                            ),
                            Text(
                              'R${item.totalPrice.toStringAsFixed(2)}',
                              style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: cs.primary),
                            ),
                          ],
                        ),
                      )),
                  const Divider(height: 20),
                  _SummaryRow(
                      'Subtotal', 'R${order.subtotal.toStringAsFixed(2)}'),
                  const SizedBox(height: 4),
                  _SummaryRow(
                    'Delivery',
                    order.deliveryFee == 0
                        ? 'FREE'
                        : 'R${order.deliveryFee.toStringAsFixed(2)}',
                    valueColor: order.deliveryFee == 0 ? cs.primary : null,
                  ),
                  const SizedBox(height: 8),
                  _SummaryRow(
                    'Total',
                    'R${order.total.toStringAsFixed(2)}',
                    bold: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Delivery info ──────────────────────────────────────────────
            if (order.deliveryAddress.isNotEmpty)
              _InfoCard(
                title: 'Delivery Address',
                icon: Icons.location_on_outlined,
                child: Text(
                  order.deliveryAddress,
                  style: const TextStyle(height: 1.5),
                ),
              ),
            const SizedBox(height: 24),

            // ── Done button ────────────────────────────────────────────────
            ElevatedButton(
              onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
              style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52)),
              child: const Text('Back to Home'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepper(ColorScheme cs, ThemeData theme) {
    // Only show the first 5 statuses (exclude cancelled)
    final steps = [
      OrderStatus.pending,
      OrderStatus.confirmed,
      OrderStatus.preparing,
      OrderStatus.onTheWay,
      OrderStatus.delivered,
    ];
    final currentStep = steps.indexOf(order.status);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        children: steps.asMap().entries.map((entry) {
          final idx = entry.key;
          final step = entry.value;
          final isDone = idx < currentStep;
          final isCurrent = idx == currentStep;
          final isLast = idx == steps.length - 1;

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Circle + line
              Column(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDone || isCurrent
                          ? cs.primary
                          : const Color(0xFFE0E0E0),
                      border: isCurrent
                          ? Border.all(color: cs.primary, width: 3)
                          : null,
                    ),
                    child: Center(
                      child: isDone
                          ? const Icon(Icons.check_rounded,
                              color: Colors.white, size: 16)
                          : Text(
                              step.emoji,
                              style: const TextStyle(fontSize: 14),
                            ),
                    ),
                  ),
                  if (!isLast)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 2,
                      height: 32,
                      color: isDone ? cs.primary : const Color(0xFFE0E0E0),
                    ),
                ],
              ),
              const SizedBox(width: 14),
              // Label
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(top: 4, bottom: isLast ? 0 : 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        step.label,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: isCurrent
                              ? cs.primary
                              : isDone
                                  ? const Color(0xFF1B2B1C)
                                  : const Color(0xFF9E9E9E),
                        ),
                      ),
                      if (isCurrent) ...[
                        const SizedBox(height: 2),
                        Text(
                          step.description,
                          style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF6E6E6E),
                              height: 1.4),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

// ── Shared widgets ────────────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _InfoCard(
      {required this.title, required this.icon, required this.child});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, color: cs.primary, size: 18),
            const SizedBox(width: 8),
            Text(title,
                style:
                    const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
          ]),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  final Color? valueColor;

  const _SummaryRow(this.label, this.value,
      {this.bold = false, this.valueColor});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
                fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
                fontSize: bold ? 16 : 14,
                color:
                    bold ? const Color(0xFF1B2B1C) : const Color(0xFF6E6E6E))),
        Text(value,
            style: TextStyle(
                fontWeight: bold ? FontWeight.w900 : FontWeight.w600,
                fontSize: bold ? 18 : 14,
                color: valueColor ??
                    (bold ? cs.primary : const Color(0xFF6E6E6E)))),
      ],
    );
  }
}
