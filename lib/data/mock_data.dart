// data/mock_data.dart
// Replace these with Firestore calls when integrating Firebase.
// Structure mirrors what you'd store in a 'foods' Firestore collection.

import '../models/food.dart';

const List<String> kCategories = [
  'All',
  'Burgers',
  'Pizza',
  'Sushi',
  'Salads',
  'Pasta',
  'Desserts',
  'Drinks',
];

const List<Food> kMockFoods = [
  // BURGERS
  Food(
    id: 'b1',
    name: 'Classic Smash Burger',
    description:
        'Two smashed beef patties with American cheese, caramelised onions, pickles, and our secret smoky sauce on a brioche bun.',
    price: 14.99,
    imageUrl:
        'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=600&q=80',
    category: 'Burgers',
    rating: 4.8,
    reviewCount: 324,
    calories: 720,
    prepTimeMinutes: 15,
    isPopular: true,
    ingredients: [
      'Beef patty',
      'American cheese',
      'Caramelised onions',
      'Pickles',
      'Brioche bun',
      'Secret sauce',
    ],
    tags: ['Bestseller', 'Spicy'],
  ),
  Food(
    id: 'b2',
    name: 'BBQ Bacon Burger',
    description:
        'Juicy beef patty topped with crispy streaky bacon, cheddar, BBQ sauce, and crunchy onion rings.',
    price: 16.49,
    imageUrl:
        'https://images.unsplash.com/photo-1553979459-d2229ba7433b?w=600&q=80',
    category: 'Burgers',
    rating: 4.6,
    reviewCount: 218,
    calories: 850,
    prepTimeMinutes: 18,
    isPopular: true,
    ingredients: ['Beef patty', 'Bacon', 'Cheddar', 'BBQ sauce', 'Onion rings'],
    tags: ['Meaty'],
  ),
  Food(
    id: 'b3',
    name: 'Garden Veggie Burger',
    description:
        'House-made black bean and roasted veggie patty with avocado, sprouts, tomato, and chipotle mayo.',
    price: 13.49,
    imageUrl:
        'https://images.unsplash.com/photo-1520072959219-c595dc870360?w=600&q=80',
    category: 'Burgers',
    rating: 4.5,
    reviewCount: 156,
    calories: 520,
    prepTimeMinutes: 14,
    isVegetarian: true,
    ingredients: [
      'Black bean patty',
      'Avocado',
      'Sprouts',
      'Tomato',
      'Chipotle mayo',
    ],
    tags: ['Vegan', 'Healthy'],
  ),

  // PIZZA
  Food(
    id: 'p1',
    name: 'Margherita Napoletana',
    description:
        'San Marzano tomato, fresh mozzarella di bufala, basil, and extra virgin olive oil on a perfectly charred Neapolitan crust.',
    price: 15.99,
    imageUrl:
        'https://images.unsplash.com/photo-1574071318508-1cdbab80d002?w=600&q=80',
    category: 'Pizza',
    rating: 4.9,
    reviewCount: 412,
    calories: 680,
    prepTimeMinutes: 20,
    isPopular: true,
    isVegetarian: true,
    ingredients: [
      'San Marzano tomato',
      'Buffalo mozzarella',
      'Basil',
      'Olive oil',
    ],
    tags: ['Classic', 'Vegetarian'],
  ),
  Food(
    id: 'p2',
    name: 'Truffle & Mushroom',
    description:
        'White base with wild mushroom medley, truffle oil, thyme, and aged parmesan on a thin crispy crust.',
    price: 18.99,
    imageUrl:
        'https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?w=600&q=80',
    category: 'Pizza',
    rating: 4.7,
    reviewCount: 287,
    calories: 740,
    prepTimeMinutes: 22,
    isVegetarian: true,
    ingredients: [
      'Wild mushrooms',
      'Truffle oil',
      'Thyme',
      'Parmesan',
      'White sauce',
    ],
    tags: ['Gourmet', 'Vegetarian'],
  ),
  Food(
    id: 'p3',
    name: 'Spicy Salami',
    description:
        'Tomato base loaded with spicy Calabrese salami, roasted peppers, chilli flakes, and smoked scamorza.',
    price: 17.49,
    imageUrl:
        'https://images.unsplash.com/photo-1513104890138-7c749659a591?w=600&q=80',
    category: 'Pizza',
    rating: 4.6,
    reviewCount: 198,
    calories: 810,
    prepTimeMinutes: 20,
    isPopular: true,
    ingredients: ['Calabrese salami', 'Roasted peppers', 'Scamorza', 'Chilli'],
    tags: ['Spicy', 'Meaty'],
  ),

  // SUSHI
  Food(
    id: 's1',
    name: 'Rainbow Roll (8 pcs)',
    description:
        'California roll topped with alternating slices of tuna, salmon, yellowtail, and avocado. Chef\'s favourite.',
    price: 19.99,
    imageUrl:
        'https://images.unsplash.com/photo-1617196034183-421b4040ed20?w=600&q=80',
    category: 'Sushi',
    rating: 4.9,
    reviewCount: 501,
    calories: 420,
    prepTimeMinutes: 12,
    isPopular: true,
    ingredients: [
      'Tuna',
      'Salmon',
      'Yellowtail',
      'Avocado',
      'Crab',
      'Cucumber',
      'Rice',
    ],
    tags: ['Chef\'s Pick', 'Fresh'],
  ),
  Food(
    id: 's2',
    name: 'Spicy Tuna Roll (6 pcs)',
    description:
        'Fresh tuna with spicy sriracha mayo, cucumber, and sesame seeds wrapped in nori and sushi rice.',
    price: 14.99,
    imageUrl:
        'https://images.unsplash.com/photo-1562802378-063ec186a863?w=600&q=80',
    category: 'Sushi',
    rating: 4.7,
    reviewCount: 334,
    calories: 320,
    prepTimeMinutes: 10,
    isPopular: true,
    ingredients: [
      'Tuna',
      'Sriracha mayo',
      'Cucumber',
      'Sesame',
      'Nori',
      'Rice',
    ],
    tags: ['Spicy', 'Popular'],
  ),

  // SALADS
  Food(
    id: 'sa1',
    name: 'Super Green Bowl',
    description:
        'Kale, edamame, avocado, roasted chickpeas, cucumber, and sunflower seeds with miso-ginger dressing.',
    price: 12.99,
    imageUrl:
        'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=600&q=80',
    category: 'Salads',
    rating: 4.6,
    reviewCount: 189,
    calories: 380,
    prepTimeMinutes: 8,
    isVegetarian: true,
    ingredients: [
      'Kale',
      'Edamame',
      'Avocado',
      'Chickpeas',
      'Cucumber',
      'Miso dressing',
    ],
    tags: ['Vegan', 'Healthy', 'Low-cal'],
  ),
  Food(
    id: 'sa2',
    name: 'Grilled Caesar',
    description:
        'Romaine hearts, grilled chicken, house-made Caesar dressing, sourdough croutons, and shaved parmesan.',
    price: 13.99,
    imageUrl:
        'https://images.unsplash.com/photo-1550304943-4f24f54ddde9?w=600&q=80',
    category: 'Salads',
    rating: 4.5,
    reviewCount: 211,
    calories: 490,
    prepTimeMinutes: 10,
    ingredients: [
      'Romaine',
      'Grilled chicken',
      'Caesar dressing',
      'Croutons',
      'Parmesan',
    ],
    tags: ['Classic', 'Protein'],
  ),

  // PASTA
  Food(
    id: 'pa1',
    name: 'Cacio e Pepe',
    description:
        'Perfectly al-dente tonnarelli pasta with aged Pecorino Romano, Parmigiano, and freshly cracked black pepper.',
    price: 15.49,
    imageUrl:
        'https://images.unsplash.com/photo-1621996346565-e3dbc646d9a9?w=600&q=80',
    category: 'Pasta',
    rating: 4.8,
    reviewCount: 276,
    calories: 620,
    prepTimeMinutes: 14,
    isPopular: true,
    isVegetarian: true,
    ingredients: [
      'Tonnarelli',
      'Pecorino Romano',
      'Parmigiano',
      'Black pepper',
      'Butter',
    ],
    tags: ['Classic', 'Vegetarian'],
  ),
  Food(
    id: 'pa2',
    name: 'Lobster Linguine',
    description:
        'Fresh linguine tossed with half a butter-poached lobster, cherry tomatoes, white wine, garlic, and chilli.',
    price: 29.99,
    imageUrl:
        'https://images.unsplash.com/photo-1563379926898-05f4575a45d8?w=600&q=80',
    category: 'Pasta',
    rating: 4.9,
    reviewCount: 143,
    calories: 780,
    prepTimeMinutes: 25,
    ingredients: [
      'Linguine',
      'Lobster',
      'Cherry tomatoes',
      'White wine',
      'Garlic',
      'Chilli',
    ],
    tags: ['Premium', 'Seafood'],
  ),

  // DESSERTS
  Food(
    id: 'd1',
    name: 'Molten Lava Cake',
    description:
        'Warm dark chocolate cake with a gooey molten centre, served with vanilla bean ice cream and raspberry coulis.',
    price: 8.99,
    imageUrl:
        'https://images.unsplash.com/photo-1624353365286-3f8d62daad51?w=600&q=80',
    category: 'Desserts',
    rating: 4.9,
    reviewCount: 389,
    calories: 580,
    prepTimeMinutes: 12,
    isPopular: true,
    isVegetarian: true,
    ingredients: [
      'Dark chocolate',
      'Butter',
      'Eggs',
      'Sugar',
      'Vanilla ice cream',
    ],
    tags: ['Indulgent', 'Hot'],
  ),
  Food(
    id: 'd2',
    name: 'Mango Panna Cotta',
    description:
        'Silky Italian vanilla cream set with fresh mango compote and passionfruit drizzle.',
    price: 7.49,
    imageUrl:
        'https://images.unsplash.com/photo-1488477181946-6428a0291777?w=600&q=80',
    category: 'Desserts',
    rating: 4.7,
    reviewCount: 214,
    calories: 340,
    prepTimeMinutes: 5,
    isVegetarian: true,
    ingredients: ['Cream', 'Vanilla', 'Mango', 'Passionfruit', 'Gelatin'],
    tags: ['Light', 'Fruity'],
  ),

  // DRINKS
  Food(
    id: 'dr1',
    name: 'Matcha Latte',
    description:
        'Ceremonial grade Japanese matcha whisked with steamed oat milk and a touch of honey. Hot or iced.',
    price: 5.49,
    imageUrl:
        'https://images.unsplash.com/photo-1515823662972-da6a2e4d3002?w=600&q=80',
    category: 'Drinks',
    rating: 4.8,
    reviewCount: 441,
    calories: 160,
    prepTimeMinutes: 4,
    isVegetarian: true,
    isPopular: true,
    ingredients: ['Matcha', 'Oat milk', 'Honey'],
    tags: ['Vegan', 'Healthy'],
  ),
  Food(
    id: 'dr2',
    name: 'Strawberry Basil Lemonade',
    description:
        'Freshly squeezed lemonade muddled with strawberries and fresh basil. Refreshing and totally addictive.',
    price: 4.99,
    imageUrl:
        'https://images.unsplash.com/photo-1621263764928-df1444c5e859?w=600&q=80',
    category: 'Drinks',
    rating: 4.6,
    reviewCount: 298,
    calories: 140,
    prepTimeMinutes: 3,
    isVegetarian: true,
    ingredients: ['Lemon', 'Strawberry', 'Basil', 'Sugar', 'Sparkling water'],
    tags: ['Refreshing', 'Seasonal'],
  ),
];

// Helper — fetch by category
List<Food> getFoodsByCategory(String category) {
  if (category == 'All') return kMockFoods;
  return kMockFoods.where((f) => f.category == category).toList();
}

// Helper — popular items
List<Food> getPopularFoods() => kMockFoods.where((f) => f.isPopular).toList();

// Helper — search
List<Food> searchFoods(String query) {
  final q = query.toLowerCase();
  return kMockFoods.where((f) {
    return f.name.toLowerCase().contains(q) ||
        f.category.toLowerCase().contains(q) ||
        f.tags.any((t) => t.toLowerCase().contains(q));
  }).toList();
}
