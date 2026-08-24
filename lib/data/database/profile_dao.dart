import 'bergamot_database.dart';

/// دیتابیس پروفایل کاربر
/// پروفایل کاربر ۱:۱ است، از upsert استفاده می‌شود
class ProfileDao {
  final BergamotDatabase db;
  ProfileDao(this.db);

  /// واچ پروفایل کاربر
  Stream<UserProfile?> watchProfile() {
    return (db.select(db.userProfiles)..limit(1)).watchSingleOrNull();
  }

  /// دریافت پروفایل فعلی
  Future<UserProfile?> getProfile() {
    return (db.select(db.userProfiles)..limit(1)).getSingleOrNull();
  }

  /// درج یا بروزرسانی پروفایل
  /// اگر رکوردی وجود داشت بروزرسانی می‌شود، وگرنه درج
  Future<void> upsertProfile(UserProfilesCompanion entry) async {
    await db.transaction(() async {
      final existing = await getProfile();
      if (existing == null) {
        await db.into(db.userProfiles).insert(entry);
      } else {
        await (db.update(db.userProfiles)..where((t) => t.id.equals(existing.id)))
            .write(entry);
      }
    });
  }
}
