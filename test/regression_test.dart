import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:prepcivic_app/services/question_text.dart';
import 'package:prepcivic_app/services/session_repository.dart';
import 'package:prepcivic_app/auth_wrapper.dart';
import 'package:prepcivic_app/screens/quiz/result_screen.dart';
import 'package:prepcivic_app/firebase_options.dart';
import 'package:prepcivic_app/services/database_helper.dart';
import 'package:prepcivic_app/services/account_deletion_service.dart';
import 'package:prepcivic_app/services/question_csv.dart';
import 'package:prepcivic_app/services/practice_repository.dart';
import 'package:prepcivic_app/services/purchase_service.dart';
import 'package:prepcivic_app/services/billing_client.dart';
import 'package:prepcivic_app/services/database_service.dart';
import 'package:prepcivic_app/models/question_model.dart';
import 'package:prepcivic_app/screens/practice/practice_quiz_screen.dart';
import 'package:prepcivic_app/screens/premium/subscription_screen.dart';

class MemorySessions extends SessionRepository {
  final SessionIdentity? initial;
  final bool guest;
  final String access;
  final changes = StreamController<SessionIdentity?>();
  int tierCalls = 0;
  bool fail = false;
  Completer<String>? pending;
  MemorySessions(this.initial, {this.guest = false, this.access = 'free'});
  @override
  Stream<SessionIdentity?> get identities async* {
    yield initial;
    yield* changes.stream;
  }

  @override
  Future<bool> isGuest() async => guest;
  @override
  Future<String> tier() async {
    tierCalls++;
    if (fail) throw StateError('Store connection failed');
    return pending == null ? access : await pending!.future;
  }
}

AuthWrapper sessionScreen(MemorySessions sessions) => AuthWrapper(
  sessions: sessions,
  mainBuilder: (_, tier) => Scaffold(body: Text('Access: $tier')),
  onboardingBuilder: (_) => const Scaffold(body: Text('Onboarding')),
  loginBuilder: (_) => const Scaffold(body: Text('Verify login')),
);

class FileTranslations extends AssetLoader {
  const FileTranslations();
  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async =>
      jsonDecode(File('$path/${locale.languageCode}.json').readAsStringSync())
          as Map<String, dynamic>;
}

class MemoryPractice extends PracticeRepository {
  final String access;
  int loads = 0;
  int saves = 0;
  Set<String> excluded = {};
  MemoryPractice(this.access);
  @override
  Future<String> language() async => 'bn';
  @override
  Future<String> tier() async => access;
  @override
  Future<List<Map<String, dynamic>>> questions(
    String category,
    String tier,
    Set<String> excludeHashes,
  ) async {
    loads++;
    excluded = Set.of(excludeHashes);
    return List.generate(
      10,
      (i) => {
        'hash_id': '$loads-$i',
        'text_fr': 'Question $loads-${i + 1} ?',
        'text_bn': 'Question $loads-${i + 1} ? (প্রশ্ন ${i + 1})',
        'options': [
          {
            'id': 1,
            'text_fr': 'Correct',
            'text_bn': 'Correct (সঠিক)',
            'is_correct': 1,
          },
          {
            'id': 2,
            'text_fr': 'Incorrect',
            'text_bn': 'Incorrect (ভুল)',
            'is_correct': 0,
          },
        ],
      },
    );
  }

  @override
  Future<void> saveAnswer(String hash, bool correct) async {
    saves++;
  }
}

Package plan(String id) => Package(
  id,
  PackageType.custom,
  const StoreProduct(
    'ios.product',
    'Description',
    'Plan',
    30,
    '29,99 €',
    'EUR',
  ),
  const PresentedOfferingContext('default', null, null),
);

CustomerInfo customer([String? entitlement]) {
  final active = <String, EntitlementInfo>{
    if (entitlement != null)
      entitlement: EntitlementInfo(
        entitlement,
        true,
        false,
        '2026-01-01',
        '2026-01-01',
        'ios.product',
        true,
      ),
  };
  return CustomerInfo(
    EntitlementInfos(active, active),
    {},
    [],
    [],
    [],
    '2026-01-01',
    'test',
    {},
    '2026-01-01',
  );
}

class MemoryBilling extends BillingClient {
  Offerings data;
  int purchases = 0;
  int mirrors = 0;
  String? mirroredTier;
  CustomerInfo info = customer('access_basic');
  bool cancel = false;
  bool billingUnavailable = false;
  Completer<Offerings>? pending;
  MemoryBilling(this.data);
  @override
  String? get accountId => null; // Guest access must work too.
  @override
  Future<void> identify() async {}
  @override
  Future<Offerings> offerings() async {
    if (billingUnavailable)
      throw PlatformException(code: '3', message: 'Billing unavailable');
    return pending?.future ?? Future.value(data);
  }

  @override
  Future<CustomerInfo> purchase(Package package) async {
    purchases++;
    if (cancel) throw PlatformException(code: '1', message: 'Cancelled');
    return info;
  }

  @override
  Future<CustomerInfo> restore() async => info;
  @override
  Future<void> mirror(CustomerInfo info, String? accountId) async {
    mirrors++;
    mirroredTier = PurchaseService.tier(info);
  }
}

Offerings offering(List<Package> packages) {
  final current = Offering('default', 'Test', {}, packages);
  return Offerings({'default': current}, current: current);
}

Future<void> show(
  WidgetTester tester,
  Widget child, {
  Size size = const Size(430, 932),
  double scale = 1,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    EasyLocalization(
      supportedLocales: const [Locale('fr')],
      path: 'assets/translations',
      assetLoader: const FileTranslations(),
      startLocale: const Locale('fr'),
      child: Builder(
        builder: (context) => MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(scale)),
            child: child!,
          ),
          locale: context.locale,
          supportedLocales: context.supportedLocales,
          localizationsDelegates: context.localizationDelegates,
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                child: const Text('Open'),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => child),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
}

Future<void> completePractice(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.tap(find.text(i == 0 ? 'Incorrect' : 'Correct'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(i == 9 ? 'Terminer' : 'Suivant'));
    await tester.pumpAndSettle();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    GoogleFonts.config.allowRuntimeFetching = false;
    await EasyLocalization.ensureInitialized();
  });

  test(
    'legacy bilingual cells preserve nested translation and omit French',
    () {
      expect(
        QuestionText.translation('35 heures (৩৫ ঘণ্টা)', '35 heures'),
        '৩৫ ঘণ্টা',
      );
      expect(
        QuestionText.translation('SAMU ? (জরুরি (SAMU) নম্বর?)', 'SAMU ?'),
        'জরুরি (SAMU) নম্বর?',
      );
      expect(
        QuestionText.translation('French [English (detail)]', 'French'),
        'English (detail)',
      );
      expect(QuestionText.translation('French', 'French'), '');
      expect(QuestionText.translation('বাংলা', 'French'), 'বাংলা');
      expect(
        QuestionText.translation(
          'Circulation (aller et venir)',
          'Circulation (aller et venir)',
        ),
        '',
      );
      expect(QuestionText.translation('1815 (1815)', '1815'), '');
      expect(QuestionText.sourceKey('1815 (1815)'), '1815');
      expect(
        QuestionText.translation(
          "Prud'hommes ? (Conseil (শ্রম আদালত) সম্পর্কিত)",
          "Prud'hommes ?",
        ),
        'Conseil (শ্রম আদালত) সম্পর্কিত',
      );
      expect(
        QuestionText.sourceKey('Impôt (écoles mais pas armée) ? (কর?)'),
        QuestionText.sourceKey('Impôt (écoles mais pas armée) ?'),
      );
    },
  );

  test('CSV handles quoted commas, escaped quotes and multiline cells', () {
    final rows = QuestionCsv.parse(
      'type,text\r\nquestion,"Un ""mot"", oui"\r\nanswer,"deux\nlignes"',
    );
    expect(rows[1][1], 'Un "mot", oui');
    expect(rows[2][1], 'deux\nlignes');
  });

  test('omitted translation blocks do not shift subsequent questions', () {
    final index = QuestionCsv.translationIndex(
      'type,text\nquestion,Premier ? (প্রথম?)\nanswer,Oui (হ্যাঁ)\nquestion,Troisième ? (তৃতীয়?)\nanswer,Non (না)',
    );
    expect(index[QuestionText.sourceKey('Deuxième ?')], isNull);
    expect(
      index[QuestionText.sourceKey('Troisième ?')]!['question'],
      contains('তৃতীয়'),
    );
  });

  test('Pashto history parses all 223 question blocks after CSV repair', () {
    final rows = QuestionCsv.parse(
      File('assets/ps/q_history.csv').readAsStringSync(),
    );
    expect(rows.length, 893);
    expect(rows.where((row) => row[0] == 'question').length, 223);
  });

  test(
    'highest active entitlement determines access; unrelated IDs grant none',
    () {
      expect(PurchaseService.tierFromEntitlements(['access_basic']), '2_years');
      expect(
        PurchaseService.tierFromEntitlements(['access_basic', 'access_pro']),
        '10_years',
      );
      expect(
        PurchaseService.tierFromEntitlements(['access_max', 'access_pro']),
        'nationality',
      );
      expect(PurchaseService.tierFromEntitlements(['unknown']), 'free');
    },
  );

  test(
    'mock pool filters duplicate text and invalid correct-answer indices',
    () {
      QuestionModel q(String id, String text, int index) => QuestionModel(
        id: id,
        questionText: text,
        options: ['A', 'B'],
        correctAnswerIndex: index,
      );
      final result = DatabaseService.uniqueQuestions([
        q('a', 'Une question ?', 1),
        q('b', ' Une   question ? ', 1),
        q('c', 'Invalid', 5),
        q('d', '', 0),
        q('e', 'Autre ?', 0),
      ]);
      expect(result.map((q) => q.id), ['a', 'e']);
    },
  );

  test('all six localization files contain completion and billing keys', () {
    for (final lang in ['fr', 'en', 'bn', 'ar', 'ur', 'ps']) {
      final contents = File(
        'assets/translations/$lang.json',
      ).readAsStringSync();
      for (final key in [
        'free_practice_completed',
        'practice_new_premium',
        'packages_unavailable',
        'restore_success',
        'purchase_access_pending',
      ]) {
        expect(contents, contains('"$key"'), reason: '$lang: $key');
      }
    }
  });

  test('local databases isolate guests and distinct account IDs', () {
    final names = [
      null,
      'guest',
      'a/b',
      'a_b',
      'alice',
      'bob',
    ].map(DatabaseHelper.filenameFor).toSet();
    expect(names.length, 6);
    expect(
      names.every((name) => !name.contains('/') && !name.contains('\\')),
      isTrue,
    );
    expect(names.contains('prep_civic_v10.db'), isFalse);
    expect(DatabaseHelper.filenameFor('x' * 128).length, lessThan(100));
  });

  test('failed reauthentication cannot delete data or identity', () async {
    final steps = <String>[];
    await expectLater(
      AccountDeletionService.run(
        authenticate: () async {
          steps.add('auth');
          throw StateError('bad password');
        },
        removeData: () async {
          steps.add('data');
        },
        removeIdentity: () async {
          steps.add('identity');
        },
      ),
      throwsStateError,
    );
    expect(steps, ['auth']);
  });

  test(
    'failed data cleanup leaves the authenticated identity for retry',
    () async {
      final steps = <String>[];
      await expectLater(
        AccountDeletionService.run(
          authenticate: () async {
            steps.add('auth');
          },
          removeData: () async {
            steps.add('data');
            throw StateError('network');
          },
          removeIdentity: () async {
            steps.add('identity');
          },
        ),
        throwsStateError,
      );
      expect(steps, ['auth', 'data']);
    },
  );

  test('Dart Android Firebase configuration matches the native client', () {
    final native = jsonDecode(
      File('android/app/google-services.json').readAsStringSync(),
    );
    final client = (native['client'] as List).singleWhere(
      (c) =>
          c['client_info']['android_client_info']['package_name'] ==
          'com.torcdigital.prepcivique',
    );
    expect(
      DefaultFirebaseOptions.android.projectId,
      native['project_info']['project_id'],
    );
    expect(
      DefaultFirebaseOptions.android.messagingSenderId,
      native['project_info']['project_number'],
    );
    expect(
      DefaultFirebaseOptions.android.appId,
      client['client_info']['mobilesdk_app_id'],
    );
    expect(
      DefaultFirebaseOptions.android.apiKey,
      client['api_key'][0]['current_key'],
    );
    expect(
      DefaultFirebaseOptions.ios.projectId,
      DefaultFirebaseOptions.android.projectId,
    );
    expect(
      DefaultFirebaseOptions.ios.iosBundleId,
      'com.torcdigital.prepcivique',
    );
  });

  for (final access in ['free', '2_years', '10_years', 'nationality']) {
    testWidgets('returning verified account restores exact $access access', (
      tester,
    ) async {
      final sessions = MemorySessions(
        const SessionIdentity('user', emailVerified: true),
        access: access,
      );
      addTearDown(sessions.changes.close);
      await show(tester, sessionScreen(sessions));
      expect(find.text('Access: $access'), findsOneWidget);
      expect(sessions.tierCalls, 1);
    });
  }

  testWidgets('returning paid guest keeps RevenueCat access', (tester) async {
    final sessions = MemorySessions(null, guest: true, access: 'nationality');
    addTearDown(sessions.changes.close);
    await show(tester, sessionScreen(sessions));
    expect(find.text('Access: nationality'), findsOneWidget);
  });

  testWidgets('new visitor enters onboarding without querying purchases', (
    tester,
  ) async {
    final sessions = MemorySessions(null);
    addTearDown(sessions.changes.close);
    await show(tester, sessionScreen(sessions));
    expect(find.text('Onboarding'), findsOneWidget);
    expect(sessions.tierCalls, 0);
  });

  testWidgets(
    'unverified account cannot bypass the email login gate on restart',
    (tester) async {
      final sessions = MemorySessions(
        const SessionIdentity('user', emailVerified: false),
      );
      addTearDown(sessions.changes.close);
      await show(tester, sessionScreen(sessions));
      expect(find.text('Verify login'), findsOneWidget);
      expect(sessions.tierCalls, 0);
    },
  );

  testWidgets('late purchase lookup cannot restore a signed-out account', (
    tester,
  ) async {
    final sessions = MemorySessions(
      const SessionIdentity('user', emailVerified: true),
    )..pending = Completer<String>();
    addTearDown(sessions.changes.close);
    await tester.pumpWidget(MaterialApp(home: sessionScreen(sessions)));
    await tester.pump();
    sessions.changes.add(null);
    await tester.pumpAndSettle();
    expect(find.text('Onboarding'), findsOneWidget);
    sessions.pending!.complete('nationality');
    await tester.pumpAndSettle();
    expect(find.text('Onboarding'), findsOneWidget);
    expect(find.text('Access: nationality'), findsNothing);
  });

  testWidgets('failed session restoration can retry', (tester) async {
    final sessions = MemorySessions(
      const SessionIdentity('user', emailVerified: true),
    )..fail = true;
    addTearDown(sessions.changes.close);
    await show(tester, sessionScreen(sessions));
    expect(find.text('Réessayer'), findsOneWidget);
    sessions.fail = false;
    await tester.tap(find.text('Réessayer'));
    await tester.pumpAndSettle();
    expect(find.text('Access: free'), findsOneWidget);
  });

  for (final restart in [true, false]) {
    testWidgets(
      'result ${restart ? 'restart' : 'dashboard'} dismisses only the result route',
      (tester) async {
        var restarts = 0;
        var dashboards = 0;
        await show(
          tester,
          ResultScreen(
            score: 8,
            totalQuestions: 10,
            onRestart: () => restarts++,
            onDashboard: () => dashboards++,
          ),
        );
        final button = find.byType(restart ? ElevatedButton : OutlinedButton);
        await tester.ensureVisible(button);
        await tester.tap(button);
        await tester.pumpAndSettle();
        expect(restarts, restart ? 1 : 0);
        expect(dashboards, restart ? 0 : 1);
        expect(find.text('Open'), findsOneWidget);
      },
    );
  }
  testWidgets(
    'small screen with enlarged text keeps purchase and restore reachable',
    (tester) async {
      final billing = MemoryBilling(offering([plan('pkg_2_4_year')]));
      await show(
        tester,
        SubscriptionScreen(billing: billing),
        size: const Size(320, 568),
        scale: 1.8,
      );
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.text('Restaurer les achats'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.text("S'abonner maintenant"));
      await tester.tap(find.text("S'abonner maintenant"));
      await tester.pumpAndSettle();
      expect(billing.purchases, 1);
      expect(find.text('Open'), findsOneWidget);
    },
  );

  testWidgets(
    'review starts at question one, retains answers and cannot rescore',
    (tester) async {
      final repository = MemoryPractice('free');
      await show(
        tester,
        PracticeQuizScreen(
          category: 'Test',
          userPackage: 'free',
          repository: repository,
        ),
      );
      await completePractice(tester);
      expect(find.text('Votre Score: 9 / 10'), findsOneWidget);
      await tester.tap(find.text('Revoir les Réponses'));
      await tester.pumpAndSettle();
      expect(find.text('Question 1/10'), findsOneWidget);
      expect(find.byIcon(Icons.cancel), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      await tester.tap(find.text('Correct'));
      await tester.pumpAndSettle();
      expect(repository.saves, 10);
      expect(repository.loads, 1);
    },
  );

  testWidgets(
    'paid continuation resets the score and excludes prior questions',
    (tester) async {
      final repository = MemoryPractice('2_years');
      await show(
        tester,
        PracticeQuizScreen(
          category: 'Test',
          userPackage: 'free',
          repository: repository,
        ),
      );
      await completePractice(tester);
      await tester.tap(find.text('Plus de Pratique'));
      await tester.pumpAndSettle();
      expect(repository.loads, 2);
      expect(repository.excluded.length, 10);
      expect(find.text('Question 1/10'), findsOneWidget);
      expect(find.text('Question 2-1 ?'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsNothing);
    },
  );

  testWidgets(
    'unavailable device billing gives store guidance instead of a connection error',
    (tester) async {
      final billing = MemoryBilling(const Offerings({}))
        ..billingUnavailable = true;
      await show(tester, SubscriptionScreen(billing: billing));
      expect(
        find.textContaining('Vérifiez votre connexion à la boutique'),
        findsOneWidget,
      );
      expect(
        tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
        isNull,
      );
      billing.billingUnavailable = false;
      billing.data = offering([plan('pkg_2_4_year')]);
      await tester.tap(find.text('Réessayer'));
      await tester.pumpAndSettle();
      expect(find.text('29,99 €'), findsOneWidget);
    },
  );

  testWidgets(
    'empty offering disables payment; retry recovers and uses store price',
    (tester) async {
      final billing = MemoryBilling(const Offerings({}));
      await show(tester, SubscriptionScreen(billing: billing));
      expect(
        tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
        isNull,
      );
      expect(find.text('€30'), findsNothing);
      billing.data = offering([plan('pkg_2_4_year')]);
      await tester.tap(find.text('Réessayer'));
      await tester.pumpAndSettle();
      expect(find.text('29,99 €'), findsOneWidget);
      expect(
        tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
        isNotNull,
      );
      await tester.ensureVisible(find.text("S'abonner maintenant"));
      await tester.tap(find.text("S'abonner maintenant"));
      await tester.pumpAndSettle();
      expect(billing.purchases, 1);
      expect(billing.mirroredTier, '2_years');
      expect(find.text('Open'), findsOneWidget);
    },
  );

  testWidgets(
    'unknown package IDs stay unavailable instead of pretending to load',
    (tester) async {
      await show(
        tester,
        SubscriptionScreen(
          billing: MemoryBilling(offering([plan('wrong_id')])),
        ),
      );
      expect(
        tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
        isNull,
      );
      expect(find.text('Réessayer'), findsOneWidget);
    },
  );

  testWidgets(
    'a purchase without the expected entitlement explains pending access',
    (tester) async {
      final billing = MemoryBilling(offering([plan('pkg_2_4_year')]))
        ..info = customer();
      await show(tester, SubscriptionScreen(billing: billing));
      await tester.ensureVisible(find.text("S'abonner maintenant"));
      await tester.tap(find.text("S'abonner maintenant"));
      await tester.pumpAndSettle();
      expect(billing.mirrors, 0);
      expect(find.textContaining('Ne payez pas à nouveau'), findsOneWidget);
      expect(find.byType(SubscriptionScreen), findsOneWidget);
    },
  );

  testWidgets('restore mirrors the highest tier and unlocks guest access', (
    tester,
  ) async {
    final billing = MemoryBilling(const Offerings({}))
      ..info = customer('access_max');
    await show(tester, SubscriptionScreen(billing: billing));
    await tester.ensureVisible(find.text('Restaurer les achats'));
    await tester.tap(find.text('Restaurer les achats'));
    await tester.pumpAndSettle();
    expect(billing.mirroredTier, 'nationality');
    expect(find.text('Open'), findsOneWidget);
  });

  testWidgets(
    'cancelled purchases stay on the paywall without an error alert',
    (tester) async {
      final billing = MemoryBilling(offering([plan('pkg_2_4_year')]))
        ..cancel = true;
      await show(tester, SubscriptionScreen(billing: billing));
      await tester.ensureVisible(find.text("S'abonner maintenant"));
      await tester.tap(find.text("S'abonner maintenant"));
      await tester.pumpAndSettle();
      expect(find.byType(SubscriptionScreen), findsOneWidget);
      expect(find.byType(SnackBar), findsNothing);
      expect(billing.mirrors, 0);
    },
  );
}
