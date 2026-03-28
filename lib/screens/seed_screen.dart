// // screens/seed_screen.dart
// //
// // One-time admin screen to seed foods and categories into Firestore.
// // Access it from the Profile screen → "Seed Database" menu item.
// // Remove this screen (and the menu item) once your database is populated.

// import 'package:flutter/material.dart';
// import '../services/food_service.dart';

// class SeedScreen extends StatefulWidget {
//   const SeedScreen({super.key});

//   @override
//   State<SeedScreen> createState() => _SeedScreenState();
// }

// class _SeedScreenState extends State<SeedScreen> {
//   _SeedState _state = _SeedState.idle;
//   SeedResult? _result;

//   Future<void> _seed() async {
//     setState(() => _state = _SeedState.loading);
//     final result = await FoodService().seedDatabase();
//     setState(() {
//       _result = result;
//       _state = result.success ? _SeedState.success : _SeedState.error;
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     final cs = Theme.of(context).colorScheme;
//     final theme = Theme.of(context);

//     return Scaffold(
//       backgroundColor: cs.background,
//       appBar: AppBar(
//         title: Text('Seed Database',
//             style: theme.textTheme.titleLarge
//                 ?.copyWith(fontWeight: FontWeight.w900)),
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back_ios_new_rounded),
//           onPressed: () => Navigator.pop(context),
//         ),
//       ),
//       body: SafeArea(
//         child: Padding(
//           padding: const EdgeInsets.all(24),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.stretch,
//             children: [
//               // Info card
//               Container(
//                 padding: const EdgeInsets.all(20),
//                 decoration: BoxDecoration(
//                   color: cs.primaryContainer,
//                   borderRadius: BorderRadius.circular(20),
//                 ),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Row(children: [
//                       Icon(Icons.info_outline_rounded,
//                           color: cs.primary, size: 22),
//                       const SizedBox(width: 10),
//                       Text('One-time setup',
//                           style: TextStyle(
//                             fontWeight: FontWeight.w800,
//                             fontSize: 16,
//                             color: cs.onPrimaryContainer,
//                           )),
//                     ]),
//                     const SizedBox(height: 12),
//                     Text(
//                       'This will upload 16 food items and 7 categories into your Firestore database. '
//                       'It is safe to run multiple times — existing documents will be updated, not duplicated.',
//                       style: TextStyle(
//                         color: cs.onPrimaryContainer,
//                         height: 1.5,
//                         fontSize: 14,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               const SizedBox(height: 24),

//               // What gets seeded
//               const _SeedItem(
//                   icon: Icons.restaurant_menu_rounded,
//                   label: '16 food items',
//                   subtitle:
//                       'Burgers, Pizza, Sushi, Salads, Pasta, Desserts, Drinks,'),
//               const SizedBox(height: 12),
//               const _SeedItem(
//                   icon: Icons.category_outlined,
//                   label: '7 categories',
//                   subtitle: 'Used for the category filter chips on Home'),
//               const SizedBox(height: 32),

//               // Result banner
//               if (_state == _SeedState.success && _result != null) ...[
//                 _ResultBanner(
//                   icon: Icons.check_circle_rounded,
//                   color: cs.primary,
//                   title: 'Database seeded successfully!',
//                   body:
//                       '${_result!.foodCount} foods and ${_result!.categoryCount} categories written to Firestore.\n\n'
//                       'You can now remove this screen from the app.',
//                 ),
//                 const SizedBox(height: 24),
//               ],
//               if (_state == _SeedState.error && _result != null) ...[
//                 _ResultBanner(
//                   icon: Icons.error_outline_rounded,
//                   color: cs.error,
//                   title: 'Seeding failed',
//                   body: _result!.error ??
//                       'Check your Firestore rules and internet connection.',
//                 ),
//                 const SizedBox(height: 24),
//               ],

//               const Spacer(),

//               // Action button
//               ElevatedButton.icon(
//                 onPressed: _state == _SeedState.loading ? null : _seed,
//                 icon: _state == _SeedState.loading
//                     ? const SizedBox(
//                         width: 18,
//                         height: 18,
//                         child: CircularProgressIndicator(
//                             strokeWidth: 2.5, color: Colors.white),
//                       )
//                     : Icon(
//                         _state == _SeedState.success
//                             ? Icons.refresh_rounded
//                             : Icons.cloud_upload_outlined,
//                       ),
//                 label: Text(
//                   _state == _SeedState.loading
//                       ? 'Uploading...'
//                       : _state == _SeedState.success
//                           ? 'Seed Again'
//                           : 'Seed Firestore Now',
//                 ),
//                 style: ElevatedButton.styleFrom(
//                   minimumSize: const Size(double.infinity, 54),
//                   backgroundColor:
//                       _state == _SeedState.error ? cs.error : cs.primary,
//                 ),
//               ),
//               const SizedBox(height: 12),
//               Text(
//                 'After seeding, go back to the Home screen and pull to refresh.',
//                 textAlign: TextAlign.center,
//                 style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

// enum _SeedState { idle, loading, success, error }

// class _SeedItem extends StatelessWidget {
//   final IconData icon;
//   final String label;
//   final String subtitle;

//   const _SeedItem(
//       {required this.icon, required this.label, required this.subtitle});

//   @override
//   Widget build(BuildContext context) {
//     final cs = Theme.of(context).colorScheme;
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//               color: Colors.black.withOpacity(0.04),
//               blurRadius: 8,
//               offset: const Offset(0, 2))
//         ],
//       ),
//       child: Row(
//         children: [
//           Container(
//             width: 42,
//             height: 42,
//             decoration: BoxDecoration(
//               color: cs.primaryContainer,
//               borderRadius: BorderRadius.circular(12),
//             ),
//             child: Icon(icon, color: cs.primary, size: 22),
//           ),
//           const SizedBox(width: 14),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(label,
//                     style: const TextStyle(
//                         fontWeight: FontWeight.w800, fontSize: 15)),
//                 const SizedBox(height: 2),
//                 Text(subtitle,
//                     style:
//                         TextStyle(fontSize: 12, color: Colors.grey.shade500)),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _ResultBanner extends StatelessWidget {
//   final IconData icon;
//   final Color color;
//   final String title;
//   final String body;

//   const _ResultBanner(
//       {required this.icon,
//       required this.color,
//       required this.title,
//       required this.body});

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.all(18),
//       decoration: BoxDecoration(
//         color: color.withOpacity(0.08),
//         borderRadius: BorderRadius.circular(16),
//         border: Border.all(color: color.withOpacity(0.3)),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(children: [
//             Icon(icon, color: color, size: 20),
//             const SizedBox(width: 8),
//             Text(title,
//                 style: TextStyle(
//                     fontWeight: FontWeight.w800, color: color, fontSize: 15)),
//           ]),
//           const SizedBox(height: 8),
//           Text(body,
//               style: TextStyle(
//                   color: color.withOpacity(0.85), height: 1.5, fontSize: 13)),
//         ],
//       ),
//     );
//   }
// }
