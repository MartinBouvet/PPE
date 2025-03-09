import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service de gestion des préférences utilisateur
class PreferencesService {
  static const String _themeKey = 'theme_mode';
  static const String _languageKey = 'language_code';
  static const String _onboardingCompleteKey = 'onboarding_complete';
  static const String _notificationsEnabledKey = 'notifications_enabled';
  static const String _lastUserIdKey = 'last_user_id';
  static const String _tokenExpirationKey = 'token_expiration';

  static late SharedPreferences _prefs;

  /// Initialise le service
  static Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Récupère le mode de thème sauvegardé
  static ThemeMode getThemeMode() {
    final themeValue = _prefs.getString(_themeKey);
    if (themeValue == 'dark') {
      return ThemeMode.dark;
    } else if (themeValue == 'light') {
      return ThemeMode.light;
    } else {
      return ThemeMode.system;
    }
  }

  /// Sauvegarde le mode de thème
  static Future<void> setThemeMode(ThemeMode mode) async {
    String value;
    switch (mode) {
      case ThemeMode.dark:
        value = 'dark';
        break;
      case ThemeMode.light:
        value = 'light';
        break;
      default:
        value = 'system';
    }
    await _prefs.setString(_themeKey, value);
  }

  /// Récupère le code de langue sauvegardé
  static String getLanguageCode() {
    return _prefs.getString(_languageKey) ?? 'fr';
  }

  /// Sauvegarde le code de langue
  static Future<void> setLanguageCode(String code) async {
    await _prefs.setString(_languageKey, code);
  }

  /// Vérifie si l'onboarding a été complété
  static bool isOnboardingComplete() {
    return _prefs.getBool(_onboardingCompleteKey) ?? false;
  }

  /// Marque l'onboarding comme complété
  static Future<void> setOnboardingComplete(bool complete) async {
    await _prefs.setBool(_onboardingCompleteKey, complete);
  }

  /// Vérifie si les notifications sont activées
  static bool areNotificationsEnabled() {
    return _prefs.getBool(_notificationsEnabledKey) ?? true;
  }

  /// Active ou désactive les notifications
  static Future<void> setNotificationsEnabled(bool enabled) async {
    await _prefs.setBool(_notificationsEnabledKey, enabled);
  }

  /// Sauvegarde l'ID du dernier utilisateur connecté
  static Future<void> setLastUserId(String userId) async {
    await _prefs.setString(_lastUserIdKey, userId);
  }

  /// Récupère l'ID du dernier utilisateur connecté
  static String? getLastUserId() {
    return _prefs.getString(_lastUserIdKey);
  }

  /// Vérifie si le token est expiré
  static bool isTokenExpired() {
    final expiryTimestamp = _prefs.getInt(_tokenExpirationKey) ?? 0;
    return DateTime.now().millisecondsSinceEpoch > expiryTimestamp;
  }

  /// Sauvegarde la date d'expiration du token
  static Future<void> setTokenExpiration(DateTime expiryDate) async {
    await _prefs.setInt(
      _tokenExpirationKey,
      expiryDate.millisecondsSinceEpoch,
    );
  }

  /// Supprime toutes les préférences (utile lors de la déconnexion)
  static Future<void> clearAllPreferences() async {
    // Sauvegardons quelques préférences qui doivent être conservées
    final themeMode = getThemeMode();
    final languageCode = getLanguageCode();
    final notificationsEnabled = areNotificationsEnabled();

    await _prefs.clear();

    // Restaurons les préférences à conserver
    await setThemeMode(themeMode);
    await setLanguageCode(languageCode);
    await setNotificationsEnabled(notificationsEnabled);
  }
}
