import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class LanguageController extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  String _currentLanguage = 'English';

  String get currentLanguage => _currentLanguage;

  LanguageController() {
    _loadLanguage();
  }

  static const Map<String, Map<String, String>> _localizedValues = {
    'English': {
      'home': 'Home',
      'jobs': 'Jobs',
      'talent': 'Talent',
      'account': 'Account',
      'hiring_overview': 'Hiring Overview',
      'upcoming_interviews': 'Upcoming Interviews',
      'recruiter_activity': 'Recruiter Activity',
      'total_applications': 'Total Applications',
      'open_jobs': 'Open Jobs',
      'conversion_rate': 'Conversion Rate',
      'interview_bookings': 'Interview Bookings',
      'settings': 'Settings',
      'change_password': 'Change Password',
      'app_language': 'App Language',
      'logout': 'Logout Account',
      'reschedule': 'Reschedule',
      'join_meeting': 'Join Meeting',
      'no_upcoming_interviews': 'No upcoming interviews.',
      'active_hiring': 'Active Hiring',
      'no_active_hiring': 'No Active Hiring',
    },
    'Hindi': {
      'home': 'होम',
      'jobs': 'नौकरियां',
      'talent': 'प्रतिभा',
      'account': 'अकाउंट',
      'hiring_overview': 'भर्ती अवलोकन',
      'upcoming_interviews': 'आगामी साक्षात्कार',
      'recruiter_activity': 'भर्ती गतिविधि',
      'total_applications': 'कुल आवेदन',
      'open_jobs': 'सक्रिय नौकरियां',
      'conversion_rate': 'रूपांतरण दर',
      'interview_bookings': 'साक्षात्कार बुकिंग',
      'settings': 'सेटिंग्स',
      'change_password': 'पासवर्ड बदलें',
      'app_language': 'ऐप भाषा',
      'logout': 'लॉगआउट अकाउंट',
      'reschedule': 'रीशेड्यूल',
      'join_meeting': 'मीटिंग जॉइन करें',
      'no_upcoming_interviews': 'कोई आगामी साक्षात्कार नहीं।',
      'active_hiring': 'सक्रिय भर्ती',
      'no_active_hiring': 'कोई सक्रिय भर्ती नहीं',
    },
    'Bengali': {
      'home': 'হোম',
      'jobs': 'চাকরি',
      'talent': 'প্রতিভা',
      'account': 'অ্যাকাউন্ট',
      'hiring_overview': 'নিয়োগের ওভারভিউ',
      'upcoming_interviews': 'আসন্ন সাক্ষাত্কার',
      'recruiter_activity': 'নিয়োগের কার্যক্রম',
      'total_applications': 'মোট আবেদন',
      'open_jobs': 'খালি চাকরি',
      'conversion_rate': 'রূপান্তর হার',
      'interview_bookings': 'সাক্ষাত্কার বুকিং',
      'settings': 'সেটিংস',
      'change_password': 'পাসওয়ার্ড পরিবর্তন',
      'app_language': '앱의 ভাষা',
      'logout': 'লগআউট অ্যাকাউন্ট',
      'reschedule': 'পুনরায় নির্ধারণ',
      'join_meeting': 'মিটিংয়ে যোগ দিন',
      'no_upcoming_interviews': 'কোনো আসন্ন সাক্ষাত্কার নেই।',
      'active_hiring': 'সক্রিয় নিয়োগ',
      'no_active_hiring': 'কোনো সক্রিয় নিয়োগ নেই',
    },
    'Gujarati': {
      'home': 'હોમ',
      'jobs': 'નોકરીઓ',
      'talent': 'પ્રતિભા',
      'account': 'એકાઉન્ટ',
      'hiring_overview': 'ભરતી ઝાંખી',
      'upcoming_interviews': 'આગામી ઇન્ટરવ્યુ',
      'recruiter_activity': 'ભરતી પ્રવૃત્તિ',
      'total_applications': 'કુલ અરજીઓ',
      'open_jobs': 'ચાલુ નોકરીઓ',
      'conversion_rate': 'રૂપાંતરણ દર',
      'interview_bookings': 'ઇન્ટરવ્યુ બુકિંગ',
      'settings': 'ಸೆಟ್ಟಿಂಗ್ಸ್',
      'change_password': 'પાસવર્ડ બદલો',
      'app_language': 'એપ ભાષા',
      'logout': 'લોગઆઉટ એકાઉન્ટ',
      'reschedule': 'ફરીથી સમય નક્કી કરો',
      'join_meeting': 'મીટિંગમાં જોડાઓ',
      'no_upcoming_interviews': 'કોઈ આગામી ઇન્ટરવ્યુ નથી.',
      'active_hiring': 'સક્રિય ભરતી',
      'no_active_hiring': 'કોઈ સક્રિય ભરતી નથી',
    },
    'Kannada': {
      'home': 'ಮುಖಪುಟ',
      'jobs': 'ಉದ್ಯೋಗಗಳು',
      'talent': 'ಪ್ರತಿಭೆ',
      'account': 'ಖಾತೆ',
      'hiring_overview': 'ನೇಮಕಾತಿ ಅವಲೋಕನ',
      'upcoming_interviews': 'ಮುಂಬರುವ ಸಂದರ್ಶನಗಳು',
      'recruiter_activity': 'ನೇಮಕಾತಿ ಚಟುವಟಿಕೆ',
      'total_applications': 'ಒಟ್ಟು ಅರ್ಜಿಗಳು',
      'open_jobs': 'ಸಕ್ರಿಯ ಉದ್ಯೋಗಗಳು',
      'conversion_rate': 'ವರ್ಗಾವಣೆ ದర',
      'interview_bookings': 'ಸಂದರ್ಶన ಬುಕಿಂಗ್',
      'settings': 'ಸೆಟ್ಟಿಂಗ್‌ಗಳು',
      'change_password': 'ಪಾಸ್‌ವರ್ಡ್ ಬದಲಾಯಿಸಿ',
      'app_language': 'ಅಪ್ಲಿಕೇಶನ್ ಭಾಷೆ',
      'logout': 'ಖಾತೆ ಲಾಗ್ಔಟ್',
      'reschedule': 'ಮರುನಿಗದಿಗೊಳಿಸಿ',
      'join_meeting': 'ಸಭೆಗೆ ಸೇರಿ',
      'no_upcoming_interviews': 'ಯಾವುದే ಮುಂಬರುವ ಸಂದರ್ಶನಗಳಿಲ್ಲ.',
      'active_hiring': 'ಸಕ್ರಿಯ ನೇಮಕಾತಿ',
      'no_active_hiring': 'ಯಾವುದೇ ಸಕ್ರಿಯ ನೇಮಕಾತಿ ಇಲ್ಲ',
    },
    'Malayalam': {
      'home': 'ഹോം',
      'jobs': 'ജോലികൾ',
      'talent': 'പ്രതിഭ',
      'account': 'അക്കൗണ്ട്',
      'hiring_overview': 'നിയമന അവലോകനം',
      'upcoming_interviews': 'വരാനിരിക്കുന്ന അഭിമുഖങ്ങൾ',
      'recruiter_activity': 'നിയമന പ്രവർത്തനം',
      'total_applications': 'ആകെ അപേക്ഷകൾ',
      'open_jobs': 'സജീവ ജോലികൾ',
      'conversion_rate': 'പരിവർത്തന നിരക്ക്',
      'interview_bookings': 'അഭിമുഖം ബുക്കിംഗ്',
      'settings': 'ക്രമീകരണങ്ങൾ',
      'change_password': 'പാസ്‌വേഡ് മാറ്റുക',
      'app_language': 'ആപ്പ് ഭാഷ',
      'logout': 'ലോഗ്ഔട്ട് അക്കൗണ്ട്',
      'reschedule': 'പുനഃക്രമീകരിക്കുക',
      'join_meeting': 'മീറ്റിംഗിൽ പങ്കെടുക്കുക',
      'no_upcoming_interviews': 'വരാനിരിക്കുന്ന അഭിമുഖങ്ങൾ ഇല്ല.',
      'active_hiring': 'സജീവ നിയമനം',
      'no_active_hiring': 'സജീവ നിയമനങ്ങൾ ഇല്ല',
    },
    'Marathi': {
      'home': 'होम',
      'jobs': 'नोकऱ्या',
      'talent': 'प्रतिभा',
      'account': 'अकाउंट',
      'hiring_overview': 'भरती विहंगावलोकन',
      'upcoming_interviews': 'आगामी मुलाखती',
      'recruiter_activity': 'भरती क्रियाकलाप',
      'total_applications': 'एकूण अर्ज',
      'open_jobs': 'सक्रिय नोकऱ्या',
      'conversion_rate': 'रूपांतरण दर',
      'interview_bookings': 'मुलाखत बुकिंग',
      'settings': 'सेटिंग्ज',
      'change_password': 'पासवर्ड बदला',
      'app_language': 'अ‍ॅप भाषा',
      'logout': 'लॉगआउट अकाउंट',
      'reschedule': 'पुन्हा शेड्यूल करा',
      'join_meeting': 'मीटिंगमध्ये सामील व्हा',
      'no_upcoming_interviews': 'कोणतीही आगामी मुलाखत नाही.',
      'active_hiring': 'सक्रिय भरती',
      'no_active_hiring': 'सक्रिय भरती नाही',
    },
    'Punjabi (Gurmukhi)': {
      'home': 'ਹੋਮ',
      'jobs': 'ਨੌਕਰੀਆਂ',
      'talent': 'ਪ੍ਰਤਿਭਾ',
      'account': 'ਖਾਤਾ',
      'hiring_overview': 'ਭਰਤੀ ਦੀ ਸੰਖੇਪ ਜਾਣਕਾਰੀ',
      'upcoming_interviews': 'ਆਉਣ ਵਾਲੇ ਇੰਟਰਵਿਊ',
      'recruiter_activity': 'ਭਰਤੀ ਸਰਗਰਮੀ',
      'total_applications': 'ਕੁੱਲ ਅਰਜ਼ੀਆਂ',
      'open_jobs': 'ਸਰਗਰਮ ਨੌਕਰੀਆਂ',
      'conversion_rate': 'ਪਰਿਵਰਤਨ ਦਰ',
      'interview_bookings': 'ਇੰਟਰਵਿਊ ਬੁਕਿੰਗ',
      'settings': 'ਸੈਟਿੰਗਜ਼',
      'change_password': 'ਪਾਸਵਰਡ ਬਦਲੋ',
      'app_language': 'ਐਪ ਭਾਸ਼ਾ',
      'logout': 'ਲੌਗਆਊਟ ਖਾਤਾ',
      'reschedule': 'ਦੁਬਾਰਾ ਤੈਅ ਕਰੋ',
      'join_meeting': 'ਮੀਟਿੰਗ ਵਿੱਚ ਸ਼ਾਮਲ ਹੋਵੋ',
      'no_upcoming_interviews': 'ਕੋਈ ਆਉਣ ਵਾਲਾ ਇੰਟਰਵਿਊ ਨਹੀਂ ਹੈ।',
      'active_hiring': 'ਸਰਗਰਮ ਭਰਤੀ',
      'no_active_hiring': 'ਕੋਈ ਸਰਗਰਮ ਭਰਤੀ ਨਹੀਂ',
    },
    'Tamil': {
      'home': 'முகப்பு',
      'jobs': 'பணிகள்',
      'talent': 'திறமை',
      'account': 'கணக்கு',
      'hiring_overview': 'பணி நியமன மேலோட்டம்',
      'upcoming_interviews': 'வரவிருக்கும் நேர்காணல்கள்',
      'recruiter_activity': 'பணி நியமன செயல்பாடு',
      'total_applications': 'மொத்த விண்ணப்பங்கள்',
      'open_jobs': 'சক্রিয় பணிகள்',
      'conversion_rate': 'மாற்று விகிதம்',
      'interview_bookings': 'நேர்காணல் முன்பதிவுகள்',
      'settings': 'அமைப்புகள்',
      'change_password': 'கடவுச்சொல்லை மாற்று',
      'app_language': 'செயலி மொழி',
      'logout': 'கணக்கு வெளியேறு',
      'reschedule': 'மறுஅட்டவணை',
      'join_meeting': 'கூட்டத்தில் சேரவும்',
      'no_upcoming_interviews': 'வரவிருக்கும் நேர்காணல்கள் இல்லை.',
      'active_hiring': 'சক্রিয় பணி நியமனம்',
      'no_active_hiring': 'சক্রিয় பணி நியமனம் இல்லை',
    },
    'Telugu': {
      'home': 'హోమ్',
      'jobs': 'ఉద్యోగాలు',
      'talent': 'ప్రతిభ',
      'account': 'ఖాతా',
      'hiring_overview': 'నియామకాల అవలోకనం',
      'upcoming_interviews': 'రాబోయే ఇంటర్వ్యూలు',
      'recruiter_activity': 'నియామక కార్యాచరణ',
      'total_applications': 'మొత్తం దరఖాస్తులు',
      'open_jobs': 'సక్రియ ఉద్యోగాలు',
      'conversion_rate': 'మార్పిడి రేటు',
      'interview_bookings': 'ఇంటర్వ్యూ బుకింగ్‌లు',
      'settings': 'సెట్టింగ్లు',
      'change_password': 'పాస్‌వర్డ్ మార్చండి',
      'app_language': 'యాప్ భాష',
      'logout': 'లౌగౌట్ ఖాతా',
      'reschedule': 'పునః షెడ్యూల్',
      'join_meeting': 'సмаవేశంలో చేరండి',
      'no_upcoming_interviews': 'రాబోయే ఇంటర్వ్యూలు లేవు.',
      'active_hiring': 'సక్రియ నియామకాలు',
      'no_active_hiring': 'సక్రియ నియామకాలు లేవు',
    },
  };

  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    _currentLanguage = prefs.getString('app_language') ?? 'English';
    notifyListeners();
  }

  Future<void> setLanguage(String lang, String? recruiterId) async {
    if (!_localizedValues.containsKey(lang)) return;
    _currentLanguage = lang;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_language', lang);

    if (recruiterId != null) {
      // Synchronize with database
      await _apiService.updateSettings({
        'recruiter_id': recruiterId,
        'language': lang,
      });
    }
  }

  String translate(String key) {
    return _localizedValues[_currentLanguage]?[key] ?? _localizedValues['English']?[key] ?? key;
  }
}
