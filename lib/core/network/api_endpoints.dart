class ApiEndpoints {
  ApiEndpoints._();

  static const baseUrl = String.fromEnvironment(
    'SLAMORA_API_BASE_URL',
    defaultValue: 'https://ai-backend-u5og.onrender.com',
  );

  static const giftIdeas = '/gift-ideas';
  static const messageIdeas = '/wishes-message-ideas';
}
