-- ============================================================
--  SEEDS – Application de Livraison
--  Données de test pour toutes les fonctionnalités
--  Exécuter dans Supabase SQL Editor (Table: "user" = app_user)
-- ============================================================

-- NOTE: Dans Supabase, la table s'appelle "user" (pas "app_user")
-- Adaptez le nom de table selon votre instance Supabase.

-- ============================================================
-- 1. ADMIN
-- ============================================================
INSERT INTO admin (email, password) VALUES
  ('admin@livrapp.ma', 'admin123');

-- ============================================================
-- 2. USERS (app_user) — Mot de passe: test1234
--    ⚠️  Les mots de passe doivent être hashés en prod.
--       Pour les tests Supabase Auth, créez d'abord les users
--       via Auth puis les insérer ici avec le bon UUID.
-- ============================================================

-- Clients
INSERT INTO "app_user" (email, password, nom, num_tl, role) VALUES
  ('client1@test.ma', 'test1234', 'Youssef Alami',    '0661001001', 'client'),
  ('client2@test.ma', 'test1234', 'Sara Benali',      '0662002002', 'client'),
  ('client3@test.ma', 'test1234', 'Karim Tazi',       '0663003003', 'client');

-- Livreurs
INSERT INTO "app_user" (email, password, nom, num_tl, role) VALUES
  ('livreur1@test.ma', 'test1234', 'Hassan Moussaoui', '0664004004', 'livreur'),
  ('livreur2@test.ma', 'test1234', 'Amine Rifi',       '0665005005', 'livreur');

-- Business Owners
INSERT INTO "app_user" (email, password, nom, num_tl, role) VALUES
  ('pizza@test.ma',    'test1234', 'Pizza Palace',   '0666006006', 'business'),
  ('pharma@test.ma',   'test1234', 'Pharmacie Centrale', '0667007007', 'business'),
  ('market@test.ma',   'test1234', 'Supermarché Atlas',  '0668008008', 'business');

-- ============================================================
-- 3. CLIENT profiles
-- ============================================================
INSERT INTO client (id_user, sexe, date_naissance) VALUES
  ((SELECT id_user FROM "app_user" WHERE email='client1@test.ma'), 'homme', '1995-03-15'),
  ((SELECT id_user FROM "app_user" WHERE email='client2@test.ma'), 'femme', '1998-07-22'),
  ((SELECT id_user FROM "app_user" WHERE email='client3@test.ma'), 'homme', '1990-11-05');

-- ============================================================
-- 4. LIVREUR profiles
-- ============================================================
INSERT INTO livreur (id_user, sexe, date_naissance, cni, est_actif) VALUES
  ((SELECT id_user FROM "app_user" WHERE email='livreur1@test.ma'), 'homme', '1993-01-20', 'AA123456', TRUE),
  ((SELECT id_user FROM "app_user" WHERE email='livreur2@test.ma'), 'homme', '1997-05-10', 'BB654321', TRUE);

-- ============================================================
-- 5. BUSINESS profiles
-- ============================================================
INSERT INTO business (id_user, type_business, description, opening_hours, temps_preparation, is_open, est_actif) VALUES
  (
    (SELECT id_user FROM "app_user" WHERE email='pizza@test.ma'),
    'restaurant',
    'Les meilleures pizzas artisanales de Tétouan. Pâtes fraîches, ingrédients locaux.',
    '{"lun":"11:00-23:00","mar":"11:00-23:00","mer":"11:00-23:00","jeu":"11:00-23:00","ven":"12:00-00:00","sam":"12:00-00:00","dim":"12:00-22:00"}',
    25, TRUE, TRUE
  ),
  (
    (SELECT id_user FROM "app_user" WHERE email='pharma@test.ma'),
    'pharmacie',
    'Pharmacie de garde ouverte 7j/7. Médicaments, parapharmacie et conseils santé.',
    '{"lun":"08:00-22:00","mar":"08:00-22:00","mer":"08:00-22:00","jeu":"08:00-22:00","ven":"08:00-22:00","sam":"08:00-22:00","dim":"09:00-20:00"}',
    10, TRUE, TRUE
  ),
  (
    (SELECT id_user FROM "app_user" WHERE email='market@test.ma'),
    'super-marche',
    'Supermarché de quartier avec fruits, légumes frais et épicerie fine.',
    '{"lun":"08:00-21:00","mar":"08:00-21:00","mer":"08:00-21:00","jeu":"08:00-21:00","ven":"08:00-21:00","sam":"09:00-21:00","dim":"09:00-18:00"}',
    15, TRUE, TRUE
  );

-- ============================================================
-- 6. PRODUITS — Restaurant (Pizza Palace)
-- ============================================================
INSERT INTO produit (id_business, nom_produit, description, type_produit, prix_unitaire) VALUES
  (
    (SELECT id_business FROM business WHERE id_user=(SELECT id_user FROM "app_user" WHERE email='pizza@test.ma')),
    'Pizza Margherita',
    'Sauce tomate, mozzarella fraîche, basilic',
    'meal', 55.00
  ),
  (
    (SELECT id_business FROM business WHERE id_user=(SELECT id_user FROM "app_user" WHERE email='pizza@test.ma')),
    'Pizza 4 Fromages',
    'Mozzarella, emmental, chèvre, parmesan',
    'meal', 75.00
  ),
  (
    (SELECT id_business FROM business WHERE id_user=(SELECT id_user FROM "app_user" WHERE email='pizza@test.ma')),
    'Pizza Chawarma',
    'Poulet chawarma, légumes grillés, sauce blanche',
    'meal', 80.00
  ),
  (
    (SELECT id_business FROM business WHERE id_user=(SELECT id_user FROM "app_user" WHERE email='pizza@test.ma')),
    'Burger Classic',
    'Bœuf haché 150g, cheddar, salade, tomate',
    'meal', 50.00
  ),
  (
    (SELECT id_business FROM business WHERE id_user=(SELECT id_user FROM "app_user" WHERE email='pizza@test.ma')),
    'Coca-Cola 33cl',
    'Boisson gazeuse bien froide',
    'meal', 12.00
  ),
  (
    (SELECT id_business FROM business WHERE id_user=(SELECT id_user FROM "app_user" WHERE email='pizza@test.ma')),
    'Tiramisu maison',
    'Dessert italien classique à base de mascarpone',
    'meal', 30.00
  );

-- ============================================================
-- 7. PRODUITS — Pharmacie
-- ============================================================
INSERT INTO produit (id_business, nom_produit, description, type_produit, prix_unitaire) VALUES
  (
    (SELECT id_business FROM business WHERE id_user=(SELECT id_user FROM "app_user" WHERE email='pharma@test.ma')),
    'Paracétamol 500mg',
    'Boîte de 16 comprimés. Antidouleur et antipyrétique.',
    'pharmacy', 8.50
  ),
  (
    (SELECT id_business FROM business WHERE id_user=(SELECT id_user FROM "app_user" WHERE email='pharma@test.ma')),
    'Doliprane 1000mg',
    'Boîte de 8 comprimés effervescents.',
    'pharmacy', 15.00
  ),
  (
    (SELECT id_business FROM business WHERE id_user=(SELECT id_user FROM "app_user" WHERE email='pharma@test.ma')),
    'Spray nasal décongestionnant',
    'Soulage la congestion nasale en 2 minutes.',
    'pharmacy', 35.00
  ),
  (
    (SELECT id_business FROM business WHERE id_user=(SELECT id_user FROM "app_user" WHERE email='pharma@test.ma')),
    'Vitamines C 1000mg',
    'Boîte de 30 comprimés effervescents à l''orange.',
    'pharmacy', 45.00
  ),
  (
    (SELECT id_business FROM business WHERE id_user=(SELECT id_user FROM "app_user" WHERE email='pharma@test.ma')),
    'Crème hydratante SPF 50',
    'Protection solaire haute gamme, convient aux peaux sensibles.',
    'pharmacy', 120.00
  );

-- ============================================================
-- 8. PRODUITS — Supermarché Atlas
-- ============================================================
INSERT INTO produit (id_business, nom_produit, description, type_produit, prix_unitaire) VALUES
  (
    (SELECT id_business FROM business WHERE id_user=(SELECT id_user FROM "app_user" WHERE email='market@test.ma')),
    'Lait demi-écrémé 1L',
    'Lait pasteurisé demi-écrémé, marque Centrale Laitière.',
    'grocery', 7.00
  ),
  (
    (SELECT id_business FROM business WHERE id_user=(SELECT id_user FROM "app_user" WHERE email='market@test.ma')),
    'Yaourt nature x4',
    'Pack de 4 yaourts nature brassés, 125g chacun.',
    'grocery', 12.00
  ),
  (
    (SELECT id_business FROM business WHERE id_user=(SELECT id_user FROM "app_user" WHERE email='market@test.ma')),
    'Tomates 1kg',
    'Tomates fraîches locales, calibre moyen.',
    'grocery', 6.00
  ),
  (
    (SELECT id_business FROM business WHERE id_user=(SELECT id_user FROM "app_user" WHERE email='market@test.ma')),
    'Pommes de terre 2kg',
    'Pommes de terre de Meknès, idéales pour la cuisson.',
    'grocery', 14.00
  ),
  (
    (SELECT id_business FROM business WHERE id_user=(SELECT id_user FROM "app_user" WHERE email='market@test.ma')),
    'Huile d''olive vierge 75cl',
    'Huile d''olive extra vierge pressée à froid.',
    'grocery', 65.00
  ),
  (
    (SELECT id_business FROM business WHERE id_user=(SELECT id_user FROM "app_user" WHERE email='market@test.ma')),
    'Pain de mie complet',
    'Miche de pain de mie au blé complet, 500g.',
    'grocery', 18.00
  );

-- ============================================================
-- 9. PROMOTIONS (sur quelques produits)
-- ============================================================
INSERT INTO promotion (id_produit, pourcentage, date_debut, date_fin) VALUES
  (
    (SELECT id_produit FROM produit WHERE nom_produit='Pizza Margherita'),
    20.00,
    NOW(), NOW() + INTERVAL '30 days'
  ),
  (
    (SELECT id_produit FROM produit WHERE nom_produit='Doliprane 1000mg'),
    10.00,
    NOW(), NOW() + INTERVAL '15 days'
  ),
  (
    (SELECT id_produit FROM produit WHERE nom_produit='Lait demi-écrémé 1L'),
    5.00,
    NOW(), NOW() + INTERVAL '7 days'
  );

-- ============================================================
-- 10. ADRESSES
-- ============================================================
INSERT INTO adresse (ville, latitude, longitude) VALUES
  ('Tétouan', 35.5725, -5.3681),
  ('Tétouan', 35.5800, -5.3750),
  ('Tétouan', 35.5650, -5.3600),
  ('Tanger',  35.7595, -5.8340);

-- Lier les adresses aux clients
INSERT INTO user_adresse (id_user, id_adresse, is_default) VALUES
  (
    (SELECT id_user FROM "app_user" WHERE email='client1@test.ma'),
    (SELECT id_adresse FROM adresse WHERE ville='Tétouan' AND latitude=35.5725),
    TRUE
  ),
  (
    (SELECT id_user FROM "app_user" WHERE email='client1@test.ma'),
    (SELECT id_adresse FROM adresse WHERE ville='Tanger'),
    FALSE
  ),
  (
    (SELECT id_user FROM "app_user" WHERE email='client2@test.ma'),
    (SELECT id_adresse FROM adresse WHERE latitude=35.5800),
    TRUE
  ),
  (
    (SELECT id_user FROM "app_user" WHERE email='client3@test.ma'),
    (SELECT id_adresse FROM adresse WHERE latitude=35.5650),
    TRUE
  );

-- ============================================================
-- 11. CARTES BANCAIRES
-- ============================================================
INSERT INTO carte_bancaire (id_client, numero_carte, date_expiration, nom_carte, is_default) VALUES
  (
    (SELECT id_client FROM client WHERE id_user=(SELECT id_user FROM "app_user" WHERE email='client1@test.ma')),
    '**** **** **** 4242', '12/27', 'YOUSSEF ALAMI', TRUE
  ),
  (
    (SELECT id_client FROM client WHERE id_user=(SELECT id_user FROM "app_user" WHERE email='client1@test.ma')),
    '**** **** **** 1234', '06/26', 'YOUSSEF ALAMI', FALSE
  ),
  (
    (SELECT id_client FROM client WHERE id_user=(SELECT id_user FROM "app_user" WHERE email='client2@test.ma')),
    '**** **** **** 5678', '09/28', 'SARA BENALI', TRUE
  );

-- ============================================================
-- 12. COMMANDES
-- ============================================================
-- Commande 1 : client1 au restaurant, statut "livree"
INSERT INTO commande (id_client, id_adresse, statut_commande, type_commande, prix_total, prix_donne) VALUES
  (
    (SELECT id_client FROM client WHERE id_user=(SELECT id_user FROM "app_user" WHERE email='client1@test.ma')),
    (SELECT id_adresse FROM adresse WHERE ville='Tétouan' AND latitude=35.5725),
    'livree', 'food_delivery', 130.00, 110.00
  );

-- Lignes de la commande 1
INSERT INTO ligne_commande (id_commande, id_produit, quantite, prix_snapshot, nom_snapshot) VALUES
  (
    (SELECT id_commande FROM commande ORDER BY id_commande DESC LIMIT 1),
    (SELECT id_produit FROM produit WHERE nom_produit='Pizza Margherita'),
    1, 55.00, 'Pizza Margherita'
  ),
  (
    (SELECT id_commande FROM commande ORDER BY id_commande DESC LIMIT 1),
    (SELECT id_produit FROM produit WHERE nom_produit='Pizza 4 Fromages'),
    1, 75.00, 'Pizza 4 Fromages'
  );

-- Timeline pour commande 1
INSERT INTO timeline (id_commande, id_livreur, statut_tmlne, estimated_at, remaining_time, remaining_distance) VALUES
  (
    (SELECT id_commande FROM commande ORDER BY id_commande DESC LIMIT 1),
    (SELECT id_livreur FROM livreur WHERE id_user=(SELECT id_user FROM "app_user" WHERE email='livreur1@test.ma')),
    'livree',
    NOW() - INTERVAL '1 hour',
    0, 0.0
  );

-- Commande 2 : client2 à la pharmacie, statut "en_livraison"
INSERT INTO commande (id_client, id_adresse, statut_commande, type_commande, prix_total, prix_donne) VALUES
  (
    (SELECT id_client FROM client WHERE id_user=(SELECT id_user FROM "app_user" WHERE email='client2@test.ma')),
    (SELECT id_adresse FROM adresse WHERE latitude=35.5800),
    'en_livraison', 'shopping', 43.50, 43.50
  );

INSERT INTO ligne_commande (id_commande, id_produit, quantite, prix_snapshot, nom_snapshot) VALUES
  (
    (SELECT id_commande FROM commande ORDER BY id_commande DESC LIMIT 1),
    (SELECT id_produit FROM produit WHERE nom_produit='Paracétamol 500mg'),
    2, 8.50, 'Paracétamol 500mg'
  ),
  (
    (SELECT id_commande FROM commande ORDER BY id_commande DESC LIMIT 1),
    (SELECT id_produit FROM produit WHERE nom_produit='Vitamines C 1000mg'),
    1, 45.00, 'Vitamines C 1000mg'
  );

INSERT INTO timeline (id_commande, id_livreur, statut_tmlne, estimated_at, remaining_time, remaining_distance) VALUES
  (
    (SELECT id_commande FROM commande ORDER BY id_commande DESC LIMIT 1),
    (SELECT id_livreur FROM livreur WHERE id_user=(SELECT id_user FROM "app_user" WHERE email='livreur2@test.ma')),
    'en_livraison',
    NOW() + INTERVAL '15 minutes',
    900, 2.5
  );

-- Commande 3 : client1 supermarché, statut "preparee"
INSERT INTO commande (id_client, id_adresse, statut_commande, type_commande, prix_total) VALUES
  (
    (SELECT id_client FROM client WHERE id_user=(SELECT id_user FROM "app_user" WHERE email='client1@test.ma')),
    (SELECT id_adresse FROM adresse WHERE ville='Tétouan' AND latitude=35.5725),
    'preparee', 'shopping', 102.00
  );

INSERT INTO ligne_commande (id_commande, id_produit, quantite, prix_snapshot, nom_snapshot) VALUES
  (
    (SELECT id_commande FROM commande ORDER BY id_commande DESC LIMIT 1),
    (SELECT id_produit FROM produit WHERE nom_produit='Lait demi-écrémé 1L'),
    3, 7.00, 'Lait demi-écrémé 1L'
  ),
  (
    (SELECT id_commande FROM commande ORDER BY id_commande DESC LIMIT 1),
    (SELECT id_produit FROM produit WHERE nom_produit='Huile d''olive vierge 75cl'),
    1, 65.00, 'Huile d''olive vierge 75cl'
  ),
  (
    (SELECT id_commande FROM commande ORDER BY id_commande DESC LIMIT 1),
    (SELECT id_produit FROM produit WHERE nom_produit='Pain de mie complet'),
    2, 18.00, 'Pain de mie complet'
  );

-- ============================================================
-- 13. AVIS (store_review)
-- ============================================================
INSERT INTO store_review (id_client, id_business, evaluation, commentaire) VALUES
  (
    (SELECT id_client FROM client WHERE id_user=(SELECT id_user FROM "app_user" WHERE email='client1@test.ma')),
    (SELECT id_business FROM business WHERE id_user=(SELECT id_user FROM "app_user" WHERE email='pizza@test.ma')),
    5, 'Excellente pizza ! Livraison rapide et bien chaude.'
  ),
  (
    (SELECT id_client FROM client WHERE id_user=(SELECT id_user FROM "app_user" WHERE email='client2@test.ma')),
    (SELECT id_business FROM business WHERE id_user=(SELECT id_user FROM "app_user" WHERE email='pharma@test.ma')),
    4, 'Service rapide et professionnel. Bon stock de médicaments.'
  ),
  (
    (SELECT id_client FROM client WHERE id_user=(SELECT id_user FROM "app_user" WHERE email='client3@test.ma')),
    (SELECT id_business FROM business WHERE id_user=(SELECT id_user FROM "app_user" WHERE email='market@test.ma')),
    4, 'Produits frais et de qualité. Je recommande !'
  );

-- ============================================================
-- 14. NOTIFICATIONS
-- ============================================================
INSERT INTO notification (titre, message, type) VALUES
  ('Commande confirmée ! 🎉', 'Votre commande #1 chez Pizza Palace a été confirmée. Préparation en cours...', 'order'),
  ('En route ! 🚴', 'Votre livreur Hassan est en route. Arrivée estimée : 15 minutes.', 'delivery'),
  ('Commande livrée ✅', 'Votre commande #1 a été livrée. Bon appétit !', 'order'),
  ('Nouvelle promo 🔥', 'Pizza Margherita à -20% ce week-end seulement !', 'promo'),
  ('Commande en préparation 🍕', 'Votre commande chez Pizza Palace est en cours de préparation.', 'order'),
  ('Rappel : Panier en attente 🛒', 'Vous avez des articles dans votre panier. Finalisez votre commande !', 'reminder');

-- Lier les notifications aux clients
INSERT INTO user_notification (id_user, id_not, est_lu, lu_at) VALUES
  (
    (SELECT id_user FROM "app_user" WHERE email='client1@test.ma'),
    (SELECT id_not FROM notification WHERE titre='Commande confirmée ! 🎉'),
    TRUE, NOW() - INTERVAL '2 hours'
  ),
  (
    (SELECT id_user FROM "app_user" WHERE email='client1@test.ma'),
    (SELECT id_not FROM notification WHERE titre='En route ! 🚴'),
    TRUE, NOW() - INTERVAL '1 hour 30 minutes'
  ),
  (
    (SELECT id_user FROM "app_user" WHERE email='client1@test.ma'),
    (SELECT id_not FROM notification WHERE titre='Commande livrée ✅'),
    FALSE, NULL
  ),
  (
    (SELECT id_user FROM "app_user" WHERE email='client1@test.ma'),
    (SELECT id_not FROM notification WHERE titre='Nouvelle promo 🔥'),
    FALSE, NULL
  ),
  (
    (SELECT id_user FROM "app_user" WHERE email='client2@test.ma'),
    (SELECT id_not FROM notification WHERE titre='Commande en préparation 🍕'),
    FALSE, NULL
  ),
  (
    (SELECT id_user FROM "app_user" WHERE email='client2@test.ma'),
    (SELECT id_not FROM notification WHERE titre='Rappel : Panier en attente 🛒'),
    FALSE, NULL
  );

-- ============================================================
-- 15. FAVORIS
-- ============================================================
INSERT INTO favoris (id_client, id_business) VALUES
  (
    (SELECT id_client FROM client WHERE id_user=(SELECT id_user FROM "app_user" WHERE email='client1@test.ma')),
    (SELECT id_business FROM business WHERE id_user=(SELECT id_user FROM "app_user" WHERE email='pizza@test.ma'))
  ),
  (
    (SELECT id_client FROM client WHERE id_user=(SELECT id_user FROM "app_user" WHERE email='client2@test.ma')),
    (SELECT id_business FROM business WHERE id_user=(SELECT id_user FROM "app_user" WHERE email='pharma@test.ma'))
  );

-- ============================================================
-- RÉSUMÉ DES COMPTES DE TEST
-- ============================================================
-- Client 1   : client1@test.ma  / test1234  (Youssef Alami)
-- Client 2   : client2@test.ma  / test1234  (Sara Benali)
-- Client 3   : client3@test.ma  / test1234  (Karim Tazi)
-- Livreur 1  : livreur1@test.ma / test1234  (Hassan Moussaoui)
-- Livreur 2  : livreur2@test.ma / test1234  (Amine Rifi)
-- Business 1 : pizza@test.ma    / test1234  (Pizza Palace – restaurant)
-- Business 2 : pharma@test.ma   / test1234  (Pharmacie Centrale)
-- Business 3 : market@test.ma   / test1234  (Supermarché Atlas)
-- Admin      : admin@livrapp.ma / admin123
