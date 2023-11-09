//import 'dart:js';

//import 'dart:ffi';
//import 'dart:js_interop_unsafe';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'package:firebase_auth/firebase_auth.dart';

import 'login.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'To-Do List',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a blue toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange),
        useMaterial3: true,
      ),
      home: LoginScreen(),
      //home: ToDoPage(),
    );
  }
}

class Todo {
  Todo({required this.title, required this.done, required this.memo});
  String title;
  bool done;
  String memo;
}

class TodoCard extends StatelessWidget {
  TodoCard(
      {super.key,
      required this.todo,
      required this.onChecked,
      required this.onDeleted});

  final Todo todo;

  final void Function(Todo todo) onChecked;
  final void Function(Todo todo) onDeleted;

  TextStyle? _getStyle(bool check) {
    if (check) {
      return const TextStyle(
        color: Colors.black,
        decoration: TextDecoration.lineThrough,
      );
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
          onTap: () {
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => MemoPage(todo: todo)));
          }, //go to MemoPage

          leading: Checkbox(
            checkColor: Colors.green,
            activeColor: Colors.red,
            value: todo.done,
            onChanged: (value) {
              onChecked(todo);
              print(todo.done);
              // change it to (completed)
            },
          ),
          title: Text(todo.title, style: _getStyle(todo.done)),
          trailing: IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () {
              onDeleted(todo);
            },
          )),
    );
  }
}

class ToDoPage extends HookWidget {
  ToDoPage({super.key});

  bool updated = false;

  @override
  Widget build(BuildContext context) {
    final ex1 = Todo(
        title: 'Flutter Newbie Seminar 1',
        done: false,
        memo: 'You should use flutter_hooks');
    final ex2 = Todo(
        title: 'Flutter Newbie Seminar 2',
        done: false,
        memo: 'You must use the Navigator class');

    //List<Todo> list = [ex1];
    final todos = useState<List<Todo>>([]);

    final TextEditingController _textFieldController1 = TextEditingController();
    final TextEditingController _textFieldController2 = TextEditingController();

    var user = FirebaseAuth.instance.currentUser;

    Future<DocumentSnapshot> getUserData() async {
      if (user != null) {
        return FirebaseFirestore.instance
            .collection('users')
            .doc(user.email)
            .get();
      }
      throw Exception('Not logged in');
    }

    Future _signOut() async {
      await FirebaseAuth.instance.signOut();
    }

    void onLogin() async {
      if (user == null) {
        Navigator.push(
            context, MaterialPageRoute(builder: (context) => LoginScreen()));
      } else {
        try {
          _signOut();
          Navigator.pop(context);
        } catch (e) {
          print(e.toString());
        }
      }
    }

    void _onCheckbox(Todo todo) {
      if (user != null) {
        FirebaseFirestore.instance
            .collection('users')
            .doc(user.email)
            .update({"${todo.title}.done": !todo.done});
      }
      todos.notifyListeners();
      updated = false;
    }

    void _onDelete(Todo todo) {
      todos.value.remove(todo);
      if (user != null) {
        FirebaseFirestore.instance
            .collection('users')
            .doc(user.email)
            .update({"${todo.title}": FieldValue.delete()});
      }
      updated = false;
      todos.notifyListeners();
    }

    void _addTodoItem(String title, String memo) {
      if (user != null) {
        FirebaseFirestore.instance.collection('users').doc(user.email).set({
          title: {'memo': memo, 'done': false}
        }, SetOptions(merge: true));
      }
      updated = false;
      todos.notifyListeners();
    }

    void retrieveUserData() {
      getUserData().then((snapshot) {
        if (snapshot.exists) {
          Map<String, dynamic> userData =
              snapshot.data() as Map<String, dynamic>;
          userData.forEach((key, value) {
            todos.value.add(Todo(
                title: key.toString(),
                done: value['done'],
                memo: value['memo']));
          });
          todos.notifyListeners();
          print(todos.value);
          // Use your user data here, e.g., update the state or UI
        } else {
          todos.value = [ex1];
          // Handle the case where the user does not have data in the Firestore document
        }
      }).catchError((error) {
        // Handle errors here, e.g., show an error message
      });
    }

    Future<void> _displayDialog() async {
      return showDialog<void>(
        context: context,
        //T: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Add a todo'),
            content: Column(
              children: [
                TextField(
                  controller: _textFieldController1,
                  decoration: const InputDecoration(hintText: 'Type todo'),
                  autofocus: true,
                ),
                TextField(
                  controller: _textFieldController2,
                  decoration: const InputDecoration(hintText: "Type your memo"),
                  autofocus: true,
                )
              ],
            ),
            actions: <Widget>[
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                  todos.notifyListeners();
                  _addTodoItem(
                      _textFieldController1.text, _textFieldController2.text);
                },
                child: const Text('Add'),
              ),
            ],
          );
        },
      );
    }

    if (!updated) {
      todos.value = [];
      retrieveUserData();
      updated = true;
    } //only retrieve once

    return Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Text("To-Do List"),
              IconButton(
                icon: Icon(Icons.person_2_rounded),
                onPressed: () => onLogin,
              ),
              if (user != null)
                Text(
                  "${user.email}",
                  style: TextStyle(fontSize: 10.0),
                ),
            ],
          ),
        ),
        body: ListView(
          children: //([
              //const Card(child: ListTile(title: Text("What you should do today"),))
              //]

              todos.value
                  .map((Todo todo) => TodoCard(
                        todo: todo,
                        onChecked: _onCheckbox,
                        onDeleted: _onDelete,
                      ))
                  .toList(),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _displayDialog(),
          tooltip: 'Add new to-do',
          child: const Icon(Icons.add),
        ));
  }
}

class MemoPage extends StatelessWidget {
  const MemoPage({super.key, required this.todo});

  final Todo todo;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(todo.title),
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            children: [
              Text(
                "Completed : ${todo.done}",
                style: TextStyle(color: Colors.red),
              ),
              SizedBox(
                height: 20,
              ),
              Center(
                child: Text(
                  "Your memo : ${todo.memo}",
                  style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
