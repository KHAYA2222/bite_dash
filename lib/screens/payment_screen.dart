// screens/payment_screen.dart
//
// Checkout screen with Cash on Delivery (active now) and
// PayFast toggle (ready to enable when you go live).
// To enable PayFast: set _usePayFast = true or read from AppConfig.

import 'package:flutter/material.dart';
import '../config/app_config.dart';
import '../models/food.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../services/order_service.dart';
import '../services/payment_service.dart';
import 'delivery_address_screen.dart';
import 'order_tracking_screen.dart';
import 'payfast_webview.dart';

class PaymentScreen extends StatefulWidget {
  final CartProvider cartProvider;
  final AuthProvider authProvider;

  const PaymentScreen({
    super.key,
    required this.cartProvider,
    required this.authProvider,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  // ── Toggle this to switch between COD and PayFast ───────────────────────────
  // false = Cash on Delivery (current default)
  // true  = PayFast live payments
  static const bool _usePayFast = false;

  bool _isProcessing = false;
  String _selectedMethod = 'cod'; // 'cod' | 'payfast'

  CartProvider get cart => widget.cartProvider;

  // ── Ensure address is saved before proceeding ───────────────────────────────
  Future<bool> _ensureAddress() async {
    final address = widget.authProvider.currentUser?.deliveryAddress ?? '';
    if (address.isNotEmpty) return true;

    final saved = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => DeliveryAddressScreen(
          authProvider: widget.authProvider,
          isCheckout: true,
        ),
      ),
    );
    return saved != null && saved.isNotEmpty;
  }

  // ── Cash on Delivery flow ───────────────────────────────────────────────────
  Future<void> _placeCodOrder() async {
    setState(() => _isProcessing = true);
    final user = widget.authProvider.currentUser;

    final order = await OrderService().placeOrder(
      userId: user?.id ?? '',
      customerName: user?.name ?? '',
      customerEmail: user?.email ?? '',
      items: cart.items.toList(),
      subtotal: cart.subtotal,
      deliveryFee: cart.deliveryFee,
      total: cart.total,
      deliveryAddress: user?.deliveryAddress ?? '',
      paymentMethod: 'cod',
      paymentStatus: 'pending',
    );

    setState(() => _isProcessing = false);

    if (!mounted) return;

    if (order == null) {
      _showError('Could not place order. Please try again.');
      return;
    }

    cart.clearCart();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => OrderTrackingScreen(order: order)),
    );
  }

  // ── PayFast flow ────────────────────────────────────────────────────────────
  Future<void> _placePayFastOrder() async {
    setState(() => _isProcessing = true);
    final user = widget.authProvider.currentUser;

    // Create pending order first
    final order = await OrderService().placeOrder(
      userId: user?.id ?? '',
      customerName: user?.name ?? '',
      customerEmail: user?.email ?? '',
      items: cart.items.toList(),
      subtotal: cart.subtotal,
      deliveryFee: cart.deliveryFee,
      total: cart.total,
      deliveryAddress: user?.deliveryAddress ?? '',
      paymentMethod: 'payfast',
      paymentStatus: 'awaiting_payment',
    );

    setState(() => _isProcessing = false);
    if (!mounted || order == null) {
      _showError('Could not initiate payment. Please try again.');
      return;
    }

    // Build PayFast URL and open WebView
    final paymentUrl = PaymentService().buildPaymentUrl(
      orderId: order.id,
      orderNumber: order.orderNumber ?? order.id,
      amount: cart.total,
      customerName: user?.name ?? 'Customer',
      customerEmail: user?.email ?? '',
      itemName: '${AppConfig.appName} Order',
    );

    final result = await Navigator.push<PaymentResult>(
      context,
      MaterialPageRoute(
        builder: (_) => PayfastWebView(
          paymentUrl: paymentUrl,
          orderNumber: order.orderNumber ?? order.id,
        ),
      ),
    );

    if (!mounted) return;

    if (result == PaymentResult.success) {
      cart.clearCart();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => OrderTrackingScreen(order: order)),
      );
    } else {
      await OrderService().updateOrderStatus(order.id, OrderStatus.cancelled);
      _showError('Payment cancelled. Your order was not placed.');
    }
  }

  // ── Main handler ─────────────────────────────────────────────────────────────
  Future<void> _onConfirm() async {
    if (!await _ensureAddress()) return;

    if (_usePayFast || _selectedMethod == 'payfast') {
      await _placePayFastOrder();
    } else {
      await _placeCodOrder();
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontFamily: 'Nunito')),
      backgroundColor: Theme.of(context).colorScheme.error,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      margin: const EdgeInsets.all(16),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final user = widget.authProvider.currentUser;

    return Scaffold(
      backgroundColor: cs.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Checkout',
            style: theme.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w900)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        physics: const BouncingScrollPhysics(),
        children: [
          // ── Delivery address ───────────────────────────────────────────────
          _Section(
            title: 'Delivering to',
            icon: Icons.location_on_outlined,
            child: (user?.deliveryAddress?.isNotEmpty == true)
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user!.deliveryAddress!,
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(height: 1.5)),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DeliveryAddressScreen(
                                authProvider: widget.authProvider),
                          ),
                        ),
                        child: Text('Change address',
                            style: TextStyle(
                                color: cs.primary,
                                fontWeight: FontWeight.w700,
                                fontSize: 13)),
                      ),
                    ],
                  )
                : GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DeliveryAddressScreen(
                            authProvider: widget.authProvider,
                            isCheckout: true),
                      ),
                    ),
                    child: Row(children: [
                      Icon(Icons.add_rounded, color: cs.primary, size: 18),
                      const SizedBox(width: 6),
                      Text('Add delivery address',
                          style: TextStyle(
                              color: cs.primary, fontWeight: FontWeight.w700)),
                    ]),
                  ),
          ),
          const SizedBox(height: 16),

          // ── Order items ────────────────────────────────────────────────────
          _Section(
            title: 'Your order',
            icon: Icons.receipt_long_outlined,
            child: Column(
              children: [
                ...cart.items.map((item) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: Row(children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: cs.primaryContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text('${item.quantity}×',
                                style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 11,
                                    color: cs.primary)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(item.food.name,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600)),
                        ),
                        Text('R${item.totalPrice.toStringAsFixed(2)}',
                            style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: cs.primary)),
                      ]),
                    )),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Divider(height: 1),
                ),
                _SummaryRow('Subtotal', 'R${cart.subtotal.toStringAsFixed(2)}'),
                const SizedBox(height: 6),
                _SummaryRow(
                  'Delivery',
                  cart.freeDelivery
                      ? 'FREE'
                      : 'R${cart.deliveryFee.toStringAsFixed(2)}',
                  valueColor: cart.freeDelivery ? cs.primary : null,
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Divider(height: 1),
                ),
                _SummaryRow(
                  'Total',
                  'R${cart.total.toStringAsFixed(2)}',
                  bold: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Payment method ─────────────────────────────────────────────────
          _Section(
            title: 'Payment method',
            icon: Icons.payments_outlined,
            child: Column(
              children: [
                // Cash on Delivery
                _PaymentOption(
                  label: 'Cash on Delivery',
                  subtitle: 'Pay the driver when your order arrives',
                  icon: Icons.money_rounded,
                  selected: _selectedMethod == 'cod' || !_usePayFast,
                  onTap: _usePayFast
                      ? () => setState(() => _selectedMethod = 'cod')
                      : null,
                ),
                if (_usePayFast) ...[
                  const SizedBox(height: 10),
                  // PayFast (only shown when _usePayFast = true)
                  _PaymentOption(
                    label: 'Pay with PayFast',
                    subtitle: 'Card, EFT, Ozow and more',
                    icon: Icons.credit_card_rounded,
                    selected: _selectedMethod == 'payfast',
                    onTap: () => setState(() => _selectedMethod = 'payfast'),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 32),

          // ── Confirm button ─────────────────────────────────────────────────
          ElevatedButton(
            onPressed: _isProcessing ? null : _onConfirm,
            style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 56)),
            child: _isProcessing
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.5, color: Colors.white))
                : Text(
                    _selectedMethod == 'payfast' && _usePayFast
                        ? 'Pay R${cart.total.toStringAsFixed(2)} with PayFast'
                        : 'Place Order — Pay on Delivery',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w800),
                  ),
          ),
          const SizedBox(height: 12),
          Text(
            _selectedMethod == 'payfast' && _usePayFast
                ? 'You will be securely redirected to PayFast.'
                : 'Your driver will collect R${cart.total.toStringAsFixed(2)} in cash on arrival.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: const Color(0xFF9E9E9E)),
          ),
        ],
      ),
    );
  }
}

// ── Widgets ───────────────────────────────────────────────────────────────────

class _PaymentOption extends StatelessWidget {
  final String label;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback? onTap;

  const _PaymentOption({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.selected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? cs.primaryContainer : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? cs.primary : Colors.grey.shade200,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: selected ? cs.primary : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon,
                color: selected ? Colors.white : Colors.grey.shade500,
                size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: selected
                            ? cs.onPrimaryContainer
                            : const Color(0xFF1B2B1C))),
                Text(subtitle,
                    style: TextStyle(
                        fontSize: 12,
                        color:
                            selected ? cs.primary : const Color(0xFF9E9E9E))),
              ],
            ),
          ),
          if (selected)
            Icon(Icons.check_circle_rounded, color: cs.primary, size: 22),
        ]),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  const _Section(
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
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
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
