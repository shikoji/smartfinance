// SmartFinance Pro
// Substitua o arquivo lib/main.dart por este código.
// Antes de rodar, execute: flutter pub add firebase_core firebase_auth cloud_firestore

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final repository = FirebaseRepository();
  final database = AppDatabase(users: {});
  final controller = AppController(repository, database);

  await controller.tryRestoreSession();

  runApp(SmartFinanceApp(controller: controller));
}

/* ============================================================
   CORES E CONSTANTES
============================================================ */

const Color kGreen = Color(0xff16a34a);
const Color kDark = Color(0xff0f172a);
const Color kBg = Color(0xfff4f7fb);
const Color kBlue = Color(0xff2563eb);
const Color kRed = Color(0xffdc2626);
const Color kOrange = Color(0xfff97316);
const Color kPurple = Color(0xff7c3aed);
const Color kGray = Color(0xff64748b);

const List<String> defaultCategories = [
  'Moradia',
  'Comida',
  'Transporte',
  'Estudos',
  'Lazer',
  'Compras',
  'Saúde',
  'Assinaturas',
  'Trabalho',
  'Caixinhas',
  'Outros',
];

const Map<String, double> defaultBudgets = {
  'Moradia': 450,
  'Comida': 450,
  'Transporte': 220,
  'Estudos': 160,
  'Lazer': 180,
  'Compras': 220,
  'Saúde': 130,
  'Assinaturas': 90,
  'Trabalho': 0,
  'Caixinhas': 350,
  'Outros': 180,
};

/* ============================================================
   HELPERS
============================================================ */

String generateId() {
  return '${DateTime.now().microsecondsSinceEpoch}_${Random().nextInt(99999)}';
}

double moneyFromText(String text) {
  return double.tryParse(text.trim().replaceAll('.', '').replaceAll(',', '.')) ??
      double.tryParse(text.trim().replaceAll(',', '.')) ??
      0;
}

String money(double value) {
  final negative = value < 0;
  final absValue = value.abs();
  final parts = absValue.toStringAsFixed(2).split('.');
  final whole = parts[0];
  final cents = parts[1];
  final buffer = StringBuffer();
  for (int i = 0; i < whole.length; i++) {
    final pos = whole.length - i;
    buffer.write(whole[i]);
    if (pos > 1 && pos % 3 == 1) buffer.write('.');
  }
  return '${negative ? '-' : ''}R\$ ${buffer.toString()},$cents';
}

String percent(double value) => '${(value * 100).toStringAsFixed(1)}%';

String monthKey(DateTime date) {
  return '${date.year}-${date.month.toString().padLeft(2, '0')}';
}

DateTime monthStart(DateTime date) => DateTime(date.year, date.month, 1);

DateTime nextMonth(DateTime date) => DateTime(date.year, date.month + 1, 1);

DateTime previousMonth(DateTime date) => DateTime(date.year, date.month - 1, 1);

bool sameMonth(DateTime a, DateTime b) => a.year == b.year && a.month == b.month;

String dateLabel(DateTime date) {
  return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}

String monthLabel(DateTime date) {
  const months = [
    'Janeiro',
    'Fevereiro',
    'Março',
    'Abril',
    'Maio',
    'Junho',
    'Julho',
    'Agosto',
    'Setembro',
    'Outubro',
    'Novembro',
    'Dezembro',
  ];
  return '${months[date.month - 1]} de ${date.year}';
}

String shortMonthLabel(DateTime date) {
  const months = [
    'Jan',
    'Fev',
    'Mar',
    'Abr',
    'Mai',
    'Jun',
    'Jul',
    'Ago',
    'Set',
    'Out',
    'Nov',
    'Dez',
  ];
  return '${months[date.month - 1]}/${date.year.toString().substring(2)}';
}

int daysInMonth(DateTime date) => DateTime(date.year, date.month + 1, 0).day;

DateTime safeDayInMonth(DateTime month, int day) {
  final maxDay = daysInMonth(month);
  return DateTime(month.year, month.month, day.clamp(1, maxDay).toInt());
}

Color categoryColor(String category) {
  switch (category) {
    case 'Moradia':
      return const Color(0xff7c3aed);
    case 'Comida':
      return const Color(0xffef4444);
    case 'Transporte':
      return const Color(0xff0ea5e9);
    case 'Estudos':
      return const Color(0xff2563eb);
    case 'Lazer':
      return const Color(0xfff59e0b);
    case 'Compras':
      return const Color(0xffec4899);
    case 'Saúde':
      return const Color(0xff14b8a6);
    case 'Assinaturas':
      return const Color(0xff8b5cf6);
    case 'Trabalho':
      return const Color(0xff22c55e);
    case 'Caixinhas':
      return const Color(0xff16a34a);
    default:
      return const Color(0xff64748b);
  }
}

IconData categoryIcon(String category) {
  switch (category) {
    case 'Moradia':
      return Icons.home;
    case 'Comida':
      return Icons.restaurant;
    case 'Transporte':
      return Icons.directions_bus;
    case 'Estudos':
      return Icons.school;
    case 'Lazer':
      return Icons.sports_esports;
    case 'Compras':
      return Icons.shopping_bag;
    case 'Saúde':
      return Icons.health_and_safety;
    case 'Assinaturas':
      return Icons.subscriptions;
    case 'Trabalho':
      return Icons.work;
    case 'Caixinhas':
      return Icons.savings;
    default:
      return Icons.category;
  }
}

IconData goalIcon(String key) {
  switch (key) {
    case 'computer':
      return Icons.computer;
    case 'flight':
      return Icons.flight_takeoff;
    case 'school':
      return Icons.school;
    case 'phone':
      return Icons.phone_android;
    case 'home':
      return Icons.home;
    case 'car':
      return Icons.directions_car;
    case 'health':
      return Icons.health_and_safety;
    case 'game':
      return Icons.sports_esports;
    case 'gift':
      return Icons.card_giftcard;
    default:
      return Icons.savings;
  }
}

String variationText(double current, double previous) {
  if (previous == 0 && current == 0) return 'sem variação';
  if (previous == 0) return 'novo neste mês';
  final diff = (current - previous) / previous;
  final arrow = diff >= 0 ? '↑' : '↓';
  return '$arrow ${diff.abs() * 100 > 999 ? '999+' : (diff.abs() * 100).toStringAsFixed(1)}% vs mês anterior';
}

/* ============================================================
   MODELOS
============================================================ */

class AppDatabase {
  AppDatabase({required this.users});

  final Map<String, FinanceUser> users;

  Map<String, dynamic> toJson() => {
        'users': users.map((key, value) => MapEntry(key, value.toJson())),
      };

  factory AppDatabase.fromJson(Map<String, dynamic> json) {
    final rawUsers = Map<String, dynamic>.from(json['users'] ?? {});
    return AppDatabase(
      users: rawUsers.map(
        (key, value) => MapEntry(
          key,
          FinanceUser.fromJson(Map<String, dynamic>.from(value)),
        ),
      ),
    );
  }
}

class FinanceUser {
  FinanceUser({
    required this.email,
    required this.password,
    required this.name,
    required this.initialBalance,
    required this.monthlyLimit,
    required this.categories,
    required this.defaultCategoryBudgets,
    required this.transactions,
    required this.goals,
    required this.recurringEntries,
    required this.monthBudgets,
    required this.notesByMonth,
  });

  String email;
  String password;
  String name;
  double initialBalance;
  double monthlyLimit;
  List<String> categories;
  Map<String, double> defaultCategoryBudgets;
  List<MoneyTransaction> transactions;
  List<Goal> goals;
  List<RecurringEntry> recurringEntries;
  Map<String, Map<String, double>> monthBudgets;
  Map<String, String> notesByMonth;

  Map<String, dynamic> toJson() => {
        'email': email,
        'name': name,
        'initialBalance': initialBalance,
        'monthlyLimit': monthlyLimit,
        'categories': categories,
        'defaultCategoryBudgets': defaultCategoryBudgets,
        'transactions': transactions.map((e) => e.toJson()).toList(),
        'goals': goals.map((e) => e.toJson()).toList(),
        'recurringEntries': recurringEntries.map((e) => e.toJson()).toList(),
        'monthBudgets': monthBudgets.map(
          (key, value) => MapEntry(key, value.map((k, v) => MapEntry(k, v))),
        ),
        'notesByMonth': notesByMonth,
      };

  factory FinanceUser.fromJson(Map<String, dynamic> json) {
    final rawMonthBudgets = Map<String, dynamic>.from(json['monthBudgets'] ?? {});
    return FinanceUser(
      email: json['email'] ?? '',
      password: json['password'] ?? '',
      name: json['name'] ?? 'Usuário',
      initialBalance: (json['initialBalance'] ?? 0).toDouble(),
      monthlyLimit: (json['monthlyLimit'] ?? 0).toDouble(),
      categories: List<String>.from(json['categories'] ?? defaultCategories),
      defaultCategoryBudgets: Map<String, dynamic>.from(
        json['defaultCategoryBudgets'] ?? defaultBudgets,
      ).map((key, value) => MapEntry(key, (value ?? 0).toDouble())),
      transactions: List<Map<String, dynamic>>.from(json['transactions'] ?? [])
          .map(MoneyTransaction.fromJson)
          .toList(),
      goals: List<Map<String, dynamic>>.from(json['goals'] ?? [])
          .map(Goal.fromJson)
          .toList(),
      recurringEntries:
          List<Map<String, dynamic>>.from(json['recurringEntries'] ?? [])
              .map(RecurringEntry.fromJson)
              .toList(),
      monthBudgets: rawMonthBudgets.map(
        (key, value) => MapEntry(
          key,
          Map<String, dynamic>.from(value)
              .map((k, v) => MapEntry(k, (v ?? 0).toDouble())),
        ),
      ),
      notesByMonth: Map<String, String>.from(json['notesByMonth'] ?? {}),
    );
  }
}

class MoneyTransaction {
  MoneyTransaction({
    required this.id,
    required this.amount,
    required this.category,
    required this.description,
    required this.isIncome,
    required this.date,
    this.tag = '',
    this.recurringId,
  });

  String id;
  double amount;
  String category;
  String description;
  bool isIncome;
  DateTime date;
  String tag;
  String? recurringId;

  Map<String, dynamic> toJson() => {
        'id': id,
        'amount': amount,
        'category': category,
        'description': description,
        'isIncome': isIncome,
        'date': date.toIso8601String(),
        'tag': tag,
        'recurringId': recurringId,
      };

  factory MoneyTransaction.fromJson(Map<String, dynamic> json) => MoneyTransaction(
        id: json['id'] ?? generateId(),
        amount: (json['amount'] ?? 0).toDouble(),
        category: json['category'] ?? 'Outros',
        description: json['description'] ?? 'Sem descrição',
        isIncome: json['isIncome'] ?? json['ganho'] ?? false,
        date: DateTime.tryParse(json['date'] ?? '') ?? DateTime.now(),
        tag: json['tag'] ?? '',
        recurringId: json['recurringId'],
      );
}

class Goal {
  Goal({
    required this.id,
    required this.name,
    required this.target,
    required this.saved,
    required this.deadline,
    required this.monthlyPlan,
    required this.iconKey,
  });

  String id;
  String name;
  double target;
  double saved;
  DateTime deadline;
  double monthlyPlan;
  String iconKey;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'target': target,
        'saved': saved,
        'deadline': deadline.toIso8601String(),
        'monthlyPlan': monthlyPlan,
        'iconKey': iconKey,
      };

  factory Goal.fromJson(Map<String, dynamic> json) => Goal(
        id: json['id'] ?? generateId(),
        name: json['name'] ?? 'Meta',
        target: (json['target'] ?? json['objetivo'] ?? 0).toDouble(),
        saved: (json['saved'] ?? json['guardado'] ?? 0).toDouble(),
        deadline: DateTime.tryParse(json['deadline'] ?? '') ??
            DateTime(DateTime.now().year, DateTime.now().month + 8, 1),
        monthlyPlan: (json['monthlyPlan'] ?? 0).toDouble(),
        iconKey: json['iconKey'] ?? 'savings',
      );
}

class RecurringEntry {
  RecurringEntry({
    required this.id,
    required this.name,
    required this.amount,
    required this.category,
    required this.isIncome,
    required this.dayOfMonth,
    required this.active,
  });

  String id;
  String name;
  double amount;
  String category;
  bool isIncome;
  int dayOfMonth;
  bool active;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'amount': amount,
        'category': category,
        'isIncome': isIncome,
        'dayOfMonth': dayOfMonth,
        'active': active,
      };

  factory RecurringEntry.fromJson(Map<String, dynamic> json) => RecurringEntry(
        id: json['id'] ?? generateId(),
        name: json['name'] ?? 'Recorrência',
        amount: (json['amount'] ?? 0).toDouble(),
        category: json['category'] ?? 'Outros',
        isIncome: json['isIncome'] ?? false,
        dayOfMonth: json['dayOfMonth'] ?? 1,
        active: json['active'] ?? true,
      );
}

class MonthStats {
  MonthStats({
    required this.month,
    required this.initialBalance,
    required this.income,
    required this.expense,
    required this.finalBalance,
    required this.budgetTotal,
    required this.categoryExpenses,
  });

  final DateTime month;
  final double initialBalance;
  final double income;
  final double expense;
  final double finalBalance;
  final double budgetTotal;
  final Map<String, double> categoryExpenses;

  double get result => income - expense;
  double get savingRate => income <= 0 ? 0 : result / income;
  double get budgetProgress => budgetTotal <= 0 ? 0 : expense / budgetTotal;
}

/* ============================================================
   REPOSITÓRIO FIREBASE
============================================================ */

class FirebaseRepository {
  FirebaseRepository();

  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  String? get currentUid => auth.currentUser?.uid;

  DocumentReference<Map<String, dynamic>> _userDoc(String uid) {
    return firestore.collection('users').doc(uid);
  }

  FinanceUser _blankUserFromFirebase(User firebaseUser) {
    final email = firebaseUser.email?.trim().toLowerCase() ?? '';
    return FinanceUser(
      email: email,
      password: '',
      name: firebaseUser.displayName ?? 'Usuário',
      initialBalance: 0,
      monthlyLimit: 1800,
      categories: List<String>.from(defaultCategories),
      defaultCategoryBudgets: Map<String, double>.from(defaultBudgets),
      transactions: [],
      goals: [],
      recurringEntries: [],
      monthBudgets: {
        monthKey(DateTime.now()): Map<String, double>.from(defaultBudgets),
      },
      notesByMonth: {},
    );
  }

  Future<FinanceUser?> loadCurrentUser() async {
    final firebaseUser = auth.currentUser;
    if (firebaseUser == null) return null;

    final doc = await _userDoc(firebaseUser.uid).get();
    if (doc.exists && doc.data() != null) {
      return FinanceUser.fromJson(doc.data()!);
    }

    final user = _blankUserFromFirebase(firebaseUser);
    if (user.email.isEmpty) return null;

    await saveUser(user);
    return user;
  }

  Future<FinanceUser?> login({
    required String email,
    required String password,
  }) async {
    final credential = await auth.signInWithEmailAndPassword(
      email: email.trim().toLowerCase(),
      password: password.trim(),
    );

    final firebaseUser = credential.user;
    if (firebaseUser == null) return null;

    final doc = await _userDoc(firebaseUser.uid).get();
    if (doc.exists && doc.data() != null) {
      return FinanceUser.fromJson(doc.data()!);
    }

    final user = _blankUserFromFirebase(firebaseUser);
    if (user.email.isEmpty) return null;

    await saveUser(user);
    return user;
  }

  Future<FinanceUser> register({
    required String name,
    required String email,
    required String password,
    required double initialBalance,
  }) async {
    final credential = await auth.createUserWithEmailAndPassword(
      email: email.trim().toLowerCase(),
      password: password.trim(),
    );

    final firebaseUser = credential.user!;
    final normalized = firebaseUser.email?.trim().toLowerCase() ?? email.trim().toLowerCase();

    final user = FinanceUser(
      email: normalized,
      password: '',
      name: name.trim().isEmpty ? 'Usuário' : name.trim(),
      initialBalance: initialBalance,
      monthlyLimit: 1800,
      categories: List<String>.from(defaultCategories),
      defaultCategoryBudgets: Map<String, double>.from(defaultBudgets),
      transactions: [],
      goals: [],
      recurringEntries: [],
      monthBudgets: {
        monthKey(DateTime.now()): Map<String, double>.from(defaultBudgets),
      },
      notesByMonth: {},
    );

    await firebaseUser.updateDisplayName(user.name);
    await saveUser(user);

    return user;
  }

  Future<void> saveUser(FinanceUser user) async {
    final uid = currentUid;
    if (uid == null) return;

    await _userDoc(uid).set(user.toJson(), SetOptions(merge: true));
  }

  Future<void> logout() async {
    await auth.signOut();
  }
}

String descriptionFor(String category) {
  switch (category) {
    case 'Moradia':
      return 'Conta/ajuda de casa';
    case 'Comida':
      return 'Mercado e lanches';
    case 'Transporte':
      return 'Ônibus e deslocamento';
    case 'Estudos':
      return 'Material de estudos';
    case 'Lazer':
      return 'Cinema, jogo ou passeio';
    case 'Compras':
      return 'Compras gerais';
    case 'Saúde':
      return 'Farmácia ou consulta';
    case 'Assinaturas':
      return 'Assinaturas digitais';
    case 'Caixinhas':
      return 'Valor guardado em caixinha';
    default:
      return 'Despesa diversa';
  }
}

/* ============================================================
   CONTROLLER
============================================================ */

class AppController extends ChangeNotifier {
  AppController(this.repository, this.database);

  final FirebaseRepository repository;
  AppDatabase database;
  String? currentEmail;
  DateTime selectedMonth = monthStart(DateTime.now());

  FinanceUser? get currentUser =>
      currentEmail == null ? null : database.users[currentEmail!];

  bool get isLoggedIn => currentUser != null;

  Future<void> tryRestoreSession() async {
    final user = await repository.loadCurrentUser();
    if (user == null) return;

    database.users[user.email] = user;
    currentEmail = user.email;
    notifyListeners();
  }

  Future<void> persist() async {
    final user = currentUser;
    if (user != null) {
      await repository.saveUser(user);
    }
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    try {
      final user = await repository.login(
        email: email,
        password: password,
      );

      if (user == null) return false;

      database.users[user.email] = user;
      currentEmail = user.email;

      notifyListeners();
      return true;
    } on FirebaseAuthException {
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<String?> register({
    required String name,
    required String email,
    required String password,
    required double initialBalance,
  }) async {
    final normalized = email.trim().toLowerCase();

    if (!normalized.contains('@') || !normalized.contains('.')) {
      return 'Digite um email válido.';
    }

    if (password.trim().length < 6) {
      return 'A senha precisa ter pelo menos 6 caracteres.';
    }

    try {
      final user = await repository.register(
        name: name,
        email: normalized,
        password: password,
        initialBalance: initialBalance,
      );

      database.users[user.email] = user;
      currentEmail = user.email;

      notifyListeners();
      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        return 'Este email já está cadastrado.';
      }

      if (e.code == 'weak-password') {
        return 'A senha está fraca. Use pelo menos 6 caracteres.';
      }

      if (e.code == 'invalid-email') {
        return 'Email inválido.';
      }

      return 'Erro ao criar conta: ${e.code}';
    } catch (_) {
      return 'Erro ao criar conta.';
    }
  }

  Future<void> logout() async {
    await repository.logout();
    currentEmail = null;
    database = AppDatabase(users: {});
    notifyListeners();
  }

  void changeMonth(int delta) {
    selectedMonth = DateTime(selectedMonth.year, selectedMonth.month + delta, 1);
    notifyListeners();
  }

  void goToCurrentMonth() {
    selectedMonth = monthStart(DateTime.now());
    notifyListeners();
  }

  List<MoneyTransaction> allTransactionsSorted() {
    final user = currentUser!;
    final list = [...user.transactions];
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  List<MoneyTransaction> transactionsOfMonth(DateTime month) {
    return allTransactionsSorted().where((t) => sameMonth(t.date, month)).toList();
  }

  double balanceUntil(DateTime exclusiveDate) {
    final user = currentUser!;
    double total = user.initialBalance;
    for (final t in user.transactions) {
      if (t.date.isBefore(exclusiveDate)) {
        total += t.isIncome ? t.amount : -t.amount;
      }
    }
    return total;
  }

  double get freeBalance => balanceUntil(DateTime(2999));

  double get goalsSaved => currentUser!.goals.fold(0.0, (sum, g) => sum + g.saved);

  double get netWorth => freeBalance + goalsSaved;

  MonthStats statsFor(DateTime month) {
    final tx = transactionsOfMonth(month);
    double income = 0;
    double expense = 0;
    final byCategory = <String, double>{};
    for (final t in tx) {
      if (t.isIncome) {
        income += t.amount;
      } else {
        expense += t.amount;
        byCategory[t.category] = (byCategory[t.category] ?? 0) + t.amount;
      }
    }

    final budget = budgetMapFor(month);
    final budgetTotal = budget.values.fold(0.0, (a, b) => a + b);
    final initial = balanceUntil(monthStart(month));
    return MonthStats(
      month: monthStart(month),
      initialBalance: initial,
      income: income,
      expense: expense,
      finalBalance: initial + income - expense,
      budgetTotal: budgetTotal,
      categoryExpenses: byCategory,
    );
  }

  List<MonthStats> lastMonths(int count) {
    final result = <MonthStats>[];
    final start = DateTime(selectedMonth.year, selectedMonth.month - count + 1, 1);
    for (int i = 0; i < count; i++) {
      result.add(statsFor(DateTime(start.year, start.month + i, 1)));
    }
    return result;
  }

  Map<String, double> budgetMapFor(DateTime month) {
    final user = currentUser!;
    final key = monthKey(month);
    final base = Map<String, double>.from(user.defaultCategoryBudgets);
    final monthBudget = user.monthBudgets[key];
    if (monthBudget != null) base.addAll(monthBudget);
    for (final c in user.categories) {
      base.putIfAbsent(c, () => 0);
    }
    return base;
  }

  double categoryBudget(DateTime month, String category) {
    return budgetMapFor(month)[category] ?? 0;
  }

  Future<void> setCategoryBudget(String category, double value) async {
    final user = currentUser!;
    final key = monthKey(selectedMonth);
    user.monthBudgets.putIfAbsent(key, () => Map<String, double>.from(user.defaultCategoryBudgets));
    user.monthBudgets[key]![category] = value;
    await persist();
  }

  Future<void> saveMonthNote(String note) async {
    currentUser!.notesByMonth[monthKey(selectedMonth)] = note.trim();
    await persist();
  }

  Future<void> addTransaction(MoneyTransaction transaction) async {
    currentUser!.transactions.add(transaction);
    await persist();
  }

  Future<void> updateTransaction(MoneyTransaction transaction) async {
    final list = currentUser!.transactions;
    final index = list.indexWhere((t) => t.id == transaction.id);
    if (index >= 0) list[index] = transaction;
    await persist();
  }

  Future<void> deleteTransaction(String transactionId) async {
    currentUser!.transactions.removeWhere((t) => t.id == transactionId);
    await persist();
  }

  Future<void> addGoal(Goal goal) async {
    currentUser!.goals.add(goal);
    await persist();
  }

  Future<void> updateGoal(Goal goal) async {
    final list = currentUser!.goals;
    final index = list.indexWhere((g) => g.id == goal.id);
    if (index >= 0) list[index] = goal;
    await persist();
  }

  Future<void> deleteGoal(String goalId) async {
    currentUser!.goals.removeWhere((g) => g.id == goalId);
    await persist();
  }

  Future<String?> moveGoalMoney(Goal goal, double amount, bool deposit) async {
    if (amount <= 0) return 'Digite um valor válido.';
    if (deposit && amount > freeBalance) return 'Saldo livre insuficiente.';
    if (!deposit && amount > goal.saved) return 'A caixinha não tem esse valor.';

    if (deposit) {
      goal.saved += amount;
      currentUser!.transactions.add(MoneyTransaction(
            id: generateId(),
            amount: amount,
            category: 'Caixinhas',
            description: 'Guardado em ${goal.name}',
            isIncome: false,
            date: DateTime.now(),
            tag: 'meta',
          ));
    } else {
      goal.saved -= amount;
      currentUser!.transactions.add(MoneyTransaction(
            id: generateId(),
            amount: amount,
            category: 'Caixinhas',
            description: 'Retirada de ${goal.name}',
            isIncome: true,
            date: DateTime.now(),
            tag: 'meta',
          ));
    }
    await persist();
    return null;
  }

  Future<void> addRecurring(RecurringEntry entry) async {
    currentUser!.recurringEntries.add(entry);
    await persist();
  }

  Future<void> updateRecurring(RecurringEntry entry) async {
    final list = currentUser!.recurringEntries;
    final index = list.indexWhere((e) => e.id == entry.id);
    if (index >= 0) list[index] = entry;
    await persist();
  }

  Future<void> deleteRecurring(String recurringId) async {
    currentUser!.recurringEntries.removeWhere((e) => e.id == recurringId);
    await persist();
  }

  Future<int> applyRecurringForSelectedMonth() async {
    final user = currentUser!;
    int created = 0;
    for (final entry in user.recurringEntries.where((e) => e.active)) {
      final already = user.transactions.any(
        (t) => t.recurringId == entry.id && sameMonth(t.date, selectedMonth),
      );
      if (already) continue;
      user.transactions.add(MoneyTransaction(
        id: generateId(),
        amount: entry.amount,
        category: entry.category,
        description: entry.name,
        isIncome: entry.isIncome,
        date: safeDayInMonth(selectedMonth, entry.dayOfMonth),
        tag: 'recorrente',
        recurringId: entry.id,
      ));
      created++;
    }
    await persist();
    return created;
  }

  List<String> insightsForSelectedMonth() {
    final current = statsFor(selectedMonth);
    final previous = statsFor(previousMonth(selectedMonth));
    final insights = <String>[];

    if (current.income <= 0) {
      insights.add('Nenhuma entrada registrada em ${monthLabel(selectedMonth)}.');
    }

    if (current.expense > current.budgetTotal && current.budgetTotal > 0) {
      insights.add('Você passou ${money(current.expense - current.budgetTotal)} do orçamento planejado.');
    } else if (current.budgetTotal > 0) {
      insights.add('Você ainda tem ${money(max(0, current.budgetTotal - current.expense))} livres no orçamento do mês.');
    }

    if (previous.expense > 0) {
      final diff = current.expense - previous.expense;
      if (diff > 0) {
        insights.add('Seus gastos subiram ${money(diff)} em relação ao mês anterior.');
      } else {
        insights.add('Boa: seus gastos caíram ${money(diff.abs())} em relação ao mês anterior.');
      }
    }

    if (current.categoryExpenses.isNotEmpty) {
      final top = current.categoryExpenses.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      insights.add('Categoria que mais pesou: ${top.first.key}, com ${money(top.first.value)}.');
    }

    final lateGoals = currentUser!.goals.where((g) => goalStatus(g).contains('atrasado')).length;
    if (lateGoals > 0) {
      insights.add('$lateGoals meta(s) parecem atrasadas pelo plano mensal.');
    } else if (currentUser!.goals.isNotEmpty) {
      insights.add('Suas metas estão em bom ritmo ou próximas do planejado.');
    }

    return insights;
  }

  String goalStatus(Goal goal) {
    if (goal.saved >= goal.target) return 'concluída';
    final remaining = goal.target - goal.saved;
    final monthsLeft = max(1, ((goal.deadline.year - DateTime.now().year) * 12) + goal.deadline.month - DateTime.now().month);
    final needed = remaining / monthsLeft;
    final planned = goal.monthlyPlan <= 0 ? needed : goal.monthlyPlan;
    if (planned >= needed * 1.2) return 'adiantado';
    if (planned >= needed * 0.85) return 'em dia';
    return 'atrasado';
  }
}

/* ============================================================
   APP
============================================================ */

class SmartFinanceApp extends StatefulWidget {
  const SmartFinanceApp({super.key, required this.controller});

  final AppController controller;

  @override
  State<SmartFinanceApp> createState() => _SmartFinanceAppState();
}

class _SmartFinanceAppState extends State<SmartFinanceApp> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_refresh);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SmartFinance Pro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: kBg,
        fontFamily: 'Arial',
        colorScheme: ColorScheme.fromSeed(seedColor: kGreen),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      home: widget.controller.isLoggedIn
          ? HomeShell(controller: widget.controller)
          : LoginPage(controller: widget.controller),
    );
  }
}

/* ============================================================
   LOGIN E CADASTRO
============================================================ */

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, required this.controller});

  final AppController controller;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final email = TextEditingController();
  final password = TextEditingController();
  bool visible = false;

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    final ok = await widget.controller.login(email.text, password.text);

    if (!mounted) return;

    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email ou senha incorretos.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kDark,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(26),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 78,
                      height: 78,
                      decoration: BoxDecoration(
                        color: kGreen.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: const Icon(Icons.account_balance_wallet, color: kGreen, size: 42),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'SmartFinance Pro',
                      style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Controle financeiro mensal com metas, orçamentos, recorrências e relatórios.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: kGray),
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: email,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: password,
                      obscureText: !visible,
                      decoration: InputDecoration(
                        labelText: 'Senha',
                        prefixIcon: const Icon(Icons.lock),
                        suffixIcon: IconButton(
                          icon: Icon(visible ? Icons.visibility : Icons.visibility_off),
                          onPressed: () => setState(() => visible = !visible),
                        ),
                      ),
                      onSubmitted: (_) => submit(),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: FilledButton.icon(
                        onPressed: submit,
                        icon: const Icon(Icons.login),
                        label: const Text('Entrar'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => RegisterPage(controller: widget.controller),
                          ),
                        );
                      },
                      child: const Text('Criar nova conta'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key, required this.controller});

  final AppController controller;

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final name = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();
  final balance = TextEditingController();
  bool visible = false;

  @override
  void dispose() {
    name.dispose();
    email.dispose();
    password.dispose();
    balance.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    final error = await widget.controller.register(
      name: name.text,
      email: email.text,
      password: password.text,
      initialBalance: moneyFromText(balance.text),
    );
    if (!mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Conta criada com sucesso. Você já está logado.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kDark,
      appBar: AppBar(title: const Text('Criar conta'), backgroundColor: kDark, foregroundColor: Colors.white),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    TextField(controller: name, decoration: const InputDecoration(labelText: 'Nome', prefixIcon: Icon(Icons.person))),
                    const SizedBox(height: 12),
                    TextField(controller: email, decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email))),
                    const SizedBox(height: 12),
                    TextField(
                      controller: password,
                      obscureText: !visible,
                      decoration: InputDecoration(
                        labelText: 'Senha',
                        prefixIcon: const Icon(Icons.lock),
                        suffixIcon: IconButton(
                          icon: Icon(visible ? Icons.visibility : Icons.visibility_off),
                          onPressed: () => setState(() => visible = !visible),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: balance,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Saldo inicial', prefixIcon: Icon(Icons.savings)),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: FilledButton.icon(
                        onPressed: submit,
                        icon: const Icon(Icons.check),
                        label: const Text('Criar conta'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/* ============================================================
   SHELL
============================================================ */

class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.controller});

  final AppController controller;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int index = 0;

  Widget _screen(AppController c) {
    if (index == 0) return DashboardScreen(controller: c);
    if (index == 1) return TransactionsScreen(controller: c);
    if (index == 2) return PlannerScreen(controller: c);
    if (index == 3) return GoalsScreen(controller: c);
    if (index == 4) return ReportsScreen(controller: c);
    return SettingsScreen(controller: c);
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;

    return Scaffold(
      body: _screen(c),
      floatingActionButton: index == 0 || index == 1
          ? FloatingActionButton.extended(
              onPressed: () => openTransactionDialog(context, c),
              icon: const Icon(Icons.add),
              label: const Text('Novo lançamento'),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) => setState(() => index = i),
        height: 74,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Início'),
          NavigationDestination(icon: Icon(Icons.add_card_outlined), selectedIcon: Icon(Icons.add_card), label: 'Lançar'),
          NavigationDestination(icon: Icon(Icons.calendar_month_outlined), selectedIcon: Icon(Icons.calendar_month), label: 'Plano'),
          NavigationDestination(icon: Icon(Icons.savings_outlined), selectedIcon: Icon(Icons.savings), label: 'Metas'),
          NavigationDestination(icon: Icon(Icons.bar_chart_outlined), selectedIcon: Icon(Icons.bar_chart), label: 'Relatórios'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: 'Config.'),
        ],
      ),
    );
  }
}

/* ============================================================
   WIDGETS DE UI
============================================================ */

class PageScaffold extends StatelessWidget {
  const PageScaffold({super.key, required this.children, this.trailing});

  final List<Widget> children;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 110),
        children: [
          if (trailing != null) Align(alignment: Alignment.centerRight, child: trailing!),
          ...children,
        ],
      ),
    );
  }
}

class PageTitle extends StatelessWidget {
  const PageTitle({super.key, required this.title, required this.subtitle, this.icon});

  final String title;
  final String subtitle;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        children: [
          if (icon != null) ...[
            CircleAvatar(backgroundColor: kGreen.withValues(alpha: 0.12), child: Icon(icon, color: kGreen)),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(color: kGray)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class MonthPicker extends StatelessWidget {
  const MonthPicker({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            IconButton(onPressed: () => controller.changeMonth(-1), icon: const Icon(Icons.chevron_left)),
            Expanded(
              child: Text(
                monthLabel(controller.selectedMonth),
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17),
              ),
            ),
            TextButton(onPressed: controller.goToCurrentMonth, child: const Text('Hoje')),
            IconButton(onPressed: () => controller.changeMonth(1), icon: const Icon(Icons.chevron_right)),
          ],
        ),
      ),
    );
  }
}

class SectionCard extends StatelessWidget {
  const SectionCard({super.key, required this.title, required this.child, this.icon, this.trailing});

  final String title;
  final Widget child;
  final IconData? icon;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, color: kGreen),
                  const SizedBox(width: 8),
                ],
                Expanded(child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900))),
                if (trailing != null) trailing!,
              ],
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}

class SummaryCard extends StatelessWidget {
  const SummaryCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.subtitle,
  });

  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Container(
        constraints: const BoxConstraints(minHeight: 166),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color, color.withValues(alpha: 0.76)],
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.16),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            CircleAvatar(
              radius: 23,
              backgroundColor: Colors.white.withValues(alpha: 0.16),
              child: Icon(icon, color: Colors.white, size: 25),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w700, height: 1.15),
            ),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 26),
              ),
            ),
            if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                subtitle!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.2, fontWeight: FontWeight.w600),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class SoftMetricCard extends StatelessWidget {
  const SoftMetricCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.subtitle,
    this.footer,
  });

  final String title;
  final String value;
  final String? subtitle;
  final String? footer;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 210),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.075),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: color.withValues(alpha: 0.22)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 27,
                backgroundColor: color.withValues(alpha: 0.15),
                child: Icon(icon, color: color, size: 27),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900, height: 1.12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 32, height: 1.05),
            ),
          ),
          if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              subtitle!,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: kGray, fontSize: 15, height: 1.28, fontWeight: FontWeight.w600),
            ),
          ],
          if (footer != null && footer!.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                footer!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class ResponsiveGrid extends StatelessWidget {
  const ResponsiveGrid({super.key, required this.children, this.minWidth = 230});

  final List<Widget> children;
  final double minWidth;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final count = max(1, constraints.maxWidth ~/ minWidth);
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: children.map((child) {
            return SizedBox(width: (constraints.maxWidth - (count - 1) * 12) / count, child: child);
          }).toList(),
        );
      },
    );
  }
}

class ProgressLine extends StatelessWidget {
  const ProgressLine({super.key, required this.value, required this.color, this.height = 11});

  final double value;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: LinearProgressIndicator(
        minHeight: height,
        value: value.clamp(0.0, 1.0).toDouble(),
        color: color,
        backgroundColor: color.withValues(alpha: 0.13),
      ),
    );
  }
}

/* ============================================================
   DASHBOARD
============================================================ */

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final user = controller.currentUser!;
    final stats = controller.statsFor(controller.selectedMonth);
    final prev = controller.statsFor(previousMonth(controller.selectedMonth));
    final insights = controller.insightsForSelectedMonth();

    return PageScaffold(
      children: [
        PageTitle(
          title: 'Início',
          subtitle: 'Olá, ${user.name}. Veja de forma simples como foi ${monthLabel(controller.selectedMonth)}.',
          icon: Icons.home_rounded,
        ),
        MonthPicker(controller: controller),
        const SizedBox(height: 14),
        MonthlyHeroCard(controller: controller, stats: stats, previous: prev),
        const SizedBox(height: 16),
        SectionCard(
          title: 'O que você quer fazer agora?',
          icon: Icons.touch_app,
          child: ResponsiveGrid(
            minWidth: 340,
            children: [
              ActionBox(
                icon: Icons.arrow_downward,
                color: kGreen,
                title: 'Registrar entrada',
                subtitle: 'Use para salário, bolsa, ajuda, freela ou qualquer dinheiro que entrou.',
                buttonText: 'Adicionar entrada',
                onTap: () => openTransactionDialog(context, controller, defaultIsIncome: true),
              ),
              ActionBox(
                icon: Icons.arrow_upward,
                color: kRed,
                title: 'Registrar gasto',
                subtitle: 'Use para compra, conta, lanche, transporte, assinatura ou qualquer dinheiro que saiu.',
                buttonText: 'Adicionar gasto',
                onTap: () => openTransactionDialog(context, controller, defaultIsIncome: false),
              ),
            ],
          ),
        ),
        SectionCard(
          title: 'Diagnóstico do mês',
          icon: Icons.psychology,
          child: Column(
            children: insights.map((text) => InsightTile(text: text)).toList(),
          ),
        ),
        ResponsiveGrid(
          minWidth: 280,
          children: [
            SummaryCard(title: 'Saldo livre', value: money(controller.freeBalance), subtitle: 'dinheiro disponível agora', icon: Icons.account_balance_wallet, color: kDark),
            SummaryCard(title: 'Patrimônio', value: money(controller.netWorth), subtitle: 'saldo + caixinhas', icon: Icons.diamond, color: kBlue),
            SummaryCard(title: 'Entradas', value: money(stats.income), subtitle: variationText(stats.income, prev.income), icon: Icons.trending_up, color: kGreen),
            SummaryCard(title: 'Gastos', value: money(stats.expense), subtitle: variationText(stats.expense, prev.expense), icon: Icons.trending_down, color: kRed),
          ],
        ),
        const SizedBox(height: 16),
        SectionCard(
          title: 'Fechamento mensal explicado',
          icon: Icons.fact_check,
          child: Column(
            children: [
              const HelpLine(icon: Icons.flag, text: 'Saldo inicial: quanto você tinha ao começar o mês.'),
              const HelpLine(icon: Icons.add_circle, text: 'Entradas: todo dinheiro que entrou no mês.'),
              const HelpLine(icon: Icons.remove_circle, text: 'Saídas: tudo que você gastou no mês.'),
              const Divider(height: 24),
              KeyValueRow(label: 'Saldo inicial do mês', value: money(stats.initialBalance)),
              KeyValueRow(label: 'Entradas', value: money(stats.income), color: kGreen),
              KeyValueRow(label: 'Saídas', value: money(stats.expense), color: kRed),
              const Divider(),
              KeyValueRow(label: 'Resultado do mês', value: money(stats.result), color: stats.result >= 0 ? kGreen : kRed),
              KeyValueRow(label: 'Saldo final previsto', value: money(stats.finalBalance)),
              KeyValueRow(label: 'Taxa de economia', value: percent(stats.savingRate), color: stats.savingRate >= 0.2 ? kGreen : kOrange),
            ],
          ),
        ),
        SectionCard(
          title: 'Categorias que mais pesaram',
          icon: Icons.category,
          child: CategoryRanking(controller: controller, month: controller.selectedMonth),
        ),
        SectionCard(
          title: 'Metas em destaque',
          icon: Icons.savings,
          child: GoalPreview(controller: controller),
        ),
      ],
    );
  }
}

class MonthlyHeroCard extends StatelessWidget {
  const MonthlyHeroCard({
    super.key,
    required this.controller,
    required this.stats,
    required this.previous,
  });

  final AppController controller;
  final MonthStats stats;
  final MonthStats previous;

  @override
  Widget build(BuildContext context) {
    final resultColor = stats.result >= 0 ? kGreen : kRed;
    final budgetColor = stats.budgetProgress > 1 ? kRed : kOrange;
    final progressLabel = stats.budgetTotal <= 0
        ? 'Sem orçamento definido'
        : '${percent(stats.budgetProgress)} do orçamento usado';

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 760;
        final header = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              monthLabel(controller.selectedMonth),
              style: const TextStyle(fontSize: 15, color: Colors.white70, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              money(stats.result),
              style: const TextStyle(fontSize: 34, color: Colors.white, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 4),
            Text(
              stats.result >= 0 ? 'Você ficou positivo neste mês.' : 'Você gastou mais do que entrou neste mês.',
              style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 18),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: stats.budgetProgress.clamp(0.0, 1.0).toDouble(),
                minHeight: 13,
                color: Colors.white,
                backgroundColor: Colors.white.withValues(alpha: 0.25),
              ),
            ),
            const SizedBox(height: 8),
            Text(progressLabel, style: TextStyle(color: budgetColor == kRed ? const Color(0xffffdddd) : Colors.white70, fontWeight: FontWeight.w700)),
          ],
        );

        final details = Column(
          children: [
            _HeroMetric(label: 'Entrou', value: money(stats.income), icon: Icons.arrow_downward, color: kGreen),
            const SizedBox(height: 10),
            _HeroMetric(label: 'Saiu', value: money(stats.expense), icon: Icons.arrow_upward, color: kRed),
            const SizedBox(height: 10),
            _HeroMetric(label: 'Livre agora', value: money(controller.freeBalance), icon: Icons.wallet, color: kBlue),
          ],
        );

        return Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                resultColor == kGreen ? const Color(0xff064e3b) : const Color(0xff7f1d1d),
                const Color(0xff0f172a),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: kDark.withValues(alpha: 0.18),
                blurRadius: 24,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: compact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    header,
                    const SizedBox(height: 18),
                    details,
                  ],
                )
              : Row(
                  children: [
                    Expanded(flex: 2, child: header),
                    const SizedBox(width: 22),
                    Expanded(child: details),
                  ],
                ),
        );
      },
    );
  }
}

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.16),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w700))),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

class ActionBox extends StatelessWidget {
  const ActionBox({
    super.key,
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.buttonText,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String buttonText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(26),
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 238),
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.075),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: color.withValues(alpha: 0.22)),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 25,
                    backgroundColor: color.withValues(alpha: 0.15),
                    child: Icon(icon, color: color, size: 25),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, height: 1.1),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                subtitle,
                style: const TextStyle(color: kGray, height: 1.38, fontSize: 15, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton.tonalIcon(
                  onPressed: onTap,
                  icon: const Icon(Icons.add),
                  label: Text(buttonText, overflow: TextOverflow.ellipsis),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HelpLine extends StatelessWidget {
  const HelpLine({super.key, required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        children: [
          Icon(icon, color: kGreen, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(color: kGray, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}

class InsightTile extends StatelessWidget {
  const InsightTile({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: kGreen.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kGreen.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome, color: kGreen),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}

class KeyValueRow extends StatelessWidget {
  const KeyValueRow({super.key, required this.label, required this.value, this.color});

  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(value, style: TextStyle(fontWeight: FontWeight.w900, color: color)),
        ],
      ),
    );
  }
}

class CategoryRanking extends StatelessWidget {
  const CategoryRanking({super.key, required this.controller, required this.month});

  final AppController controller;
  final DateTime month;

  @override
  Widget build(BuildContext context) {
    final stats = controller.statsFor(month);
    final entries = stats.categoryExpenses.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    if (entries.isEmpty) return const Text('Nenhum gasto registrado nesse mês.', style: TextStyle(color: kGray));
    final maxValue = entries.first.value;
    return Column(
      children: entries.take(6).map((e) {
        final color = categoryColor(e.key);
        return Padding(
          padding: const EdgeInsets.only(bottom: 13),
          child: Column(
            children: [
              Row(
                children: [
                  CircleAvatar(radius: 16, backgroundColor: color.withValues(alpha: 0.12), child: Icon(categoryIcon(e.key), size: 17, color: color)),
                  const SizedBox(width: 10),
                  Expanded(child: Text(e.key, style: const TextStyle(fontWeight: FontWeight.w800))),
                  Text(money(e.value), style: const TextStyle(fontWeight: FontWeight.w900)),
                ],
              ),
              const SizedBox(height: 7),
              ProgressLine(value: e.value / maxValue, color: color),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class GoalPreview extends StatelessWidget {
  const GoalPreview({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final goals = controller.currentUser!.goals;
    if (goals.isEmpty) return const Text('Crie sua primeira meta na aba Metas.', style: TextStyle(color: kGray));
    return Column(
      children: goals.take(3).map((g) {
        final progress = g.target <= 0 ? 0.0 : g.saved / g.target;
        final status = controller.goalStatus(g);
        final statusColor = status == 'concluída' || status == 'adiantado'
            ? kGreen
            : status == 'atrasado'
                ? kRed
                : kOrange;
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  CircleAvatar(backgroundColor: kGreen.withValues(alpha: 0.12), child: Icon(goalIcon(g.iconKey), color: kGreen)),
                  const SizedBox(width: 10),
                  Expanded(child: Text(g.name, style: const TextStyle(fontWeight: FontWeight.w900))),
                  Chip(label: Text(status), backgroundColor: statusColor.withValues(alpha: 0.12), labelStyle: TextStyle(color: statusColor, fontWeight: FontWeight.w800)),
                ],
              ),
              const SizedBox(height: 10),
              ProgressLine(value: progress, color: statusColor, height: 12),
              const SizedBox(height: 7),
              Row(
                children: [
                  Text('${percent(progress)} concluído', style: const TextStyle(color: kGray)),
                  const Spacer(),
                  Text('${money(g.saved)} de ${money(g.target)}', style: const TextStyle(fontWeight: FontWeight.w800)),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

/* ============================================================
   LANÇAMENTOS
============================================================ */

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key, required this.controller});

  final AppController controller;

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  String search = '';
  String type = 'Todos';
  String category = 'Todas';

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final user = c.currentUser!;
    final stats = c.statsFor(c.selectedMonth);

    var list = c.transactionsOfMonth(c.selectedMonth);
    list = list.where((t) {
      final term = search.trim().toLowerCase();
      final matchesSearch = term.isEmpty ||
          t.description.toLowerCase().contains(term) ||
          t.category.toLowerCase().contains(term) ||
          t.tag.toLowerCase().contains(term);
      final matchesType = type == 'Todos' || (type == 'Entradas' && t.isIncome) || (type == 'Gastos' && !t.isIncome);
      final matchesCategory = category == 'Todas' || t.category == category;
      return matchesSearch && matchesType && matchesCategory;
    }).toList();

    return PageScaffold(
      children: [
        PageTitle(
          title: 'Lançar',
          subtitle: 'Aqui você registra o dinheiro que entrou e o dinheiro que saiu. Comece pelos botões abaixo.',
          icon: Icons.add_card,
        ),
        MonthPicker(controller: c),
        const SizedBox(height: 14),
        ResponsiveGrid(
          minWidth: 260,
          children: [
            ActionBox(
              icon: Icons.arrow_downward,
              color: kGreen,
              title: 'Entrada',
              subtitle: 'Salário, bolsa, ajuda, freela, venda ou qualquer dinheiro recebido.',
              buttonText: 'Adicionar entrada',
              onTap: () => openTransactionDialog(context, c, defaultIsIncome: true),
            ),
            ActionBox(
              icon: Icons.arrow_upward,
              color: kRed,
              title: 'Gasto',
              subtitle: 'Compra, conta, lanche, transporte, assinatura ou qualquer dinheiro que saiu.',
              buttonText: 'Adicionar gasto',
              onTap: () => openTransactionDialog(context, c, defaultIsIncome: false),
            ),
            Container(
              constraints: const BoxConstraints(minHeight: 238),
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: kBlue.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: kBlue.withValues(alpha: 0.16)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CircleAvatar(backgroundColor: Color(0xffdbeafe), child: Icon(Icons.info_outline, color: kBlue)),
                  const SizedBox(height: 12),
                  const Text('Resumo do mês', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 10),
                  KeyValueRow(label: 'Entrou no mês', value: money(stats.income), color: kGreen),
                  KeyValueRow(label: 'Saiu no mês', value: money(stats.expense), color: kRed),
                  KeyValueRow(label: 'Registros feitos', value: '${c.transactionsOfMonth(c.selectedMonth).length}'),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SectionCard(
          title: 'Como usar esta tela',
          icon: Icons.lightbulb,
          child: const Column(
            children: [
              HelpLine(icon: Icons.arrow_downward, text: 'Clique em Entrada quando o dinheiro entrar na sua conta.'),
              HelpLine(icon: Icons.arrow_upward, text: 'Clique em Gasto quando você pagar alguma coisa.'),
              HelpLine(icon: Icons.category, text: 'Escolha uma categoria para o app montar os relatórios automaticamente.'),
              HelpLine(icon: Icons.calendar_today, text: 'A data define em qual mês o lançamento vai aparecer.'),
            ],
          ),
        ),
        SectionCard(
          title: 'Encontrar lançamento',
          icon: Icons.filter_alt,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Pesquisar',
                  helperText: 'Digite parte da descrição, categoria ou tag',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (v) => setState(() => search = v),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ChoiceChip(label: const Text('Todos'), selected: type == 'Todos', onSelected: (_) => setState(() => type = 'Todos')),
                  ChoiceChip(label: const Text('Entradas'), selected: type == 'Entradas', onSelected: (_) => setState(() => type = 'Entradas')),
                  ChoiceChip(label: const Text('Gastos'), selected: type == 'Gastos', onSelected: (_) => setState(() => type = 'Gastos')),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: category,
                items: ['Todas', ...user.categories].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (v) => setState(() => category = v ?? 'Todas'),
                decoration: const InputDecoration(labelText: 'Filtrar por categoria'),
              ),
            ],
          ),
        ),
        SectionCard(
          title: 'Histórico de ${monthLabel(c.selectedMonth)} (${list.length})',
          icon: Icons.history,
          child: list.isEmpty
              ? EmptyState(
                  icon: Icons.receipt_long,
                  title: 'Nenhum lançamento encontrado',
                  message: 'Adicione uma entrada ou um gasto para começar a montar o histórico deste mês.',
                  buttonText: 'Adicionar agora',
                  onTap: () => openTransactionDialog(context, c),
                )
              : Column(children: list.map((t) => TransactionTile(controller: c, transaction: t)).toList()),
        ),
      ],
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    required this.buttonText,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String message;
  final String buttonText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: kBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          CircleAvatar(radius: 28, backgroundColor: kGreen.withValues(alpha: 0.12), child: Icon(icon, color: kGreen)),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
          const SizedBox(height: 6),
          Text(message, textAlign: TextAlign.center, style: const TextStyle(color: kGray)),
          const SizedBox(height: 14),
          FilledButton.icon(onPressed: onTap, icon: const Icon(Icons.add), label: Text(buttonText)),
        ],
      ),
    );
  }
}

class TransactionTile extends StatelessWidget {
  const TransactionTile({super.key, required this.controller, required this.transaction});

  final AppController controller;
  final MoneyTransaction transaction;

  @override
  Widget build(BuildContext context) {
    final color = transaction.isIncome ? kGreen : categoryColor(transaction.category);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: transaction.isIncome ? kGreen.withValues(alpha: 0.045) : kRed.withValues(alpha: 0.035),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.16)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.14),
            child: Icon(transaction.isIncome ? Icons.arrow_downward : categoryIcon(transaction.category), color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(transaction.description, style: const TextStyle(fontWeight: FontWeight.w900)),
                const SizedBox(height: 5),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    _SmallBadge(text: transaction.isIncome ? 'Entrada' : 'Gasto', color: transaction.isIncome ? kGreen : kRed),
                    _SmallBadge(text: transaction.category, color: categoryColor(transaction.category)),
                    _SmallBadge(text: dateLabel(transaction.date), color: kGray),
                    if (transaction.tag.isNotEmpty) _SmallBadge(text: '#${transaction.tag}', color: kBlue),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${transaction.isIncome ? '+' : '-'}${money(transaction.amount)}',
                style: TextStyle(color: transaction.isIncome ? kGreen : kRed, fontWeight: FontWeight.w900, fontSize: 15),
              ),
              const SizedBox(height: 2),
              PopupMenuButton<String>(
                tooltip: 'Ações',
                onSelected: (value) async {
                  if (value == 'edit') openTransactionDialog(context, controller, transaction: transaction);
                  if (value == 'delete') await controller.deleteTransaction(transaction.id);
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'edit', child: Text('Editar')),
                  PopupMenuItem(value: 'delete', child: Text('Excluir')),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SmallBadge extends StatelessWidget {
  const _SmallBadge({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(text, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w800)),
    );
  }
}

Future<void> openTransactionDialog(
  BuildContext context,
  AppController controller, {
  MoneyTransaction? transaction,
  bool? defaultIsIncome,
}) async {
  final user = controller.currentUser!;
  final amount = TextEditingController(text: transaction == null ? '' : transaction.amount.toStringAsFixed(2).replaceAll('.', ','));
  final desc = TextEditingController(text: transaction?.description ?? '');
  final tag = TextEditingController(text: transaction?.tag ?? '');
  String category = transaction?.category ?? user.categories.first;
  bool isIncome = transaction?.isIncome ?? defaultIsIncome ?? false;
  DateTime date = transaction?.date ?? controller.selectedMonth;

  await showDialog(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          final typeColor = isIncome ? kGreen : kRed;
          return AlertDialog(
            title: Text(transaction == null ? 'Novo lançamento' : 'Editar lançamento'),
            content: SizedBox(
              width: 520,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('1. Escolha o tipo', style: TextStyle(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ChoiceChip(
                            label: const Text('Entrada'),
                            avatar: const Icon(Icons.arrow_downward, size: 18),
                            selected: isIncome,
                            onSelected: (_) => setDialogState(() => isIncome = true),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ChoiceChip(
                            label: const Text('Gasto'),
                            avatar: const Icon(Icons.arrow_upward, size: 18),
                            selected: !isIncome,
                            onSelected: (_) => setDialogState(() => isIncome = false),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text('2. Informe os dados', style: TextStyle(fontWeight: FontWeight.w900, color: typeColor)),
                    const SizedBox(height: 10),
                    TextField(
                      controller: amount,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Valor',
                        helperText: 'Exemplo: 25,50',
                        prefixIcon: Icon(Icons.attach_money, color: typeColor),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: desc,
                      decoration: const InputDecoration(
                        labelText: 'Descrição',
                        helperText: 'Exemplo: lanche, salário, ônibus, mercado',
                        prefixIcon: Icon(Icons.notes),
                      ),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      initialValue: category,
                      items: user.categories.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                      onChanged: (v) => setDialogState(() => category = v ?? category),
                      decoration: const InputDecoration(labelText: 'Categoria', prefixIcon: Icon(Icons.category)),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: tag,
                      decoration: const InputDecoration(
                        labelText: 'Tag opcional',
                        helperText: 'Use para marcar: escola, urgente, recorrente...',
                        prefixIcon: Icon(Icons.tag),
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2035),
                            initialDate: date,
                          );
                          if (picked != null) setDialogState(() => date = picked);
                        },
                        icon: const Icon(Icons.calendar_month),
                        label: Text('Data: ${dateLabel(date)}'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancelar')),
              FilledButton.icon(
                onPressed: () async {
                  final value = moneyFromText(amount.text);
                  if (value <= 0) {
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      const SnackBar(content: Text('Digite um valor válido.')),
                    );
                    return;
                  }
                  final newTransaction = MoneyTransaction(
                    id: transaction?.id ?? generateId(),
                    amount: value,
                    category: category,
                    description: desc.text.trim().isEmpty ? 'Sem descrição' : desc.text.trim(),
                    isIncome: isIncome,
                    date: date,
                    tag: tag.text.trim(),
                    recurringId: transaction?.recurringId,
                  );
                  if (transaction == null) {
                    await controller.addTransaction(newTransaction);
                  } else {
                    await controller.updateTransaction(newTransaction);
                  }
                  if (dialogContext.mounted) Navigator.pop(dialogContext);
                },
                icon: const Icon(Icons.check),
                label: const Text('Salvar lançamento'),
              ),
            ],
          );
        },
      );
    },
  );
}

/* ============================================================
   PLANEJAMENTO: ORÇAMENTO E RECORRÊNCIAS
============================================================ */

class PlannerScreen extends StatelessWidget {
  const PlannerScreen({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final stats = controller.statsFor(controller.selectedMonth);
    final budget = controller.budgetMapFor(controller.selectedMonth);
    final entries = budget.entries.toList()..sort((a, b) => a.key.compareTo(b.key));

    return PageScaffold(
      children: [
        const PageTitle(title: 'Planejamento', subtitle: 'Orçamento por categoria, contas fixas e rotina financeira.', icon: Icons.calendar_month),
        MonthPicker(controller: controller),
        const SizedBox(height: 14),
        SectionCard(
          title: 'Resumo do orçamento',
          icon: Icons.speed,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              KeyValueRow(label: 'Orçamento total', value: money(stats.budgetTotal)),
              KeyValueRow(label: 'Gasto realizado', value: money(stats.expense), color: stats.expense > stats.budgetTotal ? kRed : kGreen),
              KeyValueRow(label: 'Disponível', value: money(stats.budgetTotal - stats.expense), color: stats.budgetTotal >= stats.expense ? kGreen : kRed),
              const SizedBox(height: 10),
              ProgressLine(value: stats.budgetProgress, color: stats.budgetProgress > 1 ? kRed : kOrange, height: 14),
            ],
          ),
        ),
        SectionCard(
          title: 'Orçamento por categoria',
          icon: Icons.account_tree,
          child: Column(
            children: entries.map((e) {
              final spent = stats.categoryExpenses[e.key] ?? 0;
              final progress = e.value <= 0 ? 0.0 : spent / e.value;
              final color = progress > 1 ? kRed : categoryColor(e.key);
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        CircleAvatar(radius: 16, backgroundColor: categoryColor(e.key).withValues(alpha: 0.12), child: Icon(categoryIcon(e.key), size: 18, color: categoryColor(e.key))),
                        const SizedBox(width: 10),
                        Expanded(child: Text(e.key, style: const TextStyle(fontWeight: FontWeight.w900))),
                        Text('${money(spent)} / ${money(e.value)}', style: const TextStyle(fontWeight: FontWeight.w800)),
                        IconButton(
                          onPressed: () => openBudgetDialog(context, controller, e.key, e.value),
                          icon: const Icon(Icons.edit),
                        ),
                      ],
                    ),
                    ProgressLine(value: progress, color: color),
                    const SizedBox(height: 6),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(progress > 1 ? 'passou ${money(spent - e.value)}' : 'restam ${money(e.value - spent)}', style: TextStyle(color: color, fontWeight: FontWeight.w800)),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
        SectionCard(
          title: 'Contas fixas e recorrências',
          icon: Icons.repeat,
          trailing: Wrap(
            spacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: () async {
                  final created = await controller.applyRecurringForSelectedMonth();
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$created recorrência(s) aplicadas.')));
                },
                icon: const Icon(Icons.playlist_add_check),
                label: const Text('Aplicar mês'),
              ),
              FilledButton.icon(
                onPressed: () => openRecurringDialog(context, controller),
                icon: const Icon(Icons.add),
                label: const Text('Nova'),
              ),
            ],
          ),
          child: RecurringList(controller: controller),
        ),
      ],
    );
  }
}

Future<void> openBudgetDialog(BuildContext context, AppController controller, String category, double current) async {
  final value = TextEditingController(text: current.toStringAsFixed(2).replaceAll('.', ','));
  await showDialog(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text('Orçamento: $category'),
      content: TextField(
        controller: value,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: const InputDecoration(labelText: 'Valor planejado para o mês'),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancelar')),
        FilledButton(
          onPressed: () async {
            await controller.setCategoryBudget(category, moneyFromText(value.text));
            if (dialogContext.mounted) Navigator.pop(dialogContext);
          },
          child: const Text('Salvar'),
        ),
      ],
    ),
  );
}

class RecurringList extends StatelessWidget {
  const RecurringList({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final list = controller.currentUser!.recurringEntries;
    if (list.isEmpty) return const Text('Nenhuma recorrência cadastrada.', style: TextStyle(color: kGray));
    return Column(
      children: list.map((e) {
        final color = e.isIncome ? kGreen : kRed;
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
          child: Row(
            children: [
              CircleAvatar(backgroundColor: color.withValues(alpha: 0.12), child: Icon(e.isIncome ? Icons.trending_up : Icons.repeat, color: color)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(e.name, style: const TextStyle(fontWeight: FontWeight.w900)),
                  Text('${e.category} • dia ${e.dayOfMonth} • ${e.active ? 'ativa' : 'pausada'}', style: const TextStyle(color: kGray)),
                ]),
              ),
              Text('${e.isIncome ? '+' : '-'}${money(e.amount)}', style: TextStyle(color: color, fontWeight: FontWeight.w900)),
              PopupMenuButton<String>(
                onSelected: (value) async {
                  if (value == 'edit') openRecurringDialog(context, controller, entry: e);
                  if (value == 'toggle') {
                    e.active = !e.active;
                    await controller.updateRecurring(e);
                  }
                  if (value == 'delete') await controller.deleteRecurring(e.id);
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'edit', child: Text('Editar')),
                  PopupMenuItem(value: 'toggle', child: Text(e.active ? 'Pausar' : 'Ativar')),
                  const PopupMenuItem(value: 'delete', child: Text('Excluir')),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

Future<void> openRecurringDialog(BuildContext context, AppController controller, {RecurringEntry? entry}) async {
  final user = controller.currentUser!;
  final name = TextEditingController(text: entry?.name ?? '');
  final amount = TextEditingController(text: entry == null ? '' : entry.amount.toStringAsFixed(2).replaceAll('.', ','));
  String category = entry?.category ?? user.categories.first;
  bool isIncome = entry?.isIncome ?? false;
  int day = entry?.dayOfMonth ?? 10;
  bool active = entry?.active ?? true;

  await showDialog(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        title: Text(entry == null ? 'Nova recorrência' : 'Editar recorrência'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: name, decoration: const InputDecoration(labelText: 'Nome')),
              const SizedBox(height: 10),
              TextField(controller: amount, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Valor')),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: category,
                items: user.categories.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (v) => setDialogState(() => category = v ?? category),
                decoration: const InputDecoration(labelText: 'Categoria'),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<int>(
                initialValue: day,
                items: List.generate(28, (i) => i + 1).map((d) => DropdownMenuItem(value: d, child: Text('Dia $d'))).toList(),
                onChanged: (v) => setDialogState(() => day = v ?? day),
                decoration: const InputDecoration(labelText: 'Dia de cobrança/entrada'),
              ),
              SwitchListTile(contentPadding: EdgeInsets.zero, title: Text(isIncome ? 'Entrada' : 'Saída'), value: isIncome, onChanged: (v) => setDialogState(() => isIncome = v)),
              SwitchListTile(contentPadding: EdgeInsets.zero, title: Text(active ? 'Ativa' : 'Pausada'), value: active, onChanged: (v) => setDialogState(() => active = v)),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () async {
              final newEntry = RecurringEntry(
                id: entry?.id ?? generateId(),
                name: name.text.trim().isEmpty ? 'Recorrência' : name.text.trim(),
                amount: moneyFromText(amount.text),
                category: category,
                isIncome: isIncome,
                dayOfMonth: day,
                active: active,
              );
              if (newEntry.amount <= 0) return;
              if (entry == null) {
                await controller.addRecurring(newEntry);
              } else {
                await controller.updateRecurring(newEntry);
              }
              if (dialogContext.mounted) Navigator.pop(dialogContext);
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    ),
  );
}

/* ============================================================
   METAS
============================================================ */

class GoalsScreen extends StatelessWidget {
  const GoalsScreen({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final goals = controller.currentUser!.goals;
    return PageScaffold(
      children: [
        PageTitle(title: 'Metas e caixinhas', subtitle: 'Acompanhe quanto já guardou, quanto falta e se suas metas estão no ritmo certo.', icon: Icons.savings),
        ResponsiveGrid(minWidth: 285, children: [
          SoftMetricCard(
            title: 'Total guardado',
            value: money(controller.goalsSaved),
            subtitle: 'Soma de todas as caixinhas que você já alimentou.',
            footer: '${goals.length} meta(s) cadastrada(s)',
            icon: Icons.savings,
            color: kGreen,
          ),
          SoftMetricCard(
            title: 'Objetivos totais',
            value: money(goals.fold(0.0, (s, g) => s + g.target)),
            subtitle: 'Valor final que você quer alcançar juntando todas as metas.',
            footer: 'planejamento geral',
            icon: Icons.flag,
            color: kBlue,
          ),
          SoftMetricCard(
            title: 'Patrimônio',
            value: money(controller.netWorth),
            subtitle: 'Seu saldo livre somado ao dinheiro guardado nas caixinhas.',
            footer: 'saldo + reservas',
            icon: Icons.diamond,
            color: kDark,
          ),
        ]),
        const SizedBox(height: 16),
        SectionCard(
          title: 'Suas metas',
          icon: Icons.flag,
          trailing: FilledButton.icon(onPressed: () => openGoalDialog(context, controller), icon: const Icon(Icons.add), label: const Text('Nova')),
          child: goals.isEmpty
              ? const Text('Nenhuma meta criada ainda.', style: TextStyle(color: kGray))
              : Column(children: goals.map((g) => GoalCard(controller: controller, goal: g)).toList()),
        ),
      ],
    );
  }
}

class GoalCard extends StatelessWidget {
  const GoalCard({super.key, required this.controller, required this.goal});

  final AppController controller;
  final Goal goal;

  @override
  Widget build(BuildContext context) {
    final progress = goal.target <= 0 ? 0.0 : (goal.saved / goal.target).clamp(0.0, 1.0).toDouble();
    final remaining = max(0.0, goal.target - goal.saved);
    final monthsLeft = max(1, ((goal.deadline.year - DateTime.now().year) * 12) + goal.deadline.month - DateTime.now().month);
    final needed = remaining / monthsLeft;
    final status = controller.goalStatus(goal);
    final color = status == 'concluída' || status == 'adiantado'
        ? kGreen
        : status == 'atrasado'
            ? kRed
            : kOrange;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: color.withValues(alpha: 0.22)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, color.withValues(alpha: 0.055)],
        ),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.06), blurRadius: 18, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: color.withValues(alpha: 0.13),
                child: Icon(goalIcon(goal.iconKey), color: color, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(goal.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 5),
                    Text('Prazo: ${monthLabel(goal.deadline)}', style: const TextStyle(color: kGray, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              PopupMenuButton<String>(
                tooltip: 'Opções da meta',
                onSelected: (value) async {
                  if (value == 'edit') openGoalDialog(context, controller, goal: goal);
                  if (value == 'deposit') openMoveGoalDialog(context, controller, goal, true);
                  if (value == 'withdraw') openMoveGoalDialog(context, controller, goal, false);
                  if (value == 'delete') await controller.deleteGoal(goal.id);
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'deposit', child: Text('Guardar dinheiro')),
                  PopupMenuItem(value: 'withdraw', child: Text('Retirar dinheiro')),
                  PopupMenuItem(value: 'edit', child: Text('Editar meta')),
                  PopupMenuItem(value: 'delete', child: Text('Excluir meta')),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              status.toUpperCase(),
              style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 12),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: Text('${percent(progress)} concluído', style: const TextStyle(color: kGray, fontWeight: FontWeight.w700))),
              Text('${money(goal.saved)} de ${money(goal.target)}', style: const TextStyle(fontWeight: FontWeight.w900)),
            ],
          ),
          const SizedBox(height: 10),
          ProgressLine(value: progress, color: color, height: 14),
          const SizedBox(height: 14),
          ResponsiveGrid(
            minWidth: 220,
            children: [
              _GoalInfoBox(icon: Icons.account_balance_wallet, label: 'Falta guardar', value: money(remaining), color: kBlue),
              _GoalInfoBox(icon: Icons.calendar_month, label: 'Plano mensal', value: money(goal.monthlyPlan), color: kGreen),
              _GoalInfoBox(icon: Icons.speed, label: 'Necessário/mês', value: money(needed), color: color),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton.icon(
                onPressed: () => openMoveGoalDialog(context, controller, goal, true),
                icon: const Icon(Icons.add),
                label: const Text('Guardar'),
              ),
              OutlinedButton.icon(
                onPressed: () => openMoveGoalDialog(context, controller, goal, false),
                icon: const Icon(Icons.remove),
                label: const Text('Retirar'),
              ),
              TextButton.icon(
                onPressed: () => openGoalDialog(context, controller, goal: goal),
                icon: const Icon(Icons.edit),
                label: const Text('Editar'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GoalInfoBox extends StatelessWidget {
  const _GoalInfoBox({required this.icon, required this.label, required this.value, required this.color});

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.075),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.14)),
      ),
      child: Row(
        children: [
          CircleAvatar(radius: 18, backgroundColor: color.withValues(alpha: 0.14), child: Icon(icon, color: color, size: 18)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: kGray, fontSize: 12, fontWeight: FontWeight.w700)),
                const SizedBox(height: 3),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(value, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> openGoalDialog(BuildContext context, AppController controller, {Goal? goal}) async {
  final name = TextEditingController(text: goal?.name ?? '');
  final target = TextEditingController(text: goal == null ? '' : goal.target.toStringAsFixed(2).replaceAll('.', ','));
  final saved = TextEditingController(text: goal == null ? '0' : goal.saved.toStringAsFixed(2).replaceAll('.', ','));
  final monthly = TextEditingController(text: goal == null ? '' : goal.monthlyPlan.toStringAsFixed(2).replaceAll('.', ','));
  DateTime deadline = goal?.deadline ?? DateTime(DateTime.now().year, DateTime.now().month + 6, 1);
  String iconKey = goal?.iconKey ?? 'savings';
  const icons = ['savings', 'computer', 'flight', 'school', 'phone', 'home', 'car', 'health', 'game', 'gift'];

  await showDialog(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        title: Text(goal == null ? 'Nova meta' : 'Editar meta'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: name, decoration: const InputDecoration(labelText: 'Nome da meta')),
              const SizedBox(height: 10),
              TextField(controller: target, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Valor objetivo')),
              const SizedBox(height: 10),
              TextField(controller: saved, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Valor já guardado')),
              const SizedBox(height: 10),
              TextField(controller: monthly, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Contribuição planejada por mês')),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () async {
                  final picked = await showDatePicker(context: context, firstDate: DateTime.now(), lastDate: DateTime(2038), initialDate: deadline);
                  if (picked != null) setDialogState(() => deadline = picked);
                },
                icon: const Icon(Icons.event),
                label: Text('Prazo: ${dateLabel(deadline)}'),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                children: icons.map((key) {
                  final selected = iconKey == key;
                  return InkWell(
                    onTap: () => setDialogState(() => iconKey = key),
                    borderRadius: BorderRadius.circular(99),
                    child: CircleAvatar(
                      backgroundColor: selected ? kGreen : Colors.grey.shade200,
                      child: Icon(goalIcon(key), color: selected ? Colors.white : kGray),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () async {
              final newGoal = Goal(
                id: goal?.id ?? generateId(),
                name: name.text.trim().isEmpty ? 'Meta' : name.text.trim(),
                target: moneyFromText(target.text),
                saved: moneyFromText(saved.text),
                deadline: deadline,
                monthlyPlan: moneyFromText(monthly.text),
                iconKey: iconKey,
              );
              if (newGoal.target <= 0) return;
              if (goal == null) {
                await controller.addGoal(newGoal);
              } else {
                await controller.updateGoal(newGoal);
              }
              if (dialogContext.mounted) Navigator.pop(dialogContext);
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    ),
  );
}

Future<void> openMoveGoalDialog(BuildContext context, AppController controller, Goal goal, bool deposit) async {
  final amount = TextEditingController();
  await showDialog(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(deposit ? 'Guardar em ${goal.name}' : 'Retirar de ${goal.name}'),
      content: TextField(
        controller: amount,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(labelText: deposit ? 'Valor para guardar' : 'Valor para retirar'),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancelar')),
        FilledButton(
          onPressed: () async {
            final error = await controller.moveGoalMoney(goal, moneyFromText(amount.text), deposit);
            if (dialogContext.mounted) {
              if (error != null) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(SnackBar(content: Text(error)));
              } else {
                Navigator.pop(dialogContext);
              }
            }
          },
          child: const Text('Confirmar'),
        ),
      ],
    ),
  );
}

/* ============================================================
   RELATÓRIOS
============================================================ */

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final months = controller.lastMonths(8);
    final current = controller.statsFor(controller.selectedMonth);
    final bestSaving = months.reduce((a, b) => a.result > b.result ? a : b);
    final worstExpense = months.reduce((a, b) => a.expense > b.expense ? a : b);

    return PageScaffold(
      children: [
        const PageTitle(title: 'Relatórios', subtitle: 'Compare meses, veja tendências e entenda seu comportamento.', icon: Icons.bar_chart),
        MonthPicker(controller: controller),
        const SizedBox(height: 14),
        ResponsiveGrid(minWidth: 285, children: [
          SoftMetricCard(
            title: 'Resultado do mês',
            value: money(current.result),
            subtitle: current.result >= 0 ? 'Entrou mais dinheiro do que saiu neste mês.' : 'Os gastos passaram das entradas neste mês.',
            footer: monthLabel(current.month),
            icon: current.result >= 0 ? Icons.sentiment_satisfied : Icons.sentiment_dissatisfied,
            color: current.result >= 0 ? kGreen : kRed,
          ),
          SoftMetricCard(
            title: 'Taxa de economia',
            value: percent(current.savingRate),
            subtitle: 'Mostra quanto sobrou em relação ao dinheiro que entrou.',
            footer: current.savingRate >= 0.2 ? 'bom ritmo' : 'atenção',
            icon: Icons.percent,
            color: current.savingRate >= 0.2 ? kGreen : kOrange,
          ),
          SoftMetricCard(
            title: 'Melhor mês',
            value: shortMonthLabel(bestSaving.month),
            subtitle: 'Mês com maior resultado positivo entre os últimos meses.',
            footer: money(bestSaving.result),
            icon: Icons.emoji_events,
            color: kBlue,
          ),
          SoftMetricCard(
            title: 'Mês mais caro',
            value: shortMonthLabel(worstExpense.month),
            subtitle: 'Mês em que suas saídas foram mais altas.',
            footer: money(worstExpense.expense),
            icon: Icons.warning,
            color: kRed,
          ),
        ]),
        const SizedBox(height: 16),
        SectionCard(title: 'Evolução dos últimos meses', icon: Icons.show_chart, child: MonthlyBars(months: months)),
        SectionCard(title: 'Gastos por categoria no mês', icon: Icons.pie_chart, child: CategoryRanking(controller: controller, month: controller.selectedMonth)),
        SectionCard(title: 'Comparativo detalhado', icon: Icons.compare_arrows, child: ComparisonTable(controller: controller, months: months)),
      ],
    );
  }
}

class MonthlyBars extends StatelessWidget {
  const MonthlyBars({super.key, required this.months});

  final List<MonthStats> months;

  @override
  Widget build(BuildContext context) {
    final maxValue = months.fold(0.0, (m, s) => max(m, max(s.income, s.expense)));
    return Column(
      children: months.map((m) {
        final positive = m.result >= 0;
        final resultColor = positive ? kGreen : kRed;
        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: resultColor.withValues(alpha: 0.045),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: resultColor.withValues(alpha: 0.14)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: resultColor.withValues(alpha: 0.12),
                    child: Icon(positive ? Icons.check_circle : Icons.warning_amber, color: resultColor),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(shortMonthLabel(m.month), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                        Text(positive ? 'Fechou positivo' : 'Gastou mais do que entrou', style: const TextStyle(color: kGray, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(money(m.result), style: TextStyle(color: resultColor, fontWeight: FontWeight.w900, fontSize: 18)),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _MonthEvolutionLine(label: 'Entradas', value: m.income, maxValue: maxValue, color: kGreen),
              const SizedBox(height: 9),
              _MonthEvolutionLine(label: 'Gastos', value: m.expense, maxValue: maxValue, color: kRed),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _MiniPill(text: 'Economia: ${percent(m.savingRate)}', color: m.savingRate >= 0.2 ? kGreen : kOrange),
                  _MiniPill(text: 'Orçamento: ${percent(m.budgetProgress)}', color: m.budgetProgress > 1 ? kRed : kBlue),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _MonthEvolutionLine extends StatelessWidget {
  const _MonthEvolutionLine({required this.label, required this.value, required this.maxValue, required this.color});

  final String label;
  final double value;
  final double maxValue;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: 78, child: Text(label, style: const TextStyle(color: kGray, fontWeight: FontWeight.w700))),
        Expanded(child: ProgressLine(value: maxValue <= 0 ? 0 : value / maxValue, color: color, height: 12)),
        const SizedBox(width: 10),
        SizedBox(
          width: 108,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Text(money(value), textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.w900)),
          ),
        ),
      ],
    );
  }
}

class _MiniPill extends StatelessWidget {
  const _MiniPill({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 12)),
    );
  }
}

class ComparisonTable extends StatelessWidget {
  const ComparisonTable({super.key, required this.controller, required this.months});

  final AppController controller;
  final List<MonthStats> months;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Mês')),
          DataColumn(label: Text('Entradas')),
          DataColumn(label: Text('Gastos')),
          DataColumn(label: Text('Resultado')),
          DataColumn(label: Text('Economia')),
          DataColumn(label: Text('Orçamento usado')),
        ],
        rows: months.reversed.map((m) {
          return DataRow(cells: [
            DataCell(Text(shortMonthLabel(m.month))),
            DataCell(Text(money(m.income))),
            DataCell(Text(money(m.expense))),
            DataCell(Text(money(m.result), style: TextStyle(color: m.result >= 0 ? kGreen : kRed, fontWeight: FontWeight.w800))),
            DataCell(Text(percent(m.savingRate))),
            DataCell(Text(percent(m.budgetProgress))),
          ]);
        }).toList(),
      ),
    );
  }
}

/* ============================================================
   CONFIGURAÇÕES
============================================================ */

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final user = controller.currentUser!;
    final note = user.notesByMonth[monthKey(controller.selectedMonth)] ?? '';
    final noteController = TextEditingController(text: note);

    return PageScaffold(
      children: [
        const PageTitle(
          title: 'Configurações',
          subtitle: 'Ajuste seu perfil e salve observações para entender melhor cada mês.',
          icon: Icons.settings,
        ),
        MonthPicker(controller: controller),
        const SizedBox(height: 14),
        SectionCard(
          title: 'Seu perfil',
          icon: Icons.person,
          child: Column(
            children: [
              KeyValueRow(label: 'Nome', value: user.name),
              KeyValueRow(label: 'Email', value: user.email),
              KeyValueRow(label: 'Saldo livre atual', value: money(controller.freeBalance)),
              KeyValueRow(label: 'Patrimônio atual', value: money(controller.netWorth)),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async { await controller.logout(); },
                  icon: const Icon(Icons.logout),
                  label: const Text('Sair da conta'),
                ),
              ),
            ],
          ),
        ),
        SectionCard(
          title: 'Observação do mês',
          icon: Icons.edit_note,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Use este espaço para anotar o que aconteceu no mês, onde você exagerou ou qual será seu foco.',
                style: TextStyle(color: kGray),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteController,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'Aprendizado ou foco do mês'),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () async {
                    await controller.saveMonthNote(noteController.text);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Observação salva.')),
                      );
                    }
                  },
                  icon: const Icon(Icons.save),
                  label: const Text('Salvar observação'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
