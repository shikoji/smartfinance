// SmartFinance Pro - versão local-first sem Firebase
// Substitua o arquivo lib/main.dart por este código.
// Antes de rodar, execute: flutter pub add shared_preferences

import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final repository = LocalRepository();
  final database = await repository.load();
  runApp(SmartFinanceApp(controller: AppController(repository, database)));
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

String id() {
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
  return DateTime(month.year, month.month, day.clamp(1, maxDay));
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
        'password': password,
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
        id: json['id'] ?? id(),
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
        id: json['id'] ?? id(),
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
        id: json['id'] ?? id(),
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
   REPOSITÓRIO LOCAL
============================================================ */

class LocalRepository {
  static const String storageKey = 'smartfinance_pro_local_v1';

  Future<AppDatabase> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(storageKey);
    if (raw == null || raw.trim().isEmpty) return seedDatabase();

    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final db = AppDatabase.fromJson(decoded);
      if (db.users.isEmpty) return seedDatabase();
      return db;
    } catch (_) {
      return seedDatabase();
    }
  }

  Future<void> save(AppDatabase database) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(storageKey, jsonEncode(database.toJson()));
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(storageKey);
  }
}

AppDatabase seedDatabase() {
  final demo = createDemoUser();
  return AppDatabase(users: {demo.email: demo});
}

FinanceUser createDemoUser() {
  final now = DateTime.now();
  final transactions = <MoneyTransaction>[];
  final budgets = <String, Map<String, double>>{};

  final random = Random(4);
  for (int i = 7; i >= 0; i--) {
    final m = DateTime(now.year, now.month - i, 1);
    final key = monthKey(m);
    budgets[key] = Map<String, double>.from(defaultBudgets);

    final baseIncome = 1450.0 + random.nextInt(350);
    transactions.add(MoneyTransaction(
      id: id(),
      amount: baseIncome,
      category: 'Trabalho',
      description: 'Bolsa/entrada principal',
      isIncome: true,
      date: safeDayInMonth(m, 5),
      tag: 'fixo',
    ));
    if (i % 2 == 0) {
      transactions.add(MoneyTransaction(
        id: id(),
        amount: 180.0 + random.nextInt(160),
        category: 'Trabalho',
        description: 'Freela ou ajuda extra',
        isIncome: true,
        date: safeDayInMonth(m, 18),
        tag: 'extra',
      ));
    }

    final expenses = <String, double>{
      'Moradia': 320 + random.nextInt(120).toDouble(),
      'Comida': 330 + random.nextInt(210).toDouble(),
      'Transporte': 120 + random.nextInt(120).toDouble(),
      'Estudos': 50 + random.nextInt(120).toDouble(),
      'Lazer': 60 + random.nextInt(180).toDouble(),
      'Compras': 70 + random.nextInt(240).toDouble(),
      'Saúde': 20 + random.nextInt(120).toDouble(),
      'Assinaturas': 59.90 + random.nextInt(50).toDouble(),
      'Caixinhas': 120 + random.nextInt(220).toDouble(),
      'Outros': 40 + random.nextInt(120).toDouble(),
    };

    int day = 2;
    for (final entry in expenses.entries) {
      transactions.add(MoneyTransaction(
        id: id(),
        amount: entry.value,
        category: entry.key,
        description: descriptionFor(entry.key),
        isIncome: false,
        date: safeDayInMonth(m, day),
        tag: entry.key == 'Assinaturas' ? 'recorrente' : '',
      ));
      day += 3;
    }
  }

  return FinanceUser(
    email: 'teste@gmail.com',
    password: '123456',
    name: 'Usuário Teste',
    initialBalance: 850,
    monthlyLimit: 2200,
    categories: List<String>.from(defaultCategories),
    defaultCategoryBudgets: Map<String, double>.from(defaultBudgets),
    transactions: transactions,
    goals: [
      Goal(
        id: id(),
        name: 'Notebook',
        target: 3500,
        saved: 1450,
        deadline: DateTime(now.year, now.month + 7, 1),
        monthlyPlan: 300,
        iconKey: 'computer',
      ),
      Goal(
        id: id(),
        name: 'Reserva de emergência',
        target: 2500,
        saved: 920,
        deadline: DateTime(now.year, now.month + 10, 1),
        monthlyPlan: 180,
        iconKey: 'health',
      ),
      Goal(
        id: id(),
        name: 'Viagem',
        target: 1800,
        saved: 410,
        deadline: DateTime(now.year, now.month + 5, 1),
        monthlyPlan: 220,
        iconKey: 'flight',
      ),
    ],
    recurringEntries: [
      RecurringEntry(
        id: id(),
        name: 'Internet',
        amount: 89.90,
        category: 'Assinaturas',
        isIncome: false,
        dayOfMonth: 10,
        active: true,
      ),
      RecurringEntry(
        id: id(),
        name: 'Spotify/streaming',
        amount: 21.90,
        category: 'Assinaturas',
        isIncome: false,
        dayOfMonth: 15,
        active: true,
      ),
      RecurringEntry(
        id: id(),
        name: 'Guardar na reserva',
        amount: 180,
        category: 'Caixinhas',
        isIncome: false,
        dayOfMonth: 6,
        active: true,
      ),
    ],
    monthBudgets: budgets,
    notesByMonth: {
      monthKey(now): 'Foco do mês: reduzir gastos com comida e manter as caixinhas em dia.',
    },
  );
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

  final LocalRepository repository;
  AppDatabase database;
  String? currentEmail;
  DateTime selectedMonth = monthStart(DateTime.now());

  FinanceUser? get currentUser =>
      currentEmail == null ? null : database.users[currentEmail!];

  bool get isLoggedIn => currentUser != null;

  Future<void> persist() async {
    await repository.save(database);
    notifyListeners();
  }

  bool login(String email, String password) {
    final normalized = email.trim().toLowerCase();
    final user = database.users[normalized];
    if (user == null) return false;
    if (user.password != password.trim()) return false;
    currentEmail = normalized;
    notifyListeners();
    return true;
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
    if (password.trim().length < 4) {
      return 'A senha precisa ter pelo menos 4 caracteres.';
    }
    if (database.users.containsKey(normalized)) return 'Este email já existe.';

    database.users[normalized] = FinanceUser(
      email: normalized,
      password: password.trim(),
      name: name.trim().isEmpty ? 'Usuário' : name.trim(),
      initialBalance: initialBalance,
      monthlyLimit: 1800,
      categories: List<String>.from(defaultCategories),
      defaultCategoryBudgets: Map<String, double>.from(defaultBudgets),
      transactions: [],
      goals: [],
      recurringEntries: [],
      monthBudgets: {monthKey(DateTime.now()): Map<String, double>.from(defaultBudgets)},
      notesByMonth: {},
    );
    await persist();
    return null;
  }

  void logout() {
    currentEmail = null;
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

  double get goalsSaved => currentUser!.goals.fold(0, (sum, g) => sum + g.saved);

  double get netWorth => freeBalance + goalsSaved;

  MonthStats statsFor(DateTime month) {
    final user = currentUser!;
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
            id: id(),
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
            id: id(),
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
        id: id(),
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

  Future<void> resetDemo() async {
    database = seedDatabase();
    currentEmail = 'teste@gmail.com';
    selectedMonth = monthStart(DateTime.now());
    await persist();
  }

  Future<String?> importJson(String raw) async {
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      database = AppDatabase.fromJson(decoded);
      if (database.users.isEmpty) return 'O JSON não possui usuários.';
      currentEmail = database.users.keys.first;
      await persist();
      return null;
    } catch (e) {
      return 'JSON inválido.';
    }
  }

  String exportJson() => const JsonEncoder.withIndent('  ').convert(database.toJson());

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
        cardTheme: CardThemeData(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
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
  final email = TextEditingController(text: 'teste@gmail.com');
  final password = TextEditingController(text: '123456');
  bool visible = false;

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  void submit() {
    final ok = widget.controller.login(email.text, password.text);
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
                        color: kGreen.withOpacity(0.12),
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
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: kBlue.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Text(
                        'Conta teste: teste@gmail.com / 123456',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontWeight: FontWeight.w700, color: kBlue),
                      ),
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
                      child: const Text('Criar nova conta local'),
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
      const SnackBar(content: Text('Conta local criada. Faça login.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kDark,
      appBar: AppBar(title: const Text('Criar conta local'), backgroundColor: kDark, foregroundColor: Colors.white),
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

  final pages = const [
    'Dashboard',
    'Lançamentos',
    'Planejamento',
    'Metas',
    'Relatórios',
    'Configurações',
  ];

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final isWide = MediaQuery.of(context).size.width >= 980;
    final screen = switch (index) {
      0 => DashboardScreen(controller: c),
      1 => TransactionsScreen(controller: c),
      2 => PlannerScreen(controller: c),
      3 => GoalsScreen(controller: c),
      4 => ReportsScreen(controller: c),
      _ => SettingsScreen(controller: c),
    };

    return Scaffold(
      body: Row(
        children: [
          if (isWide)
            NavigationRail(
              selectedIndex: index,
              onDestinationSelected: (i) => setState(() => index = i),
              backgroundColor: Colors.white,
              minWidth: 78,
              labelType: NavigationRailLabelType.all,
              leading: Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 20),
                child: CircleAvatar(
                  backgroundColor: kGreen.withOpacity(0.12),
                  child: const Icon(Icons.account_balance_wallet, color: kGreen),
                ),
              ),
              destinations: const [
                NavigationRailDestination(icon: Icon(Icons.dashboard), label: Text('Início')),
                NavigationRailDestination(icon: Icon(Icons.receipt_long), label: Text('Lançar')),
                NavigationRailDestination(icon: Icon(Icons.calendar_month), label: Text('Plano')),
                NavigationRailDestination(icon: Icon(Icons.savings), label: Text('Metas')),
                NavigationRailDestination(icon: Icon(Icons.bar_chart), label: Text('Relatórios')),
                NavigationRailDestination(icon: Icon(Icons.settings), label: Text('Config.')),
              ],
            ),
          Expanded(child: screen),
        ],
      ),
      bottomNavigationBar: isWide
          ? null
          : NavigationBar(
              selectedIndex: index,
              onDestinationSelected: (i) => setState(() => index = i),
              destinations: const [
                NavigationDestination(icon: Icon(Icons.dashboard), label: 'Início'),
                NavigationDestination(icon: Icon(Icons.receipt_long), label: 'Lançar'),
                NavigationDestination(icon: Icon(Icons.calendar_month), label: 'Plano'),
                NavigationDestination(icon: Icon(Icons.savings), label: 'Metas'),
                NavigationDestination(icon: Icon(Icons.bar_chart), label: 'Relatórios'),
                NavigationDestination(icon: Icon(Icons.settings), label: 'Config.'),
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
        padding: const EdgeInsets.all(20),
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
            CircleAvatar(backgroundColor: kGreen.withOpacity(0.12), child: Icon(icon, color: kGreen)),
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
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: LinearGradient(colors: [color, color.withOpacity(0.78)]),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.white, size: 30),
            const SizedBox(height: 14),
            Text(title, style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 6),
            Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20)),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(subtitle!, style: const TextStyle(color: Colors.white70, fontSize: 12)),
            ],
          ],
        ),
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
        value: value.clamp(0, 1),
        color: color,
        backgroundColor: color.withOpacity(0.13),
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
          title: 'Visão geral',
          subtitle: 'Olá, ${user.name}. Este é o fechamento de ${monthLabel(controller.selectedMonth)}.',
          icon: Icons.dashboard,
        ),
        MonthPicker(controller: controller),
        const SizedBox(height: 14),
        ResponsiveGrid(
          children: [
            SummaryCard(title: 'Saldo livre', value: money(controller.freeBalance), icon: Icons.account_balance_wallet, color: kDark),
            SummaryCard(title: 'Patrimônio', value: money(controller.netWorth), subtitle: 'saldo + caixinhas', icon: Icons.diamond, color: kBlue),
            SummaryCard(title: 'Entradas do mês', value: money(stats.income), subtitle: variationText(stats.income, prev.income), icon: Icons.trending_up, color: kGreen),
            SummaryCard(title: 'Gastos do mês', value: money(stats.expense), subtitle: variationText(stats.expense, prev.expense), icon: Icons.trending_down, color: kRed),
          ],
        ),
        const SizedBox(height: 16),
        SectionCard(
          title: 'Diagnóstico do mês',
          icon: Icons.psychology,
          child: Column(
            children: insights.map((text) => InsightTile(text: text)).toList(),
          ),
        ),
        SectionCard(
          title: 'Fechamento mensal',
          icon: Icons.fact_check,
          child: Column(
            children: [
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
          title: 'Orçamento geral do mês',
          icon: Icons.speed,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${money(stats.expense)} usados de ${money(stats.budgetTotal)}'),
              const SizedBox(height: 10),
              ProgressLine(value: stats.budgetProgress, color: stats.budgetProgress > 1 ? kRed : kOrange, height: 14),
              const SizedBox(height: 8),
              Text('${percent(stats.budgetProgress)} usado', style: TextStyle(color: stats.budgetProgress > 1 ? kRed : kOrange, fontWeight: FontWeight.w800)),
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

class InsightTile extends StatelessWidget {
  const InsightTile({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: kGreen.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kGreen.withOpacity(0.15)),
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
                  CircleAvatar(radius: 16, backgroundColor: color.withOpacity(0.12), child: Icon(categoryIcon(e.key), size: 17, color: color)),
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
                  CircleAvatar(backgroundColor: kGreen.withOpacity(0.12), child: Icon(goalIcon(g.iconKey), color: kGreen)),
                  const SizedBox(width: 10),
                  Expanded(child: Text(g.name, style: const TextStyle(fontWeight: FontWeight.w900))),
                  Chip(label: Text(status), backgroundColor: statusColor.withOpacity(0.12), labelStyle: TextStyle(color: statusColor, fontWeight: FontWeight.w800)),
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
    var list = c.transactionsOfMonth(c.selectedMonth);
    list = list.where((t) {
      final matchesSearch = search.trim().isEmpty ||
          t.description.toLowerCase().contains(search.toLowerCase()) ||
          t.category.toLowerCase().contains(search.toLowerCase()) ||
          t.tag.toLowerCase().contains(search.toLowerCase());
      final matchesType = type == 'Todos' || (type == 'Entradas' && t.isIncome) || (type == 'Saídas' && !t.isIncome);
      final matchesCategory = category == 'Todas' || t.category == category;
      return matchesSearch && matchesType && matchesCategory;
    }).toList();

    return PageScaffold(
      children: [
        PageTitle(title: 'Lançamentos', subtitle: 'Registre, edite, filtre e acompanhe o histórico mensal.', icon: Icons.receipt_long),
        MonthPicker(controller: c),
        const SizedBox(height: 14),
        SectionCard(
          title: 'Nova transação',
          icon: Icons.add_card,
          trailing: FilledButton.icon(
            onPressed: () => openTransactionDialog(context, c),
            icon: const Icon(Icons.add),
            label: const Text('Adicionar'),
          ),
          child: const Text('Use o botão para lançar entradas ou saídas com data, categoria, descrição e tag.', style: TextStyle(color: kGray)),
        ),
        SectionCard(
          title: 'Filtros',
          icon: Icons.filter_alt,
          child: Column(
            children: [
              TextField(
                decoration: const InputDecoration(labelText: 'Pesquisar por descrição, categoria ou tag', prefixIcon: Icon(Icons.search)),
                onChanged: (v) => setState(() => search = v),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: type,
                      items: ['Todos', 'Entradas', 'Saídas'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                      onChanged: (v) => setState(() => type = v ?? 'Todos'),
                      decoration: const InputDecoration(labelText: 'Tipo'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: category,
                      items: ['Todas', ...user.categories].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                      onChanged: (v) => setState(() => category = v ?? 'Todas'),
                      decoration: const InputDecoration(labelText: 'Categoria'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        SectionCard(
          title: 'Histórico de ${monthLabel(c.selectedMonth)}',
          icon: Icons.history,
          child: list.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(20),
                  child: Text('Nenhuma transação encontrada.', style: TextStyle(color: kGray)),
                )
              : Column(children: list.map((t) => TransactionTile(controller: c, transaction: t)).toList()),
        ),
      ],
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withOpacity(0.12),
            child: Icon(transaction.isIncome ? Icons.arrow_downward : categoryIcon(transaction.category), color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(transaction.description, style: const TextStyle(fontWeight: FontWeight.w900)),
                const SizedBox(height: 2),
                Wrap(
                  spacing: 8,
                  children: [
                    Text(transaction.category, style: const TextStyle(color: kGray)),
                    Text(dateLabel(transaction.date), style: const TextStyle(color: kGray)),
                    if (transaction.tag.isNotEmpty) Text('#${transaction.tag}', style: const TextStyle(color: kBlue, fontWeight: FontWeight.w700)),
                  ],
                ),
              ],
            ),
          ),
          Text(
            '${transaction.isIncome ? '+' : '-'}${money(transaction.amount)}',
            style: TextStyle(color: transaction.isIncome ? kGreen : kRed, fontWeight: FontWeight.w900),
          ),
          PopupMenuButton<String>(
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
    );
  }
}

Future<void> openTransactionDialog(BuildContext context, AppController controller, {MoneyTransaction? transaction}) async {
  final user = controller.currentUser!;
  final amount = TextEditingController(text: transaction == null ? '' : transaction.amount.toStringAsFixed(2).replaceAll('.', ','));
  final desc = TextEditingController(text: transaction?.description ?? '');
  final tag = TextEditingController(text: transaction?.tag ?? '');
  String category = transaction?.category ?? user.categories.first;
  bool isIncome = transaction?.isIncome ?? false;
  DateTime date = transaction?.date ?? DateTime.now();

  await showDialog(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(transaction == null ? 'Nova transação' : 'Editar transação'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: amount,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Valor', prefixIcon: Icon(Icons.attach_money)),
                  ),
                  const SizedBox(height: 10),
                  TextField(controller: desc, decoration: const InputDecoration(labelText: 'Descrição', prefixIcon: Icon(Icons.notes))),
                  const SizedBox(height: 10),
                  TextField(controller: tag, decoration: const InputDecoration(labelText: 'Tag opcional', prefixIcon: Icon(Icons.tag))),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: category,
                    items: user.categories.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                    onChanged: (v) => setDialogState(() => category = v ?? category),
                    decoration: const InputDecoration(labelText: 'Categoria'),
                  ),
                  const SizedBox(height: 10),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(isIncome ? 'Entrada' : 'Saída'),
                    value: isIncome,
                    onChanged: (v) => setDialogState(() => isIncome = v),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
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
                    label: Text(dateLabel(date)),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancelar')),
              FilledButton(
                onPressed: () async {
                  final value = moneyFromText(amount.text);
                  if (value <= 0) return;
                  final newTransaction = MoneyTransaction(
                    id: transaction?.id ?? id(),
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
                child: const Text('Salvar'),
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
                        CircleAvatar(radius: 16, backgroundColor: categoryColor(e.key).withOpacity(0.12), child: Icon(categoryIcon(e.key), size: 18, color: categoryColor(e.key))),
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
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$created recorrência(s) aplicadas.')));
                  }
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
              CircleAvatar(backgroundColor: color.withOpacity(0.12), child: Icon(e.isIncome ? Icons.trending_up : Icons.repeat, color: color)),
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
                id: entry?.id ?? id(),
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
        PageTitle(title: 'Metas e caixinhas', subtitle: 'Planeje objetivos com prazo, contribuição mensal e status.', icon: Icons.savings),
        ResponsiveGrid(children: [
          SummaryCard(title: 'Guardado', value: money(controller.goalsSaved), icon: Icons.savings, color: kGreen),
          SummaryCard(title: 'Objetivos totais', value: money(goals.fold(0.0, (s, g) => s + g.target)), icon: Icons.flag, color: kBlue),
          SummaryCard(title: 'Patrimônio', value: money(controller.netWorth), icon: Icons.diamond, color: kDark),
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
    final progress = goal.target <= 0 ? 0.0 : goal.saved / goal.target;
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
      margin: const EdgeInsets.only(bottom: 13),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.25)),
        color: color.withOpacity(0.04),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(backgroundColor: color.withOpacity(0.12), child: Icon(goalIcon(goal.iconKey), color: color)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(goal.name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
                  Text('Prazo: ${monthLabel(goal.deadline)}', style: const TextStyle(color: kGray)),
                ]),
              ),
              Chip(label: Text(status), backgroundColor: color.withOpacity(0.12), labelStyle: TextStyle(color: color, fontWeight: FontWeight.w900)),
              PopupMenuButton<String>(
                onSelected: (value) async {
                  if (value == 'edit') openGoalDialog(context, controller, goal: goal);
                  if (value == 'deposit') openMoveGoalDialog(context, controller, goal, true);
                  if (value == 'withdraw') openMoveGoalDialog(context, controller, goal, false);
                  if (value == 'delete') await controller.deleteGoal(goal.id);
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'deposit', child: Text('Guardar dinheiro')),
                  PopupMenuItem(value: 'withdraw', child: Text('Retirar dinheiro')),
                  PopupMenuItem(value: 'edit', child: Text('Editar')),
                  PopupMenuItem(value: 'delete', child: Text('Excluir')),
                ],
              ),
            ],
          ),
          const SizedBox(height: 13),
          ProgressLine(value: progress, color: color, height: 13),
          const SizedBox(height: 8),
          Row(
            children: [
              Text('${percent(progress)} • faltam ${money(remaining)}', style: const TextStyle(color: kGray)),
              const Spacer(),
              Text('${money(goal.saved)} / ${money(goal.target)}', style: const TextStyle(fontWeight: FontWeight.w900)),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
            child: Row(
              children: [
                Expanded(child: Text('Plano mensal: ${money(goal.monthlyPlan)}', style: const TextStyle(fontWeight: FontWeight.w700))),
                Expanded(child: Text('Necessário: ${money(needed)}/mês', textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.w700))),
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
                id: goal?.id ?? id(),
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
        ResponsiveGrid(children: [
          SummaryCard(title: 'Resultado do mês', value: money(current.result), icon: current.result >= 0 ? Icons.sentiment_satisfied : Icons.sentiment_dissatisfied, color: current.result >= 0 ? kGreen : kRed),
          SummaryCard(title: 'Taxa de economia', value: percent(current.savingRate), icon: Icons.percent, color: current.savingRate >= 0.2 ? kGreen : kOrange),
          SummaryCard(title: 'Melhor mês', value: shortMonthLabel(bestSaving.month), subtitle: money(bestSaving.result), icon: Icons.emoji_events, color: kBlue),
          SummaryCard(title: 'Mês mais caro', value: shortMonthLabel(worstExpense.month), subtitle: money(worstExpense.expense), icon: Icons.warning, color: kRed),
        ]),
        const SizedBox(height: 16),
        SectionCard(title: 'Evolução mês a mês', icon: Icons.show_chart, child: MonthlyBars(months: months)),
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
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [Expanded(child: Text(shortMonthLabel(m.month), style: const TextStyle(fontWeight: FontWeight.w900))), Text('Resultado: ${money(m.result)}', style: TextStyle(color: m.result >= 0 ? kGreen : kRed, fontWeight: FontWeight.w800))]),
              const SizedBox(height: 7),
              Row(children: [
                const SizedBox(width: 72, child: Text('Entradas', style: TextStyle(color: kGray))),
                Expanded(child: ProgressLine(value: maxValue <= 0 ? 0 : m.income / maxValue, color: kGreen)),
                const SizedBox(width: 8),
                SizedBox(width: 100, child: Text(money(m.income), textAlign: TextAlign.right)),
              ]),
              const SizedBox(height: 5),
              Row(children: [
                const SizedBox(width: 72, child: Text('Gastos', style: TextStyle(color: kGray))),
                Expanded(child: ProgressLine(value: maxValue <= 0 ? 0 : m.expense / maxValue, color: kRed)),
                const SizedBox(width: 8),
                SizedBox(width: 100, child: Text(money(m.expense), textAlign: TextAlign.right)),
              ]),
            ],
          ),
        );
      }).toList(),
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
   CONFIGURAÇÕES E BACKUP
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
        const PageTitle(title: 'Configurações', subtitle: 'Perfil, backup local, reset de demonstração e observações mensais.', icon: Icons.settings),
        MonthPicker(controller: controller),
        const SizedBox(height: 14),
        SectionCard(
          title: 'Perfil local',
          icon: Icons.person,
          child: Column(
            children: [
              KeyValueRow(label: 'Nome', value: user.name),
              KeyValueRow(label: 'Email', value: user.email),
              KeyValueRow(label: 'Saldo livre atual', value: money(controller.freeBalance)),
              KeyValueRow(label: 'Patrimônio atual', value: money(controller.netWorth)),
              const SizedBox(height: 10),
              SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: controller.logout, icon: const Icon(Icons.logout), label: const Text('Sair da conta'))),
            ],
          ),
        ),
        SectionCard(
          title: 'Observação do mês',
          icon: Icons.edit_note,
          child: Column(
            children: [
              TextField(
                controller: noteController,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'Escreva seu foco, problema ou aprendizado do mês'),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () async => controller.saveMonthNote(noteController.text),
                  icon: const Icon(Icons.save),
                  label: const Text('Salvar observação'),
                ),
              ),
            ],
          ),
        ),
        SectionCard(
          title: 'Backup e dados locais',
          icon: Icons.backup,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Por enquanto, sem Firebase, os dados ficam salvos no navegador deste dispositivo. Use exportar/importar para backup manual.', style: TextStyle(color: kGray)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  FilledButton.icon(onPressed: () => openExportDialog(context, controller), icon: const Icon(Icons.download), label: const Text('Exportar JSON')),
                  OutlinedButton.icon(onPressed: () => openImportDialog(context, controller), icon: const Icon(Icons.upload), label: const Text('Importar JSON')),
                  OutlinedButton.icon(onPressed: () async => controller.resetDemo(), icon: const Icon(Icons.restart_alt), label: const Text('Recarregar demo')),
                ],
              ),
            ],
          ),
        ),
        SectionCard(
          title: 'Próxima etapa: Firebase',
          icon: Icons.cloud,
          child: const Text(
            'Quando este site estiver do jeito que você quer, a próxima fase é trocar o repositório local por Firebase Authentication + Firestore. A estrutura deste código já separa dados, controller e interface para facilitar essa troca.',
            style: TextStyle(color: kGray),
          ),
        ),
      ],
    );
  }
}

Future<void> openExportDialog(BuildContext context, AppController controller) async {
  final export = controller.exportJson();
  await showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Backup JSON'),
      content: SizedBox(
        width: 700,
        child: TextField(
          controller: TextEditingController(text: export),
          maxLines: 15,
          readOnly: true,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
      ),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Fechar'))],
    ),
  );
}

Future<void> openImportDialog(BuildContext context, AppController controller) async {
  final text = TextEditingController();
  await showDialog(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Importar JSON'),
      content: SizedBox(
        width: 700,
        child: TextField(
          controller: text,
          maxLines: 12,
          decoration: const InputDecoration(labelText: 'Cole o JSON exportado aqui'),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancelar')),
        FilledButton(
          onPressed: () async {
            final error = await controller.importJson(text.text);
            if (dialogContext.mounted) {
              if (error != null) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(SnackBar(content: Text(error)));
              } else {
                Navigator.pop(dialogContext);
              }
            }
          },
          child: const Text('Importar'),
        ),
      ],
    ),
  );
}
