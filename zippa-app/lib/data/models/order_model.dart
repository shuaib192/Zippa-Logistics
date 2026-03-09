// ============================================
// 📦 ORDER MODEL (order_model.dart)
// ============================================

class OrderModel {
  final String? id;
  final String? orderNumber;
  final String customerId;
  final String? riderId;
  
  // Delivery Details
  final String pickupAddress;
  final double pickupLat;
  final double pickupLng;
  final String dropoffAddress;
  final double dropoffLat;
  final double dropoffLng;
  
  // Package Details
  final String packageSize; // small, medium, large, extra_large
  final String packageType; // document, electronics, food, etc.
  final String? packageDescription;
  final String? customerNotes;
  
  // Marketplace Specific
  final bool isMarketplace;
  final String? vendorName;
  
  // Recipient info
  final String recipientName;
  final String recipientPhone;
  
  // Pricing
  final double itemPrice;
  final double subtotal;
  final double platformFee;
  final double totalFare;
  final double riderEarnings;

  double get fare => totalFare;
  
  // Status & Timestamps
  final String status; // pending, accepted, picked_up, delivered, cancelled
  final String? paymentStatus;
  final bool customerConfirmed;
  final String? paymentMethod;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  
  // Rider Info (Loaded in details)
  final String? riderName;
  final String? riderPhone;
  final String? riderAvatar;

  OrderModel({
    this.id,
    this.orderNumber,
    required this.customerId,
    this.riderId,
    required this.pickupAddress,
    required this.pickupLat,
    required this.pickupLng,
    required this.dropoffAddress,
    required this.dropoffLat,
    required this.dropoffLng,
    required this.packageSize,
    required this.packageType,
    this.packageDescription,
    required this.recipientName,
    required this.recipientPhone,
    required this.subtotal,
    required this.platformFee,
    required this.totalFare,
    required this.riderEarnings,
    this.itemPrice = 0.0,
    this.status = 'pending',
    this.paymentStatus = 'unpaid',
    this.customerConfirmed = false,
    this.paymentMethod = 'cash',
    this.createdAt,
    this.updatedAt,
    this.riderName,
    this.riderPhone,
    this.riderAvatar,
    this.customerNotes,
    this.isMarketplace = false,
    this.vendorName,
  });

  // Convert JSON to Order object
  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id']?.toString(),
      orderNumber: json['order_number'],
      customerId: json['customer_id']?.toString() ?? '',
      riderId: json['rider_id']?.toString(),
      pickupAddress: json['pickup_address'],
      pickupLat: double.tryParse(json['pickup_lat']?.toString() ?? '0') ?? 0.0,
      pickupLng: double.tryParse(json['pickup_lng']?.toString() ?? '0') ?? 0.0,
      dropoffAddress: json['dropoff_address'],
      dropoffLat: double.tryParse(json['dropoff_lat']?.toString() ?? '0') ?? 0.0,
      dropoffLng: double.tryParse(json['dropoff_lng']?.toString() ?? '0') ?? 0.0,
      packageSize: json['package_size'] ?? 'medium',
      packageType: json['package_type'] ?? 'parcel',
      packageDescription: json['package_description'],
      recipientName: json['recipient_name'] ?? json['dropoff_contact_name'] ?? '',
      recipientPhone: json['recipient_phone'] ?? json['dropoff_contact_phone'] ?? '',
      itemPrice: double.tryParse(json['item_price']?.toString() ?? '0') ?? 0.0,
      subtotal: double.tryParse(json['subtotal']?.toString() ?? '0') ?? 0.0,
      platformFee: double.tryParse(json['platform_fee']?.toString() ?? '0') ?? 0.0,
      totalFare: double.tryParse(json['total_fare']?.toString() ?? '0') ?? 0.0,
      riderEarnings: double.tryParse(json['rider_earning']?.toString() ?? '0') ?? 0.0,
      status: json['status'] ?? 'pending',
      paymentStatus: json['payment_status'],
      customerConfirmed: json['customer_confirmed'] == true,
      paymentMethod: json['payment_method'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
      riderName: json['rider_name'],
      riderPhone: json['rider_phone'],
      riderAvatar: json['rider_avatar'],
      customerNotes: json['customer_notes'],
      isMarketplace: json['is_marketplace'] == true,
      vendorName: json['vendor_name'] ?? json['pickup_contact_name'],
    );
  }

  // Convert Order object to JSON (for API)
  Map<String, dynamic> toJson() {
    return {
      'pickup_address': pickupAddress,
      'pickup_lat': pickupLat,
      'pickup_lng': pickupLng,
      'dropoff_address': dropoffAddress,
      'dropoff_lat': dropoffLat,
      'dropoff_lng': dropoffLng,
      'package_size': packageSize,
      'package_type': packageType,
      'package_description': packageDescription,
      'recipient_name': recipientName,
      'recipient_phone': recipientPhone,
      'payment_method': paymentMethod,
    };
  }
}
