import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter/services.dart';
import 'dart:isolate';
import 'dart:convert';
import 'ffi.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => Notes()),
        ChangeNotifierProvider(create: (context) => Position()),
      ],
      child: MyApp(),
    ),
  );
}

void fromOtherThread(SendPort sendPort) {
  ReceivePort receivePort = ReceivePort();
  sendPort.send(receivePort.sendPort);
  receivePort.listen((delta) {
    var jsondata = jsonEncode(delta);
    api.printJson(data: jsondata);
  });
}

class Position with ChangeNotifier {
  int position = 0;

  void set(int pos) {
    position = pos;
    notifyListeners();
  }
}

class Notes with ChangeNotifier {
  List<quill.Document> list = [quill.Document()];

  void newNote() {
    list.insert(0, quill.Document());
    notifyListeners();
  }
  void set(int index, quill.Document note) {
    list[index] = note;
    notifyListeners();
  }
  void remove(int index) {
    list.removeAt(index);
    notifyListeners();
  }
}

class MyApp extends StatelessWidget {
  MyApp({Key? key}) : super(key: key);

  SendPort? sendPort;

  String title(quill.Document d) {
    if (d.isEmpty()) {
      return "New note";
    }
    var s = d.toPlainText();
    int i = s.indexOf('\n');
    if (i < 0) {
      return s;
    }
    return s.substring(0, i);
  }

  Widget noteList(BuildContext context, BoxConstraints constraints) {
    return Consumer<Notes>(
      builder: (context, notes, child) => Consumer<Position>(
        builder: (context, position, child) => ListView.separated(
          separatorBuilder: (context, index) => Divider(),
          itemCount: notes.list.length,
          itemBuilder: (context, index) {
            return ListTile(
              title: Text(
                title(notes.list[index]),
                overflow: TextOverflow.ellipsis,
              ),
              selected: constraints.maxWidth >= 600 && index == position.position,
              trailing: IconButton(
                icon: Icon(Icons.delete),
                tooltip: 'Delete note',
                onPressed: (){
                  notes.remove(index);
                  if (notes.list.length == 0) {
                    notes.newNote();
                  }
                  position.set(0);
                },
              ),
              onTap: () {
                position.set(index);
                if (constraints.maxWidth < 600) {
                  pushNoteScreen(context, notes);
                }
              },
            );
          },
        ),
      ),
    );
  }

  Widget noteMain(BuildContext context, BoxConstraints constraints) {
    return Container(
      width: constraints.maxWidth >= 600 ? 300 : constraints.maxWidth,
      padding: EdgeInsets.all(10.0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                    hintText: 'Enter a search term',
                  ),
                ),
              ),
              Material(
                child:IconButton(
                  icon: Icon(Icons.post_add),
                  tooltip: 'Create a new note',
                  onPressed: () {
                    var notes = Provider.of<Notes>(context, listen: false);
                    notes.newNote();
                    var position = Provider.of<Position>(context, listen: false);
                    position.set(0);
                    if (constraints.maxWidth < 600) {
                      pushNoteScreen(context, notes);
                    }
                  },
                ),
              ),
            ],
          ),
          Expanded(
            child: noteList(context, constraints),
          ),
        ],
      ),
    );
  }

  Widget noteContent(notes) {
    return Consumer<Position>(
      builder: (context, position, child) {
        var _controller = quill.QuillController(
          document: notes.list[position.position],
          selection: const TextSelection.collapsed(offset: 0),
        );
        _controller.changes.listen((ev) {
          notes.notifyListeners();
          sendPort?.send(ev.item2);
        });
        return Expanded(
          child: Column(
            children: [
              quill.QuillToolbar.basic(controller: _controller),
              Expanded(
                child: Container(
                  height: double.infinity, 
                  child: quill.QuillEditor.basic(
                    controller: _controller,
                    readOnly: false,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void pushNoteScreen(BuildContext context, notes) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => 
        Scaffold(
          appBar: AppBar(
            elevation: 0,
          ),
          body: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              return Row(
                children: [noteContent(notes)],
              );
            },
          ),
        ),
      ),
    );
  }

  List<Widget> layout(BuildContext context, BoxConstraints constraints) {
    if (constraints.maxWidth >= 600) {
      var notes = Provider.of<Notes>(context, listen: false);
      return [
        noteMain(context, constraints),
        noteContent(notes), // deal with this later
      ];
    }
    return [noteMain(context, constraints)];
  }

  Widget root(BuildContext context) {
    ReceivePort receivePort = ReceivePort();
    Isolate.spawn(fromOtherThread, receivePort.sendPort);
    return FutureBuilder<dynamic>(
      future: receivePort.first,
      builder: (BuildContext context, snapshot) {
        if (snapshot.hasData) {
          sendPort = snapshot.data;
          return LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              return Row(
                children: layout(context, constraints),
              );
            },
          );
        } else {
          return Container();
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Notes',
      theme: ThemeData(
        textSelectionTheme: TextSelectionThemeData(
          cursorColor: Colors.black,
        ),
        appBarTheme: AppBarTheme(
          systemOverlayStyle: SystemUiOverlayStyle.dark,
          backgroundColor: Colors.transparent,
        ),
        primarySwatch: Colors.grey,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: Text('Notes'),
          centerTitle: false,
          elevation: 0,
        ),
        body: root(context),
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}
