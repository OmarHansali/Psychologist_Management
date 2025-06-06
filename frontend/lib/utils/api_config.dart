class ApiConfig {
  // Pour l'émulateur Android Studio (localhost = 10.0.2.2)
  static const String emulatorBaseUrl = 'http://10.0.2.2:5000/api';


  static const String backendUrl = 'http://127.0.0.1:5000/api';

  // Pour un appareil physique (remplace par l'IP de ton PC)
  static const String deviceBaseUrl = 'http://192.168.1.37:5000/api';

  // Change ici selon où tu testes :
  static const String baseUrl = deviceBaseUrl; // ou deviceBaseUrl
}