import 'package:flutter/material.dart';
import 'package:flutter_mention_text_field/mention_text_editing_controller.dart';

class MyPage extends StatefulWidget {
  const MyPage({super.key});

  @override
  State<MyPage> createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> {
  static const _mentions = [
    Mention(userId: '1', name: 'Alice'),
    Mention(userId: '2', name: 'Bob'),
    Mention(userId: '3', name: 'Charlie'),
  ];


  final _controller = MentionTextEditingController(mentions: _mentions);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Mention Text Field'),
      ),
      body: Container(
        padding: const EdgeInsets.all(16),
        alignment: Alignment.center,
        child: TextField(
          controller: _controller,
          decoration: const InputDecoration(
            hintText: 'Type here...',
          ),
        ),
      ),
    );
  }
}
