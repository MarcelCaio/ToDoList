import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
// ignore: import_of_legacy_library_into_null_safe
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(const MaterialApp(
    home: Home(),
  ));
}

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final _toDoController = TextEditingController();

  List _toDoList = [];

  Map<String, dynamic>? _lastRemoved;

  int? _lastRemovedPos;

  @override
  void initState() {
    super.initState();

    _readData().then((data) {
      _toDoList = json.decode(data!);
      reloadScreen();
    });
  }

  void _addToDo() {
    // ignore: prefer_collection_literals
    Map<String, dynamic> newToDo = Map();
    newToDo["title"] = _toDoController.text;
    _toDoController.text = "";
    newToDo["ok"] = false;
    _toDoList.add(newToDo);
    _saveData();
    reloadScreen();
  }

  void reloadScreen() {
    setState(() {});
  }

  Future<void> _refresh() async {
    await Future.delayed(const Duration(seconds: 1));

    _toDoList.sort((a, b) {
      // rearrange list. If checked, uncompleted tasks appear on top
      if (a["ok"] && !b["ok"]) {
        return 1;
      } else if (!a["ok"] && b["ok"]) {
        return -1;
      } else {
        return 0;
      }
    });
    _saveData();
    reloadScreen();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Lista de Tarefas"),
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
      ),
      body: Column(children: <Widget>[
        Container(
          padding: const EdgeInsets.fromLTRB(17.0, 1.0, 7.0, 1.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _toDoController,
                  decoration: const InputDecoration(
                      labelText: "Nova Tarefa",
                      labelStyle: TextStyle(color: Colors.blueAccent)),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    primary: Colors.blueAccent, onPrimary: Colors.white),
                onPressed: _addToDo,
                child: const Text("ADD"),
              )
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
              onRefresh: _refresh,
              child: ListView.builder(
                  padding: const EdgeInsets.only(top: 10.0),
                  itemCount: _toDoList.length,
                  itemBuilder: buildItem)),
        )
      ]),
    );
  }

  Widget buildItem(context, index) {
    return Dismissible(
      key: Key(DateTime.now().millisecondsSinceEpoch.toString()),
      background: Container(
        color: Colors.red,
        child: const Align(
            alignment: Alignment(-0.9, 0.0),
            child: Icon(Icons.delete, color: Colors.white)),
      ),
      direction: DismissDirection.startToEnd,
      child: CheckboxListTile(
        title: Text(_toDoList[index]["title"]),
        value: _toDoList[index]["ok"],
        secondary: CircleAvatar(
          child: Icon(_toDoList[index]["ok"] ? Icons.check : Icons.error),
        ),
        onChanged: (c) {
          _toDoList[index]["ok"] = c;
          _saveData();
          reloadScreen();
        },
      ),
      onDismissed: (direction) {
        _lastRemoved = Map.from(_toDoList[index]);
        _lastRemovedPos = index;
        _toDoList.removeAt(index);

        _saveData();

        final snack = SnackBar(
          content: Text("Tafera \"${_lastRemoved!["title"]}\" removida"),
          action: SnackBarAction(
              label: "Desfazer",
              onPressed: () {
                setState(() {
                  _toDoList.insert(_lastRemovedPos!, _lastRemoved);
                  _saveData();
                });
              }),
          duration: const Duration(seconds: 3),
        );
        ScaffoldMessenger.of(context).removeCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(snack);
        reloadScreen();
      },
    );
  }

  Future<File> _getFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File("${directory.path}/data.json");
  }

  Future<File> _saveData() async {
    String data = json.encode(_toDoList);
    final file = await _getFile();

    return file.writeAsString(data);
  }

  Future<String?> _readData() async {
    try {
      final file = await _getFile();
      return file.readAsString();
    } catch (e) {
      // ignore: avoid_print
      print(e.toString());
      return null;
    }
  }
}
