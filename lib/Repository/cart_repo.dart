import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hello_captain_user/Models/cart_item_model.dart';

class CartNotifier extends StateNotifier<List<CartItemModel>> {
  CartNotifier() : super([]);

  int get totalItems => state.length;

  void addItem(CartItemModel item) {
    state = [...state, item];
  }

  void removeItem(String itemId) {
    state = state.where((item) => item.item_id != itemId).toList();
  }

  void updateQuantity(String itemId, int newQuantity) {
    state =
        state.map((item) {
          if (item.item_id == itemId) {
            return CartItemModel(
              item_id: item.item_id,
              merchant_id: item.merchant_id,
              item_category: item.item_category,
              item_price: item.item_price,
              promo_price: item.promo_price,
              item_name: item.item_name,
              item_image: item.item_image,
              quantity: newQuantity,
              item_desc: item.item_desc,
              created_item: item.created_item,
              item_status: item.item_status,
              promo_status: item.promo_status,
              category_name_item: item.category_name_item,
              category_item_images: item.category_item_images,
            );
          }
          return item;
        }).toList();
  }

  // Method to clear the cart
  void clearCart() {
    state = [];
  }
}

final cartProvider = StateNotifierProvider<CartNotifier, List<CartItemModel>>((
  ref,
) {
  return CartNotifier();
});
