import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import 'idea_models.dart';
import 'ideas_request.dart';

class IdeasApiService {
  IdeasApiService._({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient.instance;

  static final instance = IdeasApiService._();

  final ApiClient _apiClient;

  Future<List<GiftIdea>> fetchGiftIdeas(IdeasRequest request) async {
    final json = await _apiClient.postJson(
      ApiEndpoints.giftIdeas,
      data: request.toJson(),
    );
    final giftIdeas = json['giftIdeas'];
    final gifts = giftIdeas is Map ? giftIdeas['gifts'] : null;

    if (gifts is! List) {
      return const [];
    }

    return gifts
        .whereType<Map>()
        .map((item) => GiftIdea.fromJson(Map<String, dynamic>.from(item)))
        .where((idea) => idea.title.trim().isNotEmpty)
        .toList();
  }

  Future<List<MessageIdea>> fetchMessageIdeas(IdeasRequest request) async {
    final json = await _apiClient.postJson(
      ApiEndpoints.messageIdeas,
      data: request.toJson(),
    );
    final suggestions = json['suggestions'];
    final wishes = suggestions is Map ? suggestions['Wishes'] : null;

    if (wishes is! List) {
      return const [];
    }

    return wishes
        .whereType<Map>()
        .map((item) => MessageIdea.fromJson(Map<String, dynamic>.from(item)))
        .where((idea) => idea.wish.trim().isNotEmpty)
        .toList();
  }
}
