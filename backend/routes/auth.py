# ===== blueprints/auth.py =====
from flask import Blueprint, request, jsonify
from flask_jwt_extended import create_access_token, jwt_required, get_jwt_identity
from werkzeug.security import check_password_hash, generate_password_hash
from flask_mail import Message
from utils.database import db
from utils.mail import mail
import random
import string
from datetime import datetime, timedelta
from models import User

auth_bp = Blueprint('auth', __name__)

# Simulation de modèles (à remplacer par les vrais modèles ORM)
reset_codes = {}

@auth_bp.route('/login', methods=['POST'])
def login():
    try:
        data = request.get_json()
        email = data.get('email')
        password = data.get('password')
        role = data.get('role')
        
        if not email or not password or not role:
            return jsonify({'error': 'Email, password et role requis'}), 400
        
        user = User.query.filter_by(email=email, role=role).first()
        if not user or not check_password_hash(user.password, password):
            return jsonify({'error': 'Identifiants invalides'}), 401
        
        # Création du token JWT
        access_token = create_access_token(
            identity=email,
            additional_claims={'role': role, 'user_id': user.id}
        )
        
        return jsonify({
            'access_token': access_token,
            'user': {
                'id': user.id,
                'email': user.email,
                'role': user.role,
                'name': user.name or ""
            }
        })
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@auth_bp.route('/forgot-password', methods=['POST'])
def forgot_password():
    try:
        data = request.get_json()
        email = data.get('email')
        
        if not email:
            return jsonify({'error': 'Email requis'}), 400
        
        # Vérifier si l'utilisateur existe
        user = User.query.filter_by(email=email).first()
        if not user:
            return jsonify({'error': 'Utilisateur non trouvé'}), 404
        
        # Générer code de vérification
        code = ''.join(random.choices(string.digits, k=6))
        expires = datetime.now() + timedelta(minutes=15)
        reset_codes[email] = {
            'code': code,
            'expires': datetime.now() + timedelta(minutes=15)
        }
        # Envoyer email (simulation)
        msg = Message(
            'Code de réinitialisation de mot de passe',
            sender=('Psycho App', 'noreply@psychoapp.com'),
            recipients=[email]
        )
        msg.body = f'Votre code de vérification est: {code}'
        
        try:
            mail.send(msg)
            return jsonify({'message': 'Code envoyé par email' + code})
        except:
            return jsonify({'message': 'Code généré (simulation): ' + code})
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@auth_bp.route('/verify-reset-code', methods=['POST'])
def verify_reset_code():
    try:
        data = request.get_json()
        email = data.get('email')
        code = data.get('code')
        
        if not email or not code:
            return jsonify({'error': 'Email et code requis'}), 400
        
        reset_data = reset_codes.get(email)
        if not reset_data or reset_data['code'] != code:
            return jsonify({'error': 'Code invalide'}), 400
        
        if datetime.now() > reset_data['expires']:
            return jsonify({'error': 'Code expiré'}), 400
        
        return jsonify({'message': 'Code valide'})
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@auth_bp.route('/reset-password', methods=['POST'])
def reset_password():
    try:
        data = request.get_json()
        email = data.get('email')
        code = data.get('code')
        new_password = data.get('new_password')
        
        if not email or not code or not new_password:
            return jsonify({'error': 'Email, code et nouveau mot de passe requis'}), 400
        
        reset_data = reset_codes.get(email)
        if not reset_data or reset_data['code'] != code:
            return jsonify({'error': 'Code invalide'}), 400
        
        if datetime.now() > reset_data['expires']:
            return jsonify({'error': 'Code expiré'}), 400
        
        # Mettre à jour le mot de passe
        user = User.query.filter_by(email=email).first()
        if user:
            user.password = generate_password_hash(new_password)
            del reset_codes[email]
            db.session.commit()
            return jsonify({'message': 'Mot de passe mis à jour'})
        
        return jsonify({'error': 'Utilisateur non trouvé'}), 404
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500