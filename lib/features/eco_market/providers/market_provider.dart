import 'package:flutter_riverpod/flutter_riverpod.dart';

// Product model class
class Product {
  final String title;
  final String villagerName;
  final String price;
  final String unit;
  final String phone;
  final String imageUrl;
  final String description;

  Product({
    required this.title,
    required this.villagerName,
    required this.price,
    required this.unit,
    required this.phone,
    required this.imageUrl,
    required this.description,
  });
}

// State class
class MarketState {
  final bool isLoading;
  final List<Product> products;

  MarketState({this.isLoading = false, this.products = const []});
}

// Notifier class
class MarketNotifier extends StateNotifier<MarketState> {
  MarketNotifier() : super(MarketState(isLoading: true)) {
    _loadDummyProducts();
  }

  void _loadDummyProducts() async {
    // Simulating network delay for smooth shimmer/loading effect
    await Future.delayed(const Duration(seconds: 2));

    state = MarketState(
      isLoading: false,
      products: [
        Product(
          title: 'Wild Forest Honey',
          villagerName: 'Muthusamu (Malasar Tribe)',
          price: '₹450',
          unit: '500g',
          phone: '919342798462',
          imageUrl: 'https://plus.unsplash.com/premium_photo-1726704133644-bd521a727cf8?w=600&auto=format&fit=crop&q=60&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxzZWFyY2h8NXx8d2lsZCUyMGhvbmV5fGVufDB8fDB8fHww',
          description: '100% pure, unadulterated wild honey collected from the deep forests of the Western Ghats.',
        ),
        Product(
          title: 'Handwoven Bamboo Basket',
          villagerName: 'Kannan Crafts',
          price: '₹250',
          unit: '1 piece',
          phone: '919342798462',
          imageUrl: 'https://images.unsplash.com/photo-1622153093514-4dd0078ac132?w=600&auto=format&fit=crop&q=60&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxzZWFyY2h8Mnx8SGFuZHdvdmVuJTIwQmFtYm9vJTIwQmFza2V0fGVufDB8fDB8fHww',
          description: 'Strong, eco-friendly bamboo baskets hand-crafted by local artisans.',
        ),
        Product(
          title: 'Eucalyptus Essential Oil',
          villagerName: 'Nilgiri Naturals',
          price: '₹300',
          unit: '50ml',
          phone: '919342798462',
          imageUrl: 'https://plus.unsplash.com/premium_photo-1670574873474-4508d368b02a?w=600&auto=format&fit=crop&q=60&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxzZWFyY2h8MTN8fEV1Y2FseXB0dXMlMjBFc3NlbnRpYWwlMjBPaWx8ZW58MHx8MHx8fDA%3D',
          description: 'Freshly extracted eucalyptus oil. Great for cold relief and aromatherapy.',
        ),
        Product(
          title: 'Organic Cardamom (Elachi)',
          villagerName: 'Idukki Spices',
          price: '₹850',
          unit: '250g',
          phone: '919342798462',
          imageUrl: 'https://plus.unsplash.com/premium_photo-1725908669570-8ae09ccf6a8d?w=600&auto=format&fit=crop&q=60&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxzZWFyY2h8MXx8T3JnYW5pYyUyMENhcmRhbW9tfGVufDB8fDB8fHww',
          description: 'Premium export-quality organic cardamom directly from forest border farms.',
        ),
        Product(
          title: 'Tribal Medicinal Herbs Pack',
          villagerName: 'Irula Herbals',
          price: '₹150',
          unit: '1 Pack',
          phone: '919342798462',
          imageUrl: 'https://images.unsplash.com/photo-1593460914954-bfe709776e91?w=600&auto=format&fit=crop&q=60&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxzZWFyY2h8Nnx8VHJpYmFsJTIwTWVkaWNpbmFsJTIwSGVyYnMlMjBQYWNrfGVufDB8fDB8fHww',
          description: 'A traditional mix of dried roots and herbs for boosting natural immunity.',
        ),
        Product(
          title: 'Forest Beeswax Candles',
          villagerName: 'Prakruthi Eco',
          price: '₹180',
          unit: 'Set of 3',
          phone: '919342798462',
          imageUrl: 'https://images.unsplash.com/photo-1599591590264-22dbba64111c?w=600&auto=format&fit=crop&q=60&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxzZWFyY2h8OHx8Rm9yZXN0JTIwQmVlc3dheCUyMENhbmRsZXN8ZW58MHx8MHx8fDA%3D',
          description: 'Chemical-free, slow-burning candles made from natural forest beeswax.',
        ),
      ],
    );
  }
}

// Global Provider
final marketProvider = StateNotifierProvider<MarketNotifier, MarketState>((ref) {
  return MarketNotifier();
});