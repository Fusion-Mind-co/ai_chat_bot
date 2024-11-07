// database_interface.dart

abstract class DatabaseInterface {
  Future<void> createDB();

  Future<List<Map<String, dynamic>>> getChatMessages(int chatId);

  Future<int> postChatDB(int chatId, String inputChat, bool isUserMessage, int? responseToMessageId);

  Future<List<Map<String, dynamic>>> getAllSelectChat();

  Future<Map<String, dynamic>?> getSelectChatById(int id);

  Future<void> updateChatUpdatedAt(int id);

  Future<int?> insertNewChat();

  Future<void> updateChatTitle(String title, int id);

  Future<void> deleteChat(int id);

  Future<void> saveCostDataLocally(
    double nowTotalCost,
    int user_text_length,
    int inputTokens,
    double inCost,
    int gpt_text_length,
    int outputTokens,
    double outCost,
    String model,
  );
}
