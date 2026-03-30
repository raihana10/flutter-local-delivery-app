# Guide d'Installation Complet – Application de Livraison Locale

Ce document décrit en détail les pré-requis, les étapes de configuration et de déploiement de l'application (composée d'un frontend en Flutter, d'un backend en Dart, et d'une base de données Supabase) sur Android (APK), iOS, et Web.

---

## 1. Pré-requis Système Communs

Avant toute compilation, assurez-vous d'avoir installé les outils ci-dessous sur votre machine de développement :

1. **Flutter SDK** : [Installer Flutter](https://docs.flutter.dev/get-started/install). 
   - Vérifiez l'installation générale avec : `flutter doctor`
2. **Dart SDK** : Généralement inclus avec Flutter.
3. **Git** : Pour cloner et gérer le code source.
4. **Environnement de développement (IDE)** : VS Code, Cursor, ou Android Studio avec les extensions Flutter/Dart installées.
5. **Supabase** : Pour la base de données. Vous devez disposer d'un projet [Supabase Cloud](https://supabase.com/) en ligne ou d'une instance Docker locale.

---

## 2. Configuration du Backend et Base de Données

L'application repose sur le service Backend (dossier `backend`) et la base de données (définie par les scripts SQL).

### 2.1 Base de Données (Supabase)
1. Créez un projet Supabase.
2. Allez dans le **SQL Editor** de Dashboard Supabase.
3. Copiez le contenu du fichier `livraison_schema.sql` (situé à la racine) et exécutez-le pour créer toutes les tables, types ENUM, et triggers.
4. Exécutez le script `seeds.sql` pour insérer des données factices permettant de tester l'application.
5. Notez votre **URL Supabase** et la **clé publique d'API (anon key)** issues des paramètres du projet Supabase.

### 2.2 Serveur Backend (Dart)
1. Ouvrez un terminal dans le dossier `backend/`.
2. Installez les dépendances : `dart pub get`.
3. Configurez les clés d'environnement (si le backend dispose d'un `.env`).
4. Lancez le serveur localement pour vos tests : `dart run bin/server.dart` (nommer le fichier selon l'entrée principale).

---

## 3. Configuration du Frontend (Application Flutter)

Le code source de l'application client / livreur / admin se trouve dans le dossier `frontend`.

1. **Variables d'Environnement** :
   - Dans le répertoire `frontend/`, dupliquez le fichier `.env.example` en le nommant `.env`.
   - Modifiez ce fichier avec les URL et clés d'API de votre base de données Supabase, l'URL de votre backend, ou encore les clés Google Maps/Stripe :
     ```env
     SUPABASE_URL=https://<votre_projet>.supabase.co
     SUPABASE_ANON_KEY=<votre_cle_api>
     BACKEND_URL=http://localhost:8080 # Ou l'URL en production
     ```
2. **Téléchargement des dépendances** :
   - Depuis le terminal, lancez :
     ```bash
     cd frontend
     flutter clean
     flutter pub get
     ```

---

## 4. Compilation et Build : Web

Le build Web Flutter est le plus simple à lancer car il n'exige pas d'installation de lourds IDE spécifiques type Xcode ou Android Studio.

### Lancement en mode debug
```bash
flutter run -d chrome
```

### Build de Production
Le build va compiler et minifier le code JavaScript/HTML pour le web.
```bash
flutter build web --release
```
Le dossier généré se trouve dans `frontend/build/web/`. Ce dossier peut être hébergé sur des plateformes comme Vercel, Firebase Hosting, Netlify ou Supabase Hosting.

> [!WARNING]
> **Problèmes Courants (Web)**
> - **Erreurs CORS** : Si votre frontend tente d'appeler l'API de votre backend ou une API externe, et que le Web affiche des erreurs réseaux (XMLHttpRequest), vous devrez configurer le backend avec les entêtes CORS corrects (`Access-Control-Allow-Origin: *`).
> - **Bloqueur HTTPS** : En production, Flutter web exécute des requêtes cryptées (HTTPS). Assurez-vous que le backend de l'application prend correctement en charge les certificats sécurisés.

---

## 5. Compilation et Build : Android (APK)

### 5.1 Pré-requis Android
- Avoir installé **Android Studio**.
- Installer le **SDK Android** (SDK Platform 33/34 sont recommandés) ainsi que les `Command-line tools`.
- Accepter les licences SDK (`flutter doctor --android-licenses`).

### 5.2 Lancement sur simulateur ou smartphone testé
1. Vérifier les émulateurs / appareils connectés : `flutter devices`
2. Démarrez l'application : `flutter run -d <id_appareil>`

### 5.3 Générer un APK (Installateur) de Production
Ceci compile l'application, l'optimise, en fait une version Release. Idéal pour un test final sur périphérique physique sans passer par le Play Store.
```bash
flutter build apk --release
```
Le fichier d'installation APK se trouvera dans :
`frontend/build/app/outputs/flutter-apk/app-release.apk`
(Vous pouvez l'envoyer directement sur votre téléphone Android pour l'installer.)

> [!TIP]
> **Problèmes Courants (Android)**
> - **Incompatibilité Gradle/Java** : Vérifiez que la version de Java utilisée par votre système d'exploitation est compatible avec la version Gradle située dans `frontend/android/gradle/wrapper/gradle-wrapper.properties`. Le SDK Java 17 est souvent recommandé.
> - **Erreur de permission de la localisation / stockage** : Vérifiez que les autorisations dans `frontend/android/app/src/main/AndroidManifest.xml` (ex: `ACCESS_FINE_LOCATION`, `INTERNET`) sont correctement déclarées.
> - **Problème Not In GZIP format** : C'est une erreur due au téléchargement corrompu d'une image système Android Studio ou d'un paquet. La solution est de nettoyer le cache de Gradle et d'Android.

---

## 6. Compilation et Build : iOS

> [!CAUTION]
> Compiler pour le système iOS demande obligatoirement un ordinateur fonctionnant sous **macOS**. Cela ne peut pas se faire nativement sous Windows ou Linux.

### 6.1 Pré-requis iOS
- **macOS** mis à jour.
- **Xcode** installé depuis l'App Store Mac.
- **CocoaPods** installé : `sudo gem install cocoapods` ou via Homebrew `brew install cocoapods`.

### 6.2 Installation Spécifique à iOS
Depuis le dossier `frontend` :
```bash
cd ios
pod install
pod repo update
cd ..
```

### 6.3 Lancement en mode debug
Démarrez le simulateur iOS (`open -a Simulator`), puis :
```bash
flutter run -d simulator
```

### 6.4 Générer une version Release (Archive / TestFlight)
Cette manipulation doit souvent passer par Xcode :
1. Lancez `open ios/Runner.xcworkspace`.
2. Allez dans *Signing & Capabilities*, entrez votre **Apple Developer Team**.
3. Définissez le **Bundle Identifier** correct.
4. Lancez via le terminal :
   ```bash
   flutter build ipa --release
   ```
5. Le fichier produit se trouve dans `frontend/build/ios/ipa`. Il peut être uploadé à l'App Store Connect via Xcode Organiser ou l'application *Transporter*.

> [!WARNING]
> **Problèmes Courants (iOS)**
> - **Erreur CocoaPods M1/M2 Process Architecture** : Les Mac équipés de processeurs Apple Silicon nécessitent parfois `arch -x86_64 pod install`.
> - **Code Signing / Provisioning Profile** : La compilation `.ipa` va échouer si vous n'avez pas associé un compte développeur Apple payant ou valide directement au workspace Xcode. 
> - **Info.plist manquant** : Les autorisations spécifiques à iOS (par ex: `NSLocationWhenInUseUsageDescription` pour l'emplacement du livreur) doivent valider un texte dans `/ios/Runner/Info.plist`. Si c'est manquant, Apple crashera l'app automatiquement au démarrage.
