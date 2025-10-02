import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';

// Import the global variable
import '../pages/sign_in.dart';

class ApiService {
  // Fixed base URL - removed the duplicate path
  static const String baseUrl = 'http://192.168.1.102:5000';

  // Increased timeout duration for audio processing
  static const Duration timeoutDuration = Duration(seconds: 90);

  // Get supported languages
  static Future<List<Map<String, dynamic>>> getLanguages() async {
    try {
      print('Fetching languages from: $baseUrl/api/languages');

      final response = await http.get(
        Uri.parse('$baseUrl/api/languages'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(Duration(seconds: 15));

      print('Languages response status: ${response.statusCode}');
      print('Languages response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['languages']);
      }
      throw Exception('Failed to load languages: ${response.statusCode}');
    } catch (e) {
      print('Error fetching languages: $e');
      throw Exception('Error fetching languages: $e');
    }
  }
  //Combined query request
  static Future<Map<String, dynamic>> processCombinedQuery({
    String? text,
    required String languageCode,
    File? imageFile,
    File? audioFile,
  }) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/process-combined'));

      // Add text if available
      if (text != null && text.isNotEmpty) {
        request.fields['text'] = text;
      }

      request.fields['language'] = languageCode;

      // Add image if available
      if (imageFile != null) {
        request.files.add(await http.MultipartFile.fromPath(
          'image',
          imageFile.path,
          contentType: MediaType('image', 'jpeg'),
        ));
      }

      // Add audio if available
      if (audioFile != null) {
        request.files.add(await http.MultipartFile.fromPath(
          'audio',
          audioFile.path,
          contentType: MediaType('audio', 'wav'),
        ));
      }

      var response = await request.send();
      var responseData = await response.stream.bytesToString();
      var jsonResponse = json.decode(responseData);

      return {
        'success': true,
        'analysis': jsonResponse['analysis'],
        'query': jsonResponse['transcribed_text'] ?? text,
      };

    } catch (e) {
      return {
        'success': false,
        'error': 'Failed to process combined query: $e'
      };
    }
  }
  // Process query with image and/or audio
  static Future<Map<String, dynamic>> processQuery({
    required String languageCode,
    File? imageFile,
    File? audioFile,
  }) async {
    try {
      print('Processing query with language: $languageCode');
      print('Image file: ${imageFile?.path}');
      print('Audio file: ${audioFile?.path}');

      // Validate that at least one file is provided
      if (imageFile == null && audioFile == null) {
        return {
          'success': false,
          'error': 'At least one file (image or audio) must be provided'
        };
      }

      // Use the global language variable from sign_in.dart
      String selectedLanguage = selectedLanguageGlobal;
      print('Using global language: $selectedLanguage');

      // Prepare request body
      Map<String, dynamic> requestBody = {
        'language': selectedLanguage,
      };

      // Add image if provided
      if (imageFile != null) {
        try {
          // Check file size (limit to 5MB)
          int fileSize = await imageFile.length();
          if (fileSize > 5 * 1024 * 1024) {
            return {
              'success': false,
              'error': 'Image file too large. Please select an image smaller than 5MB.'
            };
          }

          Uint8List imageBytes = await imageFile.readAsBytes();
          String base64Image = base64Encode(imageBytes);

          // Determine image format from file extension
          String extension = imageFile.path
              .split('.')
              .last
              .toLowerCase();
          String mimeType = _getImageMimeType(extension);

          requestBody['image'] = 'data:$mimeType;base64,$base64Image';
          print('Image encoded successfully (${imageBytes.length} bytes)');
        } catch (e) {
          print('Error encoding image: $e');
          return {
            'success': false,
            'error': 'Failed to process image file: $e'
          };
        }
      }

      // Add audio if provided
      if (audioFile != null) {
        try {
          // Check file size (limit to 10MB for audio)
          int fileSize = await audioFile.length();
          if (fileSize > 10 * 1024 * 1024) {
            return {
              'success': false,
              'error': 'Audio file too large. Please select an audio file smaller than 10MB.'
            };
          }

          Uint8List audioBytes = await audioFile.readAsBytes();
          String base64Audio = base64Encode(audioBytes);

          // For audio, send it with proper mime type prefix
          String extension = audioFile.path
              .split('.')
              .last
              .toLowerCase();
          String mimeType = _getAudioMimeType(extension);

          requestBody['audio'] = 'data:$mimeType;base64,$base64Audio';
          print('Audio encoded successfully (${audioBytes.length} bytes)');
        } catch (e) {
          print('Error encoding audio: $e');
          return {
            'success': false,
            'error': 'Failed to process audio file: $e'
          };
        }
      }

      print('Sending request to: $baseUrl/api/process-query');
      print('Request body keys: ${requestBody.keys}');

      // Send request with longer timeout for audio processing
      final response = await http.post(
        Uri.parse('$baseUrl/api/process-query'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(requestBody),
      ).timeout(timeoutDuration);

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return {
          'success': true,
          ...responseData,
        };
      } else {
        return {
          'success': false,
          'error': 'Server error: ${response.statusCode} - ${response.body}'
        };
      }
    } on SocketException catch (e) {
      print('Network error: $e');
      return {
        'success': false,
        'error': 'Network connection failed. Please check your connection and server status.'
      };
    } on HttpException catch (e) {
      print('HTTP error: $e');
      return {
        'success': false,
        'error': 'HTTP error: $e'
      };
    } on FormatException catch (e) {
      print('JSON parsing error: $e');
      return {
        'success': false,
        'error': 'Invalid response format from server'
      };
    } catch (e) {
      print('Unexpected error: $e');
      // Check if it's a timeout error and provide more specific message
      if (e.toString().contains('TimeoutException')) {
        return {
          'success': false,
          'error': 'Request timed out. The server is taking too long to process your request. Please try with a smaller file or check your internet connection.'
        };
      }
      return {
        'success': false,
        'error': 'Unexpected error: $e'
      };
    }
  }

  // Process text-only queries
  static Future<Map<String, dynamic>> processTextQuery({
    required String text,
  }) async {
    try {
      // Use the global language variable from sign_in.dart
      String selectedLanguage = selectedLanguageGlobal;
      print('Processing text query: $text');
      print('Language: $selectedLanguage');

      Map<String, dynamic> requestBody = {
        'language': selectedLanguage,
        'text': text,
      };

      print('Sending text request to: $baseUrl/api/process-text');

      final response = await http.post(
        Uri.parse('$baseUrl/api/process-text'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(requestBody),
      ).timeout(Duration(seconds: 45)); // Shorter timeout for text

      print('Text response status: ${response.statusCode}');
      print('Text response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return {
          'success': true,
          ...responseData,
        };
      } else {
        return {
          'success': false,
          'error': 'Server error: ${response.statusCode} - ${response.body}'
        };
      }
    } on SocketException catch (e) {
      print('Network error: $e');
      return {
        'success': false,
        'error': 'Network connection failed. Please check your connection and server status.'
      };
    } catch (e) {
      print('Error processing text: $e');
      if (e.toString().contains('TimeoutException')) {
        return {
          'success': false,
          'error': 'Request timed out. Please try again or check your internet connection.'
        };
      }
      return {
        'success': false,
        'error': 'Error processing text: $e'
      };
    }
  }

  // Helper method to get image MIME type
  static String _getImageMimeType(String extension) {
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'bmp':
        return 'image/bmp';
      default:
        return 'image/jpeg'; // default fallback
    }
  }

  // Helper method to get audio MIME type
  static String _getAudioMimeType(String extension) {
    switch (extension) {
      case 'mp3':
        return 'audio/mpeg';
      case 'wav':
        return 'audio/wav';
      case 'm4a':
        return 'audio/mp4';
      case 'aac':
        return 'audio/aac';
      case 'ogg':
        return 'audio/ogg';
      case 'flac':
        return 'audio/flac';
      default:
        return 'audio/wav'; // default fallback
    }
  }

  // Test server connection
  static Future<bool> testConnection() async {
    try {
      print('Testing connection to: $baseUrl');

      final response = await http.get(
        Uri.parse('$baseUrl/health'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(Duration(seconds: 10));

      print('Connection test response: ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      print('Connection test failed: $e');
      return false;
    }
  }

  // Pick image from gallery or camera
  static Future<File?> pickImage(
      {ImageSource source = ImageSource.gallery}) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        final file = File(pickedFile.path);
        print('Image selected: ${file.path}');
        print('Image size: ${await file.length()} bytes');
        return file;
      }
      return null;
    } catch (e) {
      print('Error picking image: $e');
      return null;
    }
  }

  // Pick audio file
  static Future<File?> pickAudio() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = File(result.files.first.path!);
        print('Audio selected: ${file.path}');
        print('Audio size: ${await file.length()} bytes');
        return file;
      }
      return null;
    } catch (e) {
      print('Error picking audio: $e');
      return null;
    }
  }
}