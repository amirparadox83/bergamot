# -*- coding: utf-8 -*-
"""
Bergamot Pre-Implementation Analysis Document Generator
Generates a comprehensive RTL Persian HTML document with 15 analysis sections.
"""

import os

OUTPUT_DIR = "/home/z/my-project/download"
OUTPUT_HTML = os.path.join(OUTPUT_DIR, "bergamot-analysis.html")

def h(level, text):
    """Generate heading tag."""
    return f"<h{level}>{text}</h{level}>\n"

def p(text):
    """Generate paragraph."""
    return f"<p>{text}</p>\n"

def bold(text):
    return f"<strong>{text}</strong>"

def li(text):
    return f"<li>{text}</li>\n"

def ul(items):
    return "<ul>" + "".join(items) + "</ul>\n"

def table_from_data(headers, rows, col_widths=None):
    """Generate an HTML table from headers and rows."""
    html = '<div class="table-wrapper"><table>\n'
    html += '<thead><tr>'
    for h_text in headers:
        html += f'<th>{h_text}</th>'
    html += '</tr></thead>\n'
    html += '<tbody>\n'
    for row in rows:
        html += '<tr>'
        for cell in row:
            html += f'<td>{cell}</td>'
        html += '</tr>\n'
    html += '</tbody></table></div>\n'
    return html

def section_divider():
    return '<div class="section-divider"></div>\n'

def card(title, content):
    return f'''<div class="card">
    <div class="card-title">{title}</div>
    <div class="card-body">{content}</div>
</div>
\n'''

def tag(text):
    return f'<span class="tag">{text}</span>\n'

def generate_cover():
    return '''<div class="cover">
        <div class="cover-decoration circle-1"></div>
        <div class="cover-decoration circle-2"></div>
        <div class="cover-content">
            <div class="cover-badge">PRE-IMPLEMENTATION ANALYSIS</div>
            <div class="cover-title">برگاموت</div>
            <div class="cover-subtitle">Personal Health &amp; Lifestyle OS</div>
            <div class="cover-line"></div>
            <div class="cover-desc">تحلیل جامع پیش از پیاده‌سازی — شامل ۱۵ سند تحلیلی</div>
            <div class="cover-meta">
                <span>بازار اولیه: ایران</span>
                <span class="sep">|</span>
                <span>زبان: فارسی / RTL</span>
                <span class="sep">|</span>
                <span>Offline-First</span>
            </div>
            <div class="cover-bottom-label">محرمانگی، کیفیت و تجربه کاربری برتر</div>
        </div>
    </div>'''

def generate_toc():
    items = [
        ("01", "تحلیل رقابتی", "Competitive Analysis"),
        ("02", "تحلیل مخازن Open Source", "Open Source Repository Analysis"),
        ("03", "بررسی لایسنس", "License Audit"),
        ("04", "معماری محصول", "Product Architecture"),
        ("05", "ماتریس ویژگی‌ها", "Feature Matrix"),
        ("06", "طراحی دیتابیس", "Database ERD"),
        ("07", "معماری Rule Engine", "Rule Engine Architecture"),
        ("08", "معماری اطلاعات", "Information Architecture"),
        ("09", "جریان‌های کاربری", "User Flows"),
        ("10", "استراتژی UX", "UX Strategy"),
        ("11", "پیشنهاد Design System", "Design System Proposal"),
        ("12", "فهرست صفحات", "Screen List"),
        ("13", "محدوده MVP", "MVP Scope"),
        ("14", "نقشه راه توسعه", "Development Roadmap"),
        ("15", "پیشنهاد استک فنی", "Technical Stack Recommendation"),
    ]
    html = '<div class="chapter-header"><div class="section-tag">فهرست مطالب</div>'
    html += '<div class="section-title">فهرست ۱۵ سند تحلیلی</div><div class="divider"></div></div>\n'
    for num, fa, en in items:
        html += f'''<div class="toc-item">
            <span class="toc-num">{num}</span>
            <span class="toc-fa">{fa}</span>
            <span class="toc-en">{en}</span>
        </div>\n'''
    return html


def sec01_competitive():
    html = '<div class="chapter-header"><div class="section-tag">سند ۰۱</div>'
    html += '<div class="section-title">تحلیل رقابتی بازار</div><div class="divider"></div></div>\n'
    
    html += h(3, "الف) اپلیکیشن‌های ایرانی")
    html += p("بازار اپلیکیشن‌های سلامت ایران در حال رشد است ولی هنوز فاصله زیادی با استانداردهای جهانی دارد. ده اپلیکیشن ایرانی بررسی شدند که مهم‌ترین آن‌ها عبارتند از: کرفس (بزرگ‌ترین کالری‌شمار ایرانی با ۷۷ هزار نصب در بازار)، جیم شو (بانک غذای ۹ هزار آیتم ایرانی با ویدیوهای آموزشی)، انرجیم (جامع‌ترین با مشاوره پزشکی و هوش مصنوعی)، میزان (نوآوری AI Food Recognition)، و فیتارا (تنها اپ Offline-first). هیچ‌کدام تمام محورهای سبک زندگی را یکجا پوشش نمی‌دهند و اکثراً وابسته به اینترنت هستند.")
    
    html += table_from_data(
        ["اپلیکیشن", "ویژگی اصلی", "Offline", "Privacy", "امتیاز"],
        [
            ["کرفس", "کالری‌شماری + رژیم", "خیر", "خیر", "۴.۴/۵"],
            ["جیم شو", "تغذیه + ویدیو ورزشی", "خیر", "خیر", "متوسط"],
            ["انرجیم", "ورزش + تغذیه + AI", "خیر", "خیر", "متوسط"],
            ["میزان", "AI Food Recognition", "خیر", "خیر", "۳.۲/۵"],
            ["فیتارا", "ثبت تمرین بدنسازی", "بله", "بله", "۴.۴/۵"],
            ["گامیران", "پیاده‌روی + Gamification", "خیر", "خیر", "متوسط"],
        ]
    )
    
    html += h(3, "ب) رقبای جهانی")
    html += p("در سطح جهانی، MyFitnessPal با ۲۰۰ میلیون دانلود و دیتابیس ۱۴ میلیاردی غذایی، بزرگ‌ترین بازیگر بازار است. YAZIO با $۴۸/سال قیمت‌گذاری رقابتی و AI Food Recognition، FatSecret با مدل رایگان و جامعه فعال، Strong و Hevy در حوزه تمرینات قدرتی، و BetterMe به‌عنوان اپ All-in-One شناخته می‌شوند.Sleep Cycle ($۵۸/سال) و WaterMinder ($۵) در niches تخصصی خود قدرتمندند. هیچ‌کدام زبان فارسی یا غذای ایرانی پشتیبانی نمی‌کنند.")
    
    html += table_from_data(
        ["اپلیکیشن", "قیمت/سال", "فارسی", "غذای ایرانی", "Offline"],
        [
            ["MyFitnessPal", "$۸۰-۱۰۰", "خیر", "خیر", "خیر"],
            ["YAZIO", "$۴۸", "خیر", "خیر", "خیر"],
            ["FatSecret", "$۶۰", "خیر", "خیر", "خیر"],
            ["Strong", "$۴۰", "خیر", "خیر", "بله"],
            ["Hevy", "$۲۴", "خیر", "خیر", "محدود"],
            ["BetterMe", "$۶۰-۲۴۰", "خیر", "خیر", "خیر"],
            ["FitNotes", "رایگان", "خیر", "خیر", "بله"],
        ]
    )
    
    html += h(3, "ج) شکاف‌های بازار و فرصت برگاموت")
    html += p("ده شکاف کلیدی در بازار شناسایی شده است. مهم‌ترین آن‌ها: عدم وجود اپلیکیشن واقعاً Offline-first ایرانی، نبود Privacy-focused بودن، عدم یکپارچگی محورهای مختلف سبک زندگی (خواب، آب، ورزش، تغذیه، وزن)، و نبود Gamification حرفه‌ای. برگاموت با ترکیب Persian-First + Offline-First + Privacy-First + Unified Lifestyle می‌تواند موقعیت منحصر به فردی ایجاد کند. هیچ اپلیکیشنی در بازار ایران (و حتی جهانی) این چهار ستون را همزمان ندارد.")
    
    gaps = [
        "هیچ اپ ایرانی واقعاً Offline-first نیست (فقط فیتارا که بسیار محدود است)",
        "هیچ اپ ایرانی Privacy-focused نیست و حریم خصوصی مشخصی ندارند",
        "هیچ اپ Unified Lifestyle (خواب+آب+ورزش+تغذیه+وزن+عادت) ندارد",
        "Wearable Integration در اپ‌های ایرانی صفر است",
        "Gamification حرفه‌ای نادیده گرفته شده (بجز گامیران)",
        "هیچ اپلیکیشنی Wearable Integration با ساعت‌های هوشمند ندارد",
        "تحلیل‌های پیشرفته و Insights متقاطع وجود ندارد",
        "پشتیبانی از Mental Wellness (مدیتیشن، استرس) بسیار محدود است",
    ]
    html += ul([li(g) for g in gaps])
    
    html += h(3, "د) پوزیشن‌یابی استراتژیک برگاموت")
    html += p("برگاموت باید در نقطه تلاقی Localisation بالا و Feature Breadth بالا قرار گیرد. اپ‌های ایرانی (کرفس، جیم شو) Localisation بالایی دارند ولی محدوده ویژگی‌شان узر است. اپ‌های جهانی (BetterMe) Feature Breadth بالایی دارند ولی هیچ Localisation ایرانی ندارند. برگاموت با پوشش کامل سبک زندگی به زبان فارسی، با دیتابیس غذایی ایرانی و حالت کاملاً Offline، می‌تواند این شکاف استراتژیک را پر کند.")
    
    return html


def sec02_opensource():
    html = '<div class="chapter-header"><div class="section-tag">سند ۰۲</div>'
    html += '<div class="section-title">تحلیل مخازن Open Source</div><div class="divider"></div></div>\n'
    
    html += h(3, "۱. wger-project/wger")
    html += p("wger یک اپلیکیشن وب بالغ (۱۳+ سال توسعه) با ۶,۷۰۰+ ستاره است. از Django 6 + DRF + React + PostgreSQL استفاده می‌کند. لایسنس AGPL-3.0 دارد که استفاده مستقیم از کد آن را برای محصول تجاری ممنوع می‌کند. مهم‌ترین الگوهای قابل الهام: سیستم Base + Translation برای داده‌های چندزبانه، ساختار Routine به‌صورت Day به‌صورت Slot به‌صورت SlotEntry با قوانین پیشرفت خودکار (AbstractChangeConfig)، سیستم حذف ایمن (DeletionLog با replace_by)، و واحدهای سفارشی اندازه‌گیری (IngredientWeightUnit). دیتابیس تمرینات شامل ۸ دسته‌بندی، ۱۶ عضله و ۱۲ نوع تجهیزات است.")
    
    html += card("الگوی قابل الهام: Base + Translation", "wger داده ساختاری (عضلات، تجهیزات، دسته‌بندی) را از داده زبانی (نام، توصیه) جدا می‌کند. هر Exercise یک مدل پایه دارد و چند Translation. این الگو برای دیتابیس غذایی ایرانی و تمرینات فارسی ایده‌آل است. جستجوی فازی با PostgreSQL GIN + trigram روی نام تمرینات انجام می‌شود.")
    
    html += card("الگوی قابل الهام: Automatic Weight Progression", "سیستم AbstractChangeConfig با Operation (ADD/SET) و Step (LINEAR/ARITHMETIC) و Requirements به کاربر اجازه می‌دهد قوانین پیشرفت خودکار تعریف کند. مثلاً: اگر همه تکرارها انجام شد، ۲.۵ کیلو اضافه کن. این سیستم بدون AI و کاملاً Deterministic کار می‌کند.")
    
    html += h(3, "۲. Princeu3/LifeOS")
    html += p("LifeOS یک سیستم‌عامل شخصی self-hosted با مفهوم Unified Timeline است. از React 19 + FastAPI + PostgreSQL + pgvector استفاده می‌کند. لایسنس MIT دارد (آزاد برای استفاده تجاری). مهم‌ترین الگو: جدول timeline_events به‌عنوان ستون فقرات append-only که هر رویداد از هر دامنه‌ای را یکپارچه می‌کند. هر رویداد دارای domain, ref_table, ref_id است که به جدول نرمال‌سازی‌شده مربوطه متصل می‌شود. اصل Structured Default, Freeform Fallback یعنی هر ورودی هم structured و هم freeform دارد و داده خام هرگز از دست نمی‌رود.")
    
    html += card("مفهوم کلیدی: Unified Timeline", "تمام اتفاقات کاربر (خواب، غذا، تمرین، آب، خلق) در یک Timeline یکپارچه نمایش داده می‌شوند. ورودی‌ها بر اساس روز گروه‌بندی شده و هر ورودی شامل emoji دامنه، label، ساعت و خلاصه است. این مفهوم برای برگاموت بسیار ارزشمند است زیرا کاربر می‌تواند یک تصویر کامل از روز خود ببیند.")
    
    html += card("مفهوم کلیدی: Offline-first با Idempotency", "ترکیب Dexie IndexedDB + Workbox Background Sync + server-side Idempotency-Key یک سیستم سه‌لایه‌ای قوی برای offline است. هر capture فوراً در IndexedDB ذخیره می‌شود و پس از اتصال، با token یکتا به سرور ارسال می‌شود. این الگو برای کاربران ایرانی با اینترنت ناپایدار حیاتی است.")
    
    html += h(3, "۳. egebese/lifeos")
    html += p("LifeOS (egebese) یک اپلیکیشن Next.js 15 + PostgreSQL + Drizzle ORM با تمرکز بر فیتنس و تغذیه است. لایسنس MIT دارد. مهم‌ترین ویژگی‌ها: نمایش Last Performance (عملکرد قبلی) هنگام ثبت تمرین، محاسبه 1RM با فرمول Epley، Rest Timer خودکار پس از هر ست، و PR Detection خودکار. دیتابیس شامل ۱,۳۲۴ تمرین دوزبانه (انگلیسی/ترکی) است. از recharts برای نمودارها و fal.ai برای AI استفاده می‌کند. این اپ Single-user و Cloud-dependent است (نه offline-first).")
    
    html += card("الگوی قابل الهام: Last Performance Display", "وقتی کاربر شروع به ثبت ست‌های یک exercise می‌کند، آخرین باری که همان exercise را انجام داده نمایش داده می‌شود. مثلاً: آخرین بار: ۶۰kg به‌صورت ۸. این الگو ساده اما impact بسیار بالایی روی UX تمرین دارد و کاربر را قادر می‌سازد بدون navigate کردن، progression را ببیند.")
    
    html += card("الگوی قابل الهام: Rest Timer + 1RM", "تایمر استراحت خودکار پس از هر ست با قابلیت تنظیم (۶۰/۹۰/۱۲۰/۱۸۰ ثانیه). محاسبه 1RM با فرمول Epley: 1RM = weight به‌صورت (1 + reps / 30). تشخیص خودکار رکوردهای شخصی با جشن (confetti/animation).")
    
    html += h(3, "۴. CodeWithCJ/SparkyFitness")
    html += p("SparkyFitness یک اپلیکیشن جامع فیتنس با پشتیبانی از تغذیه، تمرین، آب، خواب، Fasting، خلق، اندازه‌گیری بدن، اهداف، Check-in‌ها و Achievements است. ویژگی‌های منحصر به فرد شامل Family Profiles (چند کاربره)، سیستم Achievements گسترده، و Charts بلندمدت است. این مخزن منبع خوبی برای طراحی سیستم Gamification و ماتریس ویژگی‌های جامع محسوب می‌شود.")
    
    html += h(3, "جمع‌بندی مقایسه‌ای")
    html += table_from_data(
        ["مخزن", "لایسنس", "Offline", "الگوی کلیدی", "بلوغ"],
        [
            ["wger", "AGPL-3.0", "خیر", "Base+Translation, Progression", "بالا (۱۳ سال)"],
            ["LifeOS (Princeu3)", "MIT", "بله", "Unified Timeline, Idempotency", "پایین (Phase 2)"],
            ["lifeos (egebese)", "MIT", "خیر", "Last Performance, Rest Timer", "متوسط"],
            ["SparkyFitness", "MIT", "خیر", "Achievements, Family Profiles", "متوسط"],
        ]
    )
    
    return html


def sec03_license():
    html = '<div class="chapter-header"><div class="section-tag">سند ۰۳</div>'
    html += '<div class="section-title">بررسی لایسنس</div><div class="divider"></div></div>\n'
    
    html += h(3, "لایسنس مخازن Open Source")
    html += p("بررسی لایسنس چهار مخزن Open Source نشان می‌دهد که wger تحت لایسنس AGPL-3.0-or-later منتشر شده که قوی‌ترین Copyleft license است. این لایسنس استفاده مستقیم از کد در محصول تجاری را ممنوع می‌کند: اگر تغییری در کد ایجاد کنید و روی سرور عمومی اجرا کنید، مجبورید تمام تغییرات را تحت AGPL منتشر کنید. مخازن LifeOS (Princeu3)، lifeos (egebese) و SparkyFitness همگی تحت لایسنس MIT هستند که استفاده تجاری، تغییر، توزیع و حتی sublicense را بدون محدودیت مجاز می‌کنند.")
    
    html += table_from_data(
        ["مخزن", "لایسنس", "استفاده تجاری", "Attribution", "Copyleft"],
        [
            ["wger", "AGPL-3.0", "محدود", "بله", "بله (قوی)"],
            ["LifeOS (Princeu3)", "MIT", "آزاد", "بله (حداقل)", "خیر"],
            ["lifeos (egebese)", "MIT", "آزاد", "بله (حداقل)", "خیر"],
            ["SparkyFitness", "MIT", "آزاد", "بله (حداقل)", "خیر"],
        ]
    )
    
    html += h(3, "قوانین برگاموت")
    rules = [
        "هیچ کدی از wger کپی نمی‌شود (به‌دلیل AGPL). فقط الگوهای طراحی و ایده‌ها قابل استفاده‌اند.",
        "داده‌های تمرینات wger (fixtures) نیز تحت Creative Commons هستند و هر ورودی لایسنس مجزا دارد.",
        "داده غذایی باید از منابع قابل اعتماد با لایسنس مناسب تهیه شود (USDA، منابع آکادمیک ایرانی).",
        "از مخازن MIT-license می‌توان الگوهای معماری و طراحی را مطالعه و پیاده‌سازی مستقل کرد.",
        "تمام dependencyهای نهایی باید از نظر لایسنس بررسی شوند (Stable, Well-maintained, Compatible).",
        "فونت‌ها: از Google Fonts با لایسنس OFL (Open Font License) استفاده می‌شود.",
        "آیکون‌ها: از مجموعه‌هایی با لایسنس مناسب (Apache 2.0 یا MIT) استفاده می‌شود.",
    ]
    html += ul([li(r) for r in rules])
    
    html += h(3, "Dependencyهای پیشنهادی و لایسنس آن‌ها")
    html += table_from_data(
        ["Dependency", "لایسنس", "نوع", "Offline-compatible"],
        [
            ["Flutter", "BSD-3", "Framework", "بله"],
            ["Drift (SQLite)", "MIT", "ORM", "بله"],
            ["sqlite3 (mobile)", "Public Domain", "Database", "بله"],
            ["riverpod", "MIT", "State Mgmt", "بله"],
            ["fl_chart", "BSD-3", "Charts", "بله"],
            ["Vazirmatn (font)", "OFL", "Typography", "بله"],
        ]
    )
    
    return html


def sec04_architecture():
    html = '<div class="chapter-header"><div class="section-tag">سند ۰۴</div>'
    html += '<div class="section-title">معماری محصول</div><div class="divider"></div></div>\n'
    
    html += h(3, "الگوی Clean Architecture")
    html += p("معماری برگاموت بر اساس الگوی Clean Architecture با سه لایه اصلی طراحی شده است. لایه Presentation شامل UI و State Management است. لایه Domain شامل Business Logic، Rule Engine و Entityهای خالص است. لایه Data شامل Repositoryها، Database و Data Sourceها است. این جداسازی باعث می‌شود Rule Engine و محاسبات بدون وابستگی به UI یا Database قابل تست باشند. مهم‌ترین نکته: Rule Engine در Domain Layer قرار می‌گیرد و تمام قوانین Deterministic, Explainable و Testable هستند.")
    
    html += card("لایه Presentation", "شامل Flutter Widgets، Screens، BLoC/Cubit (یا Riverpod Providers) و State Management. این لایه فقط با Domain Layer ارتباط دارد و هیچ‌گونه Business Logic ندارد. تمام UI Logic در این لایه است: Navigation، Animation، Theme Management و Responsive Layout.")
    
    html += card("لایه Domain", "قلب محصول. شامل Entityها (خالص، بدون وابستگی به فریمورک)، Use Caseها، Rule Engine و Interfaceهای Repository. Rule Engine شامل SleepRule, HydrationRule, NutritionRule, WorkoutRule, HabitRule, RecoveryRule, GoalRule و ProgressRule است. تمام Ruleها باید Deterministic, Explainable, Testable و Local باشند.")
    
    html += card("لایه Data", "شامل Implementations واقعی Repositoryها، Database (Drift/SQLite)، Local Storage و Data Sourceها. Repository Pattern به‌عنوان واسط بین Domain و Data استفاده می‌شود. Dependency Injection برای تزریق وابستگی‌ها و تسهیل تست‌پذیری به کار می‌رود.")
    
    html += h(3, "نمودار لایه‌ها")
    html += card("جریان داده", "Presentation (UI + State) من Dangerous Domain (Entities + UseCases + RuleEngine) من Dangerous Data (Repositories + Database + LocalStorage). هر لایه فقط با لایه داخلی‌تر ارتباط دارد و هرگز برعکس. این اصل Inversion of Dependency نامیده می‌شود.")
    
    html += h(3, "مبانی طراحی")
    principles = [
        "Offline-First: تمام Core Features بدون اینترنت کار می‌کنند. داده روی دستگاه ذخیره می‌شود.",
        "Privacy-First: هیچ داده سلامتی به‌صورت اجباری به سرور ارسال نمی‌شود. No mandatory account.",
        "No AI: هوشمندی از طریق Rule Engine، Algorithms، Statistics و Deterministic Logic ساخته می‌شود.",
        "Repository Pattern: abstraction بین Domain و Data. تسهیل تست و جایگزینی Data Source.",
        "Dependency Injection: Riverpod برای تزریق وابستگی‌ها. کد تمیز‌تر و تست‌پذیرتر.",
        "Single Source of Truth: Database محلی تنها منبع حقیقت داده است.",
        "Separation of Concerns: هر لایه مسئولیت مشخصی دارد. تغییر در یک لایه بر لایه دیگر تاثیر نمی‌گذارد.",
    ]
    html += ul([li(pr) for pr in principles])
    
    return html


def sec05_feature_matrix():
    html = '<div class="chapter-header"><div class="section-tag">سند ۰۵</div>'
    html += '<div class="section-title">ماتریس ویژگی‌ها</div><div class="divider"></div></div>\n'
    
    html += p("ماتریس زیر تمام ویژگی‌های برگاموت را بر اساس فاز توسعه (MVP، Phase 2، Phase 3) و مدل قیمت‌گذاری (Free/Premium) طبقه‌بندی می‌کند. این ماتریس به‌عنوان مرجع اصلی محصول در طول توسعه عمل می‌کند و هر ویژگی باید در یکی از خانه‌های زیر جای گیرد.")
    
    html += h(3, "ماتریس فاز و قیمت‌گذاری")
    html += table_from_data(
        ["ویژگی", "MVP", "Phase 2", "Phase 3", "Free/Premium"],
        [
            ["Onboarding شخصی‌سازی‌شده", "بله", "-", "-", "Free"],
            ["صفحه Home با Lifestyle Score", "بله", "-", "-", "Free"],
            ["ردیابی خواب", "بله", "-", "-", "Free"],
            ["ردیابی تغذیه + بانک غذای ایرانی", "بله", "-", "-", "Free"],
            ["ردیابی آب", "بله", "-", "-", "Free"],
            ["ردیابی وزن", "بله", "-", "-", "Free"],
            ["کتابخانه تمرینات فارسی", "بله", "-", "-", "Free"],
            ["Workout Builder", "بله", "-", "-", "Free"],
            ["Rest Timer", "بله", "-", "-", "Free"],
            ["Rule Engine (توصیه‌ها)", "بله", "-", "-", "Free"],
            ["نمودارهای پیشرفت", "بله", "-", "-", "Free"],
            ["Notificationهای محلی", "بله", "-", "-", "Free"],
            ["Dark Mode", "بله", "-", "-", "Free"],
            ["عادت‌ها و Streak", "-", "بله", "-", "Free"],
            ["Achievements و Gamification", "-", "بله", "-", "Free"],
            ["Timeline یکپارچه", "-", "بله", "-", "Free"],
            ["Weekly Review", "-", "بله", "-", "Free"],
            ["نمودارهای پیشرفته", "-", "بله", "-", "Free"],
            ["Meal Templates", "-", "بله", "-", "Premium"],
            ["Progressive Overload خودکار", "-", "بله", "-", "Premium"],
            ["برنامه‌های تمرینی پیشرفته", "-", "-", "بله", "Premium"],
            ["برنامه غذایی پیشرفته", "-", "-", "بله", "Premium"],
            ["گزارش PDF", "-", "-", "بله", "Premium"],
            ["Personal Records", "-", "-", "بله", "Premium"],
        ]
    )
    
    return html


def sec06_database():
    html = '<div class="chapter-header"><div class="section-tag">سند ۰۶</div>'
    html += '<div class="section-title">طراحی دیتابیس (ERD)</div><div class="divider"></div></div>\n'
    
    html += h(3, "موجودیت‌های اصلی")
    html += p("دیتابیس برگاموت شامل ۲۰ موجودیت اصلی است که بر اساس الگوی Local-First با SQLite/Drift طراحی شده‌اند. هر موجودیت دارای شناسه یکتا، فیلدهای timestamp و relationshipهای بهینه‌سازی‌شده با Index مناسب است. تمام داده‌ها روی دستگاه کاربر ذخیره می‌شوند و هیچ وابستگی به Cloud یا Backend برای Core Features وجود ندارد.")
    
    html += table_from_data(
        ["موجودیت", "توضیح", "فیلدهای کلیدی", "رابطه"],
        [
            ["UserProfile", "پروفایل کاربر", "age, gender, height, activityLevel", "1:1"],
            ["Goal", "اهداف کاربر", "type, target, startDate, deadline", "N:1 UserProfile"],
            ["Food", "مواد غذایی", "nameFa, nameEn, category, calories, protein, carbs, fat, fiber", "1:N FoodServing"],
            ["FoodServing", "اندازه سروینگ", "servingSize, unit, gramEquivalent", "N:1 Food"],
            ["Meal", "وعده غذایی", "type (breakfast/lunch/dinner/snack), date", "1:N MealItem"],
            ["MealItem", "آیتم غذایی", "foodId, servingId, quantity", "N:1 Meal, N:1 Food"],
            ["Exercise", "تمرین", "nameFa, nameEn, category, primaryMuscle, equipment, difficulty", "1:N WorkoutExercise"],
            ["Workout", "جلسه تمرین", "date, startTime, endTime, notes, impression", "1:N WorkoutExercise"],
            ["WorkoutExercise", "تمرین در جلسه", "exerciseId, order", "1:N WorkoutSet"],
            ["WorkoutSet", "ست تمرین", "reps, weight, rpe, restSeconds, isCompleted", "N:1 WorkoutExercise"],
            ["SleepEntry", "ثبت خواب", "bedTime, wakeTime, duration, quality, target", "N:1 UserProfile"],
            ["WaterEntry", "ثبت آب", "amount, unit, timestamp", "N:1 UserProfile"],
            ["WeightEntry", "ثبت وزن", "weight, bodyFat, date", "N:1 UserProfile"],
            ["BodyMeasurement", "اندازه بدن", "type (waist/chest/arm/hip/thigh), value, date", "N:1 UserProfile"],
            ["Habit", "عادت", "name, frequency, target", "1:N HabitEntry"],
            ["HabitEntry", "ثبت عادت", "date, completed, notes", "N:1 Habit"],
            ["Achievement", "افتخار", "type, title, descriptionFa, icon, condition", "-"],
            ["ProgressRecord", "رکورد پیشرفت", "type, value, date", "N:1 UserProfile"],
            ["TimelineEvent", "رویداد Timeline", "type, timestamp, title, data (JSON)", "-"],
            ["Settings", "تنظیمات", "notifications, units, theme, language", "1:1 UserProfile"],
        ]
    )
    
    html += h(3, "استراتژی Migration")
    html += p("دیتابیس برگاموت از Drift (SQLite wrapper برای Dart) استفاده می‌کند که سیستم Migration داخلی دارد. هر تغییر Schema در فایل‌های Migration versioned ذخیره می‌شود. استراتژی: ابتدا تمام Schemaها را با دقت طراحی می‌کنیم (این سند)، سپس Implementation با Migration number 1 شروع می‌شود. هر تغییر آتی در Migration جدید اعمال می‌شود. Drift از رویکرد Step-by-step Migration پشتیبانی می‌کند و امکان rollback هم وجود دارد. Indexها برای فیلدهایی که به‌طور مکرر query می‌شوند (مثل date در SleepEntry, WaterEntry, WeightEntry) ایجاد خواهند شد.")
    
    return html


def sec07_rule_engine():
    html = '<div class="chapter-header"><div class="section-tag">سند ۰۷</div>'
    html += '<div class="section-title">معماری Rule Engine</div><div class="divider"></div></div>\n'
    
    html += p("Rule Engine قلب هوشمند برگاموت است. این سیستم بدون هیچ وابستگی به AI یا Cloud، تمام توصیه‌ها و تحلیل‌ها را از طریق قوانین Deterministic و قابل توضیح تولید می‌کند. هر Rule از الگوی Input به‌صورت Condition به‌صورت Action پیروی می‌کند. ورودی‌ها از داده محلی کاربر خوانده می‌شوند، شرط‌ها بررسی می‌شوند و اگر برقرار باشند، Action مناسب اجرا می‌شود.")
    
    html += h(3, "ماژول‌های Rule Engine")
    html += table_from_data(
        ["ماژول", "ورودی", "شرط نمونه", "Action نمونه"],
        [
            ["SleepRule", "SleepEntry امروز", "duration < 6 ساعت", "پیشنهاد تمرین سبک"],
            ["HydrationRule", "WaterEntry امروز", "progress < 50% هدف", "یادآوری آب‌نوشی"],
            ["NutritionRule", "MealItem امروز", "پروتئین < هدف", "پیشنهاد وعده پروتئینی"],
            ["WorkoutRule", "Workout", "streak >= 3", "تشویق + XP bonus"],
            ["HabitRule", "HabitEntry", "streak >= 7 روز", "باز کردن Achievement"],
            ["RecoveryRule", "Sleep + Workout", "خواب کم + تمرین سنگین", "پیشنهاد روز استراحت"],
            ["GoalRule", "Goal + WeightEntry", "روند وزن نامطلوب", "نمایش Progress Review"],
            ["ProgressRule", "WorkoutSet", "progression موفق", "به‌روزرسانی 1RM"],
        ]
    )
    
    html += h(3, "الگوی طراحی Rule")
    html += p("هر Rule از کلاس پایه BaseRule ارث‌بری می‌کند و متدهای evaluate() و execute() را پیاده‌سازی می‌کند. متد evaluate() داده‌های لازم را از Repository می‌خواند، شرط‌ها را بررسی می‌کند و خروجی RuleResult (شامل shouldExecute, priority, message, action) برمی‌گرداند. متد execute() Action مربوطه را انجام می‌دهد (مثلاً ایجاد Notification، آپدیت DailyPlan یا باز کردن Achievement). تمام Ruleها Testable هستند: با mocking داده ورودی، خروجی قابل پیش‌بینی و تایید است.")
    
    html += card("مثال عملی: SleepRule", "IF sleepDuration < minimum THEN recommend recovery workout. اگر کاربر کمتر از حداقل هدف خوابیده باشد (مثلاً ۶ ساعت)، Rule Engine تمرین سبک (Light Movement, Stretching) را برای آن روز پیشنهاد می‌دهد. این Rule همزمان DailyPlan را آپدیت می‌کند و Lifestyle Score را کاهش می‌دهد.")
    
    html += card("مثال عملی: HabitRule", "IF habit streak >= 7 THEN unlock achievement. اگر کاربر یک عادت را ۷ روز متوالی انجام داده باشد، Achievement مربوطه باز می‌شود. این Rule همزمان XP اضافه می‌کند و Progression User را به‌روزرسانی می‌کند.")
    
    return html


def sec08_ia():
    html = '<div class="chapter-header"><div class="section-tag">سند ۰۸</div>'
    html += '<div class="section-title">معماری اطلاعات</div><div class="divider"></div></div>\n'
    
    html += p("Information Architecture برگاموت بر اساس سه اصل طراحی شده است: اول، سلسله‌مراتب اطلاعات بر اساس اهمیت روزانه (Home به‌عنوان مهم‌ترین صفحه). دوم، کاهش Friction برای ثبت داده (هر ثبت باید در کمترین تعداد Tap ممکن انجام شود). سوم، دسترسی سریع به جزئیات از طریق Navigation عمیق حداکثر ۳ سطحی.")
    
    html += h(3, "ساختار ناوبری اصلی")
    html += table_from_data(
        ["تب", "نام", "محتوا", "اولویت"],
        [
            ["تب ۱", "خانه", "Lifestyle Score, Today Focus, Progress Summary", "بالا"],
            ["تب ۲", "Timeline", "Unified Timeline همه رویدادها", "بالا"],
            ["تب ۳", "ثبت سریع", "Quick Add: غذا، آب، تمرین، خواب", "بالا"],
            ["تب ۴", "ورزش", "Workout Builder, Exercise Library, History", "بالا"],
            ["تب ۵", "پروفایل", "Goals, Settings, Progress, Privacy Center", "متوسط"],
        ]
    )
    
    html += h(3, "ساختار صفحات داخلی")
    html += p("از هر تب اصلی، کاربر می‌تواند به صفحات داخلی دسترسی پیدا کند. عمق ناوبری حداکثر ۳ سطح است: تب من Dangerous صفحه لیست من Dangerous صفحه جزئیات. مثلاً: خانه من Dangerous تغذیه من Dangerous جزئیات وعده. یا: ورزش من Dangerous تاریخچه من Dangerous جزئیات جلسه. این ساختار ساده باعث می‌شود کاربر هرگز گم نشود و همواره بداند کجاست.")
    
    html += h(3, "الگوی دسترسی به اطلاعات")
    items = [
        "Home: وضعیت امروز + تمرکز روز + پیشرفت (اطلاعات کلیدی در یک نگاه)",
        "Timeline: تاریخچه یکپارچه همه رویدادها (فعالیت‌های امروز به ترتیب زمان)",
        "Quick Add: ثبت سریع بدون navigate کردن (غذا، آب، تمرین، خواب، عادت)",
        "صفحات تخصصی: جزئیات هر محور (نمودارهای خواب، تاریخچه تغذیه، رکوردهای ورزشی)",
        "پروفایل: اهداف، تنظیمات، Privacy Center، Export/Import",
    ]
    html += ul([li(i) for i in items])
    
    return html


def sec09_userflows():
    html = '<div class="chapter-header"><div class="section-tag">سند ۰۹</div>'
    html += '<div class="section-title">جریان‌های کاربری</div><div class="divider"></div></div>\n'
    
    html += h(3, "۱. جریان Onboarding")
    html += p("Onboarding در ۵ مرحله طراحی شده و نباید حس فرم ثبت‌نام بدهد. مرحله اول: انتخاب اهداف (Multi-select از ۸ گزینه). مرحله دوم: اطلاعات بدنی (سن، جنسیت، قد، وزن، سطح فعالیت، هدف). مرحله سوم: محیط تمرین (خانه، باشگاه، هر دو). مرحله چهارم: ترجیحات غذایی (ایرانی، معمولی، گیاهخواری، پروتئین بالا). مرحله پنجم: زمان‌بندی ترجیحی (صبح، بعدازظهر، عصر، شب). در پایان یک Personal Plan اولیه تولید می‌شود. تمام این منطق Offline است.")
    
    html += h(3, "۲. جریان ثبت غذا")
    html += p("ثبت غذا باید در حداکثر ۳ Tap انجام شود. جریان: انتخاب وعده (صبحانه/ناهار/شام/میان‌وعده) من Dangerous جستجوی غذا (فازی، Local) من Dangerous انتخاب از نتایج من Dangerous تعیین مقدار (سروینگ) من Dangerous تایید. با Meal Template: یک Tap برای ثبت وعده تکراری. جستجو شامل نام فارسی، نام انگلیسی و نام‌های جایگزین است. اگر غذایی پیدا نشود، کاربر می‌تواند غذای سفارشی ایجاد کند.")
    
    html += h(3, "۳. جریان ثبت تمرین")
    html += p("جریان: انتخاب Workout (از Template یا ساخت جدید) من Dangerous شروع تمرین من Dangerous برای هر Exercise: ثبت ست‌ها (reps, weight, RPE) من Dangerous مشاهده Last Performance من Dangerous تایید. Rest Timer به‌صورت خودکار پس از هر ست شروع می‌شود. در پایان جلسه: خلاصه (Volume, Duration, PR Detection) من Dangerous ذخیره. Progressive Overload Rule در پس‌زمینه بررسی می‌شود.")
    
    html += h(3, "۴. جریان ثبت خواب")
    html += p("جریان ساده: تنظیم زمان خواب (bedtime) من Dangerous بیدار شدن (wake time) یا ورود دستی duration من Dangerous کیفیت خواب (rating ۱-۵، اختیاری) من Dangerous تایید. همچنین قابلیت تنظیم Bedtime Reminder و Wake Reminder وجود دارد. Sleep Debt محاسبه و نمایش داده می‌شود.")
    
    html += h(3, "۵. جریان ثبت آب")
    html += p("ساده‌ترین جریان: یک Tap برای افزودن مقدار پیش‌فرض (۲۵۰/۵۰۰/۷۵۰/۱۰۰۰ میلی‌لیتر). صفحه آب شامل: پیشرفت بصری (Bottle filling animation)، درصد هدف، تاریخچه هفتگی و یادآوری. هدف آب بر اساس فرمول محاسبه می‌شود (وزن به‌صورت ۳۵ml + فعالیت).")
    
    return html


def sec10_ux_strategy():
    html = '<div class="chapter-header"><div class="section-tag">سند ۱۰</div>'
    html += '<div class="section-title">استراتژی UX</div><div class="divider"></div></div>\n'
    
    html += h(3, "اصل اول: کمترین Friction")
    html += p("برگاموت نباید کاربر را مجبور کند دائماً داده وارد کند. ثبت غذا: حداکثر ۳ Tap. ثبت آب: ۱ Tap. ثبت تمرین: سریع با پیش‌فرض‌های هوشمند. ثبت خواب: ۲ Tap. کاربر نباید احساس کند دارد در یک Spreadsheet زندگی می‌کند. هر Feature باید Fast, Obvious, Beautiful, Useful و Emotionally Rewarding باشد.")
    
    html += h(3, "اصل دوم: Home در کمتر از ۳ ثانیه")
    html += p("صفحه Home مهم‌ترین صفحه است. کاربر در کمتر از ۳ ثانیه باید بفهمد: امروز چه وضعیتی دارد؟ چه کاری باید انجام دهد؟ چقدر پیشرفت کرده؟ ساختار Home: Lifestyle Score (عدد کلیدی)، Progress Rings (خواب، تغذیه، آب، حرکت، ریکاوری) و Today Focus (تمرکز روزانه با توصیه‌های Rule Engine). Dashboard شلوغ ممنوع است. جزئیات در صفحات داخلی.")
    
    html += h(3, "اصل سوم: حس Premium و اعتماد")
    html += p("برگاموت باید حس Premium, Calm, Modern, Fast, Beautiful و Trustworthy ایجاد کند. الهام مفهومی از Apple Health, Oura, WHOOP و Strava. اما هیچ UI را کپی نمی‌کنیم. Typography فارسی حرفه‌ای با فونت Vazirmatn. رنگ‌ها و spacing منظوم. Micro-interactions با Haptics. Animation روان بدون آسیب به Performance. Design Language منحصر به فرد برگاموت.")
    
    html += h(3, "اصل چهارم: Empty States زنده")
    html += p("هیچ صفحه‌ای نباید dead باشد. هر Empty State شامل: توضیح کوتاه فارسی (مثلاً هنوز خوابت را ثبت نکردی)، CTA واضح (ثبت اولین خواب)، و Illustration یا Icon مناسب. این طراحی باعث می‌شود حتی کاربر جدید احساس سردرگمی نکند.")
    
    html += h(3, "اصل پنجم: Accessibility")
    items = [
        "پشتیبانی از Dynamic Font Size (تنظیم اندازه متن در تنظیمات سیستم)",
        "Contrast کافی برای خوانایی (WCAG AA minimum)",
        "Touch Targets حداقل ۴۸x48pt",
        "پشتیبانی از Screen Readers",
        "حالت Reduced Motion برای کاربران حساس به Animation",
        "Color-independent states (وضعیت‌ها فقط با رنگ منتقل نشوند)",
    ]
    html += ul([li(i) for i in items])
    
    return html


def sec11_design_system():
    html = '<div class="chapter-header"><div class="section-tag">سند ۱۱</div>'
    html += '<div class="section-title">پیشنهاد Design System</div><div class="divider"></div></div>\n'
    
    html += h(3, "پالت رنگ")
    html += p("رنگ‌های برگاموت باید الهام گرفته از nature (تنه درخت برگاموت) باشند: سبز طبیعی ملایم، کرم/بژ گرم و خنثی. این پالت حس Calm, Natural و Premium را منتقل می‌کند. دو تم Light و Dark از ابتدا طراحی می‌شوند.")
    
    html += table_from_data(
        ["نقش", "Light Mode", "Dark Mode", "کاربرد"],
        [
            ["Background", "#FAFAF8", "#0F1117", "پس‌زمینه اصلی"],
            ["Surface", "#FFFFFF", "#1A1B23", "Card و Container"],
            ["Primary", "#2D6A4F", "#52B788", "دکمه‌ها، Link، Accent"],
            ["Text Primary", "#1A1A2E", "#E8E6E3", "متن اصلی"],
            ["Text Secondary", "#6B7280", "#9CA3AF", "متن ثانویه"],
            ["Success", "#10B981", "#34D399", "موفقیت، تکمیل"],
            ["Warning", "#F59E0B", "#FBBF24", "هشدار"],
            ["Error", "#EF4444", "#F87171", "خطا، لغو"],
            ["Accent", "#D4A574", "#D4A574", "برگاموت (تنه درخت)"],
        ]
    )
    
    html += h(3, "Typography")
    html += p("فونت اصلی: Vazirmatn (Google Fonts, OFL License). این فونت برای زبان فارسی بهینه‌سازی شده و وزن‌های ۱۰۰ تا ۹۰۰ را پشتیبانی می‌کند. فونت ثانویه: Inter برای اعداد لاتین و اصطلاحات فنی. سیستم Typography شامل: Hero (۲۴px, Bold)، Section Title (۲۰px, Bold)، Body (۱۶px, Regular)، Caption (۱۴px, Regular) و Label (۱۲px, Medium). Line-height برای متن فارسی: ۱.۸ (بالاتر از انگلیسی به‌دلیل پیچیدگی حروف).")
    
    html += h(3, "Spacing و Radius")
    html += p("سیستم Spacing بر اساس ۴پیکسل: ۴, ۸, ۱۲, ۱۶, ۲۴, ۳۲, ۴۸, ۶۴. Card Radius: ۱۶px. Button Radius: ۱۲px. Input Radius: ۱۰px. Chip Radius: ۲۰px (pill shape). Shadow: ظریف و natural (0 2px 8px rgba(0,0,0,0.08) در Light Mode).")
    
    html += h(3, "کامپوننت‌های پایه")
    components = [
        "Buttons: Primary (پر رنگ), Secondary (بیرون‌خطی), Ghost (بدون پس‌زمینه), Danger (قرمز)",
        "Cards: Surface Card, Interactive Card, Stat Card, Progress Card",
        "Inputs: Text Input, Search Input, Slider, Toggle, Checkbox, Radio, Segmented Control",
        "Navigation: Bottom Navigation (۵ تب), Tab Bar, Back Button, Drawer",
        "Feedback: Toast, Snackbar, Dialog, Bottom Sheet, Empty State, Error State, Loading",
        "Data Display: Progress Ring, Progress Bar, Chart Container, Stat Block, Timeline Item",
    ]
    html += ul([li(c) for c in components])
    
    return html


def sec12_screen_list():
    html = '<div class="chapter-header"><div class="section-tag">سند ۱۲</div>'
    html += '<div class="section-title">فهرست صفحات</div><div class="divider"></div></div>\n'
    
    html += p("فهرست کامل صفحات برگاموت در MVP شامل ۳۰ صفحه اصلی و ۲۰+ صفحه فرعی است. هر صفحه با شناسه یکتا، نوع (Screen/Dialog/Sheet)، سطح دسترسی و اولویت فاز مشخص شده است.")
    
    html += table_from_data(
        ["شناسه", "نام صفحه", "نوع", "فاز"],
        [
            ["S01", "Splash", "Screen", "MVP"],
            ["S02", "Onboarding (5 Steps)", "Screen", "MVP"],
            ["S03", "Home", "Screen", "MVP"],
            ["S04", "Timeline", "Screen", "Phase 2"],
            ["S05", "Quick Add", "Sheet", "MVP"],
            ["S06", "Sleep Tracker", "Screen", "MVP"],
            ["S07", "Sleep History", "Screen", "MVP"],
            ["S08", "Nutrition (Daily)", "Screen", "MVP"],
            ["S09", "Food Search", "Screen", "MVP"],
            ["S10", "Food Detail", "Screen", "MVP"],
            ["S11", "Meal Builder", "Sheet", "MVP"],
            ["S12", "Hydration", "Screen", "MVP"],
            ["S13", "Weight Tracker", "Screen", "MVP"],
            ["S14", "Body Measurements", "Screen", "MVP"],
            ["S15", "Exercise Library", "Screen", "MVP"],
            ["S16", "Exercise Detail", "Screen", "MVP"],
            ["S17", "Workout Builder", "Screen", "MVP"],
            ["S18", "Active Workout", "Screen", "MVP"],
            ["S19", "Workout History", "Screen", "MVP"],
            ["S20", "Workout Summary", "Screen", "MVP"],
            ["S21", "Goals", "Screen", "MVP"],
            ["S22", "Habits", "Screen", "Phase 2"],
            ["S23", "Achievements", "Screen", "Phase 2"],
            ["S24", "Weekly Review", "Screen", "Phase 2"],
            ["S25", "Charts & Progress", "Screen", "MVP"],
            ["S26", "Profile", "Screen", "MVP"],
            ["S27", "Settings", "Screen", "MVP"],
            ["S28", "Privacy Center", "Screen", "MVP"],
            ["S29", "Export/Import", "Screen", "MVP"],
            ["S30", "Search (Global)", "Screen", "MVP"],
        ]
    )
    
    return html


def sec13_mvp():
    html = '<div class="chapter-header"><div class="section-tag">سند ۱۳</div>'
    html += '<div class="section-title">محدوده MVP</div><div class="divider"></div></div>\n'
    
    html += p("MVP برگاموت شامل تمام ویژگی‌های Core است که بدون اینترنت کاملاً قابل استفاده باشند. هدف: ساخت یک محصول کامل و قابل عرضه که ارزش اصلی برگاموت (Offline, Privacy, Persian, Beautiful) را به نمایش بگذارد. MVP باید آنقدر خوب باشد که کاربر بگوید: این اپ واقعاً زندگی سالم من را مدیریت می‌کند.")
    
    html += h(3, "ویژگی‌های MVP")
    mvp_features = [
        "Onboarding ۵ مرحله‌ای (اهداف، اطلاعات بدنی، محیط تمرین، ترجیحات غذایی، زمان‌بندی)",
        "صفحه Home با Lifestyle Score و Today Focus",
        "ردیابی خواب (Sleep start, Wake time, Duration, Quality, Target, History, Charts)",
        "ردیابی تغذیه (Breakfast, Lunch, Dinner, Snack, Calories, Macros, Daily Target)",
        "بانک غذایی ایرانی (حداقل ۲۰۰ غذا با اطلاعات تغذیه‌ای)",
        "ردیابی آب (هدف روزانه، Quick Add، Progress بصری، History)",
        "ردیابی وزن (Weight, Charts 7D/30D/90D/1Y)",
        "کتابخانه تمرینات فارسی (حداقل ۱۰۰ تمرین)",
        "Workout Builder (Exercise, Sets, Reps, Weight, Rest)",
        "Rest Timer (شمارش معکوس، Vibration, Skip, Extend)",
        "Rule Engine (Sleep, Hydration, Nutrition, Workout, Recovery, Goal Rules)",
        "نمودارهای پیشرفت (fl_chart، 7D/30D/90D)",
        "Notificationهای محلی (خواب، آب، تمرین، وعده غذایی)",
        "Dark Mode و Light Mode",
        "RTL Native و فارسی کامل",
        "Privacy Center (Export, Import, Backup, Delete)",
        "Local Database (SQLite/Drift)",
    ]
    html += ul([li(f) for f in mvp_features])
    
    html += h(3, "خارج از محدوده MVP")
    non_mvp = [
        "Cloud Sync و Account (Phase 2)",
        "Habits و Streak (Phase 2)",
        "Achievements و Gamification کامل (Phase 2)",
        "Timeline یکپارچه (Phase 2)",
        "Weekly Review (Phase 2)",
        "Wearable Integration (Future)",
        "AI Features (هرگز در Core)",
    ]
    html += ul([li(f) for f in non_mvp])
    
    return html


def sec14_roadmap():
    html = '<div class="chapter-header"><div class="section-tag">سند ۱۴</div>'
    html += '<div class="section-title">نقشه راه توسعه</div><div class="divider"></div></div>\n'
    
    html += table_from_data(
        ["فاز", "مدت", "محدوده", "خروجی"],
        [
            ["Phase 0: Research", "۲ هفته", "تحلیل بازار، OS repos، لایسنس، معماری", "۱۵ سند تحلیلی (این فایل)"],
            ["Phase 1: Foundation", "۴ هفته", "Design System، Database، Rule Engine، Navigation", "اسکلت اپ با Dark/Light Mode"],
            ["Phase 2: Core MVP", "۸ هفته", "تمام ویژگی‌های MVP", "اپلیکیشن قابل انتشار"],
            ["Phase 3: Polish", "۲ هفته", "Animation، Micro-interactions، Performance", "نسخه ۱.۰ آماده انتشار"],
            ["Phase 4: Enhancement", "۶ هفته", "Habits, Achievements, Timeline, Weekly Review", "بروزرسانی ۱.۵"],
            ["Phase 5: Advanced", "۶ هفته", "برنامه‌های پیشرفته، گزارش PDF، ارتقای Rule Engine", "بروزرسانی ۲.۰"],
            ["Phase 6: Growth", "۴ هفته", "Wearable Integration، ارتقای بانک غذایی", "بروزرسانی ۲.۵"],
        ]
    )
    
    html += h(3, "جزئیات فازهای کلیدی")
    
    html += card("Phase 0: Research (۲ هفته)", "تولید ۱۵ سند تحلیلی شامل: تحلیل رقابتی، تحلیل OS repos، بررسی لایسنس، معماری محصول، ماتریس ویژگی‌ها، طراحی دیتابیس، معماری Rule Engine، معماری اطلاعات، جریان‌های کاربری، استراتژی UX، Design System، فهرست صفحات، محدوده MVP، نقشه راه و استک فنی. این اسناد پایه تصمیم‌گیری‌های بعدی هستند.")
    
    html += card("Phase 1: Foundation (۴ هفته)", "پیاده‌سازی Design System (Colors, Typography, Spacing, Components). پیاده‌سازی Database با Drift و تمام Entityها. پیاده‌سازی Rule Engine پایه. پیاده‌سازی Navigation و Bottom Tabs. ایجاد Onboarding Flow. در پایان این فاز، اپ باید قابل اجرا باشد با Navigation کامل و Data Layer آماده.")
    
    html += card("Phase 2: Core MVP (۸ هفته)", "پیاده‌سازی تمام صفحات و ویژگی‌های MVP: Home، Sleep، Nutrition، Hydration، Weight، Exercise Library، Workout Builder، Active Workout، Charts، Notifications، Privacy Center. بانک غذایی ایرانی (حداقل ۲۰۰ آیتم). کتابخانه تمرینات (حداقل ۱۰۰ آیتم). در پایان، اپ باید قابل انتشار در مارکت‌های ایرانی باشد.")
    
    return html


def sec15_tech_stack():
    html = '<div class="chapter-header"><div class="section-tag">سند ۱۵</div>'
    html += '<div class="section-title">پیشنهاد استک فنی</div><div class="divider"></div></div>\n'
    
    html += p("استک فنی برگاموت بر اساس سه معیار انتخاب شده: پایداری و بلوغ (Stable و Well-maintained)، سازگاری با Offline-first، و کارایی (Lightweight و Performant). هر dependency قبل از انتخاب نهایی از نظر لایسنس، جامعه، مستندات و تاریخچه نگهداری بررسی می‌شود.")
    
    html += h(3, "استک فنی نهایی")
    html += table_from_data(
        ["لایه", "تکنولوژی", "دلیل انتخاب", "لایسنس"],
        [
            ["Framework", "Flutter 3.x", "Cross-platform, Offline-first, High Performance, RTL Native", "BSD-3"],
            ["Language", "Dart 3.x", "Type-safe, Null-safe, Compiled, Async", "BSD-3"],
            ["Database", "SQLite (via Drift)", "Local, Reliable, Mature, SQL-based", "MIT"],
            ["ORM", "Drift", "Type-safe SQLite wrapper for Dart, Migrations", "MIT"],
            ["State Mgmt", "Riverpod 2.x", "Compile-safe, Testable, Scalable", "MIT"],
            ["Charts", "fl_chart", "Flutter-native, Customizable, Offline", "BSD-3"],
            ["Navigation", "GoRouter", "Declarative, Deep Linking", "MIT"],
            ["Notifications", "flutter_local_notifications", "Local-only, Scheduling", "BSD-3"],
            ["Haptics", "custom_haptic_feedback", "Micro-interactions", "MIT"],
            ["Font", "Vazirmatn", "Persian-optimized, Variable weights", "OFL"],
            ["Icons", "custom_icons (SVG)", "Brand-consistent, Lightweight", "Custom"],
            ["Testing", "flutter_test + mockito", "Unit + Widget + Integration", "BSD-3/MIT"],
            ["Export", "json_serializable + pdf", "JSON/CSV/PDF export", "BSD-3"],
        ]
    )
    
    html += h(3, "دلایل انتخاب Flutter")
    reasons = [
        "Cross-platform: یک کد برای iOS و Android (و بعداً Web/Desktop)",
        "Offline-first: SQLite به‌صورت Native روی هر دو پلتفرم کار می‌کند",
        "RTL Native: پشتیبانی داخلی از راست به چپ بدون هک",
        "Performance: Compilation به ARM code، ۶۰fps روان",
        "UI Customization: کنترل کامل بر هر پیکسل، Design System سفارشی",
        "Community: بزرگ‌ترین جامعه Open Source mobile development",
        "Hot Reload: سرعت توسعه بسیار بالا",
        "Maturity: پروژه‌های production مثل Google Pay, BMW, Alibaba از Flutter استفاده می‌کنند",
    ]
    html += ul([li(r) for r in reasons])
    
    html += h(3, "دلایل انتخاب Drift به‌جای سایر گزینه‌ها")
    html += p("Drift (قبلاً Moor) یک type-safe wrapper برای SQLite در Dart است. در مقایسه با Hive (NoSQL، بدون SQL Query)، Isar (جوان‌تر، Plugin stability)، و ObjectBox (C-native ولی پیچیده‌تر)، Drift بهترین تعادل بین Type Safety، SQL Power و Maturity را ارائه می‌دهد. پشتیبانی از Migration، Relations، Transactions و Indexes آن کامل است. جامعه فعال و مستندات عالی دارد.")
    
    html += h(3, "فرمول‌های سلامت (Health Calculations)")
    html += table_from_data(
        ["فرمول", "منبع", "توضیح"],
        [
            ["BMI", "WHO", "kg/m به توان 2"],
            ["BMR", "Mifflin-St.Jeor", "10*weight + 6.25*height - 5*age + s (s=+5 male, -161 female)"],
            ["TDEE", "BMR * PAL", "PAL: 1.2 (Sedentary) تا 1.9 (Very Active)"],
            ["Calorie Target", "TDEE +/- deficit/surplus", " deficit 500 کالری = 0.5kg/هفته"],
            ["Macro Target", "IOM Guidelines", "Protein: 1.6-2.2g/kg, Fat: 20-35%, Carbs: remainder"],
            ["Water Target", "Institute of Medicine", "weight*35ml + activity adjustment"],
            ["1RM", "Epley", "weight * (1 + reps/30)"],
            ["Workout Volume", "Standard", "sum(sets * reps * weight)"],
        ]
    )
    
    return html


def generate_ending():
    return '''<div class="ending">
        <div class="ending-content">
            <div class="ending-title">برگاموت</div>
            <div class="ending-tagline">هر روز، سالم‌تر از دیروز.</div>
            <div class="ending-privacy">Your health. Your data. Your device.</div>
            <div class="ending-line"></div>
            <div class="ending-note">این اسناد پایه تصمیم‌گیری‌های محصول و فنی هستند.</div>
            <div class="ending-note">پس از تایید، فاز Implementation آغاز خواهد شد.</div>
        </div>
    </div>'''


def generate_css():
    return '''
@import url('https://fonts.googleapis.com/css2?family=Vazirmatn:wght@100;200;300;400;500;600;700;800;900&display=swap');

@page {
    size: 210mm 297mm;
    margin: 0;
}

:root {
    --c-bg: #FAFAF8;
    --c-surface: #FFFFFF;
    --c-primary: #2D6A4F;
    --c-primary-light: #52B788;
    --c-text: #1A1A2E;
    --c-text-secondary: #6B7280;
    --c-accent: #D4A574;
    --c-border: #E5E7EB;
    --c-tag-bg: #E8F5E9;
    --c-tag-text: #2D6A4F;
    --c-cover-bg: #0F1117;
    --c-cover-text: #E8E6E3;
    --c-cover-accent: #52B788;
    --font-fa: 'Vazirmatn', sans-serif;
    --font-en: 'Vazirmatn', sans-serif;
}

html, body {
    margin: 0;
    padding: 0;
    width: 210mm;
    background: var(--c-bg);
    color: var(--c-text);
    font-family: var(--font-fa);
    font-size: 11pt;
    line-height: 1.8;
    direction: rtl;
    -webkit-font-smoothing: antialiased;
}

@media screen {
    html {
        height: auto;
        display: flex;
        justify-content: center;
        background: #e5e5e5;
    }
    body {
        margin: 20px auto;
        box-shadow: 0 4px 24px rgba(0,0,0,0.12);
        border-radius: 4px;
    }
}

/* Cover */
.cover {
    width: 210mm;
    height: 297mm;
    box-sizing: border-box;
    break-after: page;
    overflow: hidden;
    background: var(--c-cover-bg);
    position: relative;
    display: flex;
    align-items: center;
    justify-content: center;
}
.cover-decoration {
    position: absolute;
    border-radius: 50%;
    opacity: 0.08;
}
.circle-1 {
    width: 400px;
    height: 400px;
    background: var(--c-cover-accent);
    top: -100px;
    left: -100px;
}
.circle-2 {
    width: 300px;
    height: 300px;
    background: var(--c-accent);
    bottom: -80px;
    right: -80px;
}
.cover-content {
    text-align: center;
    z-index: 1;
    padding: 60px;
}
.cover-badge {
    font-size: 10pt;
    font-weight: 500;
    letter-spacing: 4px;
    color: var(--c-cover-accent);
    margin-bottom: 24px;
    text-transform: uppercase;
}
.cover-title {
    font-size: 52pt;
    font-weight: 900;
    color: var(--c-cover-text);
    margin-bottom: 12px;
    letter-spacing: -1px;
}
.cover-subtitle {
    font-size: 16pt;
    font-weight: 300;
    color: var(--c-accent);
    margin-bottom: 32px;
}
.cover-line {
    width: 60px;
    height: 3px;
    background: var(--c-cover-accent);
    margin: 0 auto 32px;
    border-radius: 2px;
}
.cover-desc {
    font-size: 12pt;
    color: #9CA3AF;
    margin-bottom: 24px;
    line-height: 1.8;
}
.cover-meta {
    font-size: 10pt;
    color: #6B7280;
}
.cover-meta .sep {
    margin: 0 12px;
    color: #374151;
}
.cover-bottom-label {
    position: absolute;
    bottom: 40px;
    left: 50%;
    transform: translateX(-50%);
    font-size: 9pt;
    color: #4B5563;
    letter-spacing: 2px;
}

/* Main Content */
.main-content {
    padding: 50px 60px 40px 60px;
}

/* Chapter Headers */
.chapter-header {
    break-after: avoid;
    break-inside: avoid;
    margin-top: 28px;
    margin-bottom: 16px;
}
.section-tag {
    font-size: 9pt;
    font-weight: 600;
    color: var(--c-primary);
    letter-spacing: 2px;
    margin-bottom: 6px;
}
.section-title {
    font-size: 22pt;
    font-weight: 800;
    color: var(--c-text);
    margin-bottom: 8px;
    line-height: 1.4;
}
.divider {
    width: 40px;
    height: 3px;
    background: var(--c-primary);
    border-radius: 2px;
}

/* Headings */
h3 {
    font-size: 14pt;
    font-weight: 700;
    color: var(--c-text);
    margin-top: 20px;
    margin-bottom: 8px;
}

/* Paragraphs */
p {
    margin-bottom: 10px;
    text-align: justify;
    color: #374151;
    line-height: 1.9;
}

/* Lists */
ul {
    margin-bottom: 12px;
    padding-right: 24px;
}
li {
    margin-bottom: 5px;
    color: #374151;
    line-height: 1.7;
}

/* Tables */
.table-wrapper {
    width: 100%;
    margin: 12px 0 16px 0;
    overflow-x: auto;
    break-inside: avoid;
}
table {
    width: 100%;
    border-collapse: collapse;
    font-size: 9.5pt;
}
thead th {
    background: var(--c-primary);
    color: #FFFFFF;
    padding: 8px 10px;
    text-align: right;
    font-weight: 600;
    font-size: 9pt;
    white-space: nowrap;
}
thead th:first-child {
    border-radius: 0 6px 0 0;
}
thead th:last-child {
    border-radius: 6px 0 0 0;
}
tbody td {
    padding: 7px 10px;
    border-bottom: 1px solid var(--c-border);
    text-align: right;
    color: #374151;
    vertical-align: top;
}
tbody tr:nth-child(even) {
    background: #F9FAFB;
}

/* Cards */
.card {
    background: var(--c-surface);
    border: 1px solid var(--c-border);
    border-radius: 10px;
    padding: 16px 18px;
    margin-bottom: 10px;
    break-inside: avoid;
}
.card-title {
    font-size: 11pt;
    font-weight: 700;
    color: var(--c-primary);
    margin-bottom: 6px;
}
.card-body {
    font-size: 10pt;
    color: #4B5563;
    line-height: 1.8;
}

/* TOC */
.toc-item {
    display: flex;
    align-items: center;
    padding: 10px 14px;
    border-bottom: 1px solid var(--c-border);
    break-inside: avoid;
}
.toc-item:last-child {
    border-bottom: none;
}
.toc-num {
    font-size: 10pt;
    font-weight: 700;
    color: var(--c-primary);
    min-width: 32px;
}
.toc-fa {
    font-size: 11pt;
    font-weight: 600;
    color: var(--c-text);
    flex: 1;
}
.toc-en {
    font-size: 9pt;
    color: var(--c-text-secondary);
    direction: ltr;
    text-align: left;
}

/* Section Divider */
.section-divider {
    height: 1px;
    background: var(--c-border);
    margin: 24px 0;
}

/* Tags */
.tag {
    display: inline-block;
    background: var(--c-tag-bg);
    color: var(--c-tag-text);
    padding: 3px 10px;
    border-radius: 12px;
    font-size: 8.5pt;
    font-weight: 600;
}

/* Ending */
.ending {
    width: 210mm;
    height: 297mm;
    box-sizing: border-box;
    break-before: page;
    overflow: hidden;
    background: var(--c-cover-bg);
    display: flex;
    align-items: center;
    justify-content: center;
}
.ending-content {
    text-align: center;
}
.ending-title {
    font-size: 36pt;
    font-weight: 900;
    color: var(--c-cover-text);
    margin-bottom: 12px;
}
.ending-tagline {
    font-size: 14pt;
    font-weight: 300;
    color: var(--c-accent);
    margin-bottom: 20px;
}
.ending-privacy {
    font-size: 10pt;
    color: #6B7280;
    font-style: italic;
    margin-bottom: 32px;
    direction: ltr;
}
.ending-line {
    width: 40px;
    height: 2px;
    background: var(--c-cover-accent);
    margin: 0 auto 24px;
    border-radius: 2px;
}
.ending-note {
    font-size: 10pt;
    color: #9CA3AF;
    margin-bottom: 6px;
}

strong {
    font-weight: 700;
    color: var(--c-text);
}
'''


def main():
    html_content = f'''<!DOCTYPE html>
<html lang="fa" dir="rtl">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>برگاموت — تحلیل جامع پیش از پیاده‌سازی</title>
    <style>{generate_css()}</style>
</head>
<body>
    {generate_cover()}
    <div class="main-content">
        {generate_toc()}
        {section_divider()}
        {sec01_competitive()}
        {section_divider()}
        {sec02_opensource()}
        {section_divider()}
        {sec03_license()}
        {section_divider()}
        {sec04_architecture()}
        {section_divider()}
        {sec05_feature_matrix()}
        {section_divider()}
        {sec06_database()}
        {section_divider()}
        {sec07_rule_engine()}
        {section_divider()}
        {sec08_ia()}
        {section_divider()}
        {sec09_userflows()}
        {section_divider()}
        {sec10_ux_strategy()}
        {section_divider()}
        {sec11_design_system()}
        {section_divider()}
        {sec12_screen_list()}
        {section_divider()}
        {sec13_mvp()}
        {section_divider()}
        {sec14_roadmap()}
        {section_divider()}
        {sec15_tech_stack()}
    </div>
    {generate_ending()}
</body>
</html>'''
    
    with open(OUTPUT_HTML, 'w', encoding='utf-8') as f:
        f.write(html_content)
    
    print(f"HTML generated: {OUTPUT_HTML}")
    print(f"Size: {os.path.getsize(OUTPUT_HTML) / 1024:.1f} KB")


if __name__ == '__main__':
    main()
