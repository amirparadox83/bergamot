# برگاموت (Bergamot)

اپلیکیشن سلامت و سبک زندگی فارسی‌اول، آفلاین‌اول و حریم‌خصوصی‌محور.

## ویژگی‌ها

- **آفلاین‌محور** — تمام داده‌ها روی دستگاه ذخیره می‌شوند، هیچ اتصال به سرور/ابر وجود ندارد
- **سبک زندگی** — ردیابی خواب، آب، تغذیه، وزن و تمرینات ورزشی
- **قانون‌محور** — موتور قوانین قطعی (Rule Engine) برای محاسبه امتیاز سبک زندگی (۰-۱۰۰)
- **RTL فارسی** — فونت Vazirmatn با ۹ وزن، طراحی کاملاً فارسی
- **تم روشن/تاریک** — Design System یکپارچه با پالت الهام‌گرفته از طبیعت

## فناوری‌ها

- **Flutter 3.24** + **Dart 3.5**
- **Drift (SQLite)** — دیتابیس آفلاین با code generation
- **Riverpod** — مدیریت حالت
- **GoRouter** — مسیریابی
- **fl_chart** — نمودارها
- **shared_preferences** — ذخیره تنظیمات ساده

## ساختار پروژه

```
lib/
├── data/
│   ├── database/          # دیتابیس Drift + DAOها + جداول
│   └── seed_data/         # داده‌های اولیه (غذاهای ایرانی، تمرینات)
├── domain/
│   ├── entities/          # محاسبات سلامت (BMI, BMR, TDEE, 1RM)
│   ├── rule_engine/       # موتور قوانین و قوانین ارزیابی
│   └── services/          # سرویس‌های محاسباتی
├── presentation/
│   ├── providers/         # Riverpod providers
│   ├── router/            # GoRouter مسیردهی
│   ├── screens/           # صفحات اپلیکیشن
│   ├── theme/             # Design System (رنگ، تایپوگرافی، فاصله‌گذاری)
│   └── widgets/           # ویجت‌های مشترک
└── main.dart              # نقطه شروع
```

## نحوه اجرا

### پیش‌نیازها

- Flutter SDK 3.24 یا بالاتر
- Android Studio / VS Code با افزونه Flutter

### مراحل

```bash
# کلون و نصب وابستگی‌ها
cd bergamot
flutter pub get

# تولید کدهای Drift
dart run build_runner build --delete-conflicting-outputs

# اجرا
flutter run

# بیلد APK
flutter build apk --release
```

## معماری

پروژه از **Clean Architecture** سه‌لایه استفاده می‌کند:

1. **Data Layer** — جداول Drift، DAOها، دیتابیس
2. **Domain Layer** — موجودیت‌ها، Rule Engine، محاسبات
3. **Presentation Layer** — صفحات، Providerها، تم، روتر

## Design System

- **رنگ‌ها:** `BergamotColors` با پشتیبانی از تم روشن/تاریک
- **فاصله‌گذاری:** `BergamotSpacing` بر اساس گرید ۴ پیکسل
- **تایپوگرافی:** فونت Vazirmatn با ۹ وزن (Thin تا Black)
- **سایه‌ها:** سه سطح (subtle, medium, large)

## دیتابیس

۱۵ جدول Drift: پروفایل کاربر، خواب، غذاها، وعده‌های غذایی، آب، تمرینات، برنامه تمرین، ست‌های تمرین، وزن، عادت‌ها، لاگ عادت‌ها، اهداف، اندازه‌گیری بدن، خلاصه روزانه، تنظیمات اپ

## لایسنس

تمامی حقوق محفوظ است.
