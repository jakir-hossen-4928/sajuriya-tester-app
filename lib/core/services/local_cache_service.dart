import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/app_model.dart';
import '../models/profile_model.dart';
import '../models/karma_transaction_model.dart';
import '../models/test_assignment_model.dart';

class LocalCacheService {
  static const String _boxMarketplace = 'marketplace_apps';
  static const String _boxActiveTests = 'active_tests';
  static const String _boxCompletedTests = 'completed_tests';
  static const String _boxMyApps = 'my_apps';
  static const String _boxTransactions = 'karma_transactions';
  static const String _boxProfile = 'user_profile';
  static const String _boxGeneralData = 'general_data';

  Future<void> init() async {
    await Hive.initFlutter();
    // We open boxes here to have them ready
    await Future.wait([
      Hive.openBox(_boxMarketplace),
      Hive.openBox(_boxActiveTests),
      Hive.openBox(_boxCompletedTests),
      Hive.openBox(_boxMyApps),
      Hive.openBox(_boxTransactions),
      Hive.openBox(_boxProfile),
      Hive.openBox(_boxGeneralData),
    ]);
    debugPrint('[LocalCache] Hive initialized and boxes opened.');
  }

  Future<void> saveMarketplaceApps(List<AppModel> apps) async {
    try {
      final box = Hive.box(_boxMarketplace);
      await box.clear(); // Clear old cache
      for (var app in apps) {
        await box.put(app.id, app.toMap());
      }
      debugPrint('[LocalCache] Saved ${apps.length} marketplace apps to Hive.');
    } catch (e) {
      debugPrint('[LocalCache] Error saving marketplace: $e');
    }
  }

  Future<List<AppModel>> getMarketplaceApps() async {
    try {
      final box = Hive.box(_boxMarketplace);
      if (box.isEmpty) return [];
      
      return box.values
          .map((e) => AppModel.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (e) {
      debugPrint('[LocalCache] Error reading marketplace: $e');
      return [];
    }
  }

  Future<void> saveMyApps(List<AppModel> apps) async {
    try {
      final box = Hive.box(_boxMyApps);
      await box.clear();
      for (var app in apps) {
        await box.put(app.id, app.toMap());
      }
      debugPrint('[LocalCache] Saved ${apps.length} my apps to Hive.');
    } catch (e) {
      debugPrint('[LocalCache] Error saving my apps: $e');
    }
  }

  Future<List<AppModel>> getMyApps() async {
    try {
      final box = Hive.box(_boxMyApps);
      if (box.isEmpty) return [];
      
      return box.values
          .map((e) => AppModel.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (e) {
      debugPrint('[LocalCache] Error reading my apps: $e');
      return [];
    }
  }

  Future<void> saveActiveTests(List<TestAssignment> tests) async {
    try {
      final box = Hive.box(_boxActiveTests);
      await box.clear();
      for (var test in tests) {
        await box.put(test.id, test.toMap());
      }
      debugPrint('[LocalCache] Saved ${tests.length} active tests to Hive.');
    } catch (e) {
      debugPrint('[LocalCache] Error saving active tests: $e');
    }
  }

  Future<List<TestAssignment>> getActiveTests() async {
    try {
      final box = Hive.box(_boxActiveTests);
      if (box.isEmpty) return [];
      
      return box.values
          .map((e) => TestAssignment.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (e) {
      debugPrint('[LocalCache] Error reading active tests: $e');
      return [];
    }
  }

  Future<void> saveCompletedTests(List<TestAssignment> tests) async {
    try {
      final box = Hive.box(_boxCompletedTests);
      await box.clear();
      for (var test in tests) {
        await box.put(test.id, test.toMap());
      }
      debugPrint('[LocalCache] Saved ${tests.length} completed tests to Hive.');
    } catch (e) {
      debugPrint('[LocalCache] Error saving completed tests: $e');
    }
  }

  Future<List<TestAssignment>> getCompletedTests() async {
    try {
      final box = Hive.box(_boxCompletedTests);
      if (box.isEmpty) return [];
      
      return box.values
          .map((e) => TestAssignment.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (e) {
      debugPrint('[LocalCache] Error reading completed tests: $e');
      return [];
    }
  }

  Future<void> saveTransactions(List<KarmaTransaction> txs) async {
    try {
      final box = Hive.box(_boxTransactions);
      await box.clear();
      for (var tx in txs) {
        await box.put(tx.id, tx.toMap());
      }
      debugPrint('[LocalCache] Saved ${txs.length} transactions to Hive.');
    } catch (e) {
      debugPrint('[LocalCache] Error saving transactions: $e');
    }
  }

  Future<List<KarmaTransaction>> getTransactions() async {
    try {
      final box = Hive.box(_boxTransactions);
      if (box.isEmpty) return [];
      
      return box.values
          .map((e) => KarmaTransaction.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (e) {
      debugPrint('[LocalCache] Error reading transactions: $e');
      return [];
    }
  }

  Future<void> clearAll() async {
    await Future.wait([
      Hive.box(_boxMarketplace).clear(),
      Hive.box(_boxActiveTests).clear(),
      Hive.box(_boxCompletedTests).clear(),
      Hive.box(_boxMyApps).clear(),
      Hive.box(_boxTransactions).clear(),
      Hive.box(_boxProfile).clear(),
      Hive.box(_boxGeneralData).clear(),
    ]);
    debugPrint('[LocalCache] All local storage cleared.');
  }

  Future<void> saveProfile(Profile profile) async {
    try {
      final box = Hive.box(_boxProfile);
      await box.put(profile.id, profile.toMap());
    } catch (e) {
      debugPrint('[LocalCache] Error saving profile: $e');
    }
  }

  Future<Profile?> getProfile(String userId) async {
    return getProfileSync(userId);
  }

  Profile? getProfileSync(String userId) {
    try {
      final box = Hive.box(_boxProfile);
      final data = box.get(userId);
      if (data == null) return null;
      return Profile.fromMap(Map<String, dynamic>.from(data as Map));
    } catch (e) {
      debugPrint('[LocalCache] Error reading profile sync: $e');
      return null;
    }
  }

  Future<void> saveString(String key, String value) async {
    try {
      final box = Hive.box(_boxGeneralData);
      await box.put(key, value);
    } catch (e) {
      debugPrint('[LocalCache] Error saving string: $e');
    }
  }

  Future<String?> getString(String key) async {
    try {
      final box = Hive.box(_boxGeneralData);
      return box.get(key) as String?;
    } catch (e) {
      debugPrint('[LocalCache] Error reading string: $e');
      return null;
    }
  }
}
