import 'dart:convert';

import 'package:hello_captain_user/Resources/constants.dart';

class CartItemModel {
  String item_id = "";
  String merchant_id = "";
  String item_name = "";
  double item_price = 0;
  double promo_price = 0;
  String item_category = "";
  String item_desc = "";
  String item_image = "";
  String created_item = "";
  String item_status = "";
  String promo_status = "";
  String category_name_item = "";
  String category_item_images = "";
  int quantity = 1;
  CartItemModel({
    required this.item_id,
    required this.merchant_id,
    required this.item_name,
    required this.item_price,
    required this.promo_price,
    required this.item_category,
    required this.item_desc,
    required this.item_image,
    required this.created_item,
    required this.item_status,
    required this.promo_status,
    required this.category_name_item,
    required this.category_item_images,
    required this.quantity,
  });

  CartItemModel copyWith({
    String? item_id,
    String? merchant_id,
    String? item_name,
    double? item_price,
    double? promo_price,
    String? item_category,
    String? item_desc,
    String? item_image,
    String? created_item,
    String? item_status,
    String? promo_status,
    String? category_name_item,
    String? category_item_images,
    int? quantity,
  }) {
    return CartItemModel(
      item_id: item_id ?? this.item_id,
      merchant_id: merchant_id ?? this.merchant_id,
      item_name: item_name ?? this.item_name,
      item_price: item_price ?? this.item_price,
      promo_price: promo_price ?? this.promo_price,
      item_category: item_category ?? this.item_category,
      item_desc: item_desc ?? this.item_desc,
      item_image: item_image ?? this.item_image,
      created_item: created_item ?? this.created_item,
      item_status: item_status ?? this.item_status,
      promo_status: promo_status ?? this.promo_status,
      category_name_item: category_name_item ?? this.category_name_item,
      category_item_images: category_item_images ?? this.category_item_images,
      quantity: quantity ?? this.quantity,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'item_id': item_id,
      'merchant_id': merchant_id,
      'item_name': item_name,
      'item_price': item_price,
      'promo_price': promo_price,
      'item_category': item_category,
      'item_desc': item_desc,
      'item_image': item_image,
      'created_item': created_item,
      'item_status': item_status,
      'promo_status': promo_status,
      'category_name_item': category_name_item,
      'category_item_images': category_item_images,
      'quantity': quantity,
    };
  }

  factory CartItemModel.fromMap(Map<String, dynamic> map) {
    return CartItemModel(
      item_id: map['item_id'] ?? '',
      merchant_id: map['merchant_id'] ?? '',
      item_name: map['item_name'] ?? '',
      item_price: parseToDouble(map['item_price']),
      promo_price: parseToDouble(map['promo_price']),
      item_category: map['item_category'] ?? '',
      item_desc: map['item_desc'] ?? '',
      item_image: map['item_image'] ?? '',
      created_item: map['created_item'] ?? '',
      item_status: map['item_status'] ?? '',
      promo_status: map['promo_status'] ?? '',
      category_name_item: map['category_name_item'] ?? '',
      category_item_images: map['category_item_images'] ?? '',
      quantity: map['quantity']?.toInt() ?? 0,
    );
  }

  String toJson() => json.encode(toMap());

  factory CartItemModel.fromJson(String source) =>
      CartItemModel.fromMap(json.decode(source));

  @override
  String toString() {
    return 'CartItemModel(item_id: $item_id, merchant_id: $merchant_id, item_name: $item_name, item_price: $item_price, promo_price: $promo_price, item_category: $item_category, item_desc: $item_desc, item_image: $item_image, created_item: $created_item, item_status: $item_status, promo_status: $promo_status, category_name_item: $category_name_item, category_item_images: $category_item_images, quantity: $quantity)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is CartItemModel &&
        other.item_id == item_id &&
        other.merchant_id == merchant_id &&
        other.item_name == item_name &&
        other.item_price == item_price &&
        other.promo_price == promo_price &&
        other.item_category == item_category &&
        other.item_desc == item_desc &&
        other.item_image == item_image &&
        other.created_item == created_item &&
        other.item_status == item_status &&
        other.promo_status == promo_status &&
        other.category_name_item == category_name_item &&
        other.category_item_images == category_item_images &&
        other.quantity == quantity;
  }

  @override
  int get hashCode {
    return item_id.hashCode ^
        merchant_id.hashCode ^
        item_name.hashCode ^
        item_price.hashCode ^
        promo_price.hashCode ^
        item_category.hashCode ^
        item_desc.hashCode ^
        item_image.hashCode ^
        created_item.hashCode ^
        item_status.hashCode ^
        promo_status.hashCode ^
        category_name_item.hashCode ^
        category_item_images.hashCode ^
        quantity.hashCode;
  }
}
