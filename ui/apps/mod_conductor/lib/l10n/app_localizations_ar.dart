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

  @override
  String get credentialNexusMods => 'نيكسس مودز';

  @override
  String get credentialDisconnectTitle => 'قطع الاتصال بنيكسس مودز؟';

  @override
  String get credentialDisconnect => 'قطع الاتصال';

  @override
  String get credentialDisconnectPause =>
      'ستتوقف تنزيلات نيكسس مؤقتًا. لن تُحذف الملفات المحلية.';

  @override
  String get credentialDisconnectRemovesSaved =>
      'ستُحذف بيانات تسجيل الدخول المحفوظة.';

  @override
  String get credentialSessionOnlyTitle => 'استخدام هذه الجلسة فقط؟';

  @override
  String get credentialSessionOnly => 'هذه الجلسة فقط';

  @override
  String get credentialSessionOnlyLost =>
      'ستُفقد بيانات تسجيل الدخول الجديدة عند إغلاق مود كوندكتور.';

  @override
  String get credentialSessionOnlyKeepsSaved =>
      'لن تُحذف بيانات تسجيل الدخول المحفوظة حاليًا.';

  @override
  String get credentialClearSessionTitle => 'مسح تسجيل دخول الجلسة؟';

  @override
  String get credentialRemoveSavedTitle => 'إزالة تسجيل الدخول المحفوظ؟';

  @override
  String get credentialClearSignIn => 'مسح تسجيل الدخول';

  @override
  String get credentialRemoveSignIn => 'إزالة تسجيل الدخول';

  @override
  String get credentialClearsSessionToo =>
      'سيمسح مود كوندكتور أيضًا بيانات تسجيل الدخول لهذه الجلسة.';

  @override
  String get credentialStorageDetails => 'تفاصيل تخزين تسجيل الدخول';

  @override
  String get credentialStorageLocked => 'حلقة مفاتيح النظام مقفلة';

  @override
  String get credentialStorageUnavailable => 'التخزين الآمن غير متاح';

  @override
  String get credentialStorageDenied => 'رُفض الوصول إلى التخزين الآمن';

  @override
  String get credentialStorageTimedOut =>
      'لم يستجب التخزين الآمن في الوقت المحدد';

  @override
  String get credentialStorageCancelled => 'أُلغيت عملية التخزين';

  @override
  String get credentialStorageTooLarge =>
      'تتجاوز بيانات تسجيل الدخول حد التخزين';

  @override
  String get credentialStorageFailed => 'فشلت عملية التخزين';

  @override
  String get credentialWaitingSignIn => 'في انتظار تسجيل الدخول';

  @override
  String credentialConnectedAs(String name) {
    return 'متصل باسم $name';
  }

  @override
  String get credentialPremium => 'مميز';

  @override
  String get credentialNotConnected => 'غير متصل';

  @override
  String get credentialNotSignedIn => 'لم يُسجل الدخول';

  @override
  String get credentialNotSaved => 'لم تُحفظ بيانات تسجيل الدخول';

  @override
  String get credentialCancelSignIn => 'إلغاء تسجيل الدخول';

  @override
  String get credentialCheckAccount => 'فحص الحساب';

  @override
  String get credentialSignInAgain => 'تسجيل الدخول مجددًا';

  @override
  String get credentialConnect => 'اتصال';

  @override
  String get credentialSignIn => 'تسجيل الدخول';

  @override
  String get credentialPersonalApiKey => 'أدخل مفتاح API الشخصي';

  @override
  String get credentialShowPersonalApiKey => 'إظهار مفتاح API الشخصي';

  @override
  String get credentialHidePersonalApiKey => 'إخفاء مفتاح API الشخصي';

  @override
  String get credentialSubmitPersonalApiKey => 'الاتصال بمفتاح API';

  @override
  String get credentialStorageCheckFailed => 'تعذر فحص تخزين تسجيل الدخول';

  @override
  String get credentialCheckEngine => 'افحص اتصال المحرك وحاول مجددًا.';

  @override
  String get credentialSavedNotRemoved => 'لم يُزل تسجيل الدخول المحفوظ';

  @override
  String get credentialUnlockKeyring => 'افتح حلقة مفاتيح النظام وحاول مجددًا.';

  @override
  String get credentialSaved => 'بيانات تسجيل الدخول محفوظة على هذا الحاسوب.';

  @override
  String get credentialNoneSaved => 'لا توجد بيانات تسجيل دخول محفوظة.';

  @override
  String get credentialCannotCheckSaved =>
      'يتعذر فحص بيانات تسجيل الدخول المحفوظة.';

  @override
  String get credentialNewSignIns => 'عمليات تسجيل الدخول الجديدة';

  @override
  String get credentialSaveOnComputer => 'حفظ على هذا الحاسوب';

  @override
  String get credentialCheckStorage => 'فحص التخزين';

  @override
  String get credentialRetryRemoval => 'إعادة محاولة الإزالة';

  @override
  String get nexusLinks => 'روابط تنزيل نيكسس';

  @override
  String get nexusOpenLinks =>
      'افتح روابط تنزيل مدير التعديلات باستخدام مود كوندكتور.';

  @override
  String get nexusRemoveWindowsTitle => 'إزالة مود كوندكتور من إعدادات ويندوز؟';

  @override
  String get nexusRemoveTitle => 'إزالة إعداد روابط نيكسس؟';

  @override
  String get nexusRemoveWindows => 'إزالة من إعدادات ويندوز';

  @override
  String get nexusRemove => 'إزالة إعداد الروابط';

  @override
  String get nexusChooseOtherDefault =>
      'اختر تطبيقًا افتراضيًا آخر في إعدادات ويندوز.';

  @override
  String get nexusRestoreDefault =>
      'لن يُستعاد التطبيق الافتراضي السابق إلا إذا ظل مود كوندكتور هو التطبيق الافتراضي.';

  @override
  String get nexusAvailableWindows => 'متاح في إعدادات ويندوز';

  @override
  String get nexusAvailable => 'إعداد الروابط متاح';

  @override
  String get nexusNotAddedWindows => 'غير مضاف إلى إعدادات ويندوز';

  @override
  String get nexusOff => 'إعداد الروابط متوقف';

  @override
  String get nexusCannotCheck => 'يتعذر فحص إعداد الروابط';

  @override
  String nexusDefaultApp(String app) {
    return 'التطبيق الافتراضي: $app';
  }

  @override
  String get nexusModConductor => 'مود كوندكتور';

  @override
  String get nexusAnotherApp => 'تطبيق آخر';

  @override
  String get nexusNotSet => 'غير محدد';

  @override
  String get nexusCannotCheckDefault => 'يتعذر الفحص';

  @override
  String get nexusChooseDefaultWindows =>
      'اختر التطبيق الافتراضي في إعدادات ويندوز.';

  @override
  String get nexusDefaultChanged =>
      'تغير التطبيق الافتراضي. ستُبقي إزالة مود كوندكتور اختيارك الحالي.';

  @override
  String get nexusCheckFailed =>
      'تعذر فحص إعداد روابط نيكسس. افحص اتصال المحرك.';

  @override
  String get nexusAddWindows => 'إضافة إلى إعدادات ويندوز';

  @override
  String get nexusUseModConductor => 'استخدام مود كوندكتور';

  @override
  String get nexusOpenWindows => 'فتح إعدادات ويندوز';

  @override
  String get nexusCheckDefault => 'فحص التطبيق الافتراضي';
}
