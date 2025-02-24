import 'dart:math';

import 'package:flutter/material.dart';
import 'package:appflowy_board/appflowy_board.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter_trabalho_final/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences_web/shared_preferences_web.dart';

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
  Color _barColor = const Color.fromARGB(255, 131, 144, 165);

  Future<List<AppFlowyGroupData>> fetchTasks() async {
    try {
      String userEmail = FirebaseAuth.instance.currentUser?.email ?? '';
      if (userEmail.isEmpty) {
        throw Exception('User email is null');
      }

      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('cards_tarefas')
          .where('user', isEqualTo: userEmail)
          .get();

      List<Map<String, dynamic>> allCardsUser =
          snapshot.docs.map((doc) => {
            'docId': doc.id,
            ...doc.data() as Map<String, dynamic>
          }).toList();

      List<Map<String, dynamic>> pendenteCards =
          allCardsUser.where((card) => card['status'] == 'Pendente').toList();
      List<Map<String, dynamic>> emAndamentoCards =
          allCardsUser.where((card) => card['status'] == 'Em andamento').toList();
      List<Map<String, dynamic>> concluidoCards =
          allCardsUser.where((card) => card['status'] == 'Concluído').toList();

      return [
        _buildGroup(AppLocalizations.of(context)!.translate('tarefas'), pendenteCards),
        _buildGroup(AppLocalizations.of(context)!.translate('andamento'), emAndamentoCards),
        _buildGroup(AppLocalizations.of(context)!.translate('concluidas'), concluidoCards),
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
      items: List<AppFlowyGroupItem>.from(cards.map((card) {
        final data = card['data'];
        final date = data != null ? (data as Timestamp).toDate() : DateTime.now();
        return RichTextItem(
          docId: card['docId'] ?? '',
          title: card['titulo'] ?? '',
          subtitle: DateFormat('yyyy-MM-dd').format(date),
        );
      }).toList()),
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
          title: Text(AppLocalizations.of(context)!.translate('add_card')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: cardController,
                decoration: InputDecoration(hintText: AppLocalizations.of(context)!.translate('nome_card').toString()),
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
                child: Text(AppLocalizations.of(context)!.translate('selecionar_data')),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: Text(AppLocalizations.of(context)!.translate('cancelar')),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text(AppLocalizations.of(context)!.translate('adicionar')),
              onPressed: () async {
                if (cardController.text.isNotEmpty && selectedDate != null) {
                  String userEmail = FirebaseAuth.instance.currentUser?.email ?? '';
                  if (userEmail.isEmpty) {
                    print("Erro: User email is null");
                    return;
                  }

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

  void _deleteCard(String docId) async {
    try {
      await FirebaseFirestore.instance.collection('cards_tarefas').doc(docId).delete();
      setState(() {
        controller.removeGroupItem(AppLocalizations.of(context)!.translate('tarefas'), docId); // Replace 'Tarefas' with the appropriate groupId if needed
      });
    } catch (e) {
      print("Erro ao deletar card no Firestore: $e");
    }
  }

  void _changeBarColor() {
    setState(() {

      if (_barColor == Colors.red) {
        _barColor = Colors.green;
      } else if (_barColor == Colors.green) {
        _barColor = Colors.orange;
      } else if (_barColor == Colors.orange) {
        _barColor = Colors.blue;
      } else if (_barColor == Colors.blue) {
        _barColor = Colors.red;
      } else {
        _barColor = Colors.red;
      }

    });
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
          title: Text(AppLocalizations.of(context)!.translate('gerenciador')),
          bottom: _isWriting
              ? const PreferredSize(
                  preferredSize: Size.fromHeight(4),
                  child: LinearProgressIndicator(),
                )
              : null,
        ),
        bottomNavigationBar: CurvedNavigationBar(
      backgroundColor: _barColor,
      items: <Widget>[
        Icon(Icons.add_circle, size: 30, color: _barColor),
        Icon(Icons.help, size: 30, color: _barColor),
        Icon(Icons.color_lens, size: 30, color: _barColor),
      ],
      onTap: (index) {
        if (index == 0) _addCard();
        // Add codigo do botao de ajuda
        if (index == 1) {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text(AppLocalizations.of(context)!.translate('ajuda')),
                content: Text(AppLocalizations.of(context)!.translate('ajuda_texto')),
                actions: <Widget>[
                  TextButton(
                    child: Text(AppLocalizations.of(context)!.translate('fechar')),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              );
            },
          );
        }
        if (index == 2) _changeBarColor();
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
                  title: Text(
                    columnData.headerData.groupName,
                    style: const TextStyle(color: Colors.black),
                  ),
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
      return RichTextCard(item: item, onDelete: _deleteCard);
    }
    // Retorna um espaço vazio para itens temporários ou desconhecidos
    return const SizedBox.shrink();
  }
}

class RichTextCard extends StatelessWidget {
  final RichTextItem item;
  final Function(String) onDelete;
  const RichTextCard({required this.item, required this.onDelete, Key? key}) : super(key: key);

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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  item.title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                IconButton(
                  icon: Icon(Icons.delete, color: Colors.red),
                  onPressed: () => onDelete(item.docId),
                ),
              ],
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
  String docId;
  String title;
  String subtitle;

  RichTextItem({required this.docId, required this.title, required this.subtitle});

  @override
  String get id => docId;
}

extension HexColor on Color {
  static Color fromHex(String hexString) {
    return Color(int.parse(hexString.replaceFirst('#', '0xFF')));
  }
}
