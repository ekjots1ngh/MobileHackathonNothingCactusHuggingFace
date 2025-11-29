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

      setState(() => status = "Loading model into memory...");
      await lm.initializeModel();

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
      appBar: AppBar(title: Text('Cactus SDK Test')),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(isLoading ? Icons.hourglass_empty : Icons.rocket_launch, size: 60, color: Colors.green),
            SizedBox(height: 20),
            Text(status, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            SizedBox(height: 20),
            if (response.isNotEmpty)
              Expanded(
                child: SingleChildScrollView(
                  child: Container(
                    padding: EdgeInsets.all(15),
                    decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(10)),
                    child: Text(response, style: TextStyle(fontSize: 16)),
                  ),
                ),
              ),
            SizedBox(height: 20),
            ElevatedButton(onPressed: isLoading ? null : testCactus, child: Padding(padding: EdgeInsets.symmetric(vertical: 15), child: Text(isLoading ? 'Testing...' : 'Test Cactus SDK', style: TextStyle(fontSize: 18)))),
          ],
        ),
      ),
    );
  }
}
