// Integration test: اجرای واقعی SeedManager روی دیتابیس in-memory Drift
// برای تأیید اینکه سیستم تطبیق مواد اولیه رسپی‌ها واقعاً کار می‌کند.
//
// این تست برای PHASE 1.2 (رفع باگ تطبیق مواد اولیه رسپی‌های ایرانی) اضافه شد.
// این تست فقط منطق pure matcher را آزمایش نمی‌کند، بلکه کل seed pipeline را
// با دیتابیس واقعی اجرا می‌کند و تعداد واقعی recipe_ingredients ایجاد شده را
// با تعداد مورد انتظار مقایسه می‌کند.
import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:bergamot/data/database/bergamot_database.dart';
import 'package:bergamot/data/seed_data/seed_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late BergamotDatabase db;

  setUp(() async {
    // In-memory database — no file persistence.
    db = BergamotDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  test('SeedManager creates all 17 recipes with smart ingredient matching',
      () async {
    // Run the actual seed pipeline.
    await SeedManager.seedIfNeeded(db);

    // Verify recipes were created.
    final recipesInDb = await db.select(db.recipes).get();
    expect(recipesInDb.length, greaterThanOrEqualTo(15),
        reason: 'Expected at least 15 recipes seeded');

    // Verify recipe ingredients were created (i.e., matching worked).
    final recipeIngredients = await db.select(db.recipeIngredients).get();
    expect(recipeIngredients.length, greaterThan(0),
        reason: 'Expected recipe_ingredients to be populated');

    // Compute per-recipe match ratio against the source JSON.
    final rawRecipes = json.decode(
      await rootBundle.loadString('assets/data/bergamot_recipes.json'),
    )['recipes'] as List<dynamic>;

    int totalExpected = 0;
    int totalMatched = 0;
    final below70 = <String>[];
    for (final r in rawRecipes) {
      final name = r['nameFa'] as String;
      final expected = (r['ingredients'] as List).length;
      final recipeRow = recipesInDb.firstWhere((rec) => rec.nameFa == name);
      final actual = await (db.select(db.recipeIngredients)
            ..where((t) => t.recipeId.equals(recipeRow.id)))
          .get();
      totalExpected += expected;
      totalMatched += actual.length;
      final ratio = expected == 0 ? 1.0 : actual.length / expected;
      // ignore: avoid_print
      print('  $name: ${actual.length}/$expected '
          '(${(ratio * 100).round()}%)');
      if (ratio < 0.7) {
        below70.add('$name (${(ratio * 100).round()}%)');
      }
    }

    final overall = totalMatched / totalExpected;
    // ignore: avoid_print
    print('━━━ SeedManager integration — Overall match ratio: '
        '$totalMatched/$totalExpected (${(overall * 100).round()}%) ━━━');

    // Hard assertions — these are the actual regression guards.
    expect(overall, greaterThanOrEqualTo(0.80),
        reason: 'Overall recipe ingredient match ratio is '
            '${(overall * 100).round()}%, below the 80% threshold');
    expect(below70, isEmpty,
        reason: 'Recipes below 70% match: ${below70.join(", ")}');
  });

  test('SeedManager.seedIfNeeded is idempotent (running twice = same result)',
      () async {
    // First run: full seed.
    await SeedManager.seedIfNeeded(db);
    final recipes1 = await db.select(db.recipes).get();
    final recipeIngs1 = await db.select(db.recipeIngredients).get();

    // Second run: should be a no-op (existing rows guard).
    await SeedManager.seedIfNeeded(db);
    final recipes2 = await db.select(db.recipes).get();
    final recipeIngs2 = await db.select(db.recipeIngredients).get();

    expect(recipes2.length, recipes1.length,
        reason: 'Recipe count changed on second seed (not idempotent)');
    expect(recipeIngs2.length, recipeIngs1.length,
        reason: 'Recipe ingredient count changed on second seed (not idempotent)');
  });
}
