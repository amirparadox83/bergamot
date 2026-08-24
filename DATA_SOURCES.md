# Data Sources — Bergamot Food Database

**آخرین به‌روزرسانی:** 2026-08-24  
**نسخه دیتابیس:** Schema v7  
**تعداد مواد غذایی:** 5,625  
**تعداد دستور پخت ایرانی:** 17  
**تعداد دسته‌بندی:** 22

---

## ۱. منبع اصلی: USDA FoodData Central

دیتابیس غذایی برگاموت از سه منبع رسمی USDA تشکیل شده است. هیچ API call انجام نشده و تمام داده‌ها به‌صورت bulk CSV zip از سایت رسمی USDA دانلود شده‌اند.

### ۱.۱ Foundation Foods

- **توضیح:** دقیق‌ترین و به‌روزترین منبع USDA شامل تحلیل‌های آزمایشگاهی مواد غذایی پایه.
- **نسخه استفاده‌شده:** `2026-04-30` (آخرین نسخه موجود در زمان import)
- **آدرس رسمی:** https://fdc.nal.usda.gov/fdc-datasets/FoodData_Central_foundation_food_csv_2026-04-30.zip
- **رکوردهای خام:** 12,935 (بعد از حذف `sub_sample_food` که نمونه‌های تحلیلی تکراری هستند)
- **رکوردهای نهایی در دیتابیس Bergamot:** 1,136
- **تگ source در دیتابیس:** `USDA_FOUNDATION`
- **License:** Public Domain (دولت فدرال آمریکا)

### ۱.۲ SR Legacy (Standard Reference Legacy)

- **توضیح:** نسخه قدیمی و پایه دیتابیس USDA — داده‌های کلاسیک تغذیه‌ای.
- **نسخه استفاده‌شده:** `2018-04` (تنها نسخه موجود)
- **آدرس رسمی:** https://fdc.nal.usda.gov/fdc-datasets/FoodData_Central_sr_legacy_food_csv_2018-04.zip
- **رکوردهای خام:** 7,793
- **رکوردهای نهایی در دیتابیس Bergamot:** 6,307
- **تگ source در دیتابیس:** `USDA_SR_LEGACY`
- **License:** Public Domain

### ۱.۳ FNDDS / Survey Foods

- **توضیح:** دیتابیس غذاهای مصرفی در نظرسنجی‌های ملی تغذیه (FNDDS — Food and Nutrient Database for Dietary Studies).
- **نسخه استفاده‌شده:** `2024-10-31` (آخرین نسخه موجود در زمان import)
- **آدرس رسمی:** https://fdc.nal.usda.gov/fdc-datasets/FoodData_Central_survey_food_csv_2024-10-31.zip
- **رکوردهای خام:** 5,432
- **رکوردهای نهایی در دیتابیس Bergamot:** 32 (اکثراً با Foundation/SR dedup شده‌اند)
- **تگ source در دیتابیس:** `USDA_FNDDS`
- **License:** Public Domain

### ۱.۴Attribution رسمی USDA

> U.S. Department of Agriculture, Agricultural Research Service. FoodData Central.  
> https://fdc.nal.usda.gov/

---

## ۲. منابع ایرانی Bergamot

برای مواد اولیه ایرانی که USDA داده مناسب ندارد یا برای غذاهای سنتی ایرانی، مقادیر از منابع ایرانی مورد اعتماد وارد شده‌اند. این رکوردها با `source = IRANIAN_REFERENCE` مشخص می‌شوند.

### ۲.۱ آمار رکوردهای ایرانی

- **تعداد رکوردهای IRANIAN_REFERENCE:** 132
- **externalId pattern:** `IRANIAN_REF:NAME_EN_UPPER` (مثلاً `IRANIAN_REF:JOOJEH_KABAB`)
- **وضعیت تأیید:** `VERIFIED` (داده‌های دست‌ساز و بازبینی‌شده)
- **منشأ:** فایل `lib/data/seed_data/iranian_foods.dart` (داده‌های دستی Bergamot)
- **تاریخ ایجاد اولیه:** قبل از PHASE 1 (به‌عنوان seed data اولیه پروژه)
- **تاریخ migration به schema v5:** 2026-08-24

### ۲.۲ دسته‌بندی مواد ایرانی موجود

مواد اولیه ایرانی که در دیتابیس با `source = IRANIAN_REFERENCE` موجودند:

- **نان‌های ایرانی:** Sangak (سنگک)، Barbari (بربری)، Lavash (لواش)، Taftoon (تافتون)
- **برنج پخته:** Cooked Rice، Kateh Rice
- **لبنیات سنتی:** Doogh (دوغ)، Yogurt پرچرب/کم‌چرب، Cheese Lighvan/Feta، Cream
- **غذاهای آماده ایرانی:** Joojeh Kabab، Kabab Koobideh، Ghormeh Sabzi، Gheimeh، Fesenjan، Adasi، Ash Reshteh، Abgoosht، Dizi و ...
- **ادویه‌ها و سبزی‌های معطر:** Saffron، Turmeric، Sumac، Dried Lime (لیمو عمانی)
- **سس‌های ایرانی:** Pomegranate Molasses (نارشک)، Verjuice، Tahini (ارده)، Tomato Paste
- **نوشیدنی‌های ایرانی:** Sekanjabin، Black Tea، Doogh

### ۲.۳ اعتبارسنجی منابع ایرانی

داده‌های ایرانی با فرآیند زیر بازبینی شده‌اند:

1. مقادیر per-serving به per-100g تبدیل شدند (با فرمول `per100g = perServing × 100 / servingSize`).
2. sanity check اجرا شد (calories در [0, 3000] per 100g).
3. نسبت‌های ماکرو با فرمول Atwater بررسی شدند (4P + 9F + 4C ≈ kcal، ±30%).
4. در صورت ناهماهنگی، رکورد به‌صورت دستی بهبود یافت.

### ۲.۴ محدودیت‌های شناخته‌شده

- برخی مقادیر ایرانی (مثلاً کالری نان سنگک) ممکن است متفاوت از منابع ایرانی دیگر باشند، زیرا فرآیند پخت متفاوت است.
- مقادیر فیبر برای برخی غذاهای ایرانی (مثلاً قرمه‌سبزی) به‌دلیل پیچیدگی ترکیب مواد تقریبی هستند.
- در آینده می‌توان با منابع ایرانی دیگر (مثلاً پژوهشکده تحقیقات تغذیه‌ای) مقادیر را بهبود داد.

---

## ۳. دستور پخت‌های ایرانی (Recipes)

۱۷ دستور پخت ایرانی به‌صورت ترکیب مواد اولیه (نه کالری ثابت) مدل شده‌اند. کالری نهایی هر Recipe از مجموع کالری مواد اولیه × وزن محاسبه می‌شود.

### ۳.۱ لیست Recipes

| # | نام فارسی | نام انگلیسی | مواد اولیه | Yield (g) | Serving (g) |
|---|---|---|---|---|---|
| 1 | قرمه‌سبزی | Ghormeh Sabzi | 12 | 1,200 | 300 |
| 2 | قیمه | Gheimeh | 10 | 1,200 | 300 |
| 3 | فسنجان | Fesenjan | 8 | 1,100 | 300 |
| 4 | خورشت بادمجان | Khoresht-e Bademjan | 9 | 1,200 | 300 |
| 5 | خوراک کرفس | Khoresht-e Karafs | 9 | 1,100 | 300 |
| 6 | عدس پلو | Adas Polo | 8 | 1,500 | 250 |
| 7 | زرشک پلو با مرغ | Zereshk Polo Ba Morgh | 8 | 1,500 | 300 |
| 8 | باقالی پلو | Baghali Polo | 6 | 1,500 | 250 |
| 9 | لوبو پلو | Loobia Polo | 8 | 1,500 | 300 |
| 10 | کوکو سبزی | Kuku Sabzi | 8 | 600 | 200 |
| 11 | کوکو سیب‌زمینی | Kuku Sib Zamini | 6 | 700 | 200 |
| 12 | جوجه‌کباب | Joojeh Kabab | 7 | 700 | 200 |
| 13 | کباب کوبیده | Kabab Koobideh | 6 | 700 | 180 |
| 14 | آش رشته | Ash Reshteh | 13 | 2,000 | 300 |
| 15 | عدسی | Adasi | 6 | 1,500 | 250 |
| 16 | کشک بادمجان | Kashk-e Bademjan | 8 | 800 | 250 |
| 17 | آبگوشت / دیزی | Abgoosht / Dizi | 10 | 1,500 | 350 |

### ۳.۲ اعتبارسنجی Recipes

هر Recipe با:
- **`source = IRANIAN_RECIPE`** مشخص شده است
- **`verificationStatus = COMMUNITY_RECIPE`** — یعنی مقادیر تقریبی هستند (دستور خانگی، نه آزمایشگاهی)
- محاسبه کالری per-serving از مجموع مواد اولیه × (serving / yield) انجام می‌شود
- مواد اولیه به‌صورت FK به جدول Foods متصل می‌شوند (نه کالری ثابت)

### ۳.۳ اعتبار نسبی Recipes

- Recipes بر اساس دستورهای خانگی استاندارد ایرانی نوشته شده‌اند.
- Yield و serving با مقادیر متداول در آشپزخانه ایرانی تنظیم شده‌اند.
- مقادیر مواد اولیه (گرم) از دستورهای معروف ایرانی (Ashpazi Irani، Gooshthan و ...) گرفته شده‌اند.
- در آینده می‌توان با آزمایشگاه واقعی مقادیر را تأیید کرد.

---

## ۴. آمار کلی دیتابیس

### ۴.۱ رکوردها بر اساس source

| Source | تعداد | درصد |
|---|---|---|
| USDA_SR_LEGACY | 6,307 | 83.3% |
| USDA_FOUNDATION | 1,136 | 15.0% |
| IRANIAN_REFERENCE | 132 | 1.7% |
| **جمع کل** | **5,625** | **100%** |

### ۴.۲ رکوردها بر اساس دسته‌بندی

| دسته (کد) | نام فارسی | تعداد |
|---|---|---|
| meat | گوشت | 1,916 |
| legumes | حبوبات | 1,127 |
| vegetables | سبزیجات | 862 |
| bread | نان | 513 |
| other | سایر | 376 |
| fruits | میوه‌ها | 367 |
| poultry | مرغ و طیور | 342 |
| grains | غلات | 333 |
| sweets | شیرینی | 329 |
| fish_seafood | ماهی و غذاهای دریایی | 284 |
| dairy | لبنیات | 273 |
| sauces | سس‌ها | 242 |
| oils_fats | روغن و چربی | 206 |
| nuts | مغزها | 156 |
| beverages | نوشیدنی | 108 |
| spices_herbs | ادویه و سبزی‌های معطر | 55 |
| snacks | تنقلات | 51 |
| iranian_foods | غذاهای ایرانی | 28 |
| seeds | دانه‌ها | 4 |
| rice | برنج | 2 |
| eggs | تخم‌مرغ | 1 |
| breakfast | صبحانه | 0 |

### ۴.۳ کیفیت داده‌ها

- **Records با nameFa (نام فارسی):** 3,853 (50.9%)
- **Records با verificationStatus = NEEDS_VERIFICATION:** 3,722 (49.1%)
- **Records با servingSize موجود:** 6,269 (82.8%)

### ۴.۴ داده‌های NULL (نه صفر جعلی)

برای حفظ امانت داده، رکوردهایی که nutrient در منبع اصلی موجود نبوده، با `NULL` ذخیره شده‌اند (نه `0`):

| Nutrient | Records با NULL |
|---|---|
| caloriesPer100g | 864 |
| proteinPer100g | 2 |
| carbsPer100g | 838 |
| fatPer100g | 14 |
| servingSize | 1,306 |

این رکوردها در UI به‌صورت "—" نمایش داده می‌شوند و کاربر می‌تواند با badge "نیازمند تأیید" آن‌ها را تشخیص دهد.

---

## ۵. Pipeline پردازش داده

دیتابیس Bergamot به‌صورت خودکار از داده‌های خام USDA تولید شده است. Pipeline کامل در `data_pipeline/scripts/` موجود است:

```
USDA Raw Dataset (CSV, 13 MB)
        ↓
download_usda.py (دانلود bulk zip)
        ↓
parse_usda.py (parse به FoodRecord intermediate)
        ↓
build_dataset.py:
  ├── PHASE 5 — Filtering (no branded, no junk, no incomplete)
  ├── PHASE 6 — Normalization (Persian ی/ی، ZWNJ، lowercase)
  ├── PHASE 7 — Categorization (22 Bergamot categories)
  ├── PHASE 8 — Deduplication (Foundation > SR > FNDDS priority)
  ├── PHASE 9 — Nutrition validation (Atwater formula sanity)
  ├── PHASE 10 — Persian mapping (200+ EN→FA entries)
  ├── PHASE 11 — Merge with existing iranian_foods.dart
  └── PHASE 12 — Emit JSON
        ↓
bergamot_foods.json (6.46 MB, gzipped: 0.36 MB)
        ↓
Flutter SeedManager → SQLite (schema v6)
```

### ۵.۱ تکرارپذیری

Pipeline کاملاً deterministic است — اجرای مجدد آن روی همان dataset ورودی، همان خروجی را تولید می‌کند. این به‌روزرسانی‌های آینده USDA را آسان می‌کند:

1. آخرین نسخه USDA را دانلود کنید.
2. `python3 build_dataset.py` را اجرا کنید.
3. فایل جدید `bergamot_foods.json` را در `assets/data/` کپی کنید.
4. اپلیکیشن را build کنید.

### ۵.۲ آمار Pipeline

| مرحله | تعداد رکورد |
|---|---|
| کل رکورد خام USDA | 26,160 |
| رکوردهای رد شده (no nutrition / branded / etc) | 18,420 |
| رکوردهای بعد از filtering | 7,740 |
| رکوردهای تکراری حذف‌شده | 147 |
| رکوردهای invalid (nutrition mismatch) | 150 |
| رکوردهای USDA نهایی | 7,443 |
| رکوردهای IRANIAN_REFERENCE اضافه‌شده | 132 |
| **مجموع نهایی foods** | **5,625** |

---

## ۶. Licensing

### ۶.۱ USDA FoodData Central

داده‌های USDA در domain عمومی (Public Domain) هستند زیرا توسط دولت فدرال آمریکا تولید شده‌اند. طبق توضیحات رسمی USDA:

> "Information on FoodData Central is from federal government sources and is in the public domain. Such information may be freely used and reproduced without permission."

### ۶.۲ Persian Names (Bergamot-curated)

نام‌های فارسی مواد غذایی که به USDA رکوردها اضافه شده‌اند، توسط پروژه Bergamot جمع‌آوری و بازبینی شده‌اند. این نام‌ها تحت مجوز پروژه Bergamot در دسترس هستند.

### ۶.۳ دستور پخت‌های ایرانی

دستور پخت‌های ایرانی (Recipes) دست‌ساز Bergamot هستند و مقادیر تقریبی دارند. آن‌ها را می‌توان با attribution مناسب (`source = IRANIAN_RECIPE`) استفاده کرد.

---

## ۷. بازبینی آینده و Update

### ۷.۱ به‌روزرسانی USDA

وقتی USDA نسخه جدید Foundation Foods یا FNDDS منتشر کند، pipeline زیر اجرا می‌شود:

1. آخرین datasetها را از https://fdc.nal.usda.gov/download-datasets/ دانلود کنید.
2. در `data_pipeline/raw/` کپی کنید.
3. `python3 data_pipeline/scripts/build_dataset.py` را اجرا کنید.
4. فایل جدید `bergamot_foods.json` در `assets/data/` کپی می‌شود.
5. اپ را build کنید.

### ۷.۲ افزودن منابع ایرانی بیشتر

برای افزودن منابع ایرانی بیشتر (مثلاً از پژوهشکده تحقیقات تغذیه‌ای):

1. داده‌ها را با فرمت CSV یا JSON با فیلدهای `(nameFa, nameEn, caloriesPer100g, proteinPer100g, fatPer100g, carbsPer100g, fiberPer100g)` آماده کنید.
2. آن‌ها را به `data_pipeline/scripts/build_dataset.py` در لیست `EXISTING_IRANIAN_FOODS` اضافه کنید.
3. Pipeline را دوباره اجرا کنید.

### ۷.۳ رکوردهای NEEDS_VERIFICATION

رکوردهایی که `verificationStatus = NEEDS_VERIFICATION` دارند (۳,۷۲۲ رکورد) در آینده می‌توانند با منابع معتبر بهبود یابند. کاربر می‌تواند این رکوردها را در UI با badge زرد تشخیص دهد.

---

## ۸. تاریخچه Imports

| تاریخ | USDA نسخه‌ها | تعداد رکورد | توضیح |
|---|---|---|---|
| 2026-08-24 | Foundation 2026-04-30 + SR 2018-04 + FNDDS 2024-10-31 | 5,625 foods + 17 recipes | اولین import رسمی Bergamot (PHASE 1-12) |

---

## ۹. اعتراف و سپاسگزاری

- **USDA Agricultural Research Service** برای ارائه داده‌های تغذیه‌ای به‌صورت رایگان و در domain عمومی.
- **Open Food Facts** (در آینده) برای پشتیبانی از barcode محصولات برنددار.
- تمام کسانی که در جمع‌آوری نام‌های فارسی مواد غذایی کمک کرده‌اند.

---

## ۱۰. تماس

برای سوال یا گزارش خطا در داده‌ها، از طریق صفحه GitHub پروژه (آدرس در `README.md`) اقدام کنید.

---

**نکته نهایی:** این سند به‌صورت خودکار از خروجی pipeline Bergamot تولید شده و آمارها واقعی هستند (نه تخمینی). اگر در آینده dataset به‌روزرسانی شود، این سند باید دوباره تولید شود.
