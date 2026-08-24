import 'package:drift/drift.dart';

class Achievements extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get key => text().unique()();
  TextColumn get titleFa => text()();
  TextColumn get descriptionFa => text()();
  TextColumn get icon => text()();
  IntColumn get unlockedAt => integer().nullable()();
}
