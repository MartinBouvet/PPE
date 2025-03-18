// lib/views/auth/signup_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart';
import '../../repositories/auth_repository.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({Key? key}) : super(key: key);

  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _pseudoController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _birthDateController = TextEditingController();
  final _authRepository = AuthRepository();

  DateTime _selectedDate = DateTime(2000, 1, 1); // Date par défaut
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _errorMessage;
  String? _selectedGender; // Initialisez à null au lieu d'une valeur par défaut
  String? _genderError; // Pour stocker le message d'erreur
  final List<String> _genderOptions = ['Homme', 'Femme', 'Autre'];

  @override
  void initState() {
    super.initState();
    _birthDateController.text = _formatDate(_selectedDate);
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      locale: const Locale('fr', 'FR'), // Pour avoir le calendrier en français
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _birthDateController.text = _formatDate(_selectedDate);
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _pseudoController.dispose();
    _firstNameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _birthDateController.dispose();
    super.dispose();
  }

  String _convertGenderToStandardFormat(String? gender) {
    switch (gender) {
      case 'Homme':
        return 'Male';
      case 'Femme':
        return 'Female';
      case 'Autre':
        return 'Other';
      default:
        return 'No Answer';
    }
  }

  Future<void> _signUp() async {
    // Masquer le clavier
    FocusScope.of(context).unfocus();

    // Vérifier si un genre est sélectionné
    setState(() {
      if (_selectedGender == null) {
        _genderError = 'Veuillez sélectionner votre genre';
      } else {
        _genderError = null;
      }
    });

    // Vérifier si le formulaire est valide ET si un genre est sélectionné
    if (!_formKey.currentState!.validate() || _genderError != null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = await _authRepository.signUp(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      pseudo: _pseudoController.text.trim(),
      firstName: _firstNameController.text.trim(),
      birthDate: _selectedDate,
      gender: _convertGenderToStandardFormat(_selectedGender), // Conversion ici
    );

      if (user != null && mounted) {
        context.go('/');
      } else {
        setState(() {
          _errorMessage = 'Échec de l\'inscription';
        });
      }
    } catch (e) {
      setState(() {
        final errorString = e.toString().toLowerCase();
        if (errorString.contains('email already in use') || 
            errorString.contains('unique constraint')) {
          _errorMessage = 'Cet email ou ce pseudo est déjà utilisé';
        } else if (errorString.contains('weak password')) {
          _errorMessage = 'Le mot de passe est trop faible';
        } else {
          _errorMessage = 'Erreur d\'inscription: ${e.toString()}';
        }
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Créer un compte'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/welcome'),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Rejoignez AKOS',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Créez un compte pour trouver des partenaires sportifs',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // Affichage des erreurs
                if (_errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Champ email
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    prefixIcon: const Icon(Icons.email),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer votre email';
                    }
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                        .hasMatch(value)) {
                      return 'Veuillez entrer un email valide';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Champ pseudo
                TextFormField(
                  controller: _pseudoController,
                  decoration: InputDecoration(
                    labelText: 'Pseudo',
                    prefixIcon: const Icon(Icons.person),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer un pseudo';
                    }
                    if (value.length < 3) {
                      return 'Le pseudo doit contenir au moins 3 caractères';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Champ prénom (optionnel)
                TextFormField(
                  controller: _firstNameController,
                  decoration: InputDecoration(
                    labelText: 'Prénom (optionnel)',
                    prefixIcon: const Icon(Icons.badge),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),

                // Champ date de naissance
                InkWell(
                  onTap: () => _selectDate(context),
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Date de naissance',
                      prefixIcon: const Icon(Icons.calendar_today),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          DateFormat('dd/MM/yyyy').format(_selectedDate),
                          style: const TextStyle(fontSize: 16),
                        ),
                        const Icon(Icons.arrow_drop_down),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Champs genre
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(left: 8.0, bottom: 8.0),
                      child: Text(
                        'Genre',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                    ),
                    Row(
                      children: [
                        const SizedBox(width: 10), // Espace à gauche
                        ...List.generate(_genderOptions.length, (index) {
                          final gender = _genderOptions[index];
                          return Expanded(
                            child: Padding(
                              // Ajouter un padding horizontal pour rapprocher les rectangles
                              padding: EdgeInsets.symmetric(
                                horizontal: index == 3 ? 0 : 5, // Pas de padding à gauche pour le premier
                              ),
                              child: InkWell(
                                onTap: () {
                                  setState(() {
                                    _selectedGender = gender;
                                    _genderError = null;
                                  });
                                  debugPrint('Genre sélectionné: $_selectedGender');
                                },
                                child: Container(
                                  // Augmenter le padding pour agrandir les rectangles
                                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                                  decoration: BoxDecoration(
                                    color: _selectedGender == gender 
                                        ? Theme.of(context).primaryColor.withOpacity(0.1)
                                        : const Color.fromARGB(0, 197, 142, 142),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: _selectedGender == gender 
                                          ? Theme.of(context).primaryColor
                                          : _genderError != null 
                                              ? Color.fromARGB(255, 180, 41, 32)
                                              : Colors.black,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      _selectedGender == gender
                                          ? Icon(Icons.check_circle, 
                                              color: Theme.of(context).primaryColor, 
                                              size: 18)
                                          : Icon(Icons.circle_outlined, 
                                              color: _genderError != null ? Color.fromARGB(255, 180, 41, 32) : const Color.fromARGB(255, 0, 0, 0), 
                                              size: 16),
                                      const SizedBox(width: 8),
                                      Text(
                                        gender,
                                        style: TextStyle(
                                          fontSize: 16, // Changer la taille du texte ici
                                          color: _selectedGender == gender 
                                              ? Colors.grey.shade700  // Couleur du texte si sélection
                                              : _genderError != null ? Color.fromARGB(255, 180, 41, 32) : Colors.black,
                                          fontWeight: _selectedGender == gender 
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                        const SizedBox(width: 10), // Espace à droite
                      ],
                    ),
                    // Afficher le message d'erreur si nécessaire
                    if (_genderError != null)
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0, top: 4.0),
                        child: Text(
                          _genderError!,
                          style: TextStyle(color: Color.fromARGB(255, 180, 41, 32), fontSize: 12),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),

                // Champ mot de passe
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Mot de passe',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer un mot de passe';
                    }
                    if (value.length < 6) {
                      return 'Le mot de passe doit contenir au moins 6 caractères';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Champ confirmation mot de passe
                TextFormField(
                  controller: _confirmPasswordController,
                  decoration: InputDecoration(
                    labelText: 'Confirmer le mot de passe',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                  obscureText: _obscureConfirmPassword,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _signUp(),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez confirmer votre mot de passe';
                    }
                    if (value != _passwordController.text) {
                      return 'Les mots de passe ne correspondent pas';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),

                // Bouton d'inscription
                ElevatedButton(
                  onPressed: _isLoading ? null : _signUp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    disabledBackgroundColor:
                        Theme.of(context).primaryColor.withOpacity(0.5),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'S\'inscrire',
                          style: TextStyle(fontSize: 16),
                        ),
                ),

                const SizedBox(height: 24),

                // Option de connexion
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Déjà inscrit ?'),
                    TextButton(
                      onPressed: () => context.go('/login'),
                      child: const Text('Se connecter'),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Conditions d'utilisation
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    'En vous inscrivant, vous acceptez nos conditions d\'utilisation et notre politique de confidentialité.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

