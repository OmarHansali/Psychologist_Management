# Psychologist Management API

API REST Flask pour la gestion des psychologues, patients, rendez-vous, messagerie, etc.  
Toutes les routes nécessitant une authentification utilisent un JWT (`Authorization: Bearer <token>`).

---

## Authentification

### `POST /api/auth/login`
**Body :**
```json
{
  "email": "admin@example.com",
  "password": "admin123",
  "role": "admin"
}
```
**Réponse :**
```json
{
  "access_token": "jwt_token",
  "user": {
    "id": 1,
    "email": "admin@example.com",
    "role": "admin",
    "name": "Admin"
  }
}
```

---

### `POST /api/auth/forgot-password`
**Body :**
```json
{ "email": "user@example.com" }
```
**Réponse :**
```json
{ "message": "Code envoyé par email" }
```

---

### `POST /api/auth/verify-reset-code`
**Body :**
```json
{ "email": "user@example.com", "code": "123456" }
```
**Réponse :**
```json
{ "message": "Code vérifié" }
```

---

### `POST /api/auth/reset-password`
**Body :**
```json
{ "email": "user@example.com", "code": "123456", "new_password": "newpass" }
```
**Réponse :**
```json
{ "message": "Mot de passe réinitialisé" }
```

---

## Administration

### `GET /api/admin/users`
**Réponse :**
```json
{ "users": [ { "id": 1, "email": "...", "role": "...", ... }, ... ] }
```

---

## Patient

### `GET /api/patient/psychologist`
**Réponse (200) :**
```json
{ "psychologist": { "id": 2, "name": "...", "email": "..." } }
```
**Réponse (404) :**
```json
{ "error": "Aucun psychologue assigné" }
```

---

### `POST /api/patient/psychologist`
**Body :**
```json
{ "psychologist_id": 2 }
```
**Réponse :**
```json
{ "message": "Psychologue assigné", "psychologist": { "id": 2, "name": "...", "email": "..." } }
```

---

### `DELETE /api/patient/psychologist`
**Réponse :**
```json
{ "message": "Assignement au psychologue annulé" }
```

---

### `GET /api/patient/psychologists`
**Réponse :**
```json
{ "psychologists": [ { "id": 2, "name": "...", "email": "..." }, ... ] }
```
**Recherche :** `/api/patient/psychologists?q=nom`

---

## Psychologue

### `GET /api/psychologist/patients`
**Réponse :**
```json
{ "patients": [ { "id": 3, "name": "...", "email": "..." }, ... ] }
```

---

### `POST /api/psychologist/patients`
**Body :**
```json
{ "id": 3 }
```
**Réponse :**
```json
{ "message": "Patient ajouté", "patient": { "id": 3, "name": "...", "email": "..." } }
```

---

## Rendez-vous

### `GET /api/appointments`
**Réponse :**
```json
{ "appointments": [ { "id": 1, "datetime": "...", "duration": 60, ... }, ... ] }
```

---

### `POST /api/appointments`
**Body :**
```json
{
  "datetime": "2025-06-01T10:00:00",
  "duration": 60,
  "notes": "Consultation",
  "psychologist_id": 2
}
```
**Réponse :**
```json
{ "message": "Rendez-vous ajouté", "appointment": { ... } }
```

---

### `PUT /api/appointments/<id>`
**Body :**
```json
{
  "datetime": "2025-06-01T11:00:00",
  "duration": 45,
  "notes": "Mise à jour"
}
```
**Réponse :**
```json
{ "message": "Rendez-vous modifié", "appointment": { ... } }
```

---

### `DELETE /api/appointments/<id>`
**Réponse :**
```json
{ "message": "Rendez-vous annulé" }
```

---

## Messagerie (Chat)

### `GET /api/chat/conversations`
**Réponse :**
```json
{ "conversations": [ { "id": 1, "patient_name": "...", "psychologist_name": "...", "last_message": {...}, "unread_count": 2 }, ... ] }
```

---

### `POST /api/chat/conversations`
**Body :**
```json
{ "psychologist_id": 2 }
```
**Réponse :**
```json
{ "message": "Conversation créée", "conversation": { ... } }
```

---

### `GET /api/chat/messages/<conversation_id>`
**Réponse :**
```json
{ "messages": [ { "id": 1, "sender_id": 3, "content": "...", "sent_at": "...", "read": true }, ... ] }
```

---

### `POST /api/chat/messages`
**Body :**
```json
{ "conversation_id": 1, "content": "Bonjour" }
```
**Réponse :**
```json
{ "message": "Message envoyé", "message_obj": { ... } }
```

---

### `POST /api/chat/messages/<conversation_id>/seen`
**Réponse :**
```json
{ "updated": 3 }
```

---

## Notes

- Toutes les routes nécessitent un JWT valide dans le header `Authorization`.
- Les erreurs sont retournées sous la forme `{ "error": "..." }`.
- Les champs obligatoires sont indiqués dans les exemples de body.

---

## Exemple d’authentification avec Postman

1. Authentifiez-vous avec `/api/auth/login` pour obtenir un `access_token`.
2. Ajoutez ce token dans le header `Authorization: Bearer <token>` pour toutes les autres requêtes.

---

## Licence

Projet académique - usage pédagogique.