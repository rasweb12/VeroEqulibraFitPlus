import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Overridden in main after the local store is available. Keeping the boundary
/// injectable makes repositories testable without device storage.
final sharedPreferencesProvider = Provider<SharedPreferences?>((ref) => null);
