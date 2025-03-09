Future<UserModel?> signUp({
  required String email,
  required String password,
  required String pseudo,
  String? firstName,
}) async {
  try {
    final response = await _supabase.auth.signUp(
      email: email,
      password: password,
    );

    if (response.user != null) {
      // Ajouter une date de naissance par défaut
      final DateTime defaultBirthDate = DateTime(2000, 1, 1);

      // Créer le profil utilisateur dans la table app_user
      await _supabase.from('app_user').insert({
        'id': response.user!.id,
        'pseudo': pseudo,
        'first_name': firstName,
        'birth_date':
            defaultBirthDate.toIso8601String(), // Ajout de la date de naissance
        'inscription_date': DateTime.now().toIso8601String(),
      });

      return UserModel(
        id: response.user!.id,
        pseudo: pseudo,
        firstName: firstName,
        birthDate:
            defaultBirthDate, // Inclure la date de naissance dans le modèle
        inscriptionDate: DateTime.now(),
      );
    }
    return null;
  } catch (e) {
    throw Exception('Échec de l\'inscription: $e');
  }
}
