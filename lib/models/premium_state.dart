import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

class PremiumState extends ChangeNotifier {
  bool _isPremiumArchives = false;
  bool _isFullPremium = false;
  
  String _priceArchives = "2.99€";
  String _pricePack = "9.99€";
  
  final Completer<void> _initCompleter = Completer<void>();
  
  static const String _keyArchives = 'is_premium_archives';
  static const String _keyFull = 'is_full_premium';
  
  static const String _idArchives = 'premium_archives';
  static const String _idPack = 'premium_pack_annual'; 

  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  late StreamSubscription<List<PurchaseDetails>> _subscription;

  // L'accès aux archives est autorisé si on a l'option archives OU le pack premium complet
  bool get isPremiumArchives => _isPremiumArchives || _isFullPremium;
  bool get isFullPremium => _isFullPremium;
  
  // isPremium représente le pack complet (Aviation, OACI, VAC, Préparation)
  bool get isPremium => _isFullPremium; 

  String get formattedPriceArchives => _priceArchives;
  String get formattedPricePack => _pricePack;
  String get formattedPrice => _pricePack;

  Future<void> get initializationDone => _initCompleter.future;

  PremiumState() {
    _init();
  }

  Future<void> _init() async {
    await _loadPremiumState();
    _initializeInAppPurchase();
    // Tenter une synchronisation silencieuse au démarrage
    Timer(const Duration(seconds: 2), () => restorePurchases(silent: true));
  }

  Future<void> _loadPremiumState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isPremiumArchives = prefs.getBool(_keyArchives) ?? false;
      _isFullPremium = prefs.getBool(_keyFull) ?? false;
    } finally {
      if (!_initCompleter.isCompleted) {
        _initCompleter.complete();
      }
      notifyListeners();
    }
  }

  void _initializeInAppPurchase() {
    final purchaseUpdated = _inAppPurchase.purchaseStream;
    _subscription = purchaseUpdated.listen((purchaseDetailsList) {
      _listenToPurchaseUpdated(purchaseDetailsList);
    }, onDone: () {
      _subscription.cancel();
    }, onError: (error) {
      debugPrint("Purchase stream error: $error");
    });
    
    _fetchProductDetails();
  }

  Future<void> _fetchProductDetails() async {
    try {
      final bool available = await _inAppPurchase.isAvailable();
      if (!available) return;

      const Set<String> kIds = <String>{_idArchives, _idPack};
      final ProductDetailsResponse response = await _inAppPurchase.queryProductDetails(kIds);

      for (var product in response.productDetails) {
        if (product.id == _idArchives) _priceArchives = product.price;
        if (product.id == _idPack) _pricePack = product.price;
      }
      notifyListeners();
    } catch (e) {
      debugPrint("Error fetching prices: $e");
    }
  }

  Future<void> _listenToPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) async {
    for (var purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.purchased ||
          purchaseDetails.status == PurchaseStatus.restored) {
        if (purchaseDetails.productID == _idArchives) {
          await _setPremiumState(_keyArchives, true);
        } else if (purchaseDetails.productID == _idPack) {
          await _setPremiumState(_keyFull, true);
        }
      }
      
      if (purchaseDetails.pendingCompletePurchase) {
        await _inAppPurchase.completePurchase(purchaseDetails);
      }
    }
  }

  Future<void> _setPremiumState(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
    await _loadPremiumState();
  }

  Future<void> buyPremiumArchives() async {
    await _buyProduct(_idArchives);
  }

  Future<void> buyPremium() async {
    await _buyProduct(_idPack);
  }

  Future<void> _buyProduct(String id) async {
    final bool available = await _inAppPurchase.isAvailable();
    if (!available) return;

    final ProductDetailsResponse response = await _inAppPurchase.queryProductDetails({id});

    if (response.productDetails.isNotEmpty) {
      final PurchaseParam purchaseParam = PurchaseParam(productDetails: response.productDetails.first);
      await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
    }
  }

  Future<void> restorePurchases({bool silent = false}) async {
    try {
      await _inAppPurchase.restorePurchases();
    } catch (e) {
      if (!silent) debugPrint("Error restoring purchases: $e");
    }
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
