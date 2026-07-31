import '../../application/ai/ai_config_http_port.dart';
import '../../domain/ports/application_http_request_port.dart';
import '../../services/ai_config_http_service.dart';

/// 将现有 AI HTTP service 适配到应用端口。
final class AiConfigHttpPortAdapter implements AiConfigHttpPort {
  AiConfigHttpPortAdapter(ApplicationHttpRequestPort httpPort)
    : _service = AiConfigHttpService(httpPort);

  final AiConfigHttpService _service;

  @override
  Future<List<String>> fetchModels({
    required String apiUrl,
    String apiKey = '',
  }) {
    return _service.fetchModels(apiUrl: apiUrl, apiKey: apiKey);
  }

  @override
  Future<int> testModel({
    required String apiUrl,
    required String model,
    String apiKey = '',
  }) {
    return _service.testModel(apiUrl: apiUrl, model: model, apiKey: apiKey);
  }
}
