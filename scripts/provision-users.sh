#!/bin/bash
# provision-users.sh
# Crée automatiquement des utilisateurs dans un realm Keycloak via l'API REST.
# Usage : renseigner CLIENT_SECRET (variable d'environnement ou ci-dessous) puis lancer ./provision-users.sh

# --- CONFIGURATION ---
KEYCLOAK_URL="http://localhost:8280"
REALM="IdentiGate"
CLIENT_ID="admin-cli-api"
CLIENT_SECRET="${KEYCLOAK_CLIENT_SECRET:-<YOUR_CLIENT_SECRET>}"

# Liste des utilisateurs à créer (username;email;password;role)
USERS=(
  "stagiaire1;stagiaire1@example.com;stagiaire123;user"
  "expert-cyber;cyber@example.com;expert2024;admin"
  "partenaire-x;partner@example.com;partenaire123;partenaire"
)

# --- OBTENTION DU TOKEN ---
echo "🔑 Obtention du token..."

RESPONSE=$(curl -s -X POST "$KEYCLOAK_URL/realms/$REALM/protocol/openid-connect/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=client_credentials" \
  -d "client_id=$CLIENT_ID" \
  -d "client_secret=$CLIENT_SECRET")

echo "📨 Réponse token brute : $RESPONSE"

ACCESS_TOKEN=$(echo "$RESPONSE" | grep -o '"access_token":"[^"]*' | cut -d':' -f2 | tr -d '"')

if [[ -z "$ACCESS_TOKEN" || "$ACCESS_TOKEN" == "null" ]]; then
  echo "❌ Échec de l'obtention du token."
  exit 1
fi

echo "✅ Token récupéré avec succès !"

# --- PROVISIONNEMENT DES UTILISATEURS ---
for entry in "${USERS[@]}"; do
  IFS=";" read -r username email password role <<< "$entry"

  echo ""
  echo "➕ Création de l'utilisateur : $username"

  JSON_PAYLOAD=$(cat <<EOF
{
  "username": "$username",
  "email": "$email",
  "enabled": true,
  "credentials": [{
    "type": "password",
    "value": "$password",
    "temporary": false
  }]
}
EOF
)

  echo "📤 Requête envoyée :"
  echo "$JSON_PAYLOAD"

  RESPONSE=$(curl -s -w "\nHTTP_CODE:%{http_code}" -X POST "$KEYCLOAK_URL/admin/realms/$REALM/users" \
    -H "Authorization: Bearer $ACCESS_TOKEN" \
    -H "Content-Type: application/json" \
    -d "$JSON_PAYLOAD")

  # Extraire le code HTTP
  HTTP_CODE=$(echo "$RESPONSE" | grep HTTP_CODE | cut -d':' -f2)
  BODY=$(echo "$RESPONSE" | sed '/HTTP_CODE/d')

  if [[ "$HTTP_CODE" == "201" ]]; then
    echo "✅ Utilisateur $username créé avec succès !"
  else
    echo "❌ Erreur pour $username (HTTP $HTTP_CODE)"
    echo "📄 Détail de l'erreur : $BODY"
  fi
done
