import 'package:flutter/material.dart';

void main() {
  runApp(const SmartFinanceApp());
}

/*
  SMARTFINANCE - VERSÃO TURBINADA

  Novidades principais:
  - Múltiplas metas/caixinhas simultâneas
  - Guardar e retirar dinheiro de cada caixinha
  - Progresso individual e progresso geral das metas
  - Histórico com descrição, data, edição e exclusão
  - Filtro de transações por tipo
  - Relatório por categoria
  - Limite mensal de gastos
  - Dicas automáticas de economia
  - Tela de configurações
  - Simulação de banco de dados por usuário

  Observação:
  Os dados ainda são simulados em memória.
  Quando fechar o app, os dados voltam ao estado inicial.
  No próximo bimestre, isso pode ser trocado por API ou banco local.
*/

String usuarioLogado = "";

int contadorIds = 100;

String gerarId() {
  contadorIds++;
  return "${DateTime.now().millisecondsSinceEpoch}_$contadorIds";
}

double lerValor(String texto) {
  return double.tryParse(texto.trim().replaceAll(",", ".")) ?? 0;
}

String moeda(double valor) {
  return "R\$ ${valor.toStringAsFixed(2).replaceAll(".", ",")}";
}

bool mesmoMes(DateTime data) {
  DateTime agora = DateTime.now();
  return data.month == agora.month && data.year == agora.year;
}

final Map<String, Map<String, dynamic>> bancoUsuarios = {
  "teste@gmail.com": {
    "senha": "123456",
    "saldo": 1250.0,
    "limiteMensal": 900.0,
    "metas": <Map<String, dynamic>>[
      {
        "id": "m1",
        "nome": "Notebook",
        "objetivo": 3000.0,
        "guardado": 850.0,
        "icone": Icons.computer,
      },
      {
        "id": "m2",
        "nome": "Viagem",
        "objetivo": 1200.0,
        "guardado": 300.0,
        "icone": Icons.flight_takeoff,
      },
      {
        "id": "m3",
        "nome": "Emergência",
        "objetivo": 1000.0,
        "guardado": 200.0,
        "icone": Icons.health_and_safety,
      },
    ],
    "transacoes": <Map<String, dynamic>>[
      {
        "id": "t1",
        "valor": 500.0,
        "categoria": "Estudos",
        "descricao": "Bolsa/ajuda de estudos",
        "ganho": true,
        "data": DateTime.now().subtract(const Duration(days: 3)),
      },
      {
        "id": "t2",
        "valor": 80.0,
        "categoria": "Transporte",
        "descricao": "Ônibus e deslocamento",
        "ganho": false,
        "data": DateTime.now().subtract(const Duration(days: 2)),
      },
      {
        "id": "t3",
        "valor": 120.0,
        "categoria": "Comida",
        "descricao": "Lanches da semana",
        "ganho": false,
        "data": DateTime.now().subtract(const Duration(days: 1)),
      },
      {
        "id": "t4",
        "valor": 950.0,
        "categoria": "Outros",
        "descricao": "Entrada extra",
        "ganho": true,
        "data": DateTime.now(),
      },
    ],
  },
};

class SmartFinanceApp extends StatelessWidget {
  const SmartFinanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "SmartFinance",
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xfff5f6fa),
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green,
          brightness: Brightness.light,
        ),
      ),
      home: const LoginPage(),
    );
  }
}

/* ---------------- LOGIN ---------------- */

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController email = TextEditingController(text: "teste@gmail.com");
  final TextEditingController senha = TextEditingController(text: "123456");

  bool senhaVisivel = false;

  @override
  void dispose() {
    email.dispose();
    senha.dispose();
    super.dispose();
  }

  void entrar() {
    String emailDigitado = email.text.trim();
    String senhaDigitada = senha.text.trim();

    if (emailDigitado.isEmpty || senhaDigitada.isEmpty) {
      aviso("Preencha o email e a senha");
      return;
    }

    if (bancoUsuarios.containsKey(emailDigitado) &&
        bancoUsuarios[emailDigitado]!["senha"] == senhaDigitada) {
      usuarioLogado = emailDigitado;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const FinanceHome(),
        ),
      );
    } else {
      aviso("Email ou senha incorretos");
    }
  }

  void aviso(String texto) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(texto)),
    );
  }

  Future<void> irCadastro() async {
    final cadastrado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => const CadastroPage(),
      ),
    );

    if (!mounted) return;

    if (cadastrado == true) {
      aviso("Conta criada com sucesso! Faça login.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Container(
            width: 390,
            padding: const EdgeInsets.all(25),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black38,
                  blurRadius: 20,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.account_balance_wallet,
                  size: 60,
                  color: Colors.green,
                ),
                const SizedBox(height: 10),
                const Text(
                  "SmartFinance",
                  style: TextStyle(
                    fontSize: 31,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  "Controle seus ganhos, gastos e caixinhas",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 25),
                TextField(
                  controller: email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: "Email",
                    prefixIcon: Icon(Icons.email),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: senha,
                  obscureText: !senhaVisivel,
                  decoration: InputDecoration(
                    labelText: "Senha",
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        senhaVisivel ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          senhaVisivel = !senhaVisivel;
                        });
                      },
                    ),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Conta de teste: teste@gmail.com / 123456",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black45,
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: entrar,
                    icon: const Icon(Icons.login),
                    label: const Text("Entrar"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: irCadastro,
                  child: const Text("Criar conta"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/* ---------------- CADASTRO ---------------- */

class CadastroPage extends StatefulWidget {
  const CadastroPage({super.key});

  @override
  State<CadastroPage> createState() => _CadastroPageState();
}

class _CadastroPageState extends State<CadastroPage> {
  final TextEditingController email = TextEditingController();
  final TextEditingController senha = TextEditingController();
  final TextEditingController saldoInicial = TextEditingController();

  bool senhaVisivel = false;

  @override
  void dispose() {
    email.dispose();
    senha.dispose();
    saldoInicial.dispose();
    super.dispose();
  }

  void aviso(String texto) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(texto)),
    );
  }

  void cadastrar() {
    String emailDigitado = email.text.trim();
    String senhaDigitada = senha.text.trim();
    double saldo = lerValor(saldoInicial.text);

    if (emailDigitado.isEmpty || senhaDigitada.isEmpty) {
      aviso("Preencha email e senha");
      return;
    }

    if (!emailDigitado.contains("@") || !emailDigitado.contains(".")) {
      aviso("Digite um email válido");
      return;
    }

    if (senhaDigitada.length < 4) {
      aviso("A senha precisa ter pelo menos 4 caracteres");
      return;
    }

    if (bancoUsuarios.containsKey(emailDigitado)) {
      aviso("Este email já foi cadastrado");
      return;
    }

    bancoUsuarios[emailDigitado] = {
      "senha": senhaDigitada,
      "saldo": saldo,
      "limiteMensal": 800.0,
      "metas": <Map<String, dynamic>>[],
      "transacoes": <Map<String, dynamic>>[],
    };

    Navigator.pop(context, true);
  }

  void voltarLogin() {
    Navigator.pop(context, false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Container(
            width: 390,
            padding: const EdgeInsets.all(25),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.person_add,
                  size: 55,
                  color: Colors.green,
                ),
                const SizedBox(height: 10),
                const Text(
                  "Criar conta",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  "Cadastre-se para começar a controlar suas finanças",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 25),
                TextField(
                  controller: email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: "Email",
                    prefixIcon: Icon(Icons.email),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: senha,
                  obscureText: !senhaVisivel,
                  decoration: InputDecoration(
                    labelText: "Senha",
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        senhaVisivel ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          senhaVisivel = !senhaVisivel;
                        });
                      },
                    ),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: saldoInicial,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: "Saldo inicial opcional",
                    prefixIcon: Icon(Icons.savings),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: cadastrar,
                    icon: const Icon(Icons.check),
                    label: const Text("Cadastrar"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: voltarLogin,
                  child: const Text("Voltar para login"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/* ---------------- HOME ---------------- */

class FinanceHome extends StatefulWidget {
  const FinanceHome({super.key});

  @override
  State<FinanceHome> createState() => _FinanceHomeState();
}

class _FinanceHomeState extends State<FinanceHome> {
  int abaAtual = 0;

  final TextEditingController valorController = TextEditingController();
  final TextEditingController descricaoController = TextEditingController();
  final TextEditingController limiteController = TextEditingController();
  final TextEditingController pesquisaController = TextEditingController();

  String categoria = "Comida";
  String filtroTipo = "Todos";

  final List<String> categorias = [
    "Comida",
    "Transporte",
    "Lazer",
    "Estudos",
    "Compras",
    "Saúde",
    "Casa",
    "Assinaturas",
    "Trabalho",
    "Outros",
  ];

  final List<IconData> iconesMetas = [
    Icons.savings,
    Icons.computer,
    Icons.flight_takeoff,
    Icons.school,
    Icons.phone_android,
    Icons.home,
    Icons.directions_car,
    Icons.health_and_safety,
    Icons.sports_esports,
    Icons.card_giftcard,
  ];

  Map<String, dynamic> get dados => bancoUsuarios[usuarioLogado]!;

  List<Map<String, dynamic>> get transacoes {
    return dados["transacoes"] as List<Map<String, dynamic>>;
  }

  List<Map<String, dynamic>> get metas {
    return dados["metas"] as List<Map<String, dynamic>>;
  }

  @override
  void dispose() {
    valorController.dispose();
    descricaoController.dispose();
    limiteController.dispose();
    pesquisaController.dispose();
    super.dispose();
  }

  void aviso(String texto) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(texto)),
    );
  }

  double calcularGanhos({bool somenteMes = false}) {
    double total = 0;

    for (Map<String, dynamic> t in transacoes) {
      DateTime data = t["data"] as DateTime;

      if (t["ganho"] == true && (!somenteMes || mesmoMes(data))) {
        total += t["valor"] as double;
      }
    }

    return total;
  }

  double calcularGastos({bool somenteMes = false}) {
    double total = 0;

    for (Map<String, dynamic> t in transacoes) {
      DateTime data = t["data"] as DateTime;

      if (t["ganho"] == false && (!somenteMes || mesmoMes(data))) {
        total += t["valor"] as double;
      }
    }

    return total;
  }

  double totalGuardadoMetas() {
    double total = 0;

    for (Map<String, dynamic> meta in metas) {
      total += meta["guardado"] as double;
    }

    return total;
  }

  double totalObjetivosMetas() {
    double total = 0;

    for (Map<String, dynamic> meta in metas) {
      total += meta["objetivo"] as double;
    }

    return total;
  }

  double patrimonioTotal() {
    return (dados["saldo"] as double) + totalGuardadoMetas();
  }

  double progressoGeralMetas() {
    double objetivo = totalObjetivosMetas();

    if (objetivo <= 0) {
      return 0;
    }

    return (totalGuardadoMetas() / objetivo).clamp(0.0, 1.0).toDouble();
  }

  void adicionarTransacao(bool ganho) {
    double valor = lerValor(valorController.text);

    if (valor <= 0) {
      aviso("Digite um valor válido");
      return;
    }

    String descricao = descricaoController.text.trim();

    setState(() {
      double saldoAtual = dados["saldo"] as double;
      dados["saldo"] = ganho ? saldoAtual + valor : saldoAtual - valor;

      transacoes.add({
        "id": gerarId(),
        "valor": valor,
        "categoria": categoria,
        "descricao": descricao.isEmpty ? "Sem descrição" : descricao,
        "ganho": ganho,
        "data": DateTime.now(),
      });
    });

    valorController.clear();
    descricaoController.clear();

    aviso(ganho ? "Ganho adicionado" : "Gasto adicionado");
  }

  void excluirTransacao(Map<String, dynamic> transacao) {
    bool ganho = transacao["ganho"] as bool;
    double valor = transacao["valor"] as double;

    setState(() {
      double saldoAtual = dados["saldo"] as double;

      // Se a transação era ganho, remover ela diminui o saldo.
      // Se era gasto, remover ela devolve o valor ao saldo.
      dados["saldo"] = ganho ? saldoAtual - valor : saldoAtual + valor;

      transacoes.removeWhere((t) => t["id"] == transacao["id"]);
    });

    aviso("Transação excluída");
  }

  Future<void> editarTransacao(Map<String, dynamic> transacao) async {
    final TextEditingController valorEdit = TextEditingController(
      text: (transacao["valor"] as double).toStringAsFixed(2),
    );

    final TextEditingController descricaoEdit = TextEditingController(
      text: transacao["descricao"] as String,
    );

    String categoriaEdit = transacao["categoria"] as String;
    bool ganhoEdit = transacao["ganho"] as bool;

    final bool? salvou = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: const Text("Editar transação"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: valorEdit,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: "Valor",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descricaoEdit,
                      decoration: const InputDecoration(
                        labelText: "Descrição",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: categoriaEdit,
                      decoration: const InputDecoration(
                        labelText: "Categoria",
                        border: OutlineInputBorder(),
                      ),
                      items: categorias.map((c) {
                        return DropdownMenuItem<String>(
                          value: c,
                          child: Text(c),
                        );
                      }).toList(),
                      onChanged: (v) {
                        if (v == null) return;
                        setDialogState(() {
                          categoriaEdit = v;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(ganhoEdit ? "Entrada" : "Saída"),
                      value: ganhoEdit,
                      onChanged: (v) {
                        setDialogState(() {
                          ganhoEdit = v;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text("Cancelar"),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  child: const Text("Salvar"),
                ),
              ],
            );
          },
        );
      },
    );

    if (salvou != true) {
      valorEdit.dispose();
      descricaoEdit.dispose();
      return;
    }

    double novoValor = lerValor(valorEdit.text);

    if (novoValor <= 0) {
      aviso("Valor inválido");
      valorEdit.dispose();
      descricaoEdit.dispose();
      return;
    }

    setState(() {
      double saldoAtual = dados["saldo"] as double;

      // desfaz o efeito antigo
      bool ganhoAntigo = transacao["ganho"] as bool;
      double valorAntigo = transacao["valor"] as double;
      saldoAtual = ganhoAntigo ? saldoAtual - valorAntigo : saldoAtual + valorAntigo;

      // aplica o novo efeito
      saldoAtual = ganhoEdit ? saldoAtual + novoValor : saldoAtual - novoValor;

      dados["saldo"] = saldoAtual;
      transacao["valor"] = novoValor;
      transacao["categoria"] = categoriaEdit;
      transacao["descricao"] = descricaoEdit.text.trim().isEmpty
          ? "Sem descrição"
          : descricaoEdit.text.trim();
      transacao["ganho"] = ganhoEdit;
    });

    valorEdit.dispose();
    descricaoEdit.dispose();

    aviso("Transação atualizada");
  }

  void limparHistorico() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text("Limpar histórico"),
          content: const Text(
            "Isso vai apagar todas as transações, mas não vai mexer no saldo atual. Deseja continuar?",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text("Cancelar"),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  transacoes.clear();
                });

                Navigator.pop(dialogContext);
                aviso("Histórico limpo");
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text("Apagar"),
            ),
          ],
        );
      },
    );
  }

  Future<void> criarOuEditarMeta({Map<String, dynamic>? meta}) async {
    final TextEditingController nomeController = TextEditingController(
      text: meta == null ? "" : meta["nome"] as String,
    );

    final TextEditingController objetivoController = TextEditingController(
      text: meta == null ? "" : (meta["objetivo"] as double).toStringAsFixed(2),
    );

    IconData iconeEscolhido = meta == null ? Icons.savings : meta["icone"] as IconData;

    final bool? salvou = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: Text(meta == null ? "Nova caixinha" : "Editar caixinha"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nomeController,
                      decoration: const InputDecoration(
                        labelText: "Nome da meta",
                        hintText: "Ex: Celular, viagem, emergência...",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: objetivoController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: "Valor objetivo",
                        prefixIcon: Icon(Icons.flag),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 15),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Escolha um ícone",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: iconesMetas.map((icone) {
                        bool selecionado = icone == iconeEscolhido;

                        return InkWell(
                          onTap: () {
                            setDialogState(() {
                              iconeEscolhido = icone;
                            });
                          },
                          borderRadius: BorderRadius.circular(100),
                          child: CircleAvatar(
                            backgroundColor: selecionado ? Colors.green : Colors.grey.shade200,
                            child: Icon(
                              icone,
                              color: selecionado ? Colors.white : Colors.black54,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text("Cancelar"),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  child: const Text("Salvar"),
                ),
              ],
            );
          },
        );
      },
    );

    if (salvou != true) {
      nomeController.dispose();
      objetivoController.dispose();
      return;
    }

    String nome = nomeController.text.trim();
    double objetivo = lerValor(objetivoController.text);

    if (nome.isEmpty) {
      aviso("Digite um nome para a meta");
      nomeController.dispose();
      objetivoController.dispose();
      return;
    }

    if (objetivo <= 0) {
      aviso("Digite um valor objetivo válido");
      nomeController.dispose();
      objetivoController.dispose();
      return;
    }

    setState(() {
      if (meta == null) {
        metas.add({
          "id": gerarId(),
          "nome": nome,
          "objetivo": objetivo,
          "guardado": 0.0,
          "icone": iconeEscolhido,
        });
      } else {
        meta["nome"] = nome;
        meta["objetivo"] = objetivo;
        meta["icone"] = iconeEscolhido;
      }
    });

    nomeController.dispose();
    objetivoController.dispose();

    aviso(meta == null ? "Caixinha criada" : "Caixinha atualizada");
  }

  Future<void> movimentarMeta(
    Map<String, dynamic> meta, {
    required bool guardar,
  }) async {
    final TextEditingController valorMeta = TextEditingController();

    final bool? confirmou = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(guardar ? "Guardar dinheiro" : "Retirar dinheiro"),
          content: TextField(
            controller: valorMeta,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: guardar ? "Valor para guardar" : "Valor para retirar",
              prefixIcon: Icon(guardar ? Icons.savings : Icons.outbox),
              border: const OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text("Cancelar"),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text("Confirmar"),
            ),
          ],
        );
      },
    );

    if (confirmou != true) {
      valorMeta.dispose();
      return;
    }

    double valor = lerValor(valorMeta.text);
    valorMeta.dispose();

    if (valor <= 0) {
      aviso("Digite um valor válido");
      return;
    }

    double saldo = dados["saldo"] as double;
    double guardado = meta["guardado"] as double;

    if (guardar && valor > saldo) {
      aviso("Saldo insuficiente para guardar esse valor");
      return;
    }

    if (!guardar && valor > guardado) {
      aviso("Essa caixinha não possui esse valor guardado");
      return;
    }

    setState(() {
      if (guardar) {
        dados["saldo"] = saldo - valor;
        meta["guardado"] = guardado + valor;

        transacoes.add({
          "id": gerarId(),
          "valor": valor,
          "categoria": "Caixinhas",
          "descricao": "Dinheiro guardado em ${meta["nome"]}",
          "ganho": false,
          "data": DateTime.now(),
        });
      } else {
        dados["saldo"] = saldo + valor;
        meta["guardado"] = guardado - valor;

        transacoes.add({
          "id": gerarId(),
          "valor": valor,
          "categoria": "Caixinhas",
          "descricao": "Resgate da caixinha ${meta["nome"]}",
          "ganho": true,
          "data": DateTime.now(),
        });
      }
    });

    aviso(guardar ? "Valor guardado na caixinha" : "Valor retirado da caixinha");
  }

  void excluirMeta(Map<String, dynamic> meta) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text("Excluir caixinha"),
          content: Text(
            "Deseja excluir a caixinha '${meta["nome"]}'? "
            "O valor guardado voltará para o saldo disponível.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text("Cancelar"),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  double saldo = dados["saldo"] as double;
                  double guardado = meta["guardado"] as double;

                  dados["saldo"] = saldo + guardado;
                  metas.removeWhere((m) => m["id"] == meta["id"]);
                });

                Navigator.pop(dialogContext);
                aviso("Caixinha excluída");
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text("Excluir"),
            ),
          ],
        );
      },
    );
  }

  void atualizarLimite() {
    double novoLimite = lerValor(limiteController.text);

    if (novoLimite <= 0) {
      aviso("Digite um limite mensal válido");
      return;
    }

    setState(() {
      dados["limiteMensal"] = novoLimite;
    });

    limiteController.clear();
    aviso("Limite mensal atualizado");
  }

  void sair() {
    usuarioLogado = "";

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const LoginPage(),
      ),
    );
  }

  List<Map<String, dynamic>> transacoesFiltradas() {
    String busca = pesquisaController.text.trim().toLowerCase();

    List<Map<String, dynamic>> lista = transacoes.where((t) {
      bool ganho = t["ganho"] as bool;
      String categoriaT = (t["categoria"] as String).toLowerCase();
      String descricaoT = (t["descricao"] as String).toLowerCase();

      bool bateTipo = filtroTipo == "Todos" ||
          (filtroTipo == "Ganhos" && ganho) ||
          (filtroTipo == "Gastos" && !ganho);

      bool bateBusca = busca.isEmpty ||
          categoriaT.contains(busca) ||
          descricaoT.contains(busca);

      return bateTipo && bateBusca;
    }).toList();

    lista.sort((a, b) {
      DateTime dataA = a["data"] as DateTime;
      DateTime dataB = b["data"] as DateTime;
      return dataB.compareTo(dataA);
    });

    return lista;
  }

  Map<String, double> gastosPorCategoria({bool somenteMes = false}) {
    Map<String, double> resultado = {};

    for (Map<String, dynamic> t in transacoes) {
      bool ganho = t["ganho"] as bool;
      DateTime data = t["data"] as DateTime;

      if (ganho) continue;
      if (somenteMes && !mesmoMes(data)) continue;

      String categoriaT = t["categoria"] as String;
      double valor = t["valor"] as double;

      resultado[categoriaT] = (resultado[categoriaT] ?? 0) + valor;
    }

    return resultado;
  }

  Widget cardResumo({
    required String titulo,
    required String valor,
    required IconData icone,
    required Color cor,
    String? subtitulo,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            icone,
            color: Colors.white,
            size: 30,
          ),
          const SizedBox(height: 10),
          Text(
            titulo,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            valor,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          if (subtitulo != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitulo,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white70,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget secao({
    required String titulo,
    required Widget child,
    IconData? icone,
    Widget? trailing,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icone != null) ...[
                Icon(icone, color: Colors.green),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  titulo,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget dicaAutomatica() {
    double saldo = dados["saldo"] as double;
    double gastosMes = calcularGastos(somenteMes: true);
    double limite = dados["limiteMensal"] as double;
    double progressoLimite = limite <= 0 ? 0 : gastosMes / limite;
    int metasConcluidas = metas.where((m) {
      return (m["guardado"] as double) >= (m["objetivo"] as double);
    }).length;

    IconData icone = Icons.lightbulb;
    Color cor = Colors.amber;
    String texto = "Boa! Continue registrando seus gastos para ter um controle melhor.";

    if (saldo < 0) {
      icone = Icons.warning;
      cor = Colors.red;
      texto = "Seu saldo ficou negativo. Tente reduzir gastos e priorizar entradas.";
    } else if (progressoLimite >= 1) {
      icone = Icons.error;
      cor = Colors.red;
      texto = "Você passou do limite mensal. Evite novas compras não essenciais.";
    } else if (progressoLimite >= 0.8) {
      icone = Icons.warning_amber;
      cor = Colors.orange;
      texto = "Você já usou mais de 80% do limite mensal. Atenção com os próximos gastos.";
    } else if (metasConcluidas > 0) {
      icone = Icons.emoji_events;
      cor = Colors.green;
      texto = "Parabéns! Você concluiu $metasConcluidas meta(s).";
    }

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: cor.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Icon(icone, color: cor),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              texto,
              style: TextStyle(
                color: cor == Colors.amber ? Colors.black87 : cor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget formularioTransacao() {
    return Column(
      children: [
        TextField(
          controller: valorController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: "Valor",
            prefixIcon: Icon(Icons.attach_money),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: descricaoController,
          decoration: const InputDecoration(
            labelText: "Descrição",
            hintText: "Ex: lanche, salário, ônibus...",
            prefixIcon: Icon(Icons.notes),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          initialValue: categoria,
          decoration: const InputDecoration(
            labelText: "Categoria",
            prefixIcon: Icon(Icons.category),
            border: OutlineInputBorder(),
          ),
          items: categorias.map((c) {
            return DropdownMenuItem<String>(
              value: c,
              child: Text(c),
            );
          }).toList(),
          onChanged: (v) {
            if (v == null) return;

            setState(() {
              categoria = v;
            });
          },
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => adicionarTransacao(true),
                icon: const Icon(Icons.add),
                label: const Text("Ganho"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => adicionarTransacao(false),
                icon: const Icon(Icons.remove),
                label: const Text("Gasto"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget cardMeta(Map<String, dynamic> meta) {
    double objetivo = meta["objetivo"] as double;
    double guardado = meta["guardado"] as double;
    double progresso = objetivo <= 0 ? 0 : (guardado / objetivo).clamp(0.0, 1.0).toDouble();
    bool concluida = guardado >= objetivo;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: concluida ? Colors.green.withValues(alpha: 0.09) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: concluida ? Colors.green : Colors.grey.shade300,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: concluida ? Colors.green : Colors.green.withValues(alpha: 0.13),
                child: Icon(
                  meta["icone"] as IconData,
                  color: concluida ? Colors.white : Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      meta["nome"] as String,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "${moeda(guardado)} de ${moeda(objetivo)}",
                      style: const TextStyle(color: Colors.black54),
                    ),
                  ],
                ),
              ),
              if (concluida)
                const Chip(
                  label: Text("Concluída"),
                  backgroundColor: Color(0xffd8f5df),
                ),
              PopupMenuButton<String>(
                onSelected: (opcao) {
                  if (opcao == "editar") {
                    criarOuEditarMeta(meta: meta);
                  } else if (opcao == "excluir") {
                    excluirMeta(meta);
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: "editar",
                    child: Text("Editar"),
                  ),
                  PopupMenuItem(
                    value: "excluir",
                    child: Text("Excluir"),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: progresso,
              minHeight: 12,
              color: concluida ? Colors.green : Colors.blue,
              backgroundColor: Colors.grey.shade300,
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              "${(progresso * 100).toStringAsFixed(1)}%",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: concluida ? Colors.green : Colors.blue,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => movimentarMeta(meta, guardar: false),
                  icon: const Icon(Icons.outbox),
                  label: const Text("Retirar"),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => movimentarMeta(meta, guardar: true),
                  icon: const Icon(Icons.savings),
                  label: const Text("Guardar"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget listaMetas({bool resumida = false}) {
    if (metas.isEmpty) {
      return Column(
        children: [
          const Text(
            "Nenhuma caixinha criada ainda.",
            style: TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            onPressed: () => criarOuEditarMeta(),
            icon: const Icon(Icons.add),
            label: const Text("Criar primeira caixinha"),
          ),
        ],
      );
    }

    List<Map<String, dynamic>> lista = resumida ? metas.take(3).toList() : metas;

    return Column(
      children: [
        for (Map<String, dynamic> meta in lista) cardMeta(meta),
        if (resumida && metas.length > 3)
          TextButton(
            onPressed: () {
              setState(() {
                abaAtual = 1;
              });
            },
            child: Text("Ver todas as ${metas.length} caixinhas"),
          ),
      ],
    );
  }

  Widget itemTransacao(Map<String, dynamic> t) {
    bool ganho = t["ganho"] as bool;
    double valor = t["valor"] as double;
    DateTime data = t["data"] as DateTime;

    return Dismissible(
      key: ValueKey(t["id"]),
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        color: Colors.blue,
        child: const Icon(Icons.edit, color: Colors.white),
      ),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          editarTransacao(t);
          return false;
        }

        excluirTransacao(t);
        return true;
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 5,
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: ganho
                  ? Colors.green.withValues(alpha: 0.15)
                  : Colors.red.withValues(alpha: 0.15),
              child: Icon(
                ganho ? Icons.arrow_downward : Icons.arrow_upward,
                color: ganho ? Colors.green : Colors.red,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t["categoria"] as String,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    t["descricao"] as String,
                    style: const TextStyle(
                      color: Colors.black54,
                    ),
                  ),
                  Text(
                    "${data.day.toString().padLeft(2, "0")}/"
                    "${data.month.toString().padLeft(2, "0")}/"
                    "${data.year}",
                    style: const TextStyle(
                      color: Colors.black38,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              "${ganho ? "+" : "-"}${moeda(valor)}",
              style: TextStyle(
                color: ganho ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget listaTransacoes({bool resumida = false}) {
    List<Map<String, dynamic>> lista = transacoesFiltradas();

    if (resumida) {
      lista = lista.take(5).toList();
    }

    if (lista.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text(
            "Nenhuma transação encontrada",
            style: TextStyle(color: Colors.black54),
          ),
        ),
      );
    }

    return Column(
      children: [
        for (Map<String, dynamic> t in lista) itemTransacao(t),
        if (resumida && transacoes.length > 5)
          TextButton(
            onPressed: () {
              setState(() {
                abaAtual = 2;
              });
            },
            child: const Text("Ver histórico completo"),
          ),
      ],
    );
  }

  Widget relatorioCategorias({bool somenteMes = false}) {
    Map<String, double> dadosCategoria = gastosPorCategoria(somenteMes: somenteMes);

    if (dadosCategoria.isEmpty) {
      return const Text(
        "Ainda não há gastos para gerar relatório.",
        style: TextStyle(color: Colors.black54),
      );
    }

    double maior = 0;

    for (double valor in dadosCategoria.values) {
      if (valor > maior) {
        maior = valor;
      }
    }

    List<MapEntry<String, double>> entradas = dadosCategoria.entries.toList();
    entradas.sort((a, b) => b.value.compareTo(a.value));

    return Column(
      children: entradas.map((entrada) {
        double porcentagem = maior <= 0 ? 0 : (entrada.value / maior).clamp(0.0, 1.0).toDouble();

        return Padding(
          padding: const EdgeInsets.only(bottom: 13),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      entrada.key,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  Text(
                    moeda(entrada.value),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: LinearProgressIndicator(
                  value: porcentagem,
                  minHeight: 10,
                  color: Colors.red,
                  backgroundColor: Colors.grey.shade300,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget telaDashboard() {
    double saldo = dados["saldo"] as double;
    double ganhosMes = calcularGanhos(somenteMes: true);
    double gastosMes = calcularGastos(somenteMes: true);
    double limite = dados["limiteMensal"] as double;
    double progressoLimite = limite <= 0 ? 0 : (gastosMes / limite).clamp(0.0, 1.0).toDouble();

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          "Visão geral",
          style: TextStyle(
            fontSize: 27,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          "Bem-vindo, $usuarioLogado",
          style: const TextStyle(
            fontSize: 14,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 20),
        dicaAutomatica(),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: cardResumo(
                titulo: "Saldo livre",
                valor: moeda(saldo),
                icone: Icons.account_balance_wallet,
                cor: Colors.black,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: cardResumo(
                titulo: "Patrimônio",
                valor: moeda(patrimonioTotal()),
                icone: Icons.diamond,
                cor: Colors.blue,
                subtitulo: "saldo + caixinhas",
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: cardResumo(
                titulo: "Ganhos do mês",
                valor: moeda(ganhosMes),
                icone: Icons.trending_up,
                cor: Colors.green,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: cardResumo(
                titulo: "Gastos do mês",
                valor: moeda(gastosMes),
                icone: Icons.trending_down,
                cor: Colors.red,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        secao(
          titulo: "Limite mensal de gastos",
          icone: Icons.speed,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "${moeda(gastosMes)} usados de ${moeda(limite)}",
                style: const TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: LinearProgressIndicator(
                  value: progressoLimite,
                  minHeight: 12,
                  color: progressoLimite >= 1 ? Colors.red : Colors.orange,
                  backgroundColor: Colors.grey.shade300,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "${(progressoLimite * 100).toStringAsFixed(1)}% do limite usado",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: progressoLimite >= 1 ? Colors.red : Colors.orange,
                ),
              ),
            ],
          ),
        ),
        secao(
          titulo: "Progresso geral das caixinhas",
          icone: Icons.savings,
          trailing: TextButton.icon(
            onPressed: () => criarOuEditarMeta(),
            icon: const Icon(Icons.add),
            label: const Text("Nova"),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "${moeda(totalGuardadoMetas())} guardados de ${moeda(totalObjetivosMetas())}",
                style: const TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: LinearProgressIndicator(
                  value: progressoGeralMetas(),
                  minHeight: 12,
                  color: Colors.green,
                  backgroundColor: Colors.grey.shade300,
                ),
              ),
              const SizedBox(height: 15),
              listaMetas(resumida: true),
            ],
          ),
        ),
        secao(
          titulo: "Adicionar transação rápida",
          icone: Icons.add_card,
          child: formularioTransacao(),
        ),
        secao(
          titulo: "Últimas transações",
          icone: Icons.history,
          child: listaTransacoes(resumida: true),
        ),
      ],
    );
  }

  Widget telaMetas() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                "Caixinhas",
                style: TextStyle(
                  fontSize: 27,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () => criarOuEditarMeta(),
              icon: const Icon(Icons.add),
              label: const Text("Nova"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          "Crie várias metas ao mesmo tempo, como as caixinhas do Nubank.",
          style: TextStyle(color: Colors.black54),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: cardResumo(
                titulo: "Guardado",
                valor: moeda(totalGuardadoMetas()),
                icone: Icons.savings,
                cor: Colors.green,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: cardResumo(
                titulo: "Objetivos",
                valor: moeda(totalObjetivosMetas()),
                icone: Icons.flag,
                cor: Colors.blue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        secao(
          titulo: "Suas metas simultâneas",
          icone: Icons.dashboard_customize,
          child: listaMetas(),
        ),
      ],
    );
  }

  Widget telaTransacoes() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                "Histórico",
                style: TextStyle(
                  fontSize: 27,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            IconButton(
              onPressed: transacoes.isEmpty ? null : limparHistorico,
              icon: const Icon(Icons.delete_sweep),
              tooltip: "Limpar histórico",
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          "Arraste para a direita para editar e para a esquerda para excluir.",
          style: TextStyle(color: Colors.black54),
        ),
        const SizedBox(height: 18),
        secao(
          titulo: "Nova transação",
          icone: Icons.add,
          child: formularioTransacao(),
        ),
        secao(
          titulo: "Filtros",
          icone: Icons.filter_alt,
          child: Column(
            children: [
              TextField(
                controller: pesquisaController,
                decoration: const InputDecoration(
                  labelText: "Pesquisar por categoria ou descrição",
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: filtroTipo,
                decoration: const InputDecoration(
                  labelText: "Tipo",
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: "Todos", child: Text("Todos")),
                  DropdownMenuItem(value: "Ganhos", child: Text("Ganhos")),
                  DropdownMenuItem(value: "Gastos", child: Text("Gastos")),
                ],
                onChanged: (v) {
                  if (v == null) return;

                  setState(() {
                    filtroTipo = v;
                  });
                },
              ),
            ],
          ),
        ),
        secao(
          titulo: "Lista de transações",
          icone: Icons.receipt_long,
          child: listaTransacoes(),
        ),
      ],
    );
  }

  Widget telaRelatorios() {
    double ganhosMes = calcularGanhos(somenteMes: true);
    double gastosMes = calcularGastos(somenteMes: true);
    double resultadoMes = ganhosMes - gastosMes;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          "Relatórios",
          style: TextStyle(
            fontSize: 27,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          "Resumo simples para defender que o app evoluiu de verdade.",
          style: TextStyle(color: Colors.black54),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: cardResumo(
                titulo: "Resultado do mês",
                valor: moeda(resultadoMes),
                icone: resultadoMes >= 0 ? Icons.sentiment_satisfied : Icons.sentiment_dissatisfied,
                cor: resultadoMes >= 0 ? Colors.green : Colors.red,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: cardResumo(
                titulo: "Qtd. transações",
                valor: "${transacoes.length}",
                icone: Icons.receipt,
                cor: Colors.black,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        secao(
          titulo: "Gastos por categoria neste mês",
          icone: Icons.bar_chart,
          child: relatorioCategorias(somenteMes: true),
        ),
        secao(
          titulo: "Gastos por categoria geral",
          icone: Icons.pie_chart,
          child: relatorioCategorias(),
        ),
        secao(
          titulo: "Diagnóstico financeiro",
          icone: Icons.psychology,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              linhaDiagnostico(
                "Saldo livre",
                moeda(dados["saldo"] as double),
                (dados["saldo"] as double) >= 0 ? Colors.green : Colors.red,
              ),
              linhaDiagnostico(
                "Total guardado em caixinhas",
                moeda(totalGuardadoMetas()),
                Colors.green,
              ),
              linhaDiagnostico(
                "Progresso geral das metas",
                "${(progressoGeralMetas() * 100).toStringAsFixed(1)}%",
                Colors.blue,
              ),
              linhaDiagnostico(
                "Gastos do mês",
                moeda(gastosMes),
                gastosMes <= (dados["limiteMensal"] as double) ? Colors.green : Colors.red,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget linhaDiagnostico(String titulo, String valor, Color cor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              titulo,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Text(
            valor,
            style: TextStyle(
              color: cor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget telaConfiguracoes() {
    double limite = dados["limiteMensal"] as double;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          "Configurações",
          style: TextStyle(
            fontSize: 27,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          usuarioLogado,
          style: const TextStyle(color: Colors.black54),
        ),
        const SizedBox(height: 18),
        secao(
          titulo: "Limite de gastos",
          icone: Icons.speed,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Limite atual: ${moeda(limite)}"),
              const SizedBox(height: 12),
              TextField(
                controller: limiteController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: "Novo limite mensal",
                  prefixIcon: Icon(Icons.attach_money),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: atualizarLimite,
                  icon: const Icon(Icons.update),
                  label: const Text("Atualizar limite"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
        secao(
          titulo: "Resumo da conta",
          icone: Icons.person,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Email: $usuarioLogado"),
              const SizedBox(height: 6),
              Text("Saldo livre: ${moeda(dados["saldo"] as double)}"),
              const SizedBox(height: 6),
              Text("Caixinhas criadas: ${metas.length}"),
              const SizedBox(height: 6),
              Text("Transações registradas: ${transacoes.length}"),
            ],
          ),
        ),
        secao(
          titulo: "Ações",
          icone: Icons.settings,
          child: Column(
            children: [
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      abaAtual = 0;
                    });
                  },
                  icon: const Icon(Icons.home),
                  label: const Text("Voltar para visão geral"),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: sair,
                  icon: const Icon(Icons.logout),
                  label: const Text("Sair da conta"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget telaAtual() {
    if (abaAtual == 0) return telaDashboard();
    if (abaAtual == 1) return telaMetas();
    if (abaAtual == 2) return telaTransacoes();
    if (abaAtual == 3) return telaRelatorios();
    return telaConfiguracoes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: telaAtual(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: abaAtual,
        onTap: (index) {
          setState(() {
            abaAtual = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.black45,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: "Início",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.savings),
            label: "Caixinhas",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long),
            label: "Histórico",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: "Relatórios",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: "Config.",
          ),
        ],
      ),
    );
  }
}
