import 'package:flutter/material.dart';
import 'package:cactus/cactus.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cactus Test',
      theme: ThemeData(primarySwatch: Colors.green),
      home: CactusTestScreen(),
    );
  }
}

class CactusTestScreen extends StatefulWidget {
  @override
  _CactusTestScreenState createState() => _CactusTestScreenState();
}

class _CactusTestScreenState extends State<CactusTestScreen> {
  final lm = CactusLM();
  String status = "Ready to test Cactus SDK";
  String response = "";
  bool isLoading = false;

  Future<void> testCactus() async {
    setState(() {
      isLoading = true;
      status = "Downloading model (first time only)...";
      response = "";
    });

    try {
      // Download model
      await lm.downloadModel(
        model: "qwen3-0.6",
        downloadProcessCallback: (progress, msg, isError) {
          setState(() {
            if (isError) {
              status = "Error: $msg";
            } else if (progress != null) {
              status = "$msg (${(progress * 100).toStringAsFixed(0)}%)";
            } else {
              status = msg;
            }
          });
        },
      );

      // Initialize
      setState(() => status = "Loading model into memory...");
      await lm.initializeModel();

      // Generate
      setState(() => status = "Generating response...");
      final result = await lm.generateCompletion(
        messages: [
          ChatMessage(content: "Hello! Introduce yourself in one sentence.", role: "user"),
        ],
      );

      setState(() {
        if (result.success) {
          status = "✓ Success!";
          response = "${result.response}\n\n"
              "⚡ Speed: ${result.tokensPerSecond.toStringAsFixed(1)} tok/s\n"
              "⏱️ First token: ${result.timeToFirstTokenMs.toStringAsFixed(0)}ms\n"
              "📊 Total tokens: ${result.totalTokens}";
        } else {
          status = "❌ Failed";
          response = result.response;
        }
      });
    } catch (e) {
      setState(() {
        status = "❌ Error occurred";
        response = e.toString();
      });
    } finally {
      setState(() => isLoading = false);
      lm.unload();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Cactus SDK Test'),
      ),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(
              isLoading ? Icons.hourglass_empty : Icons.rocket_launch,
              size: 60,
              color: Colors.green,
            ),
            SizedBox(height: 20),
            Text(
              status,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
            if (response.isNotEmpty)
              Expanded(
                child: SingleChildScrollView(
                  child: Container(
                    padding: EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      response,
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: isLoading ? null : testCactus,
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 15),
                child: Text(
                  isLoading ? 'Testing...' : 'Test Cactus SDK',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
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
        colorScheme: .fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          //
          // TRY THIS: Invoke "debug painting" (choose the "Toggle Debug Paint"
          // action in the IDE, or press "p" in the console), to see the
          // wireframe for each widget.
          mainAxisAlignment: .center,
          children: [
            const Text('You have pushed the button this many times:'),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
