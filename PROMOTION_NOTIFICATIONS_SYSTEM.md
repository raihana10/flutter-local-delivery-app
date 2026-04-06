# 📱 Système de Notifications de Promotions - Documentation

## 📋 Aperçu Général

Quand un business (commerçant) ajoute une **nouvelle promotion** sur un de ses produits, le système notifie **uniquement les clients qui ont ce business en favoris**.

### Architecture en 3 étapes :
```
① Business crée promotion
         ↓
② Backend récupère clients en favoris
         ↓
③ Notifications in-app + Email
```

---

## 🏗️ Architecture Technique

### Tables Impliquées

| Table | Rôle | Jointure |
|-------|------|----------|
| `promotion` | Données de promotion (remise, dates) | ← `id_produit` |
| `produit` | Produit en promotion | ← `id_business` |
| `favoris` | Lien clients ↔ business | `id_client` + `id_business` |
| `client` | Profil client | → `id_user` |
| `app_user` | Email et infos utilisateur | `id_user` |
| `notification` | Notification créée | `id_not` |
| `user_notification` | Lien utilisateur → notification | `id_user` + `id_not` |

### Flux de Données

```
POST /business/{id}/promotions
  ↓
createPromotion() [business_controller.dart]
  ├─ 1️⃣ Insère promotion dans DB
  ├─ 2️⃣ Récupère nom produit + business
  ├─ 3️⃣ Récupère id_business du produit
  ├─ 4️⃣ Query: favoris WHERE id_business = {id_business}
  ├─ 5️⃣ Query: client WHERE id_client IN (resultat #4)
  ├─ 6️⃣ Crée notifications dans table notification
  ├─ 7️⃣ Crée liaisons user_notification
  ├─ 8️⃣ Récupère emails via app_user
  └─ 9️⃣ Envoie emails via EmailService
```

---

## 💻 Code Principal

### 1. **BusinessController::createPromotion()**
**Fichier:** `backend/lib/controllers/business_controller.dart`

```dart
// Étape 1: Créer la promotion
final result = await SupabaseConfig.client
    .from('promotion')
    .insert(data)
    .select('*')
    .single();

// Étape 2: Récupérer le id_business
final produitData = await SupabaseConfig.client
    .from('produit')
    .select('id_business')
    .eq('id_produit', result['id_produit'])
    .maybeSingle();
int businessId = produitData['id_business'];

// Étape 3: Récupérer les clients en favoris
final favorisClients = await SupabaseConfig.client
    .from('favoris')
    .select('id_client')
    .eq('id_business', businessId)
    .isFilter('deleted_at', null);

// Étape 4: Créer notifications
final clientUsers = await SupabaseConfig.client
    .from('client')
    .select('id_client, id_user')
    .inFilter('id_client', favorisClientIds);

for (var clientEntry in clientUsers) {
  await _createNotification(
    clientEntry['id_user'],
    titre,
    message,
    'promotion'
  );
}

// Étape 5: Envoyer emails
await _promotionService.sendPromotionEmail(
  businessName: businessName,
  productName: productName,
  discount: remise.toDouble(),
  clientEmails: clientEmails,
);
```

### 2. **PromotionService**
**Fichier:** `backend/lib/services/promotion_service.dart`

```dart
// Récupérer les emails des clients favoris
Future<List<String>> getClientsEmailsForBusiness(int businessId) async {
  // 1. Récupérer id_client depuis favoris
  // 2. Récupérer id_user depuis client
  // 3. Récupérer emails depuis app_user
  // 4. Retourner liste d'emails
}

// Envoyer l'email
Future<void> sendPromotionEmail({
  required String businessName,
  required String productName,
  required double discount,
  required List<String> clientEmails,
}) async {
  // Envoyer via EmailService (SMTP)
}
```

### 3. **EmailService** (Existant)
**Fichier:** `backend/lib/services/email_service.dart`

Utilise SMTP de Gmail avec les credentials du `.env` :
- `SMTP_HOST=smtp.gmail.com`
- `SMTP_PORT=587`
- `SMTP_USER=votre_email@gmail.com`
- `SMTP_PASS=votre_mot_de_passe_app`

---

## 📊 Exemple Concret

### Scénario

1. **Business "McDonald's" (id_business=2)** crée une promotion
   - Produit: "Big Mac" (id_produit=5)
   - Remise: 20%

2. **Clients en favoris** de McDonald's:
   - Client A (id_client=1) → id_user=10 → email=alice@gmail.com
   - Client B (id_client=3) → id_user=25 → email=bob@gmail.com
   - Client C (id_client=7) → id_user=45 → email=charlie@gmail.com

3. **Résultat**:
   - ✅ 3 notifications in-app créées
   - ✅ 3 emails envoyés
   - ❌ Les autres 97 clients ne reçoivent RIEN

### Requête SQL (Équivalent)

```sql
-- Récupérer les emails des clients favoris
SELECT DISTINCT au.email
FROM app_user au
JOIN client c ON au.id_user = c.id_user
JOIN favoris f ON c.id_client = f.id_client
WHERE f.id_business = 2
  AND f.deleted_at IS NULL;

-- Résultat:
-- alice@gmail.com
-- bob@gmail.com
-- charlie@gmail.com
```

---

## 🚀 Flow Complet Détaillé

### Message de Log

```
✅ PROMOTION CRÉÉE: ID=40
🏪 Business ID: 2
📢 NOTIFICATION PROMO: McDonald's propose -20% sur Big Mac
❤️ 3 clients avec ce business en favoris
✅ PROMOTION NOTIFIÉE À 3 CLIENTS EN FAVORIS
📧 Envoi des emails de promotion à 3 clients...
[EmailService] Envoyé → alice@gmail.com : 🎉 Nouvelle promotion chez McDonald's !
[EmailService] Envoyé → bob@gmail.com : 🎉 Nouvelle promotion chez McDonald's !
[EmailService] Envoyé → charlie@gmail.com : 🎉 Nouvelle promotion chez McDonald's !
📧 Emails de promotion envoyés à 3 clients
✅ Réponse API: promotion créée avec notifications
```

---

## 📈 Avantages du Système

### ✅ **Pertinence**
- Que reçoit les notifications les clients intéressés (en favoris)
- ❌ SPAM évité pour les autres clients

### ✅ **Engagement**
- Les clients qui ont mis le business en favoris sont les plus susceptibles de acheter
- Email + notification in-app = double touchpoint

### ✅ **Scalabilité**
- Si 1000 clients, 0 notification envoyée (car 0 favoris)
- Si 3 clients seulement, 3 notifications = efficace

### ✅ **Traçabilité**
- Chaque notification est enregistrée en DB
- Possibilité de voir qui a lu la notification (colonne `est_lu`)

---

## 🔧 Configuration Requise

### 1. Variables d'Environnement (.env)

```env
# SMTP Configuration
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=votre_email@gmail.com
SMTP_PASS=votre_mot_de_passe_app_google
EMAIL_FROM=votre_email@gmail.com
```

### 2. Créer un Mot de Passe App (Gmail)

1. Aller sur https://myaccount.google.com/security
2. Activer "Authentification à 2 facteurs"
3. Créer un "Mot de passe App" pour Gmail
4. Utiliser ce mot de passe dans `SMTP_PASS`

### 3. Structures de Données

⚠️ Vérifier que ces tables existent:
- ✅ `favoris` (id_client, id_business, deleted_at)
- ✅ `notification` (id_not, titre, message, type)
- ✅ `user_notification` (id_user, id_not, est_lu)

---

## 📱 Côté Client (Frontend)

### Option 1: Afficher les Notifications In-App
```dart
// Dans le frontend Flutter
StreamBuilder(
  stream: SupabaseConfig.client
    .from('user_notification')
    .stream(primaryKey: ['id_user_notification'])
    .where((data) => data['id_user'] == currentUser.id),
  builder: (context, snapshot) {
    if (snapshot.hasData) {
      // Afficher les notifications de promo
    }
  }
)
```

### Option 2: Afficher les Promotions du Business
```dart
// Récupérer les promotions d'un business favori
final promotions = await SupabaseConfig.client
  .from('promotion')
  .select('*, produit(nom_produit)')
  .eq('produit.id_business', favoriteBusinessId);
```

---

## 🧪 Test Manual du Système

### 1. Ajouter un Business en Favoris
```sql
INSERT INTO favoris (id_client, id_business)
VALUES (1, 2);
```

### 2. Créer une Promotion via l'API
```bash
POST /business/2/promotions HTTP/1.1
Content-Type: application/json

{
  "id_produit": 5,
  "pourcentage": 20,
  "date_debut": "2026-04-06T00:00:00Z",
  "date_fin": "2026-04-15T00:00:00Z"
}
```

### 3. Vérifier la Base de Données
```sql
-- Vérifier la notification créée
SELECT * FROM notification 
WHERE type = 'promotion' 
ORDER BY created_at DESC 
LIMIT 1;

-- Vérifier la liaison user_notification
SELECT * FROM user_notification 
WHERE id_not = <id_from_above> 
AND est_lu = FALSE;

-- Vérifier l'email envoyé (logs)
-- Chercher dans les logs du backend: "[EmailService] Envoyé →"
```

---

## ⚠️ Gestion d'Erreurs

### Cas 1: Aucun Client en Favoris
```
ℹ️ Aucun client en favoris pour ce business
→ Promotion créée BUT aucune notification envoyée
→ C'est normal ! ✅
```

### Cas 2: Erreur Gmail
```
❌ ERREUR NOTIFICATION PROMO: SMTP connection failed
→ Notifications in-app créées (✅)
→ Emails NON envoyés (❌)
→ Suggéré: vérifier SMTP_PASS, activer 2FA
```

### Cas 3: Base de Données Lente
```
⚠️ Impossible de récupérer le business
→ Promotion créée mais pas de notifications
→ Le client reste avec une promotion non annoncée
→ Solution: mettre en queue les notifications
```

---

## 🔄 Améliorations Futures

### Enhancement 1: Géolocalisation
```dart
// Notifier les clients PROCHES géographiquement
// + qui ont le business en favoris
```

### Enhancement 2: Préférences de Notification
```dart
// Ajouter colonne notifications_enabled dans client
// SELECT ... WHERE notifications_enabled = TRUE
```

### Enhancement 3: Smart Timing
```dart
// Envoyer notifications à l'heure la plus pertinente
// (ex: 18h le soir pour restaurants)
```

### Enhancement 4: Analytics
```dart
// Tracker: Combien ont cliqué sur la notification
// Combien ont commandé après notification
```

---

## 📞 Support & Dépannage

| Problème | Solution |
|----------|----------|
| Notifications pas reçues | Vérifier `favoris.deleted_at IS NULL` |
| Emails pas envoyés | Vérifier SMTP_PASS valide (mot de passe app) |
| "Aucun client en favoris" | C'est normal si business n'a pas de favoris |
| Erreur "id_business not found" | Vérifier que le produit existe dans le business |
| Pagination des emails lente | Peut augmenter si > 10k clients favoris |

---

## 📝 Résumé pour l'Équipe

✅ **Implémenté:**
- Notifications intelligentes (favoris seulement)
- Notifications in-app en temps réel
- Emails HTML formatés
- Logs détaillés pour débuggage

⏳ **À Faire (Future):**
- Push notifications (Firebase Cloud Messaging)
- SMS notifications
- A/B testing des emails
- Webhooks pour analytics externes

---

**Dernière mise à jour:** Avril 2026
**Version:** 1.0
**Statut:** ✅ Production-Ready
