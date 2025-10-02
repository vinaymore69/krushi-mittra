import sys
import google.generativeai as genai
import speech_recognition as sr
from googletrans import Translator
from gtts import gTTS
import pygame
from PIL import Image
import os
import tempfile
import re
import warnings
import time
import base64
import io
import wave
import struct

# Try to import pydub, but don't fail if FFmpeg is missing
try:
    from pydub import AudioSegment
    PYDUB_AVAILABLE = True
except Exception as e:
    print(f"⚠️ pydub not available or FFmpeg missing: {e}")
    PYDUB_AVAILABLE = False

# Suppress warnings
warnings.filterwarnings("ignore")

class MultilingualFarmerAgent:
    def __init__(self, gemini_api_key):
        # Initialize Gemini
        genai.configure(api_key=gemini_api_key)
        self.model = genai.GenerativeModel('gemini-2.0-flash-exp')

        # Initialize other services
        self.translator = Translator()
        self.recognizer = sr.Recognizer()

        # Initialize pygame for audio playback
        pygame.mixer.init()

        # Updated language mapping to match Flutter app
        self.supported_languages = {
            'en': {'name': 'English', 'tts_code': 'en', 'display': 'English', 'sr_code': 'en-US'},
            'hi': {'name': 'हिन्दी', 'tts_code': 'hi', 'display': 'हिन्दी', 'sr_code': 'hi-IN'},
            'mr': {'name': 'मराठी', 'tts_code': 'mr', 'display': 'मराठी', 'sr_code': 'mr-IN'},
            'pa': {'name': 'ਪੰਜਾਬੀ', 'tts_code': 'pa', 'display': 'ਪੰਜਾਬੀ', 'sr_code': 'pa-IN'},
            'kn': {'name': 'ಕನ್ನಡ', 'tts_code': 'kn', 'display': 'ಕನ್ನಡ', 'sr_code': 'kn-IN'},
            'ta': {'name': 'தமிழ்', 'tts_code': 'ta', 'display': 'தமிழ்', 'sr_code': 'ta-IN'},
            'te': {'name': 'తెలుగు', 'tts_code': 'te', 'display': 'తెలుగు', 'sr_code': 'te-IN'},
            'ml': {'name': 'മലയാളം', 'tts_code': 'ml', 'display': 'മലയാളം', 'sr_code': 'ml-IN'},
            'gu': {'name': 'ગુજરાતી', 'tts_code': 'gu', 'display': 'ગુજરાતી', 'sr_code': 'gu-IN'},
            'bn': {'name': 'বাংলা', 'tts_code': 'bn', 'display': 'বাংলা', 'sr_code': 'bn-IN'},
            'or': {'name': 'ଓଡ଼ିଆ', 'tts_code': 'or', 'display': 'ଓଡ଼ିଆ', 'sr_code': 'or-IN'},
            'ur': {'name': 'اردو', 'tts_code': 'ur', 'display': 'اردو', 'sr_code': 'ur-PK'}
        }

        # Language name to code mapping for Flutter integration
        self.language_name_to_code = {
            'English': 'en',
            'हिन्दी': 'hi',
            'मराठी': 'mr',
            'ਪੰਜਾਬੀ': 'pa',
            'ಕನ್ನಡ': 'kn',
            'தமிழ்': 'ta',
            'తెలుగు': 'te',
            'മലയാളം': 'ml',
            'ગુજરાતી': 'gu',
            'বাংলা': 'bn',
            'ଓଡ଼ିଆ': 'or',
            'اردو': 'ur'
        }

    def get_language_code_from_name(self, language_name):
        """Convert language name to language code"""
        return self.language_name_to_code.get(language_name, 'en')

    def get_language_name(self, language_code):
        """Get language name from code"""
        return self.supported_languages.get(language_code, {}).get('name', 'English')

    def get_supported_languages(self):
        """Return supported languages for the dropdown"""
        return [
            {'code': code, 'name': data['name'], 'display': data['display']}
            for code, data in self.supported_languages.items()
        ]

    def save_base64_audio_to_file(self, base64_data):
        """Enhanced audio file saving with better error handling"""
        try:
            print(f"📥 Received base64 audio data (length: {len(base64_data)} chars)")

            # Remove data URL prefix if present
            if base64_data.startswith('data:'):
                header, base64_data = base64_data.split(',', 1)
                print(f"📋 Detected data URL header: {header}")

            # Decode base64 data
            try:
                audio_bytes = base64.b64decode(base64_data)
                print(f"✅ Successfully decoded base64 data: {len(audio_bytes)} bytes")
            except Exception as decode_error:
                print(f"❌ Base64 decode error: {decode_error}")
                return None

            # Create a unique temporary file with proper suffix
            timestamp = int(time.time() * 1000)
            temp_dir = tempfile.gettempdir()
            temp_path = os.path.join(temp_dir, f"audio_{timestamp}.wav")

            print(f"📁 Temp directory: {temp_dir}")
            print(f"📝 Creating temp file: {temp_path}")

            # Write bytes to file
            try:
                with open(temp_path, 'wb') as temp_file:
                    temp_file.write(audio_bytes)

                # Verify file was created and has content
                if os.path.exists(temp_path):
                    file_size = os.path.getsize(temp_path)
                    print(f"✅ Audio file created successfully: {temp_path}")
                    print(f"📊 File size: {file_size} bytes")

                    if file_size == 0:
                        print("⚠️ Warning: Audio file is empty")
                        os.unlink(temp_path)
                        return None

                    return temp_path
                else:
                    print("❌ File was not created")
                    return None

            except Exception as write_error:
                print(f"❌ File write error: {write_error}")
                return None

        except Exception as e:
            print(f"❌ Error in save_base64_audio_to_file: {e}")
            return None

    def is_valid_wave_file(self, file_path):
        """Check if the file is a valid WAV file"""
        try:
            with wave.open(file_path, 'rb') as wav_file:
                # Get basic info
                frames = wav_file.getnframes()
                sample_rate = wav_file.getframerate()
                channels = wav_file.getnchannels()
                sample_width = wav_file.getsampwidth()

                print(f"📊 WAV file info: {frames} frames, {sample_rate}Hz, {channels} channels, {sample_width} bytes/sample")

                # Check if it has actual audio data
                if frames > 0:
                    return True
                else:
                    print("⚠️ WAV file has no audio frames")
                    return False

        except Exception as e:
            print(f"❌ Invalid WAV file: {e}")
            return False

    def convert_to_wav_basic(self, input_path):
        """Basic conversion without FFmpeg - works with simple formats"""
        try:
            print(f"🔄 Attempting basic WAV conversion for: {input_path}")

            # First, check if it's already a valid WAV file
            if self.is_valid_wave_file(input_path):
                print("✅ File is already a valid WAV file")
                return input_path

            # Try to read as raw audio data and create a proper WAV file
            with open(input_path, 'rb') as f:
                audio_data = f.read()

            # Check if this looks like it might be raw PCM data
            if len(audio_data) > 44:  # Must be larger than WAV header
                # Try to create a WAV file assuming 16kHz, mono, 16-bit
                output_path = input_path.replace('.wav', '_fixed.wav')

                # Create WAV header for 16kHz, mono, 16-bit PCM
                sample_rate = 16000
                channels = 1
                bits_per_sample = 16

                # Skip potential existing headers and try to find PCM data
                # Look for patterns that suggest this is audio data
                potential_data = audio_data[44:] if len(audio_data) > 44 else audio_data

                with wave.open(output_path, 'wb') as wav_file:
                    wav_file.setnchannels(channels)
                    wav_file.setsampwidth(bits_per_sample // 8)
                    wav_file.setframerate(sample_rate)
                    wav_file.writeframes(potential_data)

                # Test if the created file is valid
                if self.is_valid_wave_file(output_path):
                    print(f"✅ Successfully created WAV file: {output_path}")
                    return output_path
                else:
                    print("❌ Created WAV file is not valid")
                    if os.path.exists(output_path):
                        os.unlink(output_path)

            print("❌ Could not convert to valid WAV format")
            return None

        except Exception as e:
            print(f"❌ Basic WAV conversion error: {e}")
            return None

    def convert_audio_format(self, input_path):
        """Convert audio with fallback methods"""
        try:
            print(f"🔄 Converting audio format from {input_path}")

            # Method 1: Check if it's already a valid WAV
            if self.is_valid_wave_file(input_path):
                print("✅ File is already a valid WAV file")
                return input_path

            # Method 2: Try pydub if available
            if PYDUB_AVAILABLE:
                try:
                    print("🔄 Trying pydub conversion...")
                    audio = AudioSegment.from_file(input_path)

                    # Convert to optimal format for speech recognition
                    audio = audio.set_frame_rate(16000)
                    audio = audio.set_channels(1)
                    audio = audio.set_sample_width(2)

                    # Create output path
                    output_path = input_path.replace('.wav', '_pydub.wav')
                    audio.export(output_path, format="wav")

                    if self.is_valid_wave_file(output_path):
                        print(f"✅ pydub conversion successful: {output_path}")
                        return output_path
                    else:
                        print("❌ pydub conversion produced invalid file")
                        if os.path.exists(output_path):
                            os.unlink(output_path)

                except Exception as pydub_error:
                    print(f"❌ pydub conversion failed: {pydub_error}")

            # Method 3: Try basic conversion
            converted_path = self.convert_to_wav_basic(input_path)
            if converted_path:
                return converted_path

            # Method 4: Try to use the original file directly
            print("⚠️ Using original file without conversion")
            return input_path

        except Exception as e:
            print(f"❌ Audio conversion error: {e}")
            return input_path

    def speech_to_text_with_language(self, audio_file_path, language_code):
        """Enhanced speech recognition with better error handling"""
        print(f"🎤 Processing audio file: {audio_file_path} for language: {language_code}")

        # Check if file exists
        if not os.path.exists(audio_file_path):
            error_msg = f"Audio file not found: {audio_file_path}"
            print(f"❌ {error_msg}")
            return error_msg

        # Get file size
        try:
            file_size = os.path.getsize(audio_file_path)
            print(f"📊 Original file size: {file_size} bytes")

            if file_size == 0:
                return "Audio file is empty"

        except Exception as e:
            print(f"❌ Error checking file size: {e}")
            return f"Error accessing audio file: {e}"

        # Get the speech recognition code for the selected language
        lang_data = self.supported_languages.get(language_code, self.supported_languages['en'])
        sr_code = lang_data['sr_code']
        lang_name = lang_data['name']

        print(f"🌐 Using language: {lang_name} ({sr_code})")

        # Convert audio to compatible format
        converted_path = self.convert_audio_format(audio_file_path)
        if not converted_path:
            return "Could not process audio file format"

        try:
            # Try multiple approaches for loading the audio file
            audio_data = None

            # Approach 1: Direct WAV file loading
            if self.is_valid_wave_file(converted_path):
                try:
                    with sr.AudioFile(converted_path) as source:
                        print("✅ Audio file loaded as WAV")
                        self.recognizer.adjust_for_ambient_noise(source, duration=0.5)
                        audio_data = self.recognizer.record(source)
                except Exception as wav_error:
                    print(f"❌ WAV loading failed: {wav_error}")

            # Approach 2: Try loading as different formats
            if audio_data is None:
                for file_ext in ['.wav', '.flac', '.aiff']:
                    try:
                        temp_renamed = converted_path + file_ext
                        if converted_path != temp_renamed:
                            # Copy to temp file with different extension
                            import shutil
                            shutil.copy2(converted_path, temp_renamed)

                            with sr.AudioFile(temp_renamed) as source:
                                print(f"✅ Audio loaded as {file_ext}")
                                self.recognizer.adjust_for_ambient_noise(source, duration=0.5)
                                audio_data = self.recognizer.record(source)
                                break

                    except Exception as ext_error:
                        print(f"❌ Failed to load as {file_ext}: {ext_error}")
                        continue
                    finally:
                        # Clean up temp renamed file
                        if 'temp_renamed' in locals() and os.path.exists(temp_renamed):
                            try:
                                os.unlink(temp_renamed)
                            except:
                                pass

            if audio_data is None:
                return "Could not load audio file for speech recognition"

            print("📼 Audio data ready for recognition")

            # Try recognition with the specified language
            try:
                print(f"🔍 Attempting recognition for {lang_name}...")
                text = self.recognizer.recognize_google(
                    audio_data,
                    language=sr_code,
                    show_all=False
                )

                if text and text.strip():
                    print(f"✅ Recognition successful: '{text}'")
                    return text.strip()
                else:
                    return f"No speech detected in the {lang_name} audio"

            except sr.UnknownValueError:
                print(f"⚠️ Could not understand {lang_name} audio, trying fallback...")

                # Try with English as fallback
                try:
                    text = self.recognizer.recognize_google(audio_data, language='en-US')
                    if text and text.strip():
                        print(f"✅ Fallback recognition (English): '{text}'")
                        # Translate to target language if needed
                        if language_code != 'en':
                            try:
                                translated = self.translator.translate(text, dest=language_code)
                                return f"{text} (Translated: {translated.text})"
                            except:
                                return text
                        return text.strip()
                except sr.UnknownValueError:
                    return f"Could not understand the audio in any language"

            except sr.RequestError as e:
                print(f"❌ Google Speech Recognition error: {e}")
                return f"Speech recognition service error: {e}"

        except Exception as e:
            error_msg = f"Error processing audio file: {e}"
            print(f"❌ {error_msg}")
            return error_msg

        finally:
            # Clean up converted file if it's different from original
            if converted_path != audio_file_path and os.path.exists(converted_path):
                try:
                    os.unlink(converted_path)
                    print("🗑️ Cleaned up converted audio file")
                except:
                    pass

    def process_text_query(self, text, target_language="hi"):
        """Process text-based query in selected language"""
        try:
            lang_data = self.supported_languages.get(target_language, self.supported_languages['hi'])
            lang_name = lang_data['name']

            # Language-specific prompts for better compliance
            language_prompts = {
                'pa': "ਕਿਰਪਾ ਕਰਕੇ ਸਿਰਫ਼ ਪੰਜਾਬੀ ਵਿੱਚ ਜਵਾਬ ਦਿਓ। ਕੋਈ ਅੰਗਰੇਜ਼ੀ ਸ਼ਬਦ ਨਹੀਂ।",
                'gu': "કૃપા કરીને ફક્ત ગુજરાતીમાં જ જવાબ આપો। કોઈ અંગ્રેજી શબ્દો નહીં.",
                'mr': "कृपया फक्त मराठीत उत्तर द्या. इंग्रजी शब्द नाहीत.",
                'kn': "ದಯವಿಟ್ಟು ಕನ್ನಡದಲ್ಲಿ ಮಾತ್ರ ಉತ್ತರಿಸಿ। ಯಾವುದೇ ಇಂಗ್ಲಿಷ್ ಪದಗಳಿಲ್ಲ.",
                'ta': "தயவு செய்து தமிழில் மட்டுமே பதிலளிக்கவும். ஆங்கில சொற்கள் இல்லை.",
                'te': "దయచేసి తెలుగులో మాత్రమే సమాధానం ఇవ్వండి। ఇంగ్లీష్ పదాలు లేవు.",
                'ml': "ദയവായി മലയാളത്തിൽ മാത്രം ഉത്തരം നൽകുക। ഇംഗ്ലീഷ് വാക്കുകളില്ല.",
                'bn': "দয়া করে শুধুমাত্র বাংলায় উত্তর দিন। কোন ইংরেজি শব্দ নেই।",
                'ur': "براہ کرم صرف اردو میں جواب دیں۔ کوئی انگریزی الفاظ نہیں۔",
                'hi': "कृपया केवल हिंदी में उत्तर दें। कोई अंग्रेजी शब्द नहीं।",
                'en': "Please respond only in English. No other languages.",
                'or': "ଦୟାକରି କେବଳ ଓଡ଼ିଆରେ ଉତ୍ତର ଦିଅନ୍ତୁ। କୌଣସି ଇଂରାଜୀ ଶବ୍ଦ ନାହିଁ।"
            }

            prompt = f"""
            CRITICAL LANGUAGE INSTRUCTION: {language_prompts.get(target_language, '')}

            You are Krishi Mitra, an agricultural expert helping Indian farmers.

            The farmer asked in {lang_name}: "{text}"

            Provide agricultural advice in {lang_name} only.

            Your response MUST be 100% in {lang_name} and include relevant agricultural guidance based on the query.

            Use simple language that farmers can understand.
            RESPONSE MUST BE COMPLETELY IN {lang_name.upper()} ONLY.

            START YOUR RESPONSE IN {lang_name} NOW:
            """

            response = self.model.generate_content(prompt)
            response_text = response.text

            # If the response contains English, try to translate it
            if any(char.isascii() and char.isalpha() for char in response_text):
                print(f"⚠️ Response contains English, attempting translation to {lang_name}")
                try:
                    translated = self.translator.translate(response_text, dest=target_language)
                    return translated.text
                except:
                    # Emergency fallback
                    return self.get_emergency_response(target_language)

            return response_text

        except Exception as e:
            print(f"Error in text processing: {e}")
            return f"Error processing text query: {e}"

    def analyze_crop_image(self, image_path, query_text="", target_language="hi"):
        """Analyze crop image with language enforcement"""
        try:
            if not os.path.exists(image_path):
                return f"Image file not found: {image_path}"

            image = Image.open(image_path)
            lang_data = self.supported_languages.get(target_language, self.supported_languages['hi'])
            lang_name = lang_data['name']

            # Language-specific prompts for better compliance
            language_prompts = {
                'pa': "ਕਿਰਪਾ ਕਰਕੇ ਸਿਰਫ਼ ਪੰਜਾਬੀ ਵਿੱਚ ਜਵਾਬ ਦਿਓ। ਕੋਈ ਅੰਗਰੇਜ਼ੀ ਸ਼ਬਦ ਨਹੀਂ।",
                'gu': "કૃપા કરીને ફક્ત ગુજરાતીમાં જ જવાબ આપો। કોઈ અંગ્રેજી શબ્દો નહીં.",
                'mr': "कृपया फक्त मराठीत उत्तर द्या. इंग्रजी शब्द नाहीत.",
                'kn': "ದಯವಿಟ್ಟು ಕನ್ನಡದಲ್ಲಿ ಮಾತ್ರ ಉತ್ತರಿಸಿ। ಯಾವುದೇ ಇಂಗ್ಲಿಷ್ ಪದಗಳಿಲ್ಲ.",
                'ta': "தயவு செய்து தமிழில் மட்டுமே பதிலளிக்கவும். ஆங்கில சொற்கள் இல்லை.",
                'te': "దయచేసి తెలుగులో మాత్రమే సమాధానం ఇవ్వండి। ఇంగ్లీష్ పదాలు లేవు.",
                'ml': "ദയവായി മലയാളത്തിൽ മാത്രം ഉത്തരം നൽകുക। ഇംഗ്ലീഷ് വാക്കുകളില്ല.",
                'bn': "দয়া করে শুধুমাত্র বাংলায় উত্তর দিন। কোন ইংরেজি শব্দ নেই।",
                'ur': "براہ کرم صرف اردو میں جواب دیں۔ کوئی انگریزی الفاظ نہیں۔",
                'hi': "कृपया केवल हिंदी में उत्तर दें। कोई अंग्रेजी शब्द नहीं।",
                'en': "Please respond only in English. No other languages.",
                'or': "ଦୟାକରି କେବଳ ଓଡ଼ିଆରେ ଉତ୍ତର ଦିଅନ୍ତୁ। କୌଣସି ଇଂରାଜୀ ଶବ୍ଦ ନାହିଁ।"
            }

            prompt = f"""
            CRITICAL LANGUAGE INSTRUCTION: {language_prompts.get(target_language, '')}

            You are Krishi Mitra, an agricultural expert helping Indian farmers.

            The farmer asked in {lang_name}: "{query_text}"

            Analyze this crop image and provide agricultural advice in {lang_name} only.

            Your response MUST be 100% in {lang_name} and include:
            1. Crop identification
            2. Health status assessment
            3. Disease/pest analysis
            4. Nutrient deficiencies
            5. Treatment recommendations
            6. Prevention measures

            Use simple language that farmers can understand.
            RESPONSE MUST BE COMPLETELY IN {lang_name.upper()} ONLY.

            START YOUR RESPONSE IN {lang_name} NOW:
            """

            response = self.model.generate_content([prompt, image])
            response_text = response.text

            # If the response contains English, try to translate it
            if any(char.isascii() and char.isalpha() for char in response_text):
                print(f"⚠️ Response contains English, attempting translation to {lang_name}")
                try:
                    translated = self.translator.translate(response_text, dest=target_language)
                    return translated.text
                except:
                    # Emergency fallback
                    return self.get_emergency_response(target_language)

            return response_text

        except Exception as e:
            print(f"Error analyzing image: {e}")
            return f"Error analyzing image: {e}"

    def get_emergency_response(self, language):
        """Emergency response when all else fails"""
        responses = {
            'mr': "माफ करा, तांत्रिक अडचण आहे. कृपया पुन्हा प्रयत्न करा.",
            'hi': "क्षमा करें, तकनीकी समस्या है। कृपया पुनः प्रयास करें।",
            'gu': "માફ કરશો, તકનીકી સમસ્યા છે. કૃપા કરીને ફરી પ્રયત્ન કરો.",
            'kn': "ಕ್ಷಮಿಸಿ, ತಾಂತ್ರಿಕ ಸಮಸ್ಯೆ ಇದೆ. ದಯವಿಟ್ಟು ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ.",
            'ta': "மன்னிக்கவும், தொழில்நுட்ப சிக்கல் உள்ளது. தயவு செய்து மீண்டும் முயற்சிக்கவும்.",
            'te': "క్షమించండి, సాంకేతిక సమస్య ఉంది. దయచేసి మళ్లీ ప్రయత్నించండి.",
            'pa': "ਮਾਫ ਕਰਨਾ, ਤਕਨੀਕੀ ਸਮੱਸਿਆ ਹੈ. ਕਿਰਪਾ ਕਰਕੇ ਦੁਬਾਰਾ ਕੋਸ਼ਿਸ਼ ਕਰੋ.",
            'ml': "ക്ഷമിക്കണം, സാങ്കേതിക പ്രശ്നമുണ്ട്. ദയവായി വീണ്ടും ശ്രമിക്കുക.",
            'bn': "ক্ষমা করবেন, প্রযুক্তিগত সমস্যা হয়েছে। অনুগ্রহ করে আবার চেষ্টা করুন।",
            'ur': "معذرت، تکنیکی مسئلہ ہے۔ براہ کرم دوبارہ کوشش کریں۔",
            'en': "Technical issue. Please try again.",
            'or': "କ୍ଷମା କରନ୍ତୁ, ବୈଷୟିକ ସମସ୍ୟା ଅଛି। ଦୟାକରି ପୁଣି ଚେଷ୍ଟା କରନ୍ତୁ।"
        }
        return responses.get(language, "Technical issue. Please try again.")

    def process_farmer_query(self, image_path=None, audio_path=None, language_code="hi"):
        """Main function to process farmer's query with selected language"""
        try:
            query_text = ""

            if audio_path:
                print("\n" + "="*60)
                print(f"🌾 KRISHI MITRA - Processing Farmer Query in {self.get_language_name(language_code)}")
                print("="*60)

                # Use speech recognition with the specified language
                query_text = self.speech_to_text_with_language(audio_path, language_code)

                if "Error" in query_text or "not found" in query_text or "Could not understand" in query_text:
                    return {"error": query_text, "language": language_code, "success": False}

                print(f"\n📝 Farmer's Query: {query_text}")
                print(f"🌐 Selected Language: {self.get_language_name(language_code)} ({language_code})")

            if image_path:
                print(f"\n🌱 Analyzing crop image in {self.get_language_name(language_code)}...")

                # Analyze the image with the selected language
                analysis = self.analyze_crop_image(image_path, query_text, language_code)

                print(f"\n💬 Response Preview: {analysis[:150]}...")

                print("\n" + "="*60)
                print("✅ Query processed successfully!")
                print("="*60)

                return {
                    "query": query_text,
                    "language": language_code,
                    "language_name": self.get_language_name(language_code),
                    "analysis": analysis,
                    "success": True
                }
            elif query_text:  # Text-only query from audio
                analysis = self.process_text_query(query_text, language_code)
                return {
                    "query": query_text,
                    "language": language_code,
                    "language_name": self.get_language_name(language_code),
                    "analysis": analysis,
                    "success": True
                }
            else:
                return {"error": "No valid input provided", "success": False}

        except Exception as e:
            print(f"Error in process_farmer_query: {e}")
            return {"error": f"Processing error: {e}", "success": False}

# Flask API for integration with Flutter
from flask import Flask, request, jsonify
from flask_cors import CORS

app = Flask(__name__)
CORS(app)  # Enable CORS for Flutter app

# Initialize the agent
API_KEY = "AIzaSyDzXL13T2_XulSQAb8V4X2dReGLX52i1m0"
agent = MultilingualFarmerAgent(API_KEY)

@app.route('/health', methods=['GET'])
def health_check():
    """Health check endpoint"""
    return jsonify({"status": "healthy", "message": "Server is running"})

@app.route('/api/languages', methods=['GET'])
def get_languages():
    """Get supported languages for dropdown"""
    languages = agent.get_supported_languages()
    return jsonify({"languages": languages})

@app.route('/api/process-query', methods=['POST'])
def process_query():
    """Process farmer query with selected language - Enhanced error handling"""
    try:
        # Get data from request
        data = request.json
        if not data:
            return jsonify({"error": "No data provided", "success": False})

        language_name = data.get('language', 'English')

        # Convert language name to language code
        language_code = agent.get_language_code_from_name(language_name)

        print(f"📨 Received request for language: {language_name} -> {language_code}")

        # Handle image file
        image_data = data.get('image')
        image_path = None
        if image_data:
            try:
                # Remove data URL prefix if present
                if ',' in image_data:
                    header, image_data = image_data.split(',', 1)

                # Decode base64 image and save to temp file
                image_bytes = base64.b64decode(image_data)
                timestamp = int(time.time() * 1000)
                image_path = os.path.join(tempfile.gettempdir(), f"image_{timestamp}.png")

                with open(image_path, 'wb') as f:
                    f.write(image_bytes)
                print(f"✅ Image saved: {image_path} ({len(image_bytes)} bytes)")
            except Exception as e:
                print(f"❌ Error processing image: {e}")
                return jsonify({"error": f"Error processing image: {e}", "success": False})

        # Handle audio file with enhanced processing
        audio_data = data.get('audio')
        audio_path = None
        if audio_data:
            print("🎵 Processing audio data...")
            audio_path = agent.save_base64_audio_to_file(audio_data)
            if not audio_path:
                return jsonify({"error": "Failed to process audio file", "success": False})
            print(f"✅ Audio file ready: {audio_path}")

        # Process the query
        result = agent.process_farmer_query(
            image_path=image_path,
            audio_path=audio_path,
            language_code=language_code
        )

        # Clean up temp files
        cleanup_files = []
        if image_path and os.path.exists(image_path):
            cleanup_files.append(image_path)
        if audio_path and os.path.exists(audio_path):
            cleanup_files.append(audio_path)

        for file_path in cleanup_files:
            try:
                os.unlink(file_path)
                print(f"🗑️ Cleaned up: {file_path}")
            except Exception as cleanup_error:
                print(f"⚠️ Cleanup warning: {cleanup_error}")

        return jsonify(result)

    except Exception as e:
        print(f"❌ Server error in process_query: {e}")
        import traceback
        traceback.print_exc()
        return jsonify({"error": f"Server error: {e}", "success": False})

@app.route('/api/process-text', methods=['POST'])
def process_text():
    """Process text-only queries"""
    try:
        # Get data from request
        data = request.json
        if not data:
            return jsonify({"error": "No data provided", "success": False})

        language_name = data.get('language', 'English')
        text = data.get('text', '')

        # Convert language name to language code
        language_code = agent.get_language_code_from_name(language_name)

        print(f"📝 Processing text query: {text}")
        print(f"🌐 Language: {language_name} -> {language_code}")

        if not text.strip():
            return jsonify({"error": "Text cannot be empty", "success": False})

        # Process the text query
        response_text = agent.process_text_query(text, language_code)

        return jsonify({
            "success": True,
            "query": text,
            "response": response_text,
            "language": language_code,
            "language_name": agent.get_language_name(language_code)
        })

    except Exception as e:
        print(f"❌ Text processing error: {e}")
        import traceback
        traceback.print_exc()
        return jsonify({"error": f"Server error: {e}", "success": False})

if __name__ == "__main__":
    print("🌾 Krishi Mitra Server Starting...")
    print("🔗 Server will be available at: http://0.0.0.0:5000")
    print("📱 Make sure your Flutter app uses the correct IP address")
    print("🔧 Enhanced audio processing enabled (FFmpeg-independent)")

    # Print audio processing status
    if PYDUB_AVAILABLE:
        print("✅ pydub available - will try advanced audio conversion")
    else:
        print("⚠️ pydub/FFmpeg not available - using basic audio processing")

    # Run the Flask app
    app.run(host='0.0.0.0', port=5000, debug=False, threaded=True)