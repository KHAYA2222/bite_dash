// screens/admin_menu_screen.dart
// Admin menu management — view, add, edit, delete food items.

import 'package:flutter/material.dart';
import '../models/food.dart';
import '../services/food_service.dart';

class AdminMenuScreen extends StatefulWidget {
  const AdminMenuScreen({super.key});

  @override
  State<AdminMenuScreen> createState() => _AdminMenuScreenState();
}

class _AdminMenuScreenState extends State<AdminMenuScreen> {
  List<Food> _foods = [];
  bool _loading = true;
  String _selectedCategory = 'All';
  List<String> _categories = ['All'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final foods = await FoodService().getAllFoods();
    final cats = await FoodService().getCategories();
    if (mounted) {
      setState(() {
        _foods = foods;
        _categories = ['All', ...cats];
        _loading = false;
      });
    }
  }

  List<Food> get _filtered {
    if (_selectedCategory == 'All') return _foods;
    return _foods.where((f) => f.category == _selectedCategory).toList();
  }

  void _openForm({Food? food}) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _FoodFormSheet(
        food: food,
        categories: _categories.where((c) => c != 'All').toList(),
      ),
    );
    if (result == true) _load();
  }

  Future<void> _delete(Food food) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Item',
            style: TextStyle(fontWeight: FontWeight.w800)),
        content: Text('Remove "${food.name}" from the menu?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await FoodService().deleteFood(food.id);
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.background,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        backgroundColor: cs.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Item',
            style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: cs.primary))
          : Column(
              children: [
                // Category filter
                SizedBox(
                  height: 54,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: _categories.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, i) {
                      final cat = _categories[i];
                      final sel = cat == _selectedCategory;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedCategory = cat),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            color: sel ? cs.primary : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: sel
                                ? []
                                : [
                                    BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 6)
                                  ],
                          ),
                          child: Text(
                            cat,
                            style: TextStyle(
                              color:
                                  sel ? Colors.white : const Color(0xFF6E6E6E),
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                // Food list
                Expanded(
                  child: _filtered.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.restaurant_menu_rounded,
                                  size: 56, color: cs.primary),
                              const SizedBox(height: 16),
                              const Text('No items yet',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 18)),
                              const SizedBox(height: 8),
                              Text(
                                'Tap the button below to add your first item',
                                style: TextStyle(color: Colors.grey.shade500),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                          physics: const BouncingScrollPhysics(),
                          itemCount: _filtered.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (_, i) => _FoodTile(
                            food: _filtered[i],
                            onEdit: () => _openForm(food: _filtered[i]),
                            onDelete: () => _delete(_filtered[i]),
                          ),
                        ),
                ),
              ],
            ),
    );
  }
}

// ── Food list tile ────────────────────────────────────────────────────────────

class _FoodTile extends StatelessWidget {
  final Food food;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _FoodTile(
      {required this.food, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
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
          // Image
          ClipRRect(
            borderRadius:
                const BorderRadius.horizontal(left: Radius.circular(16)),
            child: SizedBox(
              width: 80,
              height: 80,
              child: Image.network(
                food.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: cs.primaryContainer,
                  child: Icon(Icons.restaurant, color: cs.primary),
                ),
              ),
            ),
          ),
          // Info
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          food.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 14),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (food.isPopular)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: cs.primaryContainer,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text('Popular',
                              style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: cs.primary)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(food.category,
                      style: const TextStyle(
                          color: Color(0xFF9E9E9E), fontSize: 12)),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('R${food.price.toStringAsFixed(2)}',
                          style: TextStyle(
                              fontWeight: FontWeight.w900,
                              color: cs.primary,
                              fontSize: 15)),
                      Row(
                        children: [
                          _IconBtn(
                              icon: Icons.edit_outlined,
                              color: cs.primary,
                              onTap: onEdit),
                          const SizedBox(width: 6),
                          _IconBtn(
                              icon: Icons.delete_outline_rounded,
                              color: cs.error,
                              onTap: onDelete),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _IconBtn(
      {required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
      );
}

// ── Add / Edit form sheet ─────────────────────────────────────────────────────

class _FoodFormSheet extends StatefulWidget {
  final Food? food;
  final List<String> categories;

  const _FoodFormSheet({this.food, required this.categories});

  @override
  State<_FoodFormSheet> createState() => _FoodFormSheetState();
}

class _FoodFormSheetState extends State<_FoodFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _desc;
  late final TextEditingController _price;
  late final TextEditingController _imageUrl;
  late final TextEditingController _calories;
  late final TextEditingController _prepTime;
  late final TextEditingController _tags;
  late String _category;
  late bool _isPopular;
  late bool _isVegetarian;
  bool _saving = false;

  bool get _isEditing => widget.food != null;

  @override
  void initState() {
    super.initState();
    final f = widget.food;
    _name = TextEditingController(text: f?.name ?? '');
    _desc = TextEditingController(text: f?.description ?? '');
    _price = TextEditingController(
        text: f != null ? f.price.toStringAsFixed(2) : '');
    _imageUrl = TextEditingController(text: f?.imageUrl ?? '');
    _calories = TextEditingController(text: f != null ? '${f.calories}' : '');
    _prepTime =
        TextEditingController(text: f != null ? '${f.prepTimeMinutes}' : '');
    _tags = TextEditingController(text: f != null ? f.tags.join(', ') : '');
    _category = f?.category ??
        (widget.categories.isNotEmpty ? widget.categories.first : 'Burgers');
    _isPopular = f?.isPopular ?? false;
    _isVegetarian = f?.isVegetarian ?? false;
  }

  @override
  void dispose() {
    for (final c in [
      _name,
      _desc,
      _price,
      _imageUrl,
      _calories,
      _prepTime,
      _tags
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final data = <String, dynamic>{
      'name': _name.text.trim(),
      'description': _desc.text.trim(),
      'price': double.tryParse(_price.text.trim()) ?? 0,
      'imageUrl': _imageUrl.text.trim(),
      'category': _category,
      'calories': int.tryParse(_calories.text.trim()) ?? 0,
      'prepTimeMinutes': int.tryParse(_prepTime.text.trim()) ?? 0,
      'isPopular': _isPopular,
      'isVegetarian': _isVegetarian,
      'rating': widget.food?.rating ?? 4.5,
      'reviewCount': widget.food?.reviewCount ?? 0,
      'ingredients': widget.food?.ingredients ?? [],
      'tags': _tags.text
          .split(',')
          .map((t) => t.trim())
          .where((t) => t.isNotEmpty)
          .toList(),
    };

    bool ok;
    if (_isEditing) {
      ok = await FoodService().updateFood(widget.food!.id, data);
    } else {
      final id = await FoodService().addFood(data);
      ok = id != null;
    }

    if (mounted) {
      setState(() => _saving = false);
      Navigator.pop(context, ok);
      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(_isEditing ? 'Item updated!' : 'Item added to menu!',
              style: const TextStyle(fontFamily: 'Nunito')),
          backgroundColor: const Color(0xFF2E7D32),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          margin: const EdgeInsets.all(16),
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Handle
              Center(
                child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2))),
              ),
              const SizedBox(height: 16),
              Text(_isEditing ? 'Edit Menu Item' : 'Add Menu Item',
                  style: const TextStyle(
                      fontWeight: FontWeight.w900, fontSize: 18)),
              const SizedBox(height: 20),

              // Name
              _FormField(
                label: 'Item Name *',
                child: TextFormField(
                  controller: _name,
                  decoration: const InputDecoration(hintText: 'Classic Burger'),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Required' : null,
                ),
              ),

              // Category dropdown
              _FormField(
                label: 'Category *',
                child: DropdownButtonFormField<String>(
                  value: _category,
                  decoration: const InputDecoration(),
                  items: widget.categories
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) => setState(() => _category = v!),
                ),
              ),

              // Price
              _FormField(
                label: 'Price (R) *',
                child: TextFormField(
                  controller: _price,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(hintText: '99.99'),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Required';
                    if (double.tryParse(v) == null)
                      return 'Enter a valid price';
                    return null;
                  },
                ),
              ),

              // Image URL
              _FormField(
                label: 'Image URL *',
                child: TextFormField(
                  controller: _imageUrl,
                  keyboardType: TextInputType.url,
                  decoration: const InputDecoration(
                      hintText: 'https://images.unsplash.com/...'),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Required' : null,
                ),
              ),

              // Description
              _FormField(
                label: 'Description *',
                child: TextFormField(
                  controller: _desc,
                  maxLines: 3,
                  decoration:
                      const InputDecoration(hintText: 'Describe the item...'),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Required' : null,
                ),
              ),

              // Calories + Prep time
              Row(
                children: [
                  Expanded(
                    child: _FormField(
                      label: 'Calories',
                      child: TextFormField(
                        controller: _calories,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(hintText: '500'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _FormField(
                      label: 'Prep time (min)',
                      child: TextFormField(
                        controller: _prepTime,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(hintText: '15'),
                      ),
                    ),
                  ),
                ],
              ),

              // Tags
              _FormField(
                label: 'Tags (comma separated)',
                child: TextFormField(
                  controller: _tags,
                  decoration:
                      const InputDecoration(hintText: 'Spicy, Popular, Vegan'),
                ),
              ),

              // Toggles
              Row(
                children: [
                  Expanded(
                    child: _Toggle(
                      label: '🔥 Popular',
                      value: _isPopular,
                      onChanged: (v) => setState(() => _isPopular = v),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _Toggle(
                      label: '🌿 Vegetarian',
                      value: _isVegetarian,
                      onChanged: (v) => setState(() => _isVegetarian = v),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Save button
              ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 52)),
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5, color: Colors.white))
                    : Text(_isEditing ? 'Save Changes' : 'Add to Menu'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FormField extends StatelessWidget {
  final String label;
  final Widget child;
  const _FormField({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: Color(0xFF3A3A3A))),
          const SizedBox(height: 6),
          child,
        ],
      ),
    );
  }
}

class _Toggle extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _Toggle(
      {required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: value ? cs.primaryContainer : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: value ? Border.all(color: cs.primary) : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: value ? cs.primary : const Color(0xFF6E6E6E))),
            Icon(
              value ? Icons.check_circle_rounded : Icons.circle_outlined,
              color: value ? cs.primary : Colors.grey.shade400,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
