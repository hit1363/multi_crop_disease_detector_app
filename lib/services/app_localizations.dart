import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'language_service.dart';

class AppLocalizations {
  const AppLocalizations(this.language);

  final AppLanguage language;

  static AppLocalizations of(BuildContext context) {
    return AppLocalizations(context.watch<LanguageService>().language);
  }

  TextDirection get textDirection {
    return language == AppLanguage.urdu ? TextDirection.rtl : TextDirection.ltr;
  }

  String text(String key, {Map<String, String> values = const {}}) {
    var result =
        (_translations[language.code]?[key] ??
                _translations[AppLanguage.english.code]?[key] ??
                key)
            .toString();
    for (final entry in values.entries) {
      result = result.replaceAll('{${entry.key}}', entry.value);
    }
    return result;
  }

  String severity(String value) {
    return text('severity_$value');
  }

  static const Map<String, Map<String, String>> _translations = {
    'en': {
      'app_title': 'Multi Crop Disease Detector',
      'app_subtitle': 'AI-assisted crop care',
      'home': 'Home',
      'scan': 'Scan',
      'history': 'History',
      'statistics': 'Statistics',
      'diseases': 'Diseases',
      'language': 'Language',
      'dark_mode': 'Dark mode',
      'light_mode': 'Light mode',
      'about': 'About',
      'ai_detection': 'AI Plant Disease Detection',
      'ai_description':
          'Detect diseases across multiple crops using TensorFlow Lite.',
      'start_scan': 'Start Scan',
      'gallery_hint': 'Select a leaf image from gallery',
      'browse_diseases': 'Browse Diseases',
      'browse_hint': 'Explore the offline disease encyclopedia',
      'disclaimer':
          'This application provides AI-assisted disease detection and should not replace professional agricultural consultation.',
      'scan_leaf': 'Scan Leaf',
      'live_preview': 'Live Camera Preview',
      'capture_image': 'Capture Image',
      'saving_image': 'Saving image',
      'retake': 'Retake',
      'analyze_image': 'Analyze Image',
      'analyzing': 'Analyzing',
      'select_gallery': 'Select Image from Gallery',
      'camera_unavailable': 'Camera unavailable: {error}',
      'capture_failed': 'Could not capture image: {error}',
      'analysis_failed': 'Could not analyze image: {error}',
      'put_leaf_here': 'Put leaf here',
      'disease_information': 'Disease Information',
      'no_predictions': 'No predictions available.',
      'load_disease_failed': 'Failed to load disease information.\n{error}',
      'export_pdf': 'Export PDF Report',
      'preparing_report': 'Preparing report',
      'export_failed': 'Could not export report: {error}',
      'severity_label': 'Severity: {severity}',
      'top_predictions': 'Top predictions',
      'description': 'Description',
      'symptoms': 'Symptoms',
      'cultural_control': 'Cultural Control',
      'chemical_control': 'Chemical Control',
      'biological_control': 'Biological Control',
      'favorable_conditions': 'Favorable Conditions',
      'spread': 'Spread',
      'recommendations': 'Recommendations',
      'scan_history': 'Scan History',
      'history_failed': 'Could not load history',
      'no_scans': 'No scans yet',
      'no_scans_hint': 'Completed predictions will appear here.',
      'scan_deleted': 'Scan deleted',
      'delete_scan': 'Delete scan',
      'crop': '{crop} crop',
      'statistics_failed': 'Could not load statistics.\n{error}',
      'no_statistics': 'No scan data yet. Run predictions to build statistics.',
      'total_scans': 'Total scans: {count}',
      'healthy_vs_disease': 'Healthy vs Disease',
      'healthy': 'Healthy',
      'disease': 'Disease',
      'crop_scan_counts': 'Crop Scan Counts',
      'conditions': '{count} conditions',
      'encyclopedia_failed': 'Could not load disease encyclopedia.\n{error}',
      'offline_description':
          'Offline crop disease prediction with scan history, statistics, disease encyclopedia, and PDF reporting.',
      'severity_severe': 'Severe',
      'severity_moderate': 'Moderate',
      'severity_mild': 'Mild',
      'severity_none': 'Healthy',
      'severity_unknown': 'Unknown',
      'healthy_title': 'Plant Appears Healthy',
      'healthy_message':
          'No visible disease symptoms were detected. Continue regular monitoring and good crop management practices.',
      'severe_title': 'Severe Infection Detected',
      'severe_message':
          'Immediate action is recommended. The disease may spread rapidly and significantly reduce crop yield if left untreated.',
      'moderate_title': 'Moderate Infection Detected',
      'moderate_message':
          'The disease is present and should be managed soon to prevent further spread and damage.',
      'mild_title': 'Mild Infection Detected',
      'mild_message':
          'Early signs of disease are visible. Monitor the plant closely and apply preventive measures if necessary.',
      'unknown_title': 'Prediction Available',
      'unknown_message':
          'Disease severity information is unavailable. Review symptoms carefully before taking action.',
    },
    'bn': {
      'app_title': 'বহু ফসল রোগ শনাক্তকারী',
      'app_subtitle': 'এআই-সহায়তায় ফসল পরিচর্যা',
      'home': 'হোম',
      'scan': 'স্ক্যান',
      'history': 'ইতিহাস',
      'statistics': 'পরিসংখ্যান',
      'diseases': 'রোগসমূহ',
      'language': 'ভাষা',
      'dark_mode': 'ডার্ক মোড',
      'light_mode': 'লাইট মোড',
      'about': 'সম্পর্কে',
      'ai_detection': 'এআই উদ্ভিদ রোগ শনাক্তকরণ',
      'ai_description':
          'TensorFlow Lite ব্যবহার করে একাধিক ফসলের রোগ শনাক্ত করুন।',
      'start_scan': 'স্ক্যান শুরু করুন',
      'gallery_hint': 'গ্যালারি থেকে পাতার ছবি নির্বাচন করুন',
      'browse_diseases': 'রোগসমূহ দেখুন',
      'browse_hint': 'অফলাইন রোগ বিশ্বকোষ দেখুন',
      'disclaimer':
          'এই অ্যাপটি এআই-সহায়তায় রোগ শনাক্ত করে এবং পেশাদার কৃষি পরামর্শের বিকল্প নয়।',
      'scan_leaf': 'পাতা স্ক্যান করুন',
      'live_preview': 'সরাসরি ক্যামেরা প্রিভিউ',
      'capture_image': 'ছবি তুলুন',
      'saving_image': 'ছবি সংরক্ষণ হচ্ছে',
      'retake': 'আবার তুলুন',
      'analyze_image': 'ছবি বিশ্লেষণ করুন',
      'analyzing': 'বিশ্লেষণ হচ্ছে',
      'select_gallery': 'গ্যালারি থেকে ছবি নির্বাচন করুন',
      'camera_unavailable': 'ক্যামেরা উপলভ্য নয়: {error}',
      'capture_failed': 'ছবি তোলা যায়নি: {error}',
      'analysis_failed': 'ছবি বিশ্লেষণ করা যায়নি: {error}',
      'put_leaf_here': 'এখানে পাতা রাখুন',
      'disease_information': 'রোগের তথ্য',
      'no_predictions': 'কোনো পূর্বাভাস পাওয়া যায়নি।',
      'load_disease_failed': 'রোগের তথ্য লোড করা যায়নি।\n{error}',
      'export_pdf': 'পিডিএফ প্রতিবেদন রপ্তানি করুন',
      'preparing_report': 'প্রতিবেদন প্রস্তুত হচ্ছে',
      'export_failed': 'প্রতিবেদন রপ্তানি করা যায়নি: {error}',
      'severity_label': 'তীব্রতা: {severity}',
      'top_predictions': 'শীর্ষ পূর্বাভাস',
      'description': 'বিবরণ',
      'symptoms': 'উপসর্গ',
      'cultural_control': 'কৃষি ব্যবস্থাপনা',
      'chemical_control': 'রাসায়নিক নিয়ন্ত্রণ',
      'biological_control': 'জৈব নিয়ন্ত্রণ',
      'favorable_conditions': 'অনুকূল পরিবেশ',
      'spread': 'বিস্তার',
      'recommendations': 'পরামর্শ',
      'scan_history': 'স্ক্যানের ইতিহাস',
      'history_failed': 'ইতিহাস লোড করা যায়নি',
      'no_scans': 'এখনও কোনো স্ক্যান নেই',
      'no_scans_hint': 'সম্পন্ন পূর্বাভাস এখানে দেখা যাবে।',
      'scan_deleted': 'স্ক্যান মুছে ফেলা হয়েছে',
      'delete_scan': 'স্ক্যান মুছুন',
      'crop': '{crop} ফসল',
      'statistics_failed': 'পরিসংখ্যান লোড করা যায়নি।\n{error}',
      'no_statistics':
          'এখনও কোনো স্ক্যান ডেটা নেই। পরিসংখ্যান দেখতে পূর্বাভাস চালান।',
      'total_scans': 'মোট স্ক্যান: {count}',
      'healthy_vs_disease': 'সুস্থ বনাম রোগাক্রান্ত',
      'healthy': 'সুস্থ',
      'disease': 'রোগ',
      'crop_scan_counts': 'ফসলভিত্তিক স্ক্যান সংখ্যা',
      'conditions': '{count}টি অবস্থা',
      'encyclopedia_failed': 'রোগ বিশ্বকোষ লোড করা যায়নি।\n{error}',
      'offline_description':
          'স্ক্যান ইতিহাস, পরিসংখ্যান, রোগ বিশ্বকোষ ও পিডিএফ প্রতিবেদনসহ অফলাইন ফসল রোগ পূর্বাভাস।',
      'severity_severe': 'তীব্র',
      'severity_moderate': 'মাঝারি',
      'severity_mild': 'হালকা',
      'severity_none': 'সুস্থ',
      'severity_unknown': 'অজানা',
      'healthy_title': 'গাছটি সুস্থ মনে হচ্ছে',
      'healthy_message':
          'রোগের কোনো দৃশ্যমান উপসর্গ পাওয়া যায়নি। নিয়মিত পর্যবেক্ষণ ও ভাল ফসল ব্যবস্থাপনা চালিয়ে যান।',
      'severe_title': 'তীব্র সংক্রমণ শনাক্ত হয়েছে',
      'severe_message':
          'অবিলম্বে ব্যবস্থা নিন। চিকিৎসা না করলে রোগ দ্রুত ছড়িয়ে ফলন উল্লেখযোগ্যভাবে কমাতে পারে।',
      'moderate_title': 'মাঝারি সংক্রমণ শনাক্ত হয়েছে',
      'moderate_message':
          'রোগটি উপস্থিত আছে; বিস্তার ও ক্ষতি এড়াতে দ্রুত ব্যবস্থা নিন।',
      'mild_title': 'হালকা সংক্রমণ শনাক্ত হয়েছে',
      'mild_message':
          'রোগের প্রাথমিক লক্ষণ দেখা গেছে। গাছটি পর্যবেক্ষণ করুন এবং প্রয়োজনে প্রতিরোধমূলক ব্যবস্থা নিন।',
      'unknown_title': 'পূর্বাভাস পাওয়া গেছে',
      'unknown_message':
          'রোগের তীব্রতার তথ্য নেই। ব্যবস্থা নেওয়ার আগে উপসর্গ ভালোভাবে পর্যালোচনা করুন।',
    },
    'ur': {
      'app_title': 'کثیر فصل بیماری شناخت کار',
      'app_subtitle': 'اے آئی معاون فصل نگہداشت',
      'home': 'ہوم',
      'scan': 'اسکین',
      'history': 'تاریخچہ',
      'statistics': 'اعداد و شمار',
      'diseases': 'بیماریاں',
      'language': 'زبان',
      'dark_mode': 'ڈارک موڈ',
      'light_mode': 'لائٹ موڈ',
      'about': 'متعلق',
      'ai_detection': 'اے آئی پودوں کی بیماری شناخت',
      'ai_description':
          'TensorFlow Lite کے ذریعے متعدد فصلوں کی بیماریوں کی شناخت کریں۔',
      'start_scan': 'اسکین شروع کریں',
      'gallery_hint': 'گیلری سے پتے کی تصویر منتخب کریں',
      'browse_diseases': 'بیماریاں دیکھیں',
      'browse_hint': 'آف لائن بیماری انسائیکلوپیڈیا دیکھیں',
      'disclaimer':
          'یہ ایپ اے آئی معاون بیماری شناخت فراہم کرتی ہے اور پیشہ ور زرعی مشورے کا متبادل نہیں ہے۔',
      'scan_leaf': 'پتہ اسکین کریں',
      'live_preview': 'براہ راست کیمرہ پیش منظر',
      'capture_image': 'تصویر لیں',
      'saving_image': 'تصویر محفوظ ہو رہی ہے',
      'retake': 'دوبارہ لیں',
      'analyze_image': 'تصویر کا تجزیہ کریں',
      'analyzing': 'تجزیہ ہو رہا ہے',
      'select_gallery': 'گیلری سے تصویر منتخب کریں',
      'camera_unavailable': 'کیمرہ دستیاب نہیں: {error}',
      'capture_failed': 'تصویر نہیں لی جا سکی: {error}',
      'analysis_failed': 'تصویر کا تجزیہ نہیں ہو سکا: {error}',
      'put_leaf_here': 'پتہ یہاں رکھیں',
      'disease_information': 'بیماری کی معلومات',
      'no_predictions': 'کوئی پیش گوئی دستیاب نہیں۔',
      'load_disease_failed': 'بیماری کی معلومات لوڈ نہیں ہو سکیں۔\n{error}',
      'export_pdf': 'پی ڈی ایف رپورٹ برآمد کریں',
      'preparing_report': 'رپورٹ تیار ہو رہی ہے',
      'export_failed': 'رپورٹ برآمد نہیں ہو سکی: {error}',
      'severity_label': 'شدت: {severity}',
      'top_predictions': 'بہترین پیش گوئیاں',
      'description': 'تفصیل',
      'symptoms': 'علامات',
      'cultural_control': 'زرعی انتظام',
      'chemical_control': 'کیمیائی کنٹرول',
      'biological_control': 'حیاتیاتی کنٹرول',
      'favorable_conditions': 'موافق حالات',
      'spread': 'پھیلاؤ',
      'recommendations': 'سفارشات',
      'scan_history': 'اسکین تاریخچہ',
      'history_failed': 'تاریخچہ لوڈ نہیں ہو سکا',
      'no_scans': 'ابھی کوئی اسکین نہیں',
      'no_scans_hint': 'مکمل پیش گوئیاں یہاں نظر آئیں گی۔',
      'scan_deleted': 'اسکین حذف کر دیا گیا',
      'delete_scan': 'اسکین حذف کریں',
      'crop': '{crop} فصل',
      'statistics_failed': 'اعداد و شمار لوڈ نہیں ہو سکے۔\n{error}',
      'no_statistics':
          'ابھی کوئی اسکین ڈیٹا نہیں۔ اعداد و شمار کے لیے پیش گوئی چلائیں۔',
      'total_scans': 'کل اسکین: {count}',
      'healthy_vs_disease': 'صحت مند بمقابلہ بیمار',
      'healthy': 'صحت مند',
      'disease': 'بیماری',
      'crop_scan_counts': 'فصل کے اسکین کی تعداد',
      'conditions': '{count} حالتیں',
      'encyclopedia_failed': 'بیماری انسائیکلوپیڈیا لوڈ نہیں ہو سکا۔\n{error}',
      'offline_description':
          'اسکین تاریخچہ، اعداد و شمار، بیماری انسائیکلوپیڈیا اور پی ڈی ایف رپورٹ کے ساتھ آف لائن فصل بیماری پیش گوئی۔',
      'severity_severe': 'شدید',
      'severity_moderate': 'درمیانی',
      'severity_mild': 'ہلکی',
      'severity_none': 'صحت مند',
      'severity_unknown': 'نامعلوم',
      'healthy_title': 'پودا صحت مند معلوم ہوتا ہے',
      'healthy_message':
          'بیماری کی کوئی واضح علامات نہیں ملیں۔ باقاعدہ نگرانی اور اچھی فصل نگہداشت جاری رکھیں۔',
      'severe_title': 'شدید انفیکشن کی شناخت ہوئی',
      'severe_message':
          'فوری کارروائی تجویز کی جاتی ہے۔ علاج نہ ہونے پر بیماری تیزی سے پھیل کر پیداوار کم کر سکتی ہے۔',
      'moderate_title': 'درمیانی انفیکشن کی شناخت ہوئی',
      'moderate_message':
          'بیماری موجود ہے؛ مزید پھیلاؤ اور نقصان سے بچنے کے لیے جلد انتظام کریں۔',
      'mild_title': 'ہلکے انفیکشن کی شناخت ہوئی',
      'mild_message':
          'بیماری کی ابتدائی علامات موجود ہیں۔ پودے کی نگرانی کریں اور ضرورت پر احتیاطی تدابیر اپنائیں۔',
      'unknown_title': 'پیش گوئی دستیاب ہے',
      'unknown_message':
          'بیماری کی شدت کی معلومات دستیاب نہیں۔ کارروائی سے پہلے علامات کا بغور جائزہ لیں۔',
    },
  };
}
