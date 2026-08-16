/// AI 配置页的模型发现与可用性测试边界。
abstract interface class AiConfigHttpPort {
  Future<List<String>> fetchModels({
    required String apiUrl,
    String apiKey = '',
  });

  Future<int> testModel({
    required String apiUrl,
    required String model,
    String apiKey = '',
  });
}
