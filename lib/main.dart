import 'package:english_words/english_words.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
    DeviceOrientation.portraitDown,
    DeviceOrientation.portraitUp,
  ]).then((_) {
    runApp(MyApp());
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MyAppState(),
      child: MaterialApp(
        title: 'Namer App',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme:
              ColorScheme.fromSeed(seedColor: Color.fromARGB(255, 255, 29, 29)),
        ),
        home: MyHomePage(),
      ),
    );
  }
}

class MyAppState extends ChangeNotifier {
  var current = WordPair.random();
  late List<WordPair> favorites;
  var initialized = false;

  void getNext() {
    current = WordPair.random();
    notifyListeners();
  }

  void toogleFavorite() {
    if (favorites.contains(current)) {
      favorites.remove(current);
    } else {
      favorites.add(current);
    }
    _saveToStorage();
    notifyListeners();
  }

  void deleteFavorite(favorite) {
    favorites.remove(favorite);
    _saveToStorage();
    notifyListeners();
  }

  static String _wordPairsToJson(favorite) {
    List<String> tab = [""];
    for (var i in favorite) {
      tab.add(i.first);
      tab.add(i.second);
    }
    print(tab);

    String jsonString = jsonEncode(tab.toString());
    return jsonString;
  }

  Future<bool> _saveToStorage() async {
    var storage = await SharedPreferences.getInstance();
    return await storage.setString('favorites', _wordPairsToJson(favorites));
  }

  static List<WordPair> _wordPairsFromJson(String jsonString) {
    List<WordPair> result = [WordPair("a", "a")];
    result.remove(WordPair("a", "a"));
    var jsonList = jsonDecode(jsonString);
    jsonList = jsonList.substring(1, jsonList.length - 1);
    List<String> list = jsonList.split(", ");
    list.remove("");
    int longeur = list.length;
    print(longeur);
    print(list);
    for (var i = 0; i <= longeur / 2; i = i + 2) {
      result.add(WordPair(list[i], list[i + 1]));
    }
    return result;
  }

  Future<void> init() async {
    if (initialized) {
      await Future.delayed(Duration(seconds: 5));
      return;
    }

    final storage = await SharedPreferences.getInstance();
    final data = storage.getString('favorites');

    if (data == null) {
      favorites = <WordPair>[];
    } else {
      favorites = _wordPairsFromJson(data);
    }

    initialized = true;
  }
}

class GeneratorPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    var pair = appState.current;

    IconData icon;
    if (appState.favorites.contains(pair)) {
      icon = Icons.favorite;
    } else {
      icon = Icons.favorite_border;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          BigCard(pair: pair),
          SizedBox(height: 10.0),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ↓ Ajoutez ces 2 composants
              ElevatedButton.icon(
                onPressed: () {
                  appState.toogleFavorite();
                },
                icon: Icon(icon),
                label: Text("J'aime"),
              ),
              SizedBox(width: 10),

              ElevatedButton(
                onPressed: () {
                  appState.getNext();
                },
                child: Text('Suivant'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class BigCard extends StatelessWidget {
  const BigCard({
    super.key,
    required this.pair,
  });

  final WordPair pair;

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    var style = theme.textTheme.displayMedium!.copyWith(
      color: theme.colorScheme.onPrimary,
    );

    return Card(
      color: theme.colorScheme.primary,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Text(
          pair.asLowerCase,
          style: style,
          semanticsLabel: pair.asPascalCase,
        ),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  var selectedIndex = 0;

  Future<void>? initializer;

  @override
  void initState() {
    super.initState();
    var appState = context.read<MyAppState>();
    initializer = appState.init();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: initializer,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return Center(
            child: CircularProgressIndicator(),
          );
        }

        Widget page;
        switch (selectedIndex) {
          case 0:
            page = GeneratorPage();
            break;
          case 1:
            page = FavoritesPage();
            break;
          default:
            throw UnimplementedError('aucun composant pour $selectedIndex');
        }

        return LayoutBuilder(builder: (context, constraints) {
          if (constraints.maxWidth < 11500) {
            return Scaffold(
              body: Container(
                color: Theme.of(context).colorScheme.primaryContainer,
                child: page,
              ),
              bottomNavigationBar: BottomNavigationBar(
                items: [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.home),
                    label: 'Accueil',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.favorite),
                    label: 'Favoris',
                  ),
                ],
                currentIndex: selectedIndex,
                onTap: (value) {
                  setState(() {
                    selectedIndex = value;
                  });
                },
              ),
            );
          } else {
            return Text('Écran large');
          }
        });
      },
    );
  }
}

class FavoritesPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    var style = theme.textTheme.displayMedium!.apply(color: Color(0xFF42A5F5));
    var styleb = theme.textTheme.displayLarge!;
    var favorites = context.watch<MyAppState>().favorites;
    var appState = context.watch<MyAppState>();

    return ListView(children: [
      Text('Favoris : ', style: styleb),
      for (var fv in favorites)
        Card(
          child: ListTile(
            title: Text(fv.asLowerCase, style: style),
            trailing: ElevatedButton.icon(
              onPressed: () {
                appState.deleteFavorite(fv);
              },
              icon: Icon(Icons.delete),
              label: Text("Supprimer"),
            ),
          ),
        ),
    ]);
  }
}
