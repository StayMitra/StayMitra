import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppLocalization extends ChangeNotifier {
  AppLocalization._();

  static final AppLocalization instance = AppLocalization._();

  static const String _languageKey = 'selected_language';

  String _languageCode = 'en';

  String get languageCode => _languageCode;

  // ============================================================
  // SUPPORTED LANGUAGES
  // ============================================================

  static const Map<String, String> supportedLanguages = {
    'en': 'English',
    'te': 'తెలుగు',
    'hi': 'हिन्दी',
    'kn': 'ಕನ್ನಡ',
    'ta': 'தமிழ்',
    'ml': 'മലയാളം',
    'mr': 'मराठी',
    'bn': 'বাংলা',
    'gu': 'ગુજરાતી',
    'pa': 'ਪੰਜਾਬੀ',
    'or': 'ଓଡ଼ିଆ',
    'as': 'অসমীয়া',
    'ur': 'اردو',
    'sa': 'संस्कृतम्',
    'kok': 'कोंकणी',
    'ks': 'कॉशुर',
    'sd': 'सिन्धी',
    'ne': 'नेपाली',
    'mai': 'मैथिली',
    'mni': 'মৈতৈলোন্',
    'brx': 'बड़ो',
    'sat': 'ᱥᱟᱱᱛᱟᱲᱤ',
  };

  // ============================================================
  // INITIALIZE
  // ============================================================

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();

    _languageCode =
        prefs.getString(_languageKey) ?? 'en';

    if (!supportedLanguages.containsKey(_languageCode)) {
      _languageCode = 'en';
    }

    notifyListeners();
  }

  // ============================================================
  // CHANGE LANGUAGE
  // ============================================================

  Future<void> setLanguage(String languageCode) async {
    if (!supportedLanguages.containsKey(languageCode)) {
      return;
    }

    if (_languageCode == languageCode) {
      return;
    }

    _languageCode = languageCode;

    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      _languageKey,
      languageCode,
    );

    notifyListeners();
  }

  // ============================================================
  // CURRENT LANGUAGE NAME
  // ============================================================

  String get currentLanguageName {
    return supportedLanguages[_languageCode] ??
        'English';
  }

  // ============================================================
  // TRANSLATION
  // ============================================================

  String tr(String key) {
    return _translations[_languageCode]?[key] ??
        _translations['en']?[key] ??
        key;
  }

  // ============================================================
  // TRANSLATIONS
  // ============================================================

  static const Map<String, Map<String, String>>
      _translations = {

    // ==========================================================
    // ENGLISH
    // ==========================================================

    'en': {
      'app_name': 'Stay Mitra',

      'dashboard': 'Dashboard',
      'tenant': 'Tenant',
      'tenants': 'Tenants',
      'tenant_management': 'Tenant Management',

      'check_in': 'Check-in',
      'check_out': 'Check-out',
      'tenant_check_in': 'Tenant Check-in',
      'tenant_check_out': 'Tenant Check-out',

      'day_sheet': 'Day Sheet',
      'reports': 'Reports',
      'transactions': 'Transactions',

      'more': 'More',
      'settings': 'Settings',
      'notifications': 'Notifications',
      'documents': 'Documents',

      'pg_owner': 'PG Owner',
      'property': 'Property',
      'property_settings': 'PG / Property Settings',

      'currency': 'Currency',
      'date_format': 'Date Format',
      'language': 'Language',

      'select_language': 'Select Language',

      'english': 'English',
      'telugu': 'Telugu',
      'hindi': 'Hindi',
      'kannada': 'Kannada',
      'tamil': 'Tamil',
      'malayalam': 'Malayalam',
      'marathi': 'Marathi',
      'bengali': 'Bengali',
      'gujarati': 'Gujarati',
      'punjabi': 'Punjabi',
      'odia': 'Odia',
      'assamese': 'Assamese',
      'urdu': 'Urdu',
      'sanskrit': 'Sanskrit',
      'konkani': 'Konkani',
      'kashmiri': 'Kashmiri',
      'sindhi': 'Sindhi',
      'nepali': 'Nepali',
      'maithili': 'Maithili',
      'manipuri': 'Manipuri',
      'bodo': 'Bodo',
      'santali': 'Santali',

      'save': 'Save',
      'cancel': 'Cancel',
      'close': 'Close',
      'delete': 'Delete',
      'edit': 'Edit',
      'add': 'Add',
      'update': 'Update',
      'search': 'Search',
      'refresh': 'Refresh',
      'change': 'Change',
      'select': 'Select',

      'add_tenant': 'Add Tenant',
      'tenant_name': 'Tenant Name',
      'phone': 'Phone',
      'email': 'Email',
      'address': 'Address',

      'active': 'Active',
      'vacated': 'Vacated',
      'checked_in': 'Checked In',
      'checked_out': 'Checked Out',

      'bed': 'Bed',
      'room': 'Room',
      'rooms': 'Rooms',
      'beds': 'Beds',
      'available': 'Available',
      'occupied': 'Occupied',

      'rent': 'Rent',
      'rent_amount': 'Rent Amount',

      'note': 'Note',
      'optional': 'Optional',

      'save_check_in': 'Save Check-in',
      'save_check_out': 'Save Check-out',

      'financial_summary': 'Financial Summary',
      'income': 'Income',
      'expense': 'Expense',
      'expenses': 'Expenses',
      'net_amount': 'Net Amount',
      'profit': 'Profit',
      'loss': 'Loss',

      'this_month': 'This month',
      'report_period': 'Report Period',

      'occupancy_overview': 'Occupancy Overview',
      'bed_occupancy': 'Bed Occupancy',

      'payment_methods': 'Payment Methods',
      'cash': 'Cash',
      'upi': 'UPI',
      'bank': 'Bank',

      'transaction_summary': 'Transaction Summary',
      'recent_transactions': 'Recent Transactions',
      'total': 'Total',

      'total_tenants': 'Total Tenants',
      'active_tenants': 'Active Tenants',
      'vacated_tenants': 'Vacated',

      'privacy_policy': 'Privacy Policy',
      'terms_conditions': 'Terms & Conditions',

      'account': 'Account',
      'security': 'Security',

      'success': 'Success',
      'error': 'Error',
      'warning': 'Warning',
      'information': 'Information',

      'no_data': 'No data available',
      'no_transactions': 'No transactions this month',

      'confirm': 'Confirm',
      'yes': 'Yes',
      'no': 'No',

      'loading': 'Loading...',
      'something_went_wrong': 'Something went wrong',
    },

    // ==========================================================
    // TELUGU
    // ==========================================================

    'te': {
      'app_name': 'స్టే మిత్ర',

      'dashboard': 'డాష్‌బోర్డ్',
      'tenant': 'అద్దెదారు',
      'tenants': 'అద్దెదారులు',
      'tenant_management': 'అద్దెదారుల నిర్వహణ',

      'check_in': 'చెక్-ఇన్',
      'check_out': 'చెక్-అవుట్',
      'tenant_check_in': 'అద్దెదారు చెక్-ఇన్',
      'tenant_check_out': 'అద్దెదారు చెక్-అవుట్',

      'day_sheet': 'రోజువారీ షీట్',
      'reports': 'నివేదికలు',
      'transactions': 'లావాదేవీలు',

      'more': 'మరిన్ని',
      'settings': 'సెట్టింగ్స్',
      'notifications': 'నోటిఫికేషన్లు',
      'documents': 'పత్రాలు',

      'pg_owner': 'PG యజమాని',
      'property': 'ప్రాపర్టీ',
      'property_settings': 'PG / ప్రాపర్టీ సెట్టింగ్స్',

      'currency': 'కరెన్సీ',
      'date_format': 'తేదీ ఫార్మాట్',
      'language': 'భాష',

      'select_language': 'భాషను ఎంచుకోండి',

      'english': 'ఇంగ్లీష్',
      'telugu': 'తెలుగు',
      'hindi': 'హిందీ',
      'kannada': 'కన్నడ',
      'tamil': 'తమిళం',
      'malayalam': 'మలయాళం',
      'marathi': 'మరాఠీ',
      'bengali': 'బెంగాలీ',
      'gujarati': 'గుజరాతీ',
      'punjabi': 'పంజాబీ',
      'odia': 'ఒడియా',
      'assamese': 'అస్సామీ',
      'urdu': 'ఉర్దూ',
      'sanskrit': 'సంస్కృతం',
      'konkani': 'కొంకణి',
      'kashmiri': 'కాశ్మీరీ',
      'sindhi': 'సింధీ',
      'nepali': 'నేపాలీ',
      'maithili': 'మైథిలీ',
      'manipuri': 'మణిపురి',
      'bodo': 'బోడో',
      'santali': 'సంతాలి',

      'save': 'సేవ్ చేయండి',
      'cancel': 'రద్దు చేయండి',
      'close': 'మూసివేయండి',
      'delete': 'తొలగించండి',
      'edit': 'ఎడిట్ చేయండి',
      'add': 'జోడించండి',
      'update': 'అప్‌డేట్ చేయండి',
      'search': 'వెతకండి',
      'refresh': 'రిఫ్రెష్',
      'change': 'మార్చండి',
      'select': 'ఎంచుకోండి',

      'add_tenant': 'అద్దెదారుని జోడించండి',
      'tenant_name': 'అద్దెదారు పేరు',
      'phone': 'ఫోన్',
      'email': 'ఈమెయిల్',
      'address': 'చిరునామా',

      'active': 'ప్రస్తుతం ఉన్నారు',
      'vacated': 'ఖాళీ చేశారు',
      'checked_in': 'చెక్-ఇన్ చేశారు',
      'checked_out': 'చెక్-అవుట్ చేశారు',

      'bed': 'బెడ్',
      'room': 'గది',
      'rooms': 'గదులు',
      'beds': 'బెడ్లు',
      'available': 'ఖాళీగా ఉన్నాయి',
      'occupied': 'ఆక్యుపైడ్',

      'rent': 'అద్దె',
      'rent_amount': 'అద్దె మొత్తం',

      'note': 'గమనిక',
      'optional': 'ఐచ్ఛికం',

      'save_check_in': 'చెక్-ఇన్ సేవ్ చేయండి',
      'save_check_out': 'చెక్-అవుట్ సేవ్ చేయండి',

      'financial_summary': 'ఆర్థిక సారాంశం',
      'income': 'ఆదాయం',
      'expense': 'ఖర్చు',
      'expenses': 'ఖర్చులు',
      'net_amount': 'నికర మొత్తం',
      'profit': 'లాభం',
      'loss': 'నష్టం',

      'this_month': 'ఈ నెల',
      'report_period': 'నివేదిక కాలం',

      'occupancy_overview': 'ఆక్యుపెన్సీ వివరాలు',
      'bed_occupancy': 'బెడ్ ఆక్యుపెన్సీ',

      'payment_methods': 'చెల్లింపు పద్ధతులు',
      'cash': 'నగదు',
      'upi': 'UPI',
      'bank': 'బ్యాంక్',

      'transaction_summary': 'లావాదేవీల సారాంశం',
      'recent_transactions': 'ఇటీవలి లావాదేవీలు',
      'total': 'మొత్తం',

      'total_tenants': 'మొత్తం అద్దెదారులు',
      'active_tenants': 'ప్రస్తుతం ఉన్న అద్దెదారులు',
      'vacated_tenants': 'ఖాళీ చేసిన వారు',

      'privacy_policy': 'గోప్యతా విధానం',
      'terms_conditions': 'నిబంధనలు & షరతులు',

      'account': 'ఖాతా',
      'security': 'భద్రత',

      'success': 'విజయవంతం',
      'error': 'లోపం',
      'warning': 'హెచ్చరిక',
      'information': 'సమాచారం',

      'no_data': 'డేటా అందుబాటులో లేదు',
      'no_transactions': 'ఈ నెలలో లావాదేవీలు లేవు',

      'confirm': 'నిర్ధారించండి',
      'yes': 'అవును',
      'no': 'కాదు',

      'loading': 'లోడ్ అవుతోంది...',
      'something_went_wrong': 'ఏదో తప్పు జరిగింది',
    },

    // ==========================================================
    // HINDI
    // ==========================================================

    'hi': {
      'app_name': 'स्टे मित्र',

      'dashboard': 'डैशबोर्ड',
      'tenant': 'किरायेदार',
      'tenants': 'किरायेदार',
      'tenant_management': 'किरायेदार प्रबंधन',

      'check_in': 'चेक-इन',
      'check_out': 'चेक-आउट',
      'tenant_check_in': 'किरायेदार चेक-इन',
      'tenant_check_out': 'किरायेदार चेक-आउट',

      'day_sheet': 'दैनिक शीट',
      'reports': 'रिपोर्ट',
      'transactions': 'लेन-देन',

      'more': 'अधिक',
      'settings': 'सेटिंग्स',
      'notifications': 'सूचनाएं',
      'documents': 'दस्तावेज़',

      'pg_owner': 'PG मालिक',
      'property': 'प्रॉपर्टी',
      'property_settings': 'PG / प्रॉपर्टी सेटिंग्स',

      'currency': 'मुद्रा',
      'date_format': 'तारीख प्रारूप',
      'language': 'भाषा',

      'select_language': 'भाषा चुनें',

      'english': 'अंग्रेज़ी',
      'telugu': 'तेलुगु',
      'hindi': 'हिन्दी',
      'kannada': 'कन्नड़',
      'tamil': 'तमिल',
      'malayalam': 'मलयालम',
      'marathi': 'मराठी',
      'bengali': 'बंगाली',
      'gujarati': 'गुजराती',
      'punjabi': 'पंजाबी',
      'odia': 'ओड़िया',
      'assamese': 'असमिया',
      'urdu': 'उर्दू',
      'sanskrit': 'संस्कृत',
      'konkani': 'कोंकणी',
      'kashmiri': 'कश्मीरी',
      'sindhi': 'सिंधी',
      'nepali': 'नेपाली',
      'maithili': 'मैथिली',
      'manipuri': 'मणिपुरी',
      'bodo': 'बोडो',
      'santali': 'संताली',

      'save': 'सेव करें',
      'cancel': 'रद्द करें',
      'close': 'बंद करें',
      'delete': 'हटाएं',
      'edit': 'संपादित करें',
      'add': 'जोड़ें',
      'update': 'अपडेट करें',
      'search': 'खोजें',
      'refresh': 'रिफ्रेश',
      'change': 'बदलें',
      'select': 'चुनें',

      'add_tenant': 'किरायेदार जोड़ें',
      'tenant_name': 'किरायेदार का नाम',
      'phone': 'फोन',
      'email': 'ईमेल',
      'address': 'पता',

      'active': 'सक्रिय',
      'vacated': 'खाली किया',
      'checked_in': 'चेक-इन किया',
      'checked_out': 'चेक-आउट किया',

      'bed': 'बेड',
      'room': 'कमरा',
      'rooms': 'कमरे',
      'beds': 'बेड',
      'available': 'उपलब्ध',
      'occupied': 'भरा हुआ',

      'rent': 'किराया',
      'rent_amount': 'किराया राशि',

      'note': 'नोट',
      'optional': 'वैकल्पिक',

      'save_check_in': 'चेक-इन सेव करें',
      'save_check_out': 'चेक-आउट सेव करें',

      'financial_summary': 'वित्तीय सारांश',
      'income': 'आय',
      'expense': 'खर्च',
      'expenses': 'खर्चे',
      'net_amount': 'शुद्ध राशि',
      'profit': 'लाभ',
      'loss': 'हानि',

      'this_month': 'इस महीने',
      'report_period': 'रिपोर्ट अवधि',

      'occupancy_overview': 'ऑक्यूपेंसी विवरण',
      'bed_occupancy': 'बेड ऑक्यूपेंसी',

      'payment_methods': 'भुगतान के तरीके',
      'cash': 'नकद',
      'upi': 'UPI',
      'bank': 'बैंक',

      'transaction_summary': 'लेन-देन सारांश',
      'recent_transactions': 'हाल के लेन-देन',
      'total': 'कुल',

      'total_tenants': 'कुल किरायेदार',
      'active_tenants': 'सक्रिय किरायेदार',
      'vacated_tenants': 'खाली करने वाले',

      'privacy_policy': 'गोपनीयता नीति',
      'terms_conditions': 'नियम और शर्तें',

      'account': 'खाता',
      'security': 'सुरक्षा',

      'success': 'सफल',
      'error': 'त्रुटि',
      'warning': 'चेतावनी',
      'information': 'जानकारी',

      'no_data': 'कोई डेटा उपलब्ध नहीं है',
      'no_transactions': 'इस महीने कोई लेन-देन नहीं है',

      'confirm': 'पुष्टि करें',
      'yes': 'हाँ',
      'no': 'नहीं',

      'loading': 'लोड हो रहा है...',
      'something_went_wrong': 'कुछ गलत हो गया',
    },

    // ==========================================================
    // KANNADA
    // ==========================================================

    'kn': {
      'app_name': 'ಸ್ಟೇ ಮಿತ್ರ',

      'dashboard': 'ಡ್ಯಾಶ್‌ಬೋರ್ಡ್',
      'tenant': 'ಬಾಡಿಗೆದಾರ',
      'tenants': 'ಬಾಡಿಗೆದಾರರು',
      'tenant_management': 'ಬಾಡಿಗೆದಾರರ ನಿರ್ವಹಣೆ',

      'check_in': 'ಚೆಕ್-ಇನ್',
      'check_out': 'ಚೆಕ್-ಔಟ್',
      'tenant_check_in': 'ಬಾಡಿಗೆದಾರ ಚೆಕ್-ಇನ್',
      'tenant_check_out': 'ಬಾಡಿಗೆದಾರ ಚೆಕ್-ಔಟ್',

      'day_sheet': 'ದೈನಂದಿನ ಶೀಟ್',
      'reports': 'ವರದಿಗಳು',
      'transactions': 'ವಹಿವಾಟುಗಳು',

      'more': 'ಇನ್ನಷ್ಟು',
      'settings': 'ಸೆಟ್ಟಿಂಗ್ಸ್',
      'notifications': 'ಅಧಿಸೂಚನೆಗಳು',
      'documents': 'ದಾಖಲೆಗಳು',

      'pg_owner': 'PG ಮಾಲೀಕರು',
      'property': 'ಪ್ರಾಪರ್ಟಿ',
      'property_settings': 'PG / ಪ್ರಾಪರ್ಟಿ ಸೆಟ್ಟಿಂಗ್ಸ್',

      'currency': 'ಕರೆನ್ಸಿ',
      'date_format': 'ದಿನಾಂಕ ಸ್ವರೂಪ',
      'language': 'ಭಾಷೆ',

      'select_language': 'ಭಾಷೆಯನ್ನು ಆಯ್ಕೆಮಾಡಿ',

      'english': 'ಇಂಗ್ಲಿಷ್',
      'telugu': 'ತೆಲುಗು',
      'hindi': 'ಹಿಂದಿ',
      'kannada': 'ಕನ್ನಡ',
      'tamil': 'ತಮಿಳು',
      'malayalam': 'ಮಲಯಾಳಂ',
      'marathi': 'ಮರಾಠಿ',
      'bengali': 'ಬಂಗಾಳಿ',
      'gujarati': 'ಗುಜರಾತಿ',
      'punjabi': 'ಪಂಜಾಬಿ',
      'odia': 'ಒಡಿಯಾ',
      'assamese': 'ಅಸ್ಸಾಮಿ',
      'urdu': 'ಉರ್ದು',
      'sanskrit': 'ಸಂಸ್ಕೃತ',
      'konkani': 'ಕೊಂಕಣಿ',
      'kashmiri': 'ಕಾಶ್ಮೀರಿ',
      'sindhi': 'ಸಿಂಧಿ',
      'nepali': 'ನೇಪಾಳಿ',
      'maithili': 'ಮೈಥಿಲಿ',
      'manipuri': 'ಮಣಿಪುರಿ',
      'bodo': 'ಬೋಡೋ',
      'santali': 'ಸಂತಾಲಿ',

      'save': 'ಉಳಿಸಿ',
      'cancel': 'ರದ್ದುಮಾಡಿ',
      'close': 'ಮುಚ್ಚಿ',
      'delete': 'ಅಳಿಸಿ',
      'edit': 'ತಿದ್ದು',
      'add': 'ಸೇರಿಸಿ',
      'update': 'ನವೀಕರಿಸಿ',
      'search': 'ಹುಡುಕಿ',
      'refresh': 'ರಿಫ್ರೆಶ್',
      'change': 'ಬದಲಿಸಿ',
      'select': 'ಆಯ್ಕೆಮಾಡಿ',

      'add_tenant': 'ಬಾಡಿಗೆದಾರರನ್ನು ಸೇರಿಸಿ',
      'tenant_name': 'ಬಾಡಿಗೆದಾರರ ಹೆಸರು',
      'phone': 'ಫೋನ್',
      'email': 'ಇಮೇಲ್',
      'address': 'ವಿಳಾಸ',

      'active': 'ಸಕ್ರಿಯ',
      'vacated': 'ಖಾಲಿ ಮಾಡಿದ್ದಾರೆ',
      'checked_in': 'ಚೆಕ್-ಇನ್ ಮಾಡಿದ್ದಾರೆ',
      'checked_out': 'ಚೆಕ್-ಔಟ್ ಮಾಡಿದ್ದಾರೆ',

      'bed': 'ಬೆಡ್',
      'room': 'ಕೊಠಡಿ',
      'rooms': 'ಕೊಠಡಿಗಳು',
      'beds': 'ಬೆಡ್‌ಗಳು',
      'available': 'ಲಭ್ಯ',
      'occupied': 'ಭರ್ತಿಯಾಗಿದೆ',

      'rent': 'ಬಾಡಿಗೆ',
      'rent_amount': 'ಬಾಡಿಗೆ ಮೊತ್ತ',

      'note': 'ಟಿಪ್ಪಣಿ',
      'optional': 'ಐಚ್ಛಿಕ',

      'save_check_in': 'ಚೆಕ್-ಇನ್ ಉಳಿಸಿ',
      'save_check_out': 'ಚೆಕ್-ಔಟ್ ಉಳಿಸಿ',

      'financial_summary': 'ಹಣಕಾಸಿನ ಸಾರಾಂಶ',
      'income': 'ಆದಾಯ',
      'expense': 'ವೆಚ್ಚ',
      'expenses': 'ವೆಚ್ಚಗಳು',
      'net_amount': 'ನಿವ್ವಳ ಮೊತ್ತ',
      'profit': 'ಲಾಭ',
      'loss': 'ನಷ್ಟ',

      'this_month': 'ಈ ತಿಂಗಳು',
      'report_period': 'ವರದಿ ಅವಧಿ',

      'occupancy_overview': 'ಆಕ್ಯುಪೆನ್ಸಿ ವಿವರ',
      'bed_occupancy': 'ಬೆಡ್ ಆಕ್ಯುಪೆನ್ಸಿ',

      'payment_methods': 'ಪಾವತಿ ವಿಧಾನಗಳು',
      'cash': 'ನಗದು',
      'upi': 'UPI',
      'bank': 'ಬ್ಯಾಂಕ್',

      'transaction_summary': 'ವಹಿವಾಟು ಸಾರಾಂಶ',
      'recent_transactions': 'ಇತ್ತೀಚಿನ ವಹಿವಾಟುಗಳು',
      'total': 'ಒಟ್ಟು',

      'total_tenants': 'ಒಟ್ಟು ಬಾಡಿಗೆದಾರರು',
      'active_tenants': 'ಸಕ್ರಿಯ ಬಾಡಿಗೆದಾರರು',
      'vacated_tenants': 'ಖಾಲಿ ಮಾಡಿದವರು',

      'privacy_policy': 'ಗೌಪ್ಯತಾ ನೀತಿ',
      'terms_conditions': 'ನಿಯಮಗಳು ಮತ್ತು ಷರತ್ತುಗಳು',

      'account': 'ಖಾತೆ',
      'security': 'ಭದ್ರತೆ',

      'success': 'ಯಶಸ್ವಿಯಾಗಿದೆ',
      'error': 'ದೋಷ',
      'warning': 'ಎಚ್ಚರಿಕೆ',
      'information': 'ಮಾಹಿತಿ',

      'no_data': 'ಯಾವುದೇ ಡೇಟಾ ಲಭ್ಯವಿಲ್ಲ',
      'no_transactions': 'ಈ ತಿಂಗಳು ಯಾವುದೇ ವಹಿವಾಟುಗಳಿಲ್ಲ',

      'confirm': 'ದೃಢೀಕರಿಸಿ',
      'yes': 'ಹೌದು',
      'no': 'ಇಲ್ಲ',

      'loading': 'ಲೋಡ್ ಆಗುತ್ತಿದೆ...',
      'something_went_wrong': 'ಏನೋ ತಪ್ಪಾಗಿದೆ',
    },

    // ==========================================================
    // TAMIL
    // ==========================================================

    'ta': {
      'dashboard': 'டாஷ்போர்டு',
      'tenant': 'வாடகையாளர்',
      'tenants': 'வாடகையாளர்கள்',
      'tenant_management': 'வாடகையாளர் மேலாண்மை',
      'check_in': 'செக்-இன்',
      'check_out': 'செக்-அவுட்',
      'day_sheet': 'தினசரி அறிக்கை',
      'reports': 'அறிக்கைகள்',
      'transactions': 'பரிவர்த்தனைகள்',
      'more': 'மேலும்',
      'settings': 'அமைப்புகள்',
      'notifications': 'அறிவிப்புகள்',
      'documents': 'ஆவணங்கள்',
      'pg_owner': 'PG உரிமையாளர்',
      'property': 'சொத்து',
      'language': 'மொழி',
      'select_language': 'மொழியைத் தேர்ந்தெடுக்கவும்',
      'save': 'சேமிக்கவும்',
      'cancel': 'ரத்து செய்யவும்',
      'delete': 'நீக்கவும்',
      'edit': 'திருத்தவும்',
      'add': 'சேர்க்கவும்',
      'update': 'புதுப்பிக்கவும்',
      'search': 'தேடவும்',
      'change': 'மாற்றவும்',
      'active': 'செயலில்',
      'vacated': 'காலி செய்தவர்',
      'available': 'கிடைக்கும்',
      'occupied': 'நிரம்பியுள்ளது',
      'rent': 'வாடகை',
      'note': 'குறிப்பு',
      'optional': 'விருப்பத்தேர்வு',
      'income': 'வருமானம்',
      'expense': 'செலவு',
      'expenses': 'செலவுகள்',
      'profit': 'லாபம்',
      'loss': 'நஷ்டம்',
      'this_month': 'இந்த மாதம்',
      'payment_methods': 'கட்டண முறைகள்',
      'cash': 'பணம்',
      'upi': 'UPI',
      'bank': 'வங்கி',
      'total': 'மொத்தம்',
      'success': 'வெற்றி',
      'error': 'பிழை',
      'warning': 'எச்சரிக்கை',
      'loading': 'ஏற்றப்படுகிறது...',
    },

    // ==========================================================
    // MALAYALAM
    // ==========================================================

    'ml': {
      'dashboard': 'ഡാഷ്ബോർഡ്',
      'tenant': 'വാടകക്കാരൻ',
      'tenants': 'വാടകക്കാർ',
      'tenant_management': 'വാടകക്കാരുടെ മാനേജ്മെന്റ്',
      'check_in': 'ചെക്ക്-ഇൻ',
      'check_out': 'ചെക്ക്-ഔട്ട്',
      'day_sheet': 'ദൈനംദിന ഷീറ്റ്',
      'reports': 'റിപ്പോർട്ടുകൾ',
      'transactions': 'ഇടപാടുകൾ',
      'more': 'കൂടുതൽ',
      'settings': 'ക്രമീകരണങ്ങൾ',
      'notifications': 'അറിയിപ്പുകൾ',
      'documents': 'രേഖകൾ',
      'pg_owner': 'PG ഉടമ',
      'property': 'പ്രോപ്പർട്ടി',
      'language': 'ഭാഷ',
      'select_language': 'ഭാഷ തിരഞ്ഞെടുക്കുക',
      'save': 'സേവ് ചെയ്യുക',
      'cancel': 'റദ്ദാക്കുക',
      'delete': 'ഇല്ലാതാക്കുക',
      'edit': 'എഡിറ്റ് ചെയ്യുക',
      'add': 'ചേർക്കുക',
      'update': 'അപ്‌ഡേറ്റ് ചെയ്യുക',
      'search': 'തിരയുക',
      'change': 'മാറ്റുക',
      'active': 'സജീവം',
      'vacated': 'ഒഴിഞ്ഞു',
      'available': 'ലഭ്യം',
      'occupied': 'നിറഞ്ഞു',
      'rent': 'വാടക',
      'note': 'കുറിപ്പ്',
      'optional': 'ഓപ്ഷണൽ',
      'income': 'വരുമാനം',
      'expense': 'ചെലവ്',
      'expenses': 'ചെലവുകൾ',
      'profit': 'ലാഭം',
      'loss': 'നഷ്ടം',
      'this_month': 'ഈ മാസം',
      'payment_methods': 'പണമടയ്ക്കൽ രീതികൾ',
      'cash': 'പണം',
      'upi': 'UPI',
      'bank': 'ബാങ്ക്',
      'total': 'ആകെ',
      'success': 'വിജയം',
      'error': 'പിശക്',
      'warning': 'മുന്നറിയിപ്പ്',
      'loading': 'ലോഡ് ചെയ്യുന്നു...',
    },

    // ==========================================================
    // MARATHI
    // ==========================================================

    'mr': {
      'dashboard': 'डॅशबोर्ड',
      'tenant': 'भाडेकरू',
      'tenants': 'भाडेकरू',
      'tenant_management': 'भाडेकरू व्यवस्थापन',
      'check_in': 'चेक-इन',
      'check_out': 'चेक-आउट',
      'day_sheet': 'दैनिक शीट',
      'reports': 'अहवाल',
      'transactions': 'व्यवहार',
      'more': 'अधिक',
      'settings': 'सेटिंग्ज',
      'notifications': 'सूचना',
      'documents': 'कागदपत्रे',
      'pg_owner': 'PG मालक',
      'property': 'मालमत्ता',
      'language': 'भाषा',
      'select_language': 'भाषा निवडा',
      'save': 'जतन करा',
      'cancel': 'रद्द करा',
      'delete': 'हटवा',
      'edit': 'संपादित करा',
      'add': 'जोडा',
      'update': 'अपडेट करा',
      'search': 'शोधा',
      'change': 'बदला',
      'active': 'सक्रिय',
      'vacated': 'रिकामे केले',
      'available': 'उपलब्ध',
      'occupied': 'व्याप्त',
      'rent': 'भाडे',
      'note': 'टीप',
      'income': 'उत्पन्न',
      'expense': 'खर्च',
      'profit': 'नफा',
      'loss': 'तोटा',
      'this_month': 'या महिन्यात',
      'cash': 'रोख',
      'upi': 'UPI',
      'bank': 'बँक',
      'total': 'एकूण',
      'success': 'यशस्वी',
      'error': 'त्रुटी',
      'warning': 'चेतावणी',
      'loading': 'लोड होत आहे...',
    },

    // ==========================================================
    // BENGALI
    // ==========================================================

    'bn': {
      'dashboard': 'ড্যাশবোর্ড',
      'tenant': 'ভাড়াটিয়া',
      'tenants': 'ভাড়াটিয়ারা',
      'tenant_management': 'ভাড়াটিয়া ব্যবস্থাপনা',
      'check_in': 'চেক-ইন',
      'check_out': 'চেক-আউট',
      'day_sheet': 'দৈনিক শিট',
      'reports': 'রিপোর্ট',
      'transactions': 'লেনদেন',
      'more': 'আরও',
      'settings': 'সেটিংস',
      'notifications': 'বিজ্ঞপ্তি',
      'documents': 'নথি',
      'pg_owner': 'PG মালিক',
      'property': 'সম্পত্তি',
      'language': 'ভাষা',
      'select_language': 'ভাষা নির্বাচন করুন',
      'save': 'সংরক্ষণ করুন',
      'cancel': 'বাতিল করুন',
      'delete': 'মুছুন',
      'edit': 'সম্পাদনা করুন',
      'add': 'যোগ করুন',
      'update': 'আপডেট করুন',
      'search': 'অনুসন্ধান করুন',
      'change': 'পরিবর্তন করুন',
      'active': 'সক্রিয়',
      'vacated': 'খালি করেছেন',
      'available': 'উপলব্ধ',
      'occupied': 'দখলকৃত',
      'rent': 'ভাড়া',
      'note': 'নোট',
      'income': 'আয়',
      'expense': 'খরচ',
      'profit': 'লাভ',
      'loss': 'ক্ষতি',
      'this_month': 'এই মাসে',
      'cash': 'নগদ',
      'upi': 'UPI',
      'bank': 'ব্যাংক',
      'total': 'মোট',
      'success': 'সফল',
      'error': 'ত্রুটি',
      'warning': 'সতর্কতা',
      'loading': 'লোড হচ্ছে...',
    },

    // ==========================================================
    // GUJARATI
    // ==========================================================

    'gu': {
      'dashboard': 'ડેશબોર્ડ',
      'tenant': 'ભાડૂત',
      'tenants': 'ભાડૂતો',
      'tenant_management': 'ભાડૂત વ્યવસ્થાપન',
      'check_in': 'ચેક-ઇન',
      'check_out': 'ચેક-આઉટ',
      'day_sheet': 'દૈનિક શીટ',
      'reports': 'અહેવાલો',
      'transactions': 'વ્યવહારો',
      'more': 'વધુ',
      'settings': 'સેટિંગ્સ',
      'notifications': 'સૂચનાઓ',
      'documents': 'દસ્તાવેજો',
      'pg_owner': 'PG માલિક',
      'property': 'પ્રોપર્ટી',
      'language': 'ભાષા',
      'select_language': 'ભાષા પસંદ કરો',
      'save': 'સાચવો',
      'cancel': 'રદ કરો',
      'delete': 'કાઢી નાખો',
      'edit': 'ફેરફાર કરો',
      'add': 'ઉમેરો',
      'update': 'અપડેટ કરો',
      'search': 'શોધો',
      'change': 'બદલો',
      'active': 'સક્રિય',
      'vacated': 'ખાલી કર્યું',
      'available': 'ઉપલબ્ધ',
      'occupied': 'ભરેલું',
      'rent': 'ભાડું',
      'note': 'નોંધ',
      'income': 'આવક',
      'expense': 'ખર્ચ',
      'profit': 'નફો',
      'loss': 'નુકસાન',
      'this_month': 'આ મહિને',
      'cash': 'રોકડ',
      'upi': 'UPI',
      'bank': 'બેંક',
      'total': 'કુલ',
      'success': 'સફળ',
      'error': 'ભૂલ',
      'warning': 'ચેતવણી',
      'loading': 'લોડ થઈ રહ્યું છે...',
    },

    // ==========================================================
    // PUNJABI
    // ==========================================================

    'pa': {
      'dashboard': 'ਡੈਸ਼ਬੋਰਡ',
      'tenant': 'ਕਿਰਾਏਦਾਰ',
      'tenants': 'ਕਿਰਾਏਦਾਰ',
      'tenant_management': 'ਕਿਰਾਏਦਾਰ ਪ੍ਰਬੰਧਨ',
      'check_in': 'ਚੈੱਕ-ਇਨ',
      'check_out': 'ਚੈੱਕ-ਆਊਟ',
      'day_sheet': 'ਰੋਜ਼ਾਨਾ ਸ਼ੀਟ',
      'reports': 'ਰਿਪੋਰਟਾਂ',
      'transactions': 'ਲੈਣ-ਦੇਣ',
      'more': 'ਹੋਰ',
      'settings': 'ਸੈਟਿੰਗਾਂ',
      'notifications': 'ਸੂਚਨਾਵਾਂ',
      'documents': 'ਦਸਤਾਵੇਜ਼',
      'pg_owner': 'PG ਮਾਲਕ',
      'property': 'ਪ੍ਰਾਪਰਟੀ',
      'language': 'ਭਾਸ਼ਾ',
      'select_language': 'ਭਾਸ਼ਾ ਚੁਣੋ',
      'save': 'ਸੇਵ ਕਰੋ',
      'cancel': 'ਰੱਦ ਕਰੋ',
      'delete': 'ਮਿਟਾਓ',
      'edit': 'ਸੋਧੋ',
      'add': 'ਜੋੜੋ',
      'update': 'ਅੱਪਡੇਟ ਕਰੋ',
      'search': 'ਖੋਜੋ',
      'change': 'ਬਦਲੋ',
      'active': 'ਸਰਗਰਮ',
      'vacated': 'ਖਾਲੀ ਕੀਤਾ',
      'available': 'ਉਪਲਬਧ',
      'occupied': 'ਭਰਿਆ ਹੋਇਆ',
      'rent': 'ਕਿਰਾਇਆ',
      'note': 'ਨੋਟ',
      'income': 'ਆਮਦਨ',
      'expense': 'ਖਰਚਾ',
      'profit': 'ਮੁਨਾਫਾ',
      'loss': 'ਨੁਕਸਾਨ',
      'this_month': 'ਇਸ ਮਹੀਨੇ',
      'cash': 'ਨਕਦ',
      'upi': 'UPI',
      'bank': 'ਬੈਂਕ',
      'total': 'ਕੁੱਲ',
      'success': 'ਸਫਲ',
      'error': 'ਗਲਤੀ',
      'warning': 'ਚੇਤਾਵਨੀ',
      'loading': 'ਲੋਡ ਹੋ ਰਿਹਾ ਹੈ...',
    },

    // ==========================================================
    // ODIA
    // ==========================================================

    'or': {
      'dashboard': 'ଡ୍ୟାସବୋର୍ଡ',
      'tenant': 'ଭଡ଼ାଟିଆ',
      'tenants': 'ଭଡ଼ାଟିଆମାନେ',
      'tenant_management': 'ଭଡ଼ାଟିଆ ପରିଚାଳନା',
      'check_in': 'ଚେକ୍-ଇନ୍',
      'check_out': 'ଚେକ୍-ଆଉଟ୍',
      'day_sheet': 'ଦୈନିକ ସିଟ୍',
      'reports': 'ରିପୋର୍ଟ',
      'transactions': 'କାରବାର',
      'more': 'ଅଧିକ',
      'settings': 'ସେଟିଂସ୍',
      'notifications': 'ବିଜ୍ଞପ୍ତି',
      'documents': 'ଦଲିଲ',
      'pg_owner': 'PG ମାଲିକ',
      'property': 'ସମ୍ପତ୍ତି',
      'language': 'ଭାଷା',
      'select_language': 'ଭାଷା ବାଛନ୍ତୁ',
      'save': 'ସେଭ୍ କରନ୍ତୁ',
      'cancel': 'ବାତିଲ କରନ୍ତୁ',
      'delete': 'ଡିଲିଟ୍ କରନ୍ତୁ',
      'edit': 'ସମ୍ପାଦନ କରନ୍ତୁ',
      'add': 'ଯୋଡନ୍ତୁ',
      'update': 'ଅପଡେଟ୍ କରନ୍ତୁ',
      'search': 'ଖୋଜନ୍ତୁ',
      'change': 'ବଦଳାନ୍ତୁ',
      'active': 'ସକ୍ରିୟ',
      'available': 'ଉପଲବ୍ଧ',
      'occupied': 'ଦଖଲ',
      'rent': 'ଭଡା',
      'income': 'ଆୟ',
      'expense': 'ଖର୍ଚ୍ଚ',
      'profit': 'ଲାଭ',
      'loss': 'କ୍ଷତି',
      'cash': 'ନଗଦ',
      'upi': 'UPI',
      'bank': 'ବ୍ୟାଙ୍କ',
      'total': 'ମୋଟ',
      'success': 'ସଫଳ',
      'error': 'ତ୍ରୁଟି',
      'warning': 'ଚେତାବନୀ',
      'loading': 'ଲୋଡ୍ ହେଉଛି...',
    },

    // ==========================================================
    // ASSAMESE
    // ==========================================================

    'as': {
      'dashboard': 'ড্যাশবৰ্ড',
      'tenant': 'ভাড়াতীয়া',
      'tenants': 'ভাড়াতীয়াসকল',
      'tenant_management': 'ভাড়াতীয়া ব্যৱস্থাপনা',
      'check_in': 'চেক-ইন',
      'check_out': 'চেক-আউট',
      'day_sheet': 'দৈনিক শ্বীট',
      'reports': 'প্ৰতিবেদন',
      'transactions': 'লেনদেন',
      'more': 'অধিক',
      'settings': 'ছেটিংছ',
      'notifications': 'জাননী',
      'documents': 'নথিপত্ৰ',
      'pg_owner': 'PG মালিক',
      'property': 'সম্পত্তি',
      'language': 'ভাষা',
      'select_language': 'ভাষা নিৰ্বাচন কৰক',
      'save': 'সংৰক্ষণ কৰক',
      'cancel': 'বাতিল কৰক',
      'delete': 'মচক',
      'edit': 'সম্পাদনা কৰক',
      'add': 'যোগ কৰক',
      'update': 'আপডেট কৰক',
      'search': 'সন্ধান কৰক',
      'change': 'সলনি কৰক',
      'active': 'সক্ৰিয়',
      'available': 'উপলব্ধ',
      'occupied': 'অধিকৃত',
      'rent': 'ভাড়া',
      'income': 'আয়',
      'expense': 'খৰচ',
      'profit': 'লাভ',
      'loss': 'ক্ষতি',
      'cash': 'নগদ',
      'upi': 'UPI',
      'bank': 'বেংক',
      'total': 'মুঠ',
      'success': 'সফল',
      'error': 'ত্ৰুটি',
      'warning': 'সতৰ্কবাণী',
      'loading': 'লোড হৈ আছে...',
    },

    // ==========================================================
    // URDU
    // ==========================================================

    'ur': {
      'dashboard': 'ڈیش بورڈ',
      'tenant': 'کرایہ دار',
      'tenants': 'کرایہ دار',
      'tenant_management': 'کرایہ داروں کا انتظام',
      'check_in': 'چیک اِن',
      'check_out': 'چیک آؤٹ',
      'day_sheet': 'روزانہ شیٹ',
      'reports': 'رپورٹس',
      'transactions': 'لین دین',
      'more': 'مزید',
      'settings': 'ترتیبات',
      'notifications': 'اطلاعات',
      'documents': 'دستاویزات',
      'pg_owner': 'PG مالک',
      'property': 'پراپرٹی',
      'language': 'زبان',
      'select_language': 'زبان منتخب کریں',
      'save': 'محفوظ کریں',
      'cancel': 'منسوخ کریں',
      'delete': 'حذف کریں',
      'edit': 'ترمیم کریں',
      'add': 'شامل کریں',
      'update': 'اپ ڈیٹ کریں',
      'search': 'تلاش کریں',
      'change': 'تبدیل کریں',
      'active': 'فعال',
      'available': 'دستیاب',
      'occupied': 'مصروف',
      'rent': 'کرایہ',
      'income': 'آمدنی',
      'expense': 'خرچ',
      'profit': 'منافع',
      'loss': 'نقصان',
      'cash': 'نقد',
      'upi': 'UPI',
      'bank': 'بینک',
      'total': 'کل',
      'success': 'کامیاب',
      'error': 'خرابی',
      'warning': 'انتباہ',
      'loading': 'لوڈ ہو رہا ہے...',
    },

    // ==========================================================
    // SANSKRIT
    // ==========================================================

    'sa': {
      'dashboard': 'मुख्यपटलम्',
      'tenant': 'भाटकः',
      'tenants': 'भाटकाः',
      'tenant_management': 'भाटक-प्रबन्धनम्',
      'check_in': 'प्रवेशः',
      'check_out': 'निर्गमनम्',
      'day_sheet': 'दैनिकपत्रम्',
      'reports': 'प्रतिवेदनानि',
      'transactions': 'व्यवहाराः',
      'more': 'अधिकम्',
      'settings': 'व्यवस्थाः',
      'notifications': 'सूचनाः',
      'documents': 'दस्तावेजाः',
      'pg_owner': 'PG स्वामी',
      'property': 'सम्पत्तिः',
      'language': 'भाषा',
      'select_language': 'भाषां चिनुत',
      'save': 'संगृह्णातु',
      'cancel': 'निरस्यताम्',
      'delete': 'अपाकरोतु',
      'edit': 'सम्पादयतु',
      'add': 'योजयतु',
      'update': 'अद्यतनं कुरुत',
      'search': 'अन्वेषयतु',
      'change': 'परिवर्तयतु',
      'active': 'सक्रियम्',
      'available': 'उपलब्धम्',
      'occupied': 'अधिकृतम्',
      'rent': 'भाटकम्',
      'income': 'आयः',
      'expense': 'व्ययः',
      'profit': 'लाभः',
      'loss': 'हानिः',
      'cash': 'नकदम्',
      'upi': 'UPI',
      'bank': 'बैंकः',
      'total': 'सम्पूर्णम्',
      'success': 'सफलम्',
      'error': 'दोषः',
      'warning': 'सावधानता',
      'loading': 'लोड् भवति...',
    },

    // ==========================================================
    // KONKANI
    // ==========================================================

    'kok': {
      'dashboard': 'डॅशबोर्ड',
      'tenant': 'भाडेकरू',
      'tenants': 'भाडेकरू',
      'tenant_management': 'भाडेकरू व्यवस्थापन',
      'check_in': 'चेक-इन',
      'check_out': 'चेक-आउट',
      'day_sheet': 'दिसपट्टी',
      'reports': 'अहवाल',
      'transactions': 'व्यवहार',
      'more': 'अधिक',
      'settings': 'सेटिंग्स',
      'notifications': 'सुचोवणी',
      'documents': 'कागदपत्रां',
      'pg_owner': 'PG मालक',
      'property': 'मालमत्ता',
      'language': 'भास',
      'select_language': 'भास निवडात',
      'save': 'जतन करात',
      'cancel': 'रद्द करात',
      'delete': 'काडून उडयात',
      'edit': 'संपादित करात',
      'add': 'जोडात',
      'update': 'अपडेट करात',
      'search': 'सोदात',
      'change': 'बदलात',
      'active': 'सक्रिय',
      'available': 'उपलब्ध',
      'occupied': 'भरिल्ले',
      'rent': 'भाडें',
      'income': 'उत्पन्न',
      'expense': 'खर्च',
      'profit': 'नफा',
      'loss': 'तोटा',
      'cash': 'रोख',
      'upi': 'UPI',
      'bank': 'बँक',
      'total': 'एकूण',
      'success': 'येस',
      'error': 'चूक',
      'warning': 'इशारो',
      'loading': 'लोड जाता...',
    },

    // ==========================================================
    // KASHMIRI
    // ==========================================================

    'ks': {
      'dashboard': 'ڈیش بورڈ',
      'tenant': 'کرایہ دار',
      'tenants': 'کرایہ دار',
      'tenant_management': 'کرایہ دار انتظام',
      'check_in': 'چیک اِن',
      'check_out': 'چیک آؤٹ',
      'day_sheet': 'روزانہ شیٹ',
      'reports': 'رپورٹس',
      'transactions': 'لین دین',
      'more': 'مزید',
      'settings': 'ترتیبات',
      'notifications': 'اطلاعات',
      'documents': 'دستاویزات',
      'pg_owner': 'PG مالک',
      'property': 'جائیداد',
      'language': 'زبان',
      'select_language': 'زبان منتخب کریں',
      'save': 'محفوظ کریں',
      'cancel': 'منسوخ کریں',
      'delete': 'حذف کریں',
      'edit': 'ترمیم کریں',
      'add': 'شامل کریں',
      'update': 'اپ ڈیٹ کریں',
      'search': 'تلاش کریں',
      'change': 'تبدیل کریں',
      'active': 'فعال',
      'available': 'دستیاب',
      'occupied': 'بھرا ہوا',
      'rent': 'کرایہ',
      'income': 'آمدنی',
      'expense': 'خرچ',
      'profit': 'منافع',
      'loss': 'نقصان',
      'cash': 'نقد',
      'upi': 'UPI',
      'bank': 'بینک',
      'total': 'کل',
    },

    // ==========================================================
    // SINDHI
    // ==========================================================

    'sd': {
      'dashboard': 'ڊيش بورڊ',
      'tenant': 'ڪرائيدار',
      'tenants': 'ڪرائيدار',
      'tenant_management': 'ڪرائيدارن جو انتظام',
      'check_in': 'چيڪ اِن',
      'check_out': 'چيڪ آئوٽ',
      'day_sheet': 'روزاني شيٽ',
      'reports': 'رپورٽون',
      'transactions': 'ڏيتي ليتي',
      'more': 'وڌيڪ',
      'settings': 'سيٽنگون',
      'notifications': 'اطلاع',
      'documents': 'دستاويز',
      'pg_owner': 'PG مالڪ',
      'property': 'ملڪيت',
      'language': 'ٻولي',
      'select_language': 'ٻولي چونڊيو',
      'save': 'محفوظ ڪريو',
      'cancel': 'منسوخ ڪريو',
      'delete': 'ختم ڪريو',
      'edit': 'ترميم ڪريو',
      'add': 'شامل ڪريو',
      'update': 'اپڊيٽ ڪريو',
      'search': 'ڳوليو',
      'change': 'تبديل ڪريو',
      'active': 'فعال',
      'available': 'دستياب',
      'occupied': 'ڀريل',
      'rent': 'ڪرايو',
      'income': 'آمدني',
      'expense': 'خرچ',
      'profit': 'نفعو',
      'loss': 'نقصان',
      'cash': 'نقد',
      'upi': 'UPI',
      'bank': 'بينڪ',
      'total': 'ڪل',
    },

    // ==========================================================
    // NEPALI
    // ==========================================================

    'ne': {
      'dashboard': 'ड्यासबोर्ड',
      'tenant': 'भाडामा बस्ने',
      'tenants': 'भाडामा बस्नेहरू',
      'tenant_management': 'भाडामा बस्ने व्यवस्थापन',
      'check_in': 'चेक-इन',
      'check_out': 'चेक-आउट',
      'day_sheet': 'दैनिक विवरण',
      'reports': 'रिपोर्टहरू',
      'transactions': 'कारोबारहरू',
      'more': 'थप',
      'settings': 'सेटिङहरू',
      'notifications': 'सूचनाहरू',
      'documents': 'कागजातहरू',
      'pg_owner': 'PG मालिक',
      'property': 'सम्पत्ति',
      'language': 'भाषा',
      'select_language': 'भाषा चयन गर्नुहोस्',
      'save': 'सेभ गर्नुहोस्',
      'cancel': 'रद्द गर्नुहोस्',
      'delete': 'मेटाउनुहोस्',
      'edit': 'सम्पादन गर्नुहोस्',
      'add': 'थप्नुहोस्',
      'update': 'अपडेट गर्नुहोस्',
      'search': 'खोज्नुहोस्',
      'change': 'परिवर्तन गर्नुहोस्',
      'active': 'सक्रिय',
      'available': 'उपलब्ध',
      'occupied': 'भरिएको',
      'rent': 'भाडा',
      'income': 'आम्दानी',
      'expense': 'खर्च',
      'profit': 'नाफा',
      'loss': 'नोक्सान',
      'cash': 'नगद',
      'upi': 'UPI',
      'bank': 'बैंक',
      'total': 'जम्मा',
    },

    // ==========================================================
    // MAITHILI
    // ==========================================================

    'mai': {
      'dashboard': 'डैशबोर्ड',
      'tenant': 'किरायेदार',
      'tenants': 'किरायेदार सभ',
      'tenant_management': 'किरायेदार प्रबन्धन',
      'check_in': 'चेक-इन',
      'check_out': 'चेक-आउट',
      'day_sheet': 'दैनिक शीट',
      'reports': 'रिपोर्ट',
      'transactions': 'लेन-देन',
      'more': 'बेसी',
      'settings': 'सेटिंग',
      'notifications': 'सूचना',
      'documents': 'दस्तावेज',
      'pg_owner': 'PG मालिक',
      'property': 'सम्पत्ति',
      'language': 'भाषा',
      'select_language': 'भाषा चुनू',
      'save': 'सेव करू',
      'cancel': 'रद्द करू',
      'delete': 'हटाउ',
      'edit': 'सम्पादन करू',
      'add': 'जोड़ू',
      'update': 'अपडेट करू',
      'search': 'खोजू',
      'change': 'बदलू',
      'active': 'सक्रिय',
      'available': 'उपलब्ध',
      'occupied': 'भरल',
      'rent': 'किराया',
      'income': 'आमदनी',
      'expense': 'खर्च',
      'profit': 'लाभ',
      'loss': 'हानि',
      'cash': 'नगद',
      'upi': 'UPI',
      'bank': 'बैंक',
      'total': 'कुल',
    },

    // ==========================================================
    // MANIPURI
    // ==========================================================

    'mni': {
      'dashboard': 'ꯗꯦꯁꯕꯣꯔꯗ',
      'tenant': 'ꯇꯦꯅꯦꯟꯠ',
      'tenants': 'ꯇꯦꯅꯦꯟꯠꯁꯤꯡ',
      'tenant_management': 'ꯇꯦꯅꯦꯟꯠ ꯃꯦꯅꯦꯖꯃꯦꯟꯠ',
      'check_in': 'ꯆꯦꯛ-ꯏꯟ',
      'check_out': 'ꯆꯦꯛ-ꯑꯥꯎꯠ',
      'day_sheet': 'ꯅꯨꯃꯤꯠ ꯁꯤꯠ',
      'reports': 'ꯔꯤꯄꯣꯔꯠꯁꯤꯡ',
      'transactions': 'ꯇ꯭ꯔꯥꯟꯖꯦꯛꯁꯟ',
      'more': 'ꯍꯦꯅꯒꯠꯄ',
      'settings': 'ꯁꯦꯇꯤꯡꯁ',
      'notifications': 'ꯅꯣꯇꯤꯐꯤꯀꯦꯁꯟ',
      'documents': 'ꯗꯣꯀꯨꯃꯦꯟꯇ',
      'pg_owner': 'PG ꯑꯣꯅꯔ',
      'property': 'ꯄ꯭ꯔꯣꯄꯔꯇꯤ',
      'language': 'ꯂꯣꯟ',
      'select_language': 'ꯂꯣꯟ ꯈꯅꯕ',
      'save': 'ꯁꯦꯕ ꯇꯧ',
      'cancel': 'ꯀꯦꯟꯁꯦꯜ ꯇꯧ',
      'delete': 'ꯃꯥꯡꯍꯜ',
      'edit': 'ꯏꯗꯤꯠ ꯇꯧ',
      'add': 'ꯍꯥꯄꯆꯤꯜ',
      'update': 'ꯑꯄꯗꯦꯠ ꯇꯧ',
      'search': 'ꯊꯤꯅꯕ',
      'change': 'ꯁꯣꯀꯄ',
      'active': 'ꯑꯦꯛꯇꯤꯕ',
      'available': 'ꯐꯪꯕ ꯌꯥꯕ',
      'occupied': 'ꯃꯁꯤꯡ ꯂꯩꯕ',
      'rent': 'ꯔꯦꯟꯠ',
      'income': 'ꯏꯟꯀꯝ',
      'expense': 'ꯏꯛꯁꯄꯦꯟꯁ',
      'profit': 'ꯄ꯭ꯔꯣꯐꯤꯠ',
      'loss': 'ꯂꯣꯁ',
      'cash': 'ꯀꯦꯁ',
      'upi': 'UPI',
      'bank': 'ꯕꯦꯡꯛ',
      'total': 'ꯃꯄꯨꯡ',
    },

    // ==========================================================
    // BODO
    // ==========================================================

    'brx': {
      'dashboard': 'ड्यासबोर्ड',
      'tenant': 'भाडाग्राही',
      'tenants': 'भाडाग्राहीफोर',
      'tenant_management': 'भाडाग्राही सोलों',
      'check_in': 'चेक-इन',
      'check_out': 'चेक-आउट',
      'day_sheet': 'सानस्रि सिट',
      'reports': 'रिपोर्ट',
      'transactions': 'लेन-देन',
      'more': 'गोबां',
      'settings': 'सेटिं',
      'notifications': 'खौरां',
      'documents': 'फोरमान',
      'pg_owner': 'PG मालिक',
      'property': 'जायगा',
      'language': 'राव',
      'select_language': 'राव सायख',
      'save': 'सेभ खालाम',
      'cancel': 'बातिल खालाम',
      'delete': 'बोखार',
      'edit': 'सुधार',
      'add': 'जोर',
      'update': 'आपडेट',
      'search': 'नाय',
      'change': 'सोलाय',
      'active': 'सक्रिय',
      'available': 'मोनो',
      'occupied': 'दखल',
      'rent': 'भाडा',
      'income': 'आय',
      'expense': 'खरच',
      'profit': 'लाभ',
      'loss': 'नुकसान',
      'cash': 'नगद',
      'upi': 'UPI',
      'bank': 'बैंक',
      'total': 'जेरै',
    },

    // ==========================================================
    // SANTALI
    // ==========================================================

    'sat': {
      'dashboard': 'ᱰᱮᱥᱵᱳᱨᱰ',
      'tenant': 'ᱵᱷᱟᱲᱟ ᱜᱟᱹᱦᱤᱨ',
      'tenants': 'ᱵᱷᱟᱲᱟ ᱜᱟᱹᱦᱤᱨ ᱠᱚ',
      'tenant_management': 'ᱵᱷᱟᱲᱟ ᱜᱟᱹᱦᱤᱨ ᱵᱮᱵᱚᱥᱛᱟ',
      'check_in': 'ᱪᱮᱠ-ᱤᱱ',
      'check_out': 'ᱪᱮᱠ-ᱟᱣᱩᱴ',
      'day_sheet': 'ᱢᱟᱦᱟ ᱥᱤᱴ',
      'reports': 'ᱨᱤᱯᱳᱨᱴ',
      'transactions': 'ᱞᱮᱱ-ᱫᱮᱱ',
      'more': 'ᱵᱟᱹᱲᱛᱤ',
      'settings': 'ᱥᱮᱴᱤᱝ',
      'notifications': 'ᱥᱩᱪᱱᱟ',
      'documents': 'ᱫᱚᱞᱤᱞ',
      'pg_owner': 'PG ᱢᱟᱹᱞᱤᱠ',
      'property': 'ᱥᱚᱢᱯᱚᱛᱛᱤ',
      'language': 'ᱯᱟᱹᱨᱥᱤ',
      'select_language': 'ᱯᱟᱹᱨᱥᱤ ᱵᱟᱪᱷᱟᱣ',
      'save': 'ᱥᱮᱵ ᱢᱮ',
      'cancel': 'ᱵᱟᱹᱛᱤᱞ ᱢᱮ',
      'delete': 'ᱢᱮᱴᱟᱣ ᱢᱮ',
      'edit': 'ᱥᱩᱫᱷᱨᱟᱣ ᱢᱮ',
      'add': 'ᱡᱩᱲᱟᱹᱣ ᱢᱮ',
      'update': 'ᱟᱯᱰᱮᱴ ᱢᱮ',
      'search': 'ᱥᱮᱫᱟ ᱢᱮ',
      'change': 'ᱵᱚᱫᱚᱞ ᱢᱮ',
      'active': 'ᱥᱚᱠᱨᱤᱭᱚ',
      'available': 'ᱢᱮᱱᱟᱜ',
      'occupied': 'ᱵᱷᱟᱹᱨᱛᱤ',
      'rent': 'ᱵᱷᱟᱲᱟ',
      'income': 'ᱟᱭ',
      'expense': 'ᱠᱷᱚᱨᱪᱚ',
      'profit': 'ᱞᱟᱹᱵᱷ',
      'loss': 'ᱱᱩᱠᱥᱟᱱ',
      'cash': 'ᱱᱟᱠᱟᱹ',
      'upi': 'UPI',
      'bank': 'ᱵᱮᱝᱠ',
      'total': 'ᱢᱳᱴ',
    },
  };
}