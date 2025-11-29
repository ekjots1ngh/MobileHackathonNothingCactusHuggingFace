import 'package:cactus/cactus.dart';

/// Simple wrapper around Cactus LLM + RAG usage.
class CactusService {
  final CactusLM lm = CactusLM();
  final CactusRAG rag = CactusRAG();

  /// Initialize models and RAG. Call once at app startup.
  Future<void> initialize() async {
    // Download and initialize model (first run will download weights).
    await lm.downloadModel(model: 'qwen3-0.6');
    await lm.initializeModel();

    // Initialize RAG and set embedding generator.
    await rag.initialize();
    rag.setEmbeddingGenerator((String text) async {
      final embedResult = await lm.generateEmbedding(text: text);
      return embedResult.embeddings;
    });
  }

  /// Store a document into the RAG store.
  Future<void> storeDocument({
    required String fileName,
    required String filePath,
    required String content,
    required int fileSize,
  }) async {
    await rag.storeDocument(
      fileName: fileName,
      filePath: filePath,
      content: content,
      fileSize: fileSize,
    );
  }

  /// Search the RAG index and answer the user query using the LM.
  Future<String> answerQuery({required String userQuery, int limit = 3}) async {
    final searchResults = await rag.search(text: userQuery, limit: limit);

    final context = searchResults.map((r) => r.chunk.content).join('\n\n');

    final result = await lm.generateCompletion(
      messages: [
        ChatMessage(role: 'system', content: 'Answer based on this context: $context'),
        ChatMessage(role: 'user', content: userQuery),
      ],
    );

    return result.response;
  }

  /// Unload models when not needed anymore.
  Future<void> dispose() async {
    lm.unload();
    // If the RAG library has an unload/shutdown method, call it here.
  }
}
