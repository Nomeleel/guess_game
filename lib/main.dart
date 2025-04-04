// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'dart:math';

void main() => runApp(const MaterialApp(home: GamePage()));

class GamePage extends StatefulWidget {
  const GamePage({super.key});

  @override
  _GamePageState createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  List<int> myNumbers = [];
  List<int> opponentNumbers = [];
  bool currentTurn = true;
  List<String> logs = [];
  bool gameOver = false;

  @override
  void initState() {
    super.initState();
    initializeGame();
  }

  void initializeGame() {
    myNumbers = generateValidNumbers();
    opponentNumbers = generateValidNumbers();
    opponentNumbers.shuffle();
    logs = [];
    gameOver = false;
  }

  List<int> generateValidNumbers() {
    final random = Random();
    while (true) {
      Set<int> numbers = {};
      while (numbers.length < 3) {
        numbers.add(random.nextInt(15) + 1);
      }
      List<int> list = numbers.toList();
      int sum = list[0] + list[1] + list[2];
      int fourth = 30 - sum;
      if (fourth >= 1 && fourth <= 15 && !numbers.contains(fourth)) {
        list.add(fourth);
        return list;
      }
    }
  }

  Widget buildCard(String label, int? value, bool isOpponent) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                isOpponent ? '?' : value.toString(),
                style: const TextStyle(fontSize: 26),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> handleCompare() async {
    final type = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('选择比较类型'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'single'),
            child: const Text(
              '单张比较',
              style: TextStyle(
                fontSize: 20.0,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'sum'),
            child: const Text(
              '求和比较',
              style: TextStyle(
                fontSize: 20.0,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'sub'),
            child: const Text(
              '相减比较',
              style: TextStyle(
                fontSize: 20.0,
              ),
            ),
          ),
        ],
      ),
    );

    if (type == null) return;

    final myIndexes = await selectCards('选择己方卡牌', type == 'single' ? 1 : 2);
    final oppIndexes = await selectCards('选择对方卡牌', type == 'single' ? 1 : 2);

    if (myIndexes == null || oppIndexes == null) return;

    String result;
    if (type == 'single') {
      int myVal = myNumbers[myIndexes[0]];
      int oppVal = opponentNumbers[oppIndexes[0]];
      result = '${getLabel(myIndexes[0], true)} ${getComparison(myVal, oppVal)} ${getLabel(oppIndexes[0], false)}';
    } else if (type == 'sum') {
      int mySum = myNumbers[myIndexes[0]] + myNumbers[myIndexes[1]];
      int oppSum = opponentNumbers[oppIndexes[0]] + opponentNumbers[oppIndexes[1]];
      result =
          '${getLabel(myIndexes[0], true)}+${getLabel(myIndexes[1], true)} ${getComparison(mySum, oppSum)} ${getLabel(oppIndexes[0], false)}+${getLabel(oppIndexes[1], false)}';
    } else {
      int mySub = myNumbers[myIndexes[0]] - myNumbers[myIndexes[1]];
      int oppSub = opponentNumbers[oppIndexes[0]] - opponentNumbers[oppIndexes[1]];
      result =
          '${getLabel(myIndexes[0], true)}-${getLabel(myIndexes[1], true)} ${getComparison(mySub, oppSub)} ${getLabel(oppIndexes[0], false)}-${getLabel(oppIndexes[1], false)}';
    }

    setState(() {
      logs.add(result);
      // currentTurn = !currentTurn;
    });
  }

  Future<List<int>?> selectCards(String title, int count) async {
    List<int> selected = [];
    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(title),
            scrollable: true,
            content: SizedBox(
              height: 100,
              child: Row(
                children: List.generate(
                  4,
                  (index) {
                    final isSelected = selected.contains(index);

                    return TextButton(
                      onPressed: () {
                        setState(() {
                          if (isSelected) {
                            selected.remove(index);
                          } else if (selected.length < count) {
                            selected.add(index);
                          }
                        });

                        if (selected.length == count) {
                          Navigator.pop(context);
                        }
                      },
                      child: Text(
                        getLabel(index, title.contains('己方')),
                        style: TextStyle(
                          fontSize: 26,
                          color: isSelected ? Colors.green : null,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
    return selected.length == count ? selected : null;
  }

  String getLabel(int index, bool isMy) => isMy ? ['A', 'B', 'C', 'D'][index] : ['甲', '乙', '丙', '丁'][index];

  String getComparison(int a, int b) {
    if (a > b) return '>';
    if (a < b) return '<';
    return '=';
  }

  void handleGuess() async {
    final numbers = await showDialog<List<int>>(
      context: context,
      builder: (context) => const GuessDialog(),
    );

    if (numbers != null) {
      bool correct = numbers.toSet().difference(opponentNumbers.toSet()).isEmpty;
      setState(() {
        gameOver = correct;
      });
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(correct ? '胜利!' : '错误'),
          content: Text(correct ? '你猜对了!' : '请继续推理'),
        ),
      );
    }
  }

  void restart() {
    setState(() {
      initializeGame();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('数字推理游戏')),
      body: Column(
        children: [
          // Padding(
          //   padding: EdgeInsets.all(16),
          //   child: Text('当前回合: ${currentTurn ? '我方' : '对方'}'),
          // ),
          Expanded(
            child: Row(
              children: List.generate(
                4,
                (i) => buildCard('ABCD'[i], myNumbers[i], false),
              ),
            ),
          ),
          Expanded(
            child: Row(
              children: List.generate(
                4,
                (i) => buildCard('甲乙丙丁'[i], opponentNumbers[i], true),
              ),
            ),
          ),
          const Text('记录'),
          Expanded(
            flex: 2,
            child: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(20),
              ),
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: max(MediaQuery.of(context).size.width ~/ 500, 1),
                  mainAxisExtent: 45,
                ),
                itemCount: logs.length,
                itemBuilder: (context, index) => ListTile(
                  title: Text(
                    logs[logs.length - index - 1],
                    style: const TextStyle(
                      fontSize: 20,
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (!gameOver)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 50).copyWith(top: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: currentTurn ? handleCompare : null,
                    child: const Text('提问'),
                  ),
                  ElevatedButton(
                    onPressed: currentTurn ? handleGuess : null,
                    child: const Text('猜测'),
                  ),
                  ElevatedButton(
                    onPressed: restart,
                    child: const Text(
                      ' 重新开始',
                      style: TextStyle(color: Colors.redAccent),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class GuessDialog extends StatefulWidget {
  const GuessDialog({super.key});

  @override
  _GuessDialogState createState() => _GuessDialogState();
}

class _GuessDialogState extends State<GuessDialog> {
  final controllers = List.generate(4, (_) => TextEditingController());

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('输入对方数字'),
      content: Column(
        children: List.generate(
          4,
          (i) => TextField(
            controller: controllers[i],
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: '甲乙丙丁'[i]),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        TextButton(
          onPressed: () {
            List<int> numbers = [];
            for (var c in controllers) {
              int? num = int.tryParse(c.text);
              if (num == null || num < 1 || num > 15) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请输入1-15的有效数字')));
                return;
              }
              numbers.add(num);
            }
            if (numbers.toSet().length != 4 || numbers.sum != 30) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('无效组合')));
              return;
            }
            Navigator.pop(context, numbers);
          },
          child: const Text('提交'),
        ),
      ],
    );
  }
}

extension ListSum on List<int> {
  int get sum => fold(0, (a, b) => a + b);
}
