import 'package:flutter/material.dart';
import 'package:appflowy_board/appflowy_board.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';

void main() {
  runApp(const AppScreen());
}

class AppScreen extends StatefulWidget {
  const AppScreen({Key? key}) : super(key: key);

  @override
  State<AppScreen> createState() => _AppScreenState();
}

class _AppScreenState extends State<AppScreen> with TickerProviderStateMixin {
  final AppFlowyBoardController controller = AppFlowyBoardController();
  late AppFlowyBoardScrollController boardController;
  bool _isWriting = false;
  bool _isLoadingCircular = false;
  late AnimationController _animationController;

  Future<List<AppFlowyGroupData>> fetchTasks() async {
    try {
      String userEmail = FirebaseAuth.instance.currentUser!.email!;
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('cards_tarefas')
          .where('user', isEqualTo: userEmail)
          .get();

      List<Map<String, dynamic>> allCardsUser =
          snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();

      List<Map<String, dynamic>> pendenteCards =
          allCardsUser.where((card) => card['status'] == 'Pendente').toList();
      List<Map<String, dynamic>> emAndamentoCards =
          allCardsUser.where((card) => card['status'] == 'Em andamento').toList();
      List<Map<String, dynamic>> concluidoCards =
          allCardsUser.where((card) => card['status'] == 'Concluído').toList();

      return [
        _buildGroup("Tarefas", pendenteCards),
        _buildGroup("Em andamento", emAndamentoCards),
        _buildGroup("Concluídas", concluidoCards),
      ];
    } catch (e) {
      print('Erro ao carregar tarefas: $e');
      return [];
    }
  }

  AppFlowyGroupData _buildGroup(String groupName, List<Map<String, dynamic>> cards) {
    return AppFlowyGroupData(
      id: groupName,
      name: groupName,
      items: List<AppFlowyGroupItem>.from(cards
          .map((card) => RichTextItem(
                title: card['titulo'],
                subtitle: DateFormat('yyyy-MM-dd').format(
                    (card['data'] as Timestamp).toDate()),
              ))
          .toList()),
    );
  }

  @override
  void initState() {
    super.initState();
    boardController = AppFlowyBoardScrollController();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..forward();
  }

  void _addCard() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final TextEditingController cardController = TextEditingController();
        DateTime? selectedDate;

        return AlertDialog(
          title: const Text('Adicionar Card'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: cardController,
                decoration: const InputDecoration(hintText: 'Nome do Card'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2101),
                  );
                  if (pickedDate != null) {
                    selectedDate = pickedDate;
                  }
                },
                child: const Text('Selecionar Data'),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Adicionar'),
              onPressed: () async {
                if (cardController.text.isNotEmpty && selectedDate != null) {
                  String userEmail = FirebaseAuth.instance.currentUser!.email!;

                  final newCard = {
                    'titulo': cardController.text,
                    'data': Timestamp.fromDate(selectedDate!),
                    'status': 'Pendente',
                    'user': userEmail,
                  };

                  try {
                    setState(() {
                      _isWriting = true;
                      _isLoadingCircular = true;
                    });
                    await FirebaseFirestore.instance
                        .collection('cards_tarefas')
                        .add(newCard);

                    setState(() {}); // Força o rebuild do FutureBuilder
                    Navigator.of(context).pop();
                  } catch (e) {
                    print("Erro ao adicionar card no Firestore: $e");
                  } finally {
                    setState(() {
                      _isWriting = false;
                      _isLoadingCircular = false;
                    });
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final config = AppFlowyBoardConfig(
      groupBackgroundColor: HexColor.fromHex('#F7F8FC'),
      stretchGroupHeight: false,
    );

    return FadeTransition(
      opacity: _animationController,
      child: Scaffold(
         appBar: AppBar(
          title: const Text('Gerenciador de tarefas'),
          bottom: _isWriting
              ? const PreferredSize(
                  preferredSize: Size.fromHeight(4),
                  child: LinearProgressIndicator(),
                )
              : null,
        ),
        bottomNavigationBar: CurvedNavigationBar(
      backgroundColor: Colors.blueAccent,
      items: <Widget>[
        Icon(Icons.add_circle, size: 30),
        Icon(Icons.help, size: 30),
      ],
      onTap: (index) {
        if (index == 0) _addCard();
        // Add codigo do botao de ajuda
        if (index == 1) {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Ajuda'),
                content: const Text('- Para adicionar uma tarefa, clique no botão + e preencha o nome da tarefa, junto da sua data/prazo \n- Para alterar o status da tarefa, clique e arraste a tarefa para a coluna desejada'),
                actions: <Widget>[
                  TextButton(
                    child: const Text('Fechar'),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              );
            },
          );
        }
      },
    ),
        body: _isLoadingCircular
            ? const Center(child: CircularProgressIndicator())
            : FutureBuilder<List<AppFlowyGroupData>>(
          future: fetchTasks(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return const Center(child: Text("Erro ao carregar tarefas"));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text("Nenhuma tarefa encontrada"));
            }

            final groups = snapshot.data!;
            controller.clear(); // Limpa os grupos antes de adicionar os novos
            for (var group in groups) {
              controller.addGroup(group);
            }

            return AppFlowyBoard(
              controller: controller,
              cardBuilder: (context, group, groupItem) {
                return AppFlowyGroupCard(
                  key: ValueKey(groupItem.id),
                  child: _buildCard(groupItem),
                );
              },
              boardScrollController: boardController,
              headerBuilder: (context, columnData) {
                return AppFlowyGroupHeader(
                  icon: const Icon(Icons.lightbulb_circle),
                  title: Text(columnData.headerData.groupName),
                  height: 50,
                  margin: config.groupBodyPadding,
                );
              },
              groupConstraints: const BoxConstraints.tightFor(width: 300),
              config: config,
            );
          },
        ),
      ),
    );
  }

  Widget _buildCard(AppFlowyGroupItem item) {
  if (item is RichTextItem) {
    return RichTextCard(item: item);
  }
  // Retorna um espaço vazio para itens temporários ou desconhecidos
  return const SizedBox.shrink();
}


}

class RichTextCard extends StatelessWidget {
  final RichTextItem item;
  const RichTextCard({required this.item, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).cardColor,
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 5),
            Text(
              item.subtitle,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class RichTextItem extends AppFlowyGroupItem {
  String title;
  String subtitle;

  RichTextItem({required this.title, required this.subtitle});

  @override
  String get id => title;
}

extension HexColor on Color {
  static Color fromHex(String hexString) {
    return Color(int.parse(hexString.replaceFirst('#', '0xFF')));
  }
}
