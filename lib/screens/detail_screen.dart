// screens/detail_screen.dart

import 'package:flutter/material.dart';
import '../models/food.dart';
import '../providers/cart_provider.dart';

class DetailScreen extends StatefulWidget {
  final Food food;
  final CartProvider cartProvider;

  const DetailScreen({
    super.key,
    required this.food,
    required this.cartProvider,
  });

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen>
    with TickerProviderStateMixin {
  late AnimationController _contentController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  int _quantity = 1;
  bool _isFavourite = false;

  Food get food => widget.food;

  @override
  void initState() {
    super.initState();
    _contentController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(
        parent: _contentController, curve: Curves.easeOutCubic));
    _fadeAnimation =
        CurvedAnimation(parent: _contentController, curve: Curves.easeOut);
    _contentController.forward();
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  void _addToCart() {
    final cp = widget.cartProvider;
    // Add the desired quantity
    for (int i = 0; i < _quantity; i++) {
      cp.addItem(food);
    }
    _showAddedSnackbar();
  }

  void _showAddedSnackbar() {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded,
                color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Text(
              '${food.name} added to cart!',
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: cs.background,
      body: Stack(
        children: [
          // Food Image
          SizedBox(
            height: size.height * 0.46,
            width: double.infinity,
            child: Image.network(
              food.imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: cs.primaryContainer,
                child: Icon(Icons.restaurant, color: cs.primary, size: 80),
              ),
            ),
          ),

          // Back & favourite buttons
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _CircleButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    onTap: () => Navigator.pop(context),
                  ),
                  _CircleButton(
                    icon: _isFavourite
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    iconColor: _isFavourite ? Colors.red : null,
                    onTap: () => setState(() => _isFavourite = !_isFavourite),
                  ),
                ],
              ),
            ),
          ),

          // Bottom sheet content
          DraggableScrollableSheet(
            initialChildSize: 0.6,
            minChildSize: 0.58,
            maxChildSize: 0.95,
            builder: (ctx, scrollCtrl) {
              final bottomInset = MediaQuery.of(context).padding.bottom;
              return FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(28)),
                    ),
                    child: ListView(
                      controller: scrollCtrl,
                      padding:
                          EdgeInsets.fromLTRB(24, 20, 24, 120 + bottomInset),
                      children: [
                        // Drag handle
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE0E0E0),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Name & price row
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                food.name,
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  color: const Color(0xFF1B2B1C),
                                  height: 1.2,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'R${food.price.toStringAsFixed(2)}',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w900,
                                color: cs.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Stat chips
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _StatChip(
                              icon: Icons.star_rounded,
                              iconColor: const Color(0xFFFFB300),
                              label: '${food.rating} (${food.reviewCount})',
                            ),
                            _StatChip(
                              icon: Icons.schedule_rounded,
                              iconColor: cs.primary,
                              label: '${food.prepTimeMinutes} min',
                            ),
                            _StatChip(
                              icon: Icons.local_fire_department_rounded,
                              iconColor: Colors.deepOrange,
                              label: '${food.calories} cal',
                            ),
                            if (food.isVegetarian)
                              const _StatChip(
                                icon: Icons.eco_rounded,
                                iconColor: Colors.green,
                                label: 'Vegetarian',
                              ),
                          ],
                        ),
                        const SizedBox(height: 22),

                        // Description
                        Text(
                          'About',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF1B2B1C),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          food.description,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: const Color(0xFF6E6E6E),
                            height: 1.6,
                          ),
                        ),
                        const SizedBox(height: 22),

                        // Ingredients
                        if (food.ingredients.isNotEmpty) ...[
                          Text(
                            'Ingredients',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF1B2B1C),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: food.ingredients
                                .map(
                                  (ing) => Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: cs.primaryContainer,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      ing,
                                      style: TextStyle(
                                        fontFamily: 'Nunito',
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: cs.onPrimaryContainer,
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                          const SizedBox(height: 22),
                        ],

                        // Quantity selector
                        Row(
                          children: [
                            Text(
                              'Quantity',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF1B2B1C),
                              ),
                            ),
                            const Spacer(),
                            _QuantitySelector(
                              quantity: _quantity,
                              onDecrement: () {
                                if (_quantity > 1) {
                                  setState(() => _quantity--);
                                }
                              },
                              onIncrement: () => setState(() => _quantity++),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),

          // Bottom add-to-cart bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 16,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Total',
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 12,
                            color: Color(0xFF9E9E9E),
                          ),
                        ),
                        Text(
                          'R${(food.price * _quantity).toStringAsFixed(2)}',
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: cs.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _addToCart,
                        icon: const Icon(Icons.shopping_bag_outlined, size: 20),
                        label: const Text('Add to Cart'),
                      ),
                    ),
                  ],
                ),
              ),
            ), // SafeArea
          ),
        ],
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color? iconColor;

  const _CircleButton({
    required this.icon,
    required this.onTap,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child:
            Icon(icon, size: 20, color: iconColor ?? const Color(0xFF1B2B1C)),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;

  const _StatChip({
    required this.icon,
    required this.iconColor,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: iconColor),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF4A4A4A),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuantitySelector extends StatelessWidget {
  final int quantity;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  const _QuantitySelector({
    required this.quantity,
    required this.onDecrement,
    required this.onIncrement,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.primaryContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          _QBtn(
              icon: Icons.remove_rounded,
              onTap: onDecrement,
              active: quantity > 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              '$quantity',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: cs.onPrimaryContainer,
              ),
            ),
          ),
          _QBtn(icon: Icons.add_rounded, onTap: onIncrement, active: true),
        ],
      ),
    );
  }
}

class _QBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool active;

  const _QBtn({required this.icon, required this.onTap, required this.active});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: active ? onTap : null,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: active ? cs.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon,
            size: 20,
            color:
                active ? Colors.white : cs.onPrimaryContainer.withOpacity(0.4)),
      ),
    );
  }
}
