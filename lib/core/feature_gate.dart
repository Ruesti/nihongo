import '../models/lesson.dart';
import 'api_key_service.dart';
import 'purchases_service.dart';

class FeatureGate {
  static const _freeLessonMax = 15;
  static const _freeTravelCountries = ['jp', 'es', 'fr'];
  static const _kaiwaMinLesson = 25;
  static const _kaiwaMinCards = 250;
  static const _phoneMinLesson = 40;
  static const _phoneMinConversations = 10;

  static Future<bool> canAccessLesson(Lesson lesson,
      {String lang = 'ja'}) async {
    if (lesson.id <= _freeLessonMax) return true;
    if (await PurchasesService.isUnlocked(PurchasesService.entitlementAll)) {
      return true;
    }
    return PurchasesService.isUnlocked(
        PurchasesService.langEntitlement(lang));
  }

  static Future<bool> canUseTravelCountry(String countryCode) async {
    if (_freeTravelCountries.contains(countryCode.toLowerCase())) {
      return true;
    }
    return PurchasesService.isUnlocked(PurchasesService.entitlementTravel);
  }

  static Future<bool> canUseKiConversation({String lang = 'ja'}) async {
    final hasLang = await PurchasesService.isUnlocked(
        PurchasesService.langEntitlement(lang));
    final hasAll = await PurchasesService.isUnlocked(
        PurchasesService.entitlementAll);
    if (!hasLang && !hasAll) return false;
    return ApiKeyService.hasKey();
  }

  static bool isKaiwaUnlocked(int completedLessons, int totalCards) =>
      completedLessons >= _kaiwaMinLesson &&
      totalCards >= _kaiwaMinCards;

  static bool isPhoneUnlocked(
          int completedLessons, int conversationSessions) =>
      completedLessons >= _phoneMinLesson &&
      conversationSessions >= _phoneMinConversations;

  static Future<bool> canUseKanjiGames({String lang = 'ja'}) async {
    // Kanji-Spiele N5 immer frei, N4 braucht Kauf
    return true;
  }

  static Future<bool> isN4KanjiUnlocked({String lang = 'ja'}) async {
    if (await PurchasesService.isUnlocked(PurchasesService.entitlementAll)) {
      return true;
    }
    return PurchasesService.isUnlocked(
        PurchasesService.langEntitlement(lang));
  }
}
