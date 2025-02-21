import 'package:flutter/material.dart';
import 'package:appflowy_board/appflowy_board.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  runApp(const AppScreen());
}

class AppScreen extends StatefulWidget {
  const AppScreen({Key? key}) : super(key: key);

  @override
  State<AppScreen> createState() => _AppScreenState();
}

class _AppScreenState extends State<AppScreen> {
  final AppFlowyBoardController controller = AppFlowyBoardController(
    onMoveGroup: (fromGroupId, fromIndex, toGroupId, toIndex) {
      debugPrint('Move item from $fromIndex to $toIndex');
    },
    onMoveGroupItem: (groupId, fromIndex, toIndex) {
      debugPrint('Move $groupId:$fromIndex to $groupId:$toIndex');
    },
    onMoveGroupItemToGroup: (fromGroupId, fromIndex, toGroupId, toIndex) {
      debugPrint('Move $fromGroupId:$fromIndex to $toGroupId:$toIndex');
    },
  );

  late AppFlowyBoardScrollController boardController;

  Future<List<Map<String, dynamic>>> fetchCollectionByUserId(
      String collectionName, String userId) async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection(collectionName)
          .where('user', isEqualTo: userId)
          .get();

      return snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    } catch (e) {
      print('Erro ao carregar dados: $e');
      return [];
    }
  }

  Future<void> loadData(String userId) async {
    List<Map<String, dynamic>> allCardsUser =
        await fetchCollectionByUserId('cards_tarefas', userId);

    List<Map<String, dynamic>> pendenteCards =
        allCardsUser.where((card) => card['status'] == 'Pendente').toList();
    List<Map<String, dynamic>> emAndamentoCards =
        allCardsUser.where((card) => card['status'] == 'Em andamento').toList();
    List<Map<String, dynamic>> concluidoCards =
        allCardsUser.where((card) => card['status'] == 'Concluído').toList();

    final group1 = AppFlowyGroupData(
        id: "Tarefas", name: "Tarefas", items: List<AppFlowyGroupItem>.from([]));
    final group2 = AppFlowyGroupData(id: "Em andamento", name: "Em andamento",
        items: List<AppFlowyGroupItem>.from([]));
    final group3 = AppFlowyGroupData(id: "Concluídas", name: "Concluídas",
        items: List<AppFlowyGroupItem>.from([]));

    setState(() {
      controller.addGroup(group1);
      controller.addGroup(group2);
      controller.addGroup(group3);

      for (var card in pendenteCards) {
        controller.getGroupController("Tarefas")?.add(
          RichTextItem(
            title: card['titulo'],
            subtitle: DateFormat('yyyy-MM-dd').format(
                (card['data'] as Timestamp).toDate()), // Convertendo data
          ),
        );
      }

      for (var card in emAndamentoCards) {
        controller.getGroupController("Em andamento")?.add(
          RichTextItem(
            title: card['titulo'],
            subtitle: DateFormat('yyyy-MM-dd').format(
                (card['data'] as Timestamp).toDate()),
          ),
        );
      }

      for (var card in concluidoCards) {
        controller.getGroupController("Concluídas")?.add(
          RichTextItem(
            title: card['titulo'],
            subtitle: DateFormat('yyyy-MM-dd').format(
                (card['data'] as Timestamp).toDate()),
          ),
        );
      }
    });
  }

  @override
  void initState() {
    super.initState();
    boardController = AppFlowyBoardScrollController();

    String userEmail = FirebaseAuth.instance.currentUser!.email!;
    loadData(userEmail);
  }

  void _addCard() {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      final TextEditingController cardController = TextEditingController();
      DateTime? selectedDate;

      return AlertDialog(
        title: Text('Adicionar Card'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: cardController,
              decoration: InputDecoration(hintText: 'Nome do Card'),
            ),
            SizedBox(height: 20),
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
              child: Text('Selecionar Data'),
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            child: Text('Cancelar'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          TextButton(
            child: Text('Adicionar'),
            onPressed: () async {
              if (cardController.text.isNotEmpty && selectedDate != null) {
                String userEmail =
                    FirebaseAuth.instance.currentUser!.email!; // Obtém o e-mail

                // Criando o novo card
                final newCard = {
                  'titulo': cardController.text,
                  'data': Timestamp.fromDate(selectedDate!),
                  'status': 'Pendente',
                  'user': userEmail,
                };

                try {
                  // Adicionando ao Firestore
                  await FirebaseFirestore.instance
                      .collection('cards_tarefas')
                      .add(newCard);

                  // Atualizando a UI localmente
                  setState(() {
                    var groupController =
                        controller.getGroupController("Tarefas");
                    if (groupController != null) {
                      groupController.add(RichTextItem(
                        title: cardController.text,
                        subtitle:
                            DateFormat('yyyy-MM-dd').format(selectedDate!),
                      ));
                    }
                  });

                  Navigator.of(context).pop(); // Fecha o diálogo
                } catch (e) {
                  print("Erro ao adicionar card no Firestore: $e");
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
 @override
Widget build(BuildContext context) {
  final config = AppFlowyBoardConfig(
    groupBackgroundColor: HexColor.fromHex('#F7F8FC'),
    stretchGroupHeight: false,
  );
  return Scaffold(
    appBar: AppBar(
      title: const Text('Gerenciador de tarefas'),
    ),
    body: AppFlowyBoard(
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
    ),
    floatingActionButton: FloatingActionButton(
      onPressed: _addCard,
      child: Icon(Icons.add),
    ),
  );
}
  Widget _buildCard(AppFlowyGroupItem item) {
    if (item is RichTextItem) {
      return RichTextCard(item: item);
    }
    throw UnimplementedError();
  }
}

class RichTextCard extends StatelessWidget {
  final RichTextItem item;
  const RichTextCard({required this.item, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).cardColor, // Cor do card de acordo com o tema
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.title,
              style: Theme.of(context).textTheme.titleMedium, // Herda cor do tema
            ),
            const SizedBox(height: 5),
            Text(
              item.subtitle,
              style: Theme.of(context).textTheme.bodyMedium, // Herda cor do tema
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
