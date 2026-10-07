import 'package:shared_preferences/shared_preferences.dart';
import 'database_helper.dart';
import 'purchase_service.dart';

abstract class PracticeRepository {
  const PracticeRepository();
  Future<String> language();
  Future<String> tier();
  Future<List<Map<String, dynamic>>> questions(
    String category,
    String tier,
    Set<String> excludeHashes,
  );
  Future<void> saveAnswer(String hash, bool correct);
}

class LocalPracticeRepository extends PracticeRepository {
  const LocalPracticeRepository();
  @override
  Future<String> language() async =>
      (await SharedPreferences.getInstance()).getString('selectedLanguage') ??
      'fr';
  @override
  Future<String> tier() => PurchaseService.currentTier();
  @override
  Future<List<Map<String, dynamic>>> questions(
    String category,
    String tier,
    Set<String> excludeHashes,
  ) => tier == 'free'
      ? DatabaseHelper.instance.getFixedTenQuestions(category)
      : DatabaseHelper.instance.getSmartTenQuestions(
          category,
          excludeHashes: excludeHashes,
        );
  @override
  Future<void> saveAnswer(String hash, bool correct) =>
      DatabaseHelper.instance.updateQuestionProgress(hash, correct);
}
