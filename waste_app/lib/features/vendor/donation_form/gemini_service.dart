// import 'package:flutter_dotenv/flutter_dotenv.dart';
// import 'package:google_generative_ai/google_generative_ai.dart';

// class GeminiService {
//   // Use 1.5 Flash - it's the current standard
//   final model = GenerativeModel(
//     model: 'gemini-2.5-flash-lite',
//     apiKey: dotenv.env['GEMINI_API_KEY'] ?? '',
//   );

//   Future<String> generateDescription(List<String> foodItems) async {
//     if (foodItems.isEmpty) return 'Fresh food available for donation.';

//     // Construct the content list correctly for the 1.5 model
//     final prompt =
//         '''
//         You are a professional copywriter for "NoMoreWaste," a premium food rescue platform. 
//         Your task is to write a 1-2 sentence description for a food donation post, highlighting the donated food.

//         Donation Items: ${foodItems.join(', ')}.

//         Guidelines:
//         1. Focus on the food – its type, quality, and appeal.
//         2. Keep it concise, clear, and descriptive.
//         3. Use a helpful, community-oriented, and professional tone.
//         4. Avoid casual or social media-style language.
//         5. Encourage trust and interest from potential recipients or volunteers.
//         ''';

//     final content = [Content.text(prompt)];

//     try {
//       // We pass the request options here if needed, but usually,
//       // just updating the model name to 1.5-flash is enough for the latest SDK.
//       final response = await model.generateContent(content);

//       return response.text ?? 'Nutritious food items ready for pickup.';
//     } catch (e) {
//       print('GEMINI ERROR: $e');
//       return 'Various food items available for donation.';
//     }
//   }
// }