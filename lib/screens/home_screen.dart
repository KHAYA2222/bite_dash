// screens/home_screen.dart

import 'package:flutter/material.dart';
import '../models/food.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../services/food_service.dart';
import '../widgets/food_card.dart';
import 'cart_screen.dart';
import 'profile_screen.dart';
import 'detail_screen.dart';

class HomeScreen extends StatefulWidget {
  final AuthProvider authProvider;
  const HomeScreen({super.key, required this.authProvider});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final CartProvider _cartProvider = CartProvider();
  final FoodService _foodService = FoodService();
  String _selectedCategory = 'All';
  String _searchQuery = '';
  int _selectedNavIndex = 0;
  late final AnimationController _fadeController;
  final TextEditingController _searchController = TextEditingController();

  // Firestore streams — rebuild UI on data changes
  Stream<List<Food>> get _foodsStream =>
      _foodService.foodsStream(category: _selectedCategory);
  Stream<List<Food>> get _popularStream => _foodService.popularStream();
  Stream<List<String>> get _categoriesStream => _foodService.categoriesStream();

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _navigateToDetail(Food food) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (ctx, anim, _) => DetailScreen(
          food: food,
          cartProvider: _cartProvider,
        ),
        transitionsBuilder: (ctx, anim, _, child) {
          return FadeTransition(
            opacity: anim,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.05),
                end: Offset.zero,
              ).animate(
                  CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
  }

  void _navigateToCart() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (ctx, anim, _) => CartScreen(
            cartProvider: _cartProvider, authProvider: widget.authProvider),
        transitionsBuilder: (ctx, anim, _, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1, 0),
              end: Offset.zero,
            ).animate(
                CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 320),
      ),
    );
  }

  void _navigateToProfile() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (ctx, anim, _) =>
            ProfileScreen(authProvider: widget.authProvider),
        transitionsBuilder: (ctx, anim, _, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1, 0),
              end: Offset.zero,
            ).animate(
                CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 320),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      backgroundColor: cs.background,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeController,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // App Bar — ListenableBuilder so name/initials update after profile edit
              SliverToBoxAdapter(
                child: ListenableBuilder(
                  listenable: widget.authProvider,
                  builder: (_, __) => _buildHeader(cs, theme),
                ),
              ),

              // Search
              SliverToBoxAdapter(child: _buildSearch(cs)),

              // Banner
              SliverToBoxAdapter(child: _buildPromoBanner(cs, theme)),

              // Popular section
              SliverToBoxAdapter(
                child: _buildSectionHeader('🔥 Popular Right Now', theme),
              ),
              SliverToBoxAdapter(child: _buildPopularList()),

              // Category chips
              SliverToBoxAdapter(
                  child: _buildSectionHeader('Explore Menu', theme)),
              SliverToBoxAdapter(child: _buildCategories(cs, theme)),

              // Food grid — live Firestore stream
              StreamBuilder<List<Food>>(
                stream: _foodsStream,
                builder: (ctx, snap) {
                  if (snap.connectionState == ConnectionState.waiting &&
                      !snap.hasData) {
                    return SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 60),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: cs.primary,
                            strokeWidth: 2.5,
                          ),
                        ),
                      ),
                    );
                  }
                  // Apply client-side search filter
                  var foods = snap.data ?? [];
                  if (_searchQuery.isNotEmpty) {
                    final q = _searchQuery.toLowerCase();
                    foods = foods
                        .where((f) =>
                            f.name.toLowerCase().contains(q) ||
                            f.tags.any((t) => t.toLowerCase().contains(q)))
                        .toList();
                  }
                  if (foods.isEmpty) {
                    return SliverToBoxAdapter(child: _buildEmptyState(cs));
                  }
                  return SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                    sliver: SliverGrid(
                      delegate: SliverChildBuilderDelegate(
                        (ctx, idx) {
                          final food = foods[idx];
                          return ListenableBuilder(
                            listenable: _cartProvider,
                            builder: (_, __) => FoodCard(
                              food: food,
                              isInCart: _cartProvider.isInCart(food.id),
                              onTap: () => _navigateToDetail(food),
                              onAddToCart: () => _cartProvider.addItem(food),
                            ),
                          );
                        },
                        childCount: foods.length,
                      ),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 14,
                        crossAxisSpacing: 14,
                        childAspectRatio: 0.72,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),

      // Bottom Nav
      bottomNavigationBar: _buildBottomNav(cs, theme),

      // FAB Cart
      floatingActionButton: ListenableBuilder(
        listenable: _cartProvider,
        builder: (_, __) {
          if (_cartProvider.itemCount == 0) return const SizedBox.shrink();
          return FloatingActionButton.extended(
            onPressed: _navigateToCart,
            backgroundColor: cs.primary,
            foregroundColor: Colors.white,
            elevation: 4,
            icon: const Icon(Icons.shopping_bag_outlined),
            label: Text(
              '${_cartProvider.itemCount} items · R${_cartProvider.total.toStringAsFixed(2)}',
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontWeight: FontWeight.w800,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(ColorScheme cs, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 16, 0),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Good day! 👋',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: cs.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                widget.authProvider.currentUser?.name.split(' ').first ??
                    'Foodie',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF1B2B1C),
                ),
              ),
            ],
          ),
          const Spacer(),
          ListenableBuilder(
            listenable: _cartProvider,
            builder: (_, __) => Stack(
              children: [
                IconButton(
                  onPressed: _navigateToCart,
                  icon: const Icon(Icons.shopping_bag_outlined),
                  color: const Color(0xFF1B2B1C),
                  iconSize: 26,
                ),
                if (_cartProvider.itemCount > 0)
                  Positioned(
                    right: 6,
                    top: 6,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: cs.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${_cartProvider.itemCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            fontFamily: 'Nunito',
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          GestureDetector(
            onTap: _navigateToProfile,
            child: CircleAvatar(
              radius: 20,
              backgroundColor: cs.primary,
              child: Text(
                widget.authProvider.currentUser?.initials ?? '?',
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearch(ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: TextField(
        controller: _searchController,
        onChanged: (v) => setState(() => _searchQuery = v),
        decoration: InputDecoration(
          hintText: 'Search food, drinks...',
          prefixIcon: Icon(Icons.search_rounded, color: cs.primary, size: 22),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 20),
                  color: const Color(0xFF9E9E9E),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildPromoBanner(ColorScheme cs, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Container(
        height: 140,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              cs.primary,
              const Color(0xFF1B5E20),
            ],
          ),
        ),
        child: Stack(
          children: [
            // Decorative circles
            Positioned(
              right: -20,
              top: -20,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.07),
                ),
              ),
            ),
            Positioned(
              right: 40,
              bottom: -30,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.07),
                ),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      '🚚 Free Delivery',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Nunito',
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Free delivery on orders over R${kFreeDeliveryThreshold.toStringAsFixed(0)}',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      height: 1.2,
                      fontFamily: 'Nunito',
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Order Now',
                      style: TextStyle(
                        color: cs.primary,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Nunito',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
      child: Text(
        title,
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w900,
          color: const Color(0xFF1B2B1C),
        ),
      ),
    );
  }

  Widget _buildPopularList() {
    return SizedBox(
      height: 110,
      child: StreamBuilder<List<Food>>(
        stream: _popularStream,
        builder: (ctx, snap) {
          final popular = snap.data ?? [];
          if (popular.isEmpty) {
            return const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            );
          }
          return ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            physics: const BouncingScrollPhysics(),
            itemCount: popular.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (ctx, idx) {
              final food = popular[idx];
              return ListenableBuilder(
                listenable: _cartProvider,
                builder: (_, __) => FoodCardHorizontal(
                  food: food,
                  isInCart: _cartProvider.isInCart(food.id),
                  onTap: () => _navigateToDetail(food),
                  onAddToCart: () => _cartProvider.addItem(food),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildCategories(ColorScheme cs, ThemeData theme) {
    return SizedBox(
      height: 42,
      child: StreamBuilder<List<String>>(
        stream: _categoriesStream,
        builder: (ctx, snap) {
          final categories = snap.data ?? ['All'];
          return ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            physics: const BouncingScrollPhysics(),
            itemCount: categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (ctx, idx) {
              final cat = categories[idx];
              final selected = _selectedCategory == cat;
              return GestureDetector(
                onTap: () => setState(() => _selectedCategory = cat),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  decoration: BoxDecoration(
                    color: selected ? cs.primary : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      if (!selected)
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                    ],
                  ),
                  child: Text(
                    cat,
                    style: TextStyle(
                      color: selected ? Colors.white : const Color(0xFF6E6E6E),
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(
        children: [
          Icon(Icons.search_off_rounded, size: 60, color: cs.primary),
          const SizedBox(height: 16),
          Text(
            'No results found',
            style: TextStyle(
              fontFamily: 'Nunito',
              fontWeight: FontWeight.w800,
              fontSize: 18,
              color: const Color(0xFF1B2B1C),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try a different search or category',
            style: TextStyle(
              fontFamily: 'Nunito',
              color: const Color(0xFF9E9E9E),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav(ColorScheme cs, ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: NavigationBar(
        elevation: 0,
        backgroundColor: Colors.white,
        selectedIndex: _selectedNavIndex,
        onDestinationSelected: (idx) {
          if (idx == 2) {
            _navigateToCart();
            return;
          }
          if (idx == 3) {
            _navigateToProfile();
            return;
          }
          setState(() => _selectedNavIndex = idx);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore_rounded),
            label: 'Explore',
          ),
          NavigationDestination(
            icon: Icon(Icons.shopping_bag_outlined),
            selectedIcon: Icon(Icons.shopping_bag_rounded),
            label: 'Cart',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
