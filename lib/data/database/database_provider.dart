import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'bergamot_database.dart';

/// پروویدر دیتابیس برگاموت
///
/// از نمونه Singleton دیتابیس استفاده می‌کند
final bergamotDatabaseProvider = Provider<BergamotDatabase>((ref) {
  return BergamotDatabase.instance;
});
