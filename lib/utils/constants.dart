// App Constants
class AppConstants {
  static const String appName = 'iTraceLink';
  static const String appVersion = '1.0.0';
  static const String appTaglineEn = 'Tracing Nutrition from Seed to Table';
  static const String appTaglineRw = 'Gukurikirana Intungamubiri kuva ku mbuto kugeza ku meza';
  
  // Firebase Collection Names
  static const String usersCollection = 'users';
  static const String seedProducersCollection = 'seed_producers';
  static const String agroDealersCollection = 'agro_dealers';
  static const String cooperativesCollection = 'cooperatives';
  static const String aggregatorsCollection = 'aggregators';
  static const String institutionsCollection = 'institutions';
  static const String consumersCollection = 'consumers';
  static const String ordersCollection = 'orders';
  static const String transactionsCollection = 'transactions';
  static const String notificationsCollection = 'notifications';
  static const String batchesCollection = 'batches';
  static const String consumerPurchasesCollection = 'consumer_purchases';
  static const String inventoryCollection = 'inventory';
  
  // User Types
  static const String seedProducerType = 'seed_producer';
  static const String agroDealerType = 'agro_dealer';
  static const String cooperativeType = 'cooperative';
  static const String farmerType = 'farmer';
  static const String aggregatorType = 'aggregator';
  static const String institutionType = 'institution';
  static const String consumerType = 'consumer';
  
  // Order Status
  static const String orderPending = 'pending';
  static const String orderAccepted = 'accepted';
  static const String orderRejected = 'rejected';
  static const String orderCompleted = 'completed';
  static const String orderCancelled = 'cancelled';
  static const String orderInTransit = 'in_transit';
  static const String orderPaid = 'paid';
  
  // Payment Status
  static const String paymentPending = 'pending';
  static const String paymentPaid = 'paid';
  
  // Institution Types
  static const String schoolType = 'school';
  static const String hospitalType = 'hospital';
  
  // Transaction Types
  static const String seedSaleType = 'seed_sale';
  static const String beanSaleType = 'bean_sale';
  static const String beanCollectionType = 'bean_collection';
  static const String beanDeliveryType = 'bean_delivery';
  
  // Notification Types
  static const String notificationOrder = 'order';
  static const String notificationPayment = 'payment';
  static const String notificationAlert = 'alert';
  
  // Language Codes
  static const String languageEnglish = 'en';
  static const String languageKinyarwanda = 'rw';
  
  // Shared Preferences Keys
  static const String keyLanguage = 'app_language';
  static const String keyUserId = 'user_id';
  static const String keyUserType = 'user_type';
  static const String keyIsLoggedIn = 'is_logged_in';
  static const String keyOnboardingComplete = 'onboarding_complete';
  
  // Rwanda Districts (Musanze District - Pilot)
  static const List<String> rwandaDistricts = [
    'Musanze',
    'Burera',
    'Gakenke',
    'Gicumbi',
    'Rulindo',
  ];
  
  // Seed Varieties
  static const List<String> ironBeanVarieties = [
    'RWR 2245',
    'RWR 2154',
    'MAC 42',
    'MAC 44',
  ];
  
  // Currency
  static const String currency = 'RWF';
  static const String currencySymbol = 'FRw';
  
  // Validation
  static const int minPasswordLength = 8;
  static const int otpLength = 6;
  static const int otpValidityMinutes = 10;
  
  // API Endpoints (for SMS integration - Africa's Talking)
  static const String smsApiBaseUrl = 'https://api.africastalking.com/version1';
  static const String smsEndpoint = '/messaging';
}
