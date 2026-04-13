import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// Uses Google ML Kit to extract text from a photo file.
Future<String> recognizeTextFromFile(String filePath) async {
  final inputImage = InputImage.fromFile(File(filePath));
  final recognizer = TextRecognizer();
  try {
    final result = await recognizer.processImage(inputImage);
    return result.text;
  } finally {
    await recognizer.close();
  }
}
