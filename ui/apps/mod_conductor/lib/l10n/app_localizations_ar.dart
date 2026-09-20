// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'منظّم التعديلات';

  @override
  String get changeAppearance => 'تغيير المظهر';

  @override
  String get quit => 'إنهاء';

  @override
  String get workspaces => 'مساحات العمل';

  @override
  String get preferences => 'التفضيلات';

  @override
  String openRequests(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'فتح $count طلب',
      many: 'فتح $count طلبًا',
      few: 'فتح $count طلبات',
      two: 'فتح طلبين',
      one: 'فتح طلب واحد',
      zero: 'فتح الطلبات',
    );
    return '$_temp0';
  }

  @override
  String get connected => 'متصل';

  @override
  String get connecting => 'الاتصال قيد التنفيذ';

  @override
  String get notConnected => 'غير متصل';

  @override
  String get connectionError => 'خطأ في الاتصال';

  @override
  String get connection => 'الاتصال';

  @override
  String get connectionFailed => 'فشل الاتصال';

  @override
  String get cannotOpenFromOtherApps => 'يتعذر الفتح من تطبيقات أخرى';

  @override
  String get openFromThisWindow =>
      'افتح مساحات العمل والأرشيفات من هذه النافذة.';

  @override
  String get display => 'العرض';

  @override
  String get scope => 'النطاق';

  @override
  String get application => 'التطبيق';

  @override
  String get currentWorkspace => 'مساحة العمل الحالية';

  @override
  String get appearance => 'المظهر';

  @override
  String get textSize => 'حجم النص';

  @override
  String get contrast => 'التباين';

  @override
  String get useApplicationSettings => 'استخدام إعدادات التطبيق';

  @override
  String get systemAppearance => 'استخدام مظهر النظام';

  @override
  String get light => 'فاتح';

  @override
  String get dark => 'داكن';

  @override
  String get systemContrast => 'استخدام تباين النظام';

  @override
  String get standardContrast => 'قياسي';

  @override
  String get highContrast => 'تباين عالٍ';

  @override
  String get apply => 'تطبيق';

  @override
  String get cancel => 'إلغاء';

  @override
  String get activePreferences => 'التفضيلات النشطة';

  @override
  String get close => 'إغلاق';

  @override
  String preferencesSaved(DateTime time) {
    final intl.DateFormat timeDateFormat = intl.DateFormat.Hm(localeName);
    final String timeString = timeDateFormat.format(time);

    return 'حُفظت التفضيلات في $timeString';
  }

  @override
  String get settingsLoadFailed => 'تعذر تحميل الإعدادات.';

  @override
  String get settingsSaveFailed => 'تعذر حفظ الإعدادات.';

  @override
  String get workspaceSettingsUnavailable => 'افتح مساحة عمل لتغيير إعداداتها.';

  @override
  String textScalePercent(int value) {
    return '$value٪';
  }

  @override
  String get closeInspector => 'إغلاق لوحة التفاصيل';

  @override
  String get name => 'الاسم';

  @override
  String get enterName => 'أدخل اسمًا.';

  @override
  String get closeFilter => 'إغلاق عامل التصفية';

  @override
  String get noItems => 'لا توجد عناصر.';

  @override
  String get noMatches => 'لا توجد نتائج مطابقة في العناصر المحملة.';

  @override
  String get expanded => 'موسّع';

  @override
  String get collapsed => 'مطوي';

  @override
  String get cancelLoad => 'إلغاء التحميل';

  @override
  String get loadMore => 'تحميل المزيد';

  @override
  String get retry => 'إعادة المحاولة';

  @override
  String refreshCollection(String title) {
    return 'تحديث $title';
  }

  @override
  String collapseItem(String label) {
    return 'طي $label';
  }

  @override
  String expandItem(String label) {
    return 'توسيع $label';
  }

  @override
  String get statusAvailable => 'متاح';

  @override
  String get statusUnavailable => 'غير متاح';

  @override
  String get statusUnsupported => 'غير مدعوم';

  @override
  String get statusInformation => 'معلومات';

  @override
  String get statusError => 'خطأ';
}
