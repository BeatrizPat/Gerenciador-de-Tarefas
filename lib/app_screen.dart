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

  Future<List<Map<String, dynamic>>> fetchCollectionByUserId(String collectionName, String userId) async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection(collectionName)
          .where('user', isEqualTo: userId) // Filtrando pelo ID do usuário
          .get();
      
      return snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
    } catch (e) {
      print('Erro ao carregar dados: $e');
      return [];
    }
  }


  Future<List> loadData(String userId) async {
    List<Map<String, dynamic>> data = await fetchCollectionByUserId('cards_tarefas', userId);
    print(data);
    return data;
  }


  @override
  void initState() {
    super.initState();
    boardController = AppFlowyBoardScrollController();

    String userEmail = FirebaseAuth.instance.currentUser!.email!;

    loadData(userEmail).then((allCardsUser) {
      List pentendeCards = allCardsUser.where((card) => card['status'] == 'Pendente').toList();
      print(pentendeCards);
      List emAndamentoCards = allCardsUser.where((card) => card['status'] == 'Em andamento').toList();
      print(emAndamentoCards);
      List concluidoCards = allCardsUser.where((card) => card['status'] == 'Concluído').toList();
      print(concluidoCards);
    });

    final group1 = AppFlowyGroupData(id: "Tarefas", name: "Tarefas", items: []);
    final group2 = AppFlowyGroupData(id: "Em andamento", name: "Em andamento", items: []);
    final group3 = AppFlowyGroupData(id: "Concluídas", name: "Concluídas", items: []);

    controller.addGroup(group1);
    controller.addGroup(group2);
    controller.addGroup(group3);
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
                  selectedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2101),
                  );
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
              onPressed: () {
                if (cardController.text.isNotEmpty && selectedDate != null) {
                  final newItem = RichTextItem(
                    title: cardController.text,
                    subtitle: DateFormat('yyyy-MM-dd').format(selectedDate!),
                  );
                  setState(() {
                    controller.getGroupController("Tarefas")?.add(newItem);
                  });
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _editDate(RichTextItem item) async {
    DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (selectedDate != null) {
      setState(() {
        item.subtitle = DateFormat('yyyy-MM-dd').format(selectedDate);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = AppFlowyBoardConfig(
      groupBackgroundColor: HexColor.fromHex('#F7F8FC'),
      stretchGroupHeight: false,
    );
    return MaterialApp(
      home: Scaffold(
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
              title: SizedBox(
                width: 120,
                child: TextField(
                  controller: TextEditingController()
                    ..text = columnData.headerData.groupName,
                  onSubmitted: (val) {
                    controller
                        .getGroupController(columnData.headerData.groupId)!
                        .updateGroupName(val);
                  },
                ),
              ),
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
      ),
    );
  }

  Widget _buildCard(AppFlowyGroupItem item) {
    if (item is TextItem) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
          child: Text(item.s),
        ),
      );
    }

    if (item is RichTextItem) {
      return RichTextCard(item: item, onEditDate: _editDate);
    }

    throw UnimplementedError();
  }
}

class RichTextCard extends StatefulWidget {
  final RichTextItem item;
  final Function(RichTextItem) onEditDate;
  const RichTextCard({
    required this.item,
    required this.onEditDate,
    Key? key,
  }) : super(key: key);

  @override
  State<RichTextCard> createState() => _RichTextCardState();
}

class _RichTextCardState extends State<RichTextCard> {
  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.item.title,
              style: const TextStyle(fontSize: 14),
              textAlign: TextAlign.left,
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  widget.item.subtitle,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                IconButton(
                  icon: Icon(Icons.calendar_today),
                  onPressed: () => widget.onEditDate(widget.item),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class TextItem extends AppFlowyGroupItem {
  final String s;

  TextItem(this.s);

  @override
  String get id => s;
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
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }
}