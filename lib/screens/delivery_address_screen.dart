// screens/delivery_address_screen.dart
// Full delivery address form — saves to Firestore users/{uid}

import 'package:flutter/material.dart';
import '../providers/auth_provider.dart';

class DeliveryAddressScreen extends StatefulWidget {
  final AuthProvider authProvider;
  final bool isCheckout; // true = called from cart before placing order

  const DeliveryAddressScreen({
    super.key,
    required this.authProvider,
    this.isCheckout = false,
  });

  @override
  State<DeliveryAddressScreen> createState() => _DeliveryAddressScreenState();
}

class _DeliveryAddressScreenState extends State<DeliveryAddressScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _street;
  late final TextEditingController _suburb;
  late final TextEditingController _city;
  late final TextEditingController _province;
  late final TextEditingController _postal;
  late final TextEditingController _instructions;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill from saved address if it exists
    final saved = widget.authProvider.currentUser?.deliveryAddress ?? '';
    final parts = _parseAddress(saved);
    _street = TextEditingController(text: parts['street'] ?? '');
    _suburb = TextEditingController(text: parts['suburb'] ?? '');
    _city = TextEditingController(text: parts['city'] ?? '');
    _province = TextEditingController(text: parts['province'] ?? '');
    _postal = TextEditingController(text: parts['postal'] ?? '');
    _instructions = TextEditingController(text: parts['instructions'] ?? '');
  }

  @override
  void dispose() {
    for (final c in [
      _street,
      _suburb,
      _city,
      _province,
      _postal,
      _instructions
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  /// Compose a single address string from form fields
  String get _composedAddress {
    final parts = [
      _street.text.trim(),
      _suburb.text.trim(),
      _city.text.trim(),
      _province.text.trim(),
      _postal.text.trim(),
    ].where((p) => p.isNotEmpty).join(', ');
    return parts;
  }

  /// Parse a saved flat address string back into fields (best effort)
  Map<String, String> _parseAddress(String address) {
    if (address.isEmpty) return {};
    final parts = address.split(',').map((p) => p.trim()).toList();
    return {
      'street': parts.isNotEmpty ? parts[0] : '',
      'suburb': parts.length > 1 ? parts[1] : '',
      'city': parts.length > 2 ? parts[2] : '',
      'province': parts.length > 3 ? parts[3] : '',
      'postal': parts.length > 4 ? parts[4] : '',
    };
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final address = _composedAddress;
    final success = await widget.authProvider.updateProfile(
      name: widget.authProvider.currentUser?.name ?? '',
      phone: widget.authProvider.currentUser?.phone,
      deliveryAddress: address,
    );

    if (!mounted) return;
    setState(() => _saving = false);

    if (success) {
      if (widget.isCheckout) {
        // Return the address to cart screen
        Navigator.pop(context, address);
      } else {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Row(children: [
            Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
            SizedBox(width: 10),
            Text('Address saved!',
                style: TextStyle(
                    fontFamily: 'Nunito', fontWeight: FontWeight.w600)),
          ]),
          backgroundColor: const Color(0xFF2E7D32),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          margin: const EdgeInsets.all(16),
        ));
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Could not save address. Try again.',
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

    return Scaffold(
      backgroundColor: cs.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.isCheckout ? 'Add Delivery Address' : 'Delivery Address',
          style:
              theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          physics: const BouncingScrollPhysics(),
          children: [
            // Info banner for checkout
            if (widget.isCheckout) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(children: [
                  Icon(Icons.info_outline_rounded, color: cs.primary, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Please add a delivery address before placing your order.',
                      style: TextStyle(
                          color: cs.onPrimaryContainer,
                          fontWeight: FontWeight.w600,
                          fontSize: 13),
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 20),
            ],

            // Street address
            _Field(
              label: 'Street Address *',
              hint: '123 Main Street',
              controller: _street,
              required: true,
            ),
            // Suburb
            _Field(
              label: 'Suburb *',
              hint: 'Sandton',
              controller: _suburb,
              required: true,
            ),
            // City + Province
            Row(
              children: [
                Expanded(
                  child: _Field(
                    label: 'City *',
                    hint: 'Johannesburg',
                    controller: _city,
                    required: true,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _Field(
                    label: 'Province',
                    hint: 'Gauteng',
                    controller: _province,
                  ),
                ),
              ],
            ),
            // Postal code
            _Field(
              label: 'Postal Code',
              hint: '2196',
              controller: _postal,
              keyboardType: TextInputType.number,
            ),
            // Delivery instructions
            _Field(
              label: 'Delivery Instructions',
              hint: 'Gate code, apartment number, landmark...',
              controller: _instructions,
              maxLines: 3,
            ),

            const SizedBox(height: 8),

            // Current saved address display
            if (widget.authProvider.currentUser?.deliveryAddress != null &&
                widget.authProvider.currentUser!.deliveryAddress!.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.location_on_rounded,
                        color: cs.primary, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Current saved address',
                              style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600)),
                          const SizedBox(height: 2),
                          Text(
                            widget.authProvider.currentUser!.deliveryAddress!,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 54)),
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5, color: Colors.white))
                  : Text(
                      widget.isCheckout ? 'Save & Continue' : 'Save Address'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final bool required;
  final int maxLines;
  final TextInputType? keyboardType;

  const _Field({
    required this.label,
    required this.hint,
    required this.controller,
    this.required = false,
    this.maxLines = 1,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: Color(0xFF3A3A3A)),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller,
            maxLines: maxLines,
            keyboardType: keyboardType,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(hintText: hint),
            validator: required
                ? (v) => v == null || v.trim().isEmpty ? 'Required' : null
                : null,
          ),
        ],
      ),
    );
  }
}
