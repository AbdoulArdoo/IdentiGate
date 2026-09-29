#!/bin/bash
# assign-roles.sh
# Assigne un rôle du realm à chaque utilisateur listé, via l'API REST de Keycloak.
# Usage : exporter un token admin valide dans KEYCLOAK_ACCESS_TOKEN puis lancer ./assign-roles.sh
# (le token s'obtient par ex. via la même requête client_credentials que provision-users.sh)

# --- CONFIG ---
KEYCLOAK_URL="http://localhost:8280"
REALM="IdentiGate"
ACCESS_TOKEN="${KEYCLOAK_ACCESS_TOKEN:-<YOUR_ACCESS_TOKEN>}"

# Définition des utilisateurs et rôles via 2 tableaux
USERS=("stagiaire1" "expert-cyber" "partenaire-x")
ROLES=("user" "admin" "partenaire")

# Nombre d'éléments
N=${#USERS[@]}

for (( i=0; i<N; i++ )); do
  username=${USERS[i]}
  role=${ROLES[i]}

  echo "🔎 Recherche de l'ID utilisateur : $username"
  USER_ID=$(curl -s -H "Authorization: Bearer $ACCESS_TOKEN" \
    "$KEYCLOAK_URL/admin/realms/$REALM/users?username=$username" | \
    grep -o '"id":"[^"]*' | cut -d':' -f2 | tr -d '"')

  if [ -z "$USER_ID" ]; then
    echo "❌ Utilisateur $username non trouvé !"
    continue
  fi

  echo "🔎 Recherche des infos du rôle : $role"
  ROLE_JSON=$(curl -s -H "Authorization: Bearer $ACCESS_TOKEN" \
    "$KEYCLOAK_URL/admin/realms/$REALM/roles/$role")

  echo "🖊️ Assignation du rôle $role à $username ($USER_ID)..."
  curl -s -X POST "$KEYCLOAK_URL/admin/realms/$REALM/users/$USER_ID/role-mappings/realm" \
    -H "Authorization: Bearer $ACCESS_TOKEN" \
    -H "Content-Type: application/json" \
    -d "[$ROLE_JSON]"

  echo "✅ Rôle $role assigné à $username"
done
