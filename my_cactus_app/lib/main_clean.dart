import 'package:flutter/material.dart';
import 'package:cactus/cactus.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Memory Master',
      theme: ThemeData(primarySwatch: Colors.deepPurple),
      home: MemoryMasterHome(),
    );
  }
}

class MemoryMasterHome extends StatefulWidget {
  @override
  _MemoryMasterHomeState createState() => _MemoryMasterHomeState();
}

class _MemoryMasterHomeState extends State<MemoryMasterHome> {
  final lm = CactusLM();
  final rag = CactusRAG();
  
  bool isInitialized = false;
  String initStatus = "";
  int totalDocuments = 0;
  int selectedTab = 0;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    setState(() => initStatus = "Downloading model...");

    try {
      await lm.downloadModel(
        model: "qwen3-0.6",
        downloadProcessCallback: (progress, msg, isError) {
          setState(() {
            if (progress != null) {
              initStatus = "Downloading: ${(progress * 100).toStringAsFixed(0)}%";
            } else {
              initStatus = msg;
            }
          });
        },
      );

      setState(() => initStatus = "Initializing...");
      await lm.initializeModel();
      await rag.initialize();

      rag.setEmbeddingGenerator((text) async {
        final result = await lm.generateEmbedding(text: text);
        return result.embeddings;
      });

      final docs = await rag.getAllDocuments();
      
      setState(() {
        isInitialized = true;
        totalDocuments = docs.length;
      });
    } catch (e) {
      setState(() => initStatus = "Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!isInitialized) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 20),
              Text(initStatus, style: TextStyle(fontSize: 16)),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Memory Master'),
        actions: [
          Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('$totalDocuments docs'),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildTabs(),
          Expanded(child: _buildTabContent()),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Row(
      children: [
        Expanded(child: _tabButton('Add', 0, Icons.add)),
        Expanded(child: _tabButton('Ask', 1, Icons.question_answer)),
        Expanded(child: _tabButton('View', 2, Icons.list)),
      ],
    );
  }

  Widget _tabButton(String title, int index, IconData icon) {
    final isSelected = selectedTab == index;
    return InkWell(
      onTap: () => setState(() => selectedTab = index),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? Colors.deepPurple : Colors.grey,
              width: 3,
            ),
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? Colors.deepPurple : Colors.grey),
            Text(title),
          ],
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (selectedTab) {
      case 0:
        return Center(child: Text('Add Memory tab (implement UI)'));
      case 1:
        return Center(child: Text('Ask Question tab (implement UI)'));
      case 2:
        return Center(child: Text('View Documents tab (implement UI)'));
      default:
        return Container();
    }
  }
}

class AddMemoryTab extends StatefulWidget {
  final CactusRAG rag;
  final VoidCallback onDocumentAdded;

  AddMemoryTab({required this.rag, required this.onDocumentAdded});

  @override
  _AddMemoryTabState createState() => _AddMemoryTabState();
}

class _AddMemoryTabState extends State<AddMemoryTab> {
  final titleController = TextEditingController();
  final contentController = TextEditingController();
  bool isAdding = false;
  String statusMessage = "";

  Future<void> _addDocument() async {
    if (titleController.text.isEmpty || contentController.text.isEmpty) {
      setState(() => statusMessage = "Please enter both title and content");
      return;
    }

    setState(() {
      isAdding = true;
      statusMessage = "Adding to memory...";
    });

    try {
      await widget.rag.storeDocument(
        fileName: titleController.text,
        filePath: "/local/${titleController.text}",
        content: contentController.text,
        fileSize: contentController.text.length,
      );

      setState(() {
        statusMessage = "✓ Added to memory successfully!";
        isAdding = false;
      });
      
      widget.onDocumentAdded();
      
      // Clear fields
      titleController.clear();
      contentController.clear();
      
      // Clear success message after 2 seconds
      Future.delayed(Duration(seconds: 2), () {
        if (mounted) {
          setState(() => statusMessage = "");
        }
      });
    } catch (e) {
      setState(() {
        statusMessage = "Error: $e";
        isAdding = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Add to Memory',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'Store notes, documents, or any information you want to remember',
            style: TextStyle(color: Colors.grey[600]),
          ),
          SizedBox(height: 20),
          TextField(
            controller: titleController,
            decoration: InputDecoration(
              labelText: 'Title',
              hintText: 'e.g., Recipe for Pasta, Study Notes Ch.5',
              border: OutlineInputBorder(),
            ),
          ),
          SizedBox(height: 16),
          Expanded(
            child: TextField(
              controller: contentController,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              decoration: InputDecoration(
                labelText: 'Content',
                hintText: 'Enter the information you want to store...',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
          ),
          SizedBox(height: 16),
          if (statusMessage.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Text(
                statusMessage,
                style: TextStyle(
                  color: statusMessage.startsWith('✓') ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ElevatedButton.icon(
            onPressed: isAdding ? null : _addDocument,
            icon: Icon(isAdding ? Icons.hourglass_empty : Icons.save),
            label: Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text(
                isAdding ? 'Adding to Memory...' : 'Add to Memory',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AskQuestionTab extends StatefulWidget {
  final CactusLM lm;
  final CactusRAG rag;

  AskQuestionTab({required this.lm, required this.rag});

  @override
  _AskQuestionTabState createState() => _AskQuestionTabState();
}

class _AskQuestionTabState extends State<AskQuestionTab> {
  final questionController = TextEditingController();
  bool isSearching = false;
  String answer = "";
  List<ChunkSearchResult> searchResults = [];

  Future<void> _askQuestion() async {
    if (questionController.text.isEmpty) {
      setState(() => answer = "Please enter a question");
      return;
    }

    setState(() {
      isSearching = true;
      answer = "";
      searchResults = [];
    });

    try {
      // Search for relevant documents
      final results = await widget.rag.search(
        text: questionController.text,
        limit: 3,
      );

      setState(() => searchResults = results);

      if (results.isEmpty) {
        setState(() {
          answer = "No relevant information found in memory. Try adding some documents first!";
          isSearching = false;
        });
        return;
      }

      // Build context from search results
      String context = results
          .map((r) => r.chunk.content)
          .join("\n\n---\n\n");

      // Generate answer using LLM with context
      final completion = await widget.lm.generateCompletion(
        messages: [
          ChatMessage(
            role: "system",
            content: "You are a helpful assistant. Answer the user's question based ONLY on the context provided. If the context doesn't contain enough information, say so. Context:\n\n$context",
          ),
          ChatMessage(
            role: "user",
            content: questionController.text,
          ),
        ],
        params: CactusCompletionParams(maxTokens: 300),
      );

      setState(() {
        if (completion.success) {
          answer = completion.response;
        } else {
          answer = "Error generating answer: ${completion.response}";
        }
        isSearching = false;
      });
    } catch (e) {
      setState(() {
        answer = "Error: $e";
        isSearching = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Ask a Question',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'Search your stored knowledge and get AI-powered answers',
            style: TextStyle(color: Colors.grey[600]),
          ),
          SizedBox(height: 20),
          TextField(
            controller: questionController,
            decoration: InputDecoration(
              labelText: 'Your Question',
              hintText: 'What do you want to know?',
              border: OutlineInputBorder(),
            ),
            onSubmitted: (_) => _askQuestion(),
          ),
          SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: isSearching ? null : _askQuestion,
            icon: Icon(isSearching ? Icons.hourglass_empty : Icons.search),
            label: Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text(
                isSearching ? 'Searching...' : 'Search Memory',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
          SizedBox(height: 20),
          if (answer.isNotEmpty || searchResults.isNotEmpty)
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (answer.isNotEmpty) ...[
                      Text(
                        'Answer:',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue[200]!),
                        ),
                        child: Text(
                          answer,
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                    if (searchResults.isNotEmpty) ...[
                      SizedBox(height: 20),
                      Text(
                        'Sources (${searchResults.length} documents):',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      ...searchResults.map((result) {
                        final docName = result.chunk.document.target?.fileName ?? 'Unknown';
                        return Container(
                          margin: EdgeInsets.only(bottom: 12),
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      docName,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.green[100],
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      'Match: ${(100 - result.distance).toStringAsFixed(0)}%',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.green[900],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 8),
                              Text(
                                result.chunk.content.length > 150
                                    ? result.chunk.content.substring(0, 150) + '...'
                                    : result.chunk.content,
                                style: TextStyle(fontSize: 13),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class ViewDocumentsTab extends StatefulWidget {
  final CactusRAG rag;

  ViewDocumentsTab({required this.rag});

  @override
  _ViewDocumentsTabState createState() => _ViewDocumentsTabState();
}

class _ViewDocumentsTabState extends State<ViewDocumentsTab> {
  List<Document> documents = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  Future<void> _loadDocuments() async {
    setState(() => isLoading = true);
    try {
      final docs = await widget.rag.getAllDocuments();
      setState(() {
        documents = docs;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  Future<void> _deleteDocument(int id) async {
    try {
      await widget.rag.deleteDocument(id);
      _loadDocuments();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting document: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (documents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_open, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No documents stored yet',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Add some memories to get started!',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: documents.length,
      itemBuilder: (context, index) {
        final doc = documents[index];
        return Card(
          margin: EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: Icon(Icons.description, color: Colors.deepPurple),
            title: Text(
              doc.fileName,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 4),
                Text(
                  doc.content.length > 100
                      ? doc.content.substring(0, 100) + '...'
                      : doc.content,
                ),
                SizedBox(height: 4),
                Text(
                  '${(doc.fileSize ?? 0)} characters',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            isThreeLine: true,
            trailing: IconButton(
              icon: Icon(Icons.delete, color: Colors.red),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('Delete Document'),
                    content: Text('Are you sure you want to delete "${doc.fileName}"?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _deleteDocument(doc.id);
                        },
                        child: Text('Delete', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
