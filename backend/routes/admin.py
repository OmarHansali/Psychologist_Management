# ===== blueprints/admin.py =====
from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity, get_jwt
from werkzeug.security import generate_password_hash
from utils.database import db
from datetime import datetime
from models import User

admin_bp = Blueprint('admin', __name__)

# Fonction pour vérifier si l'utilisateur est un administrateur
def admin_required():
    claims = get_jwt()
    if claims.get('role') != 'admin':
        return jsonify({'error': 'Accès administrateur requis'}), 403

admin_bp = Blueprint('admin', __name__)

@admin_bp.route('/users', methods=['GET'])
@jwt_required()
def get_users():
    admin_check = admin_required()
    if admin_check:
        return admin_check
    
    try:
        # # JQuery
        # users_list = []
        # for email, user in users_db.items():
        #     users_list.append({
        #         'id': user['id'],
        #         'email': user['email'],
        #         'role': user['role'],
        #         'name': user.get('name', ''),
        #         'created_at': user.get('created_at', '')
        #     })
        
        # return jsonify({'users': users_list})
        users = User.query.all()
        users_list = [{
            'id': user.id,
            'email': user.email,
            'role': user.role,
            'name': user.name,
            'created_at': user.created_at.isoformat() if user.created_at else ''
        } for user in users]
        return jsonify({'users': users_list})
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@admin_bp.route('/users', methods=['POST'])
@jwt_required()
def create_user():
    admin_check = admin_required()
    if admin_check:
        return admin_check
    
    try:
        data = request.get_json()
        email = data.get('email')
        password = data.get('password')
        role = data.get('role')
        name = data.get('name', '')
        
        if not email or not password or not role:
            return jsonify({'error': 'Email, mot de passe et rôle requis'}), 400
        
        if role not in ['psychologist', 'patient']:
            return jsonify({'error': 'Rôle invalide'}), 400
        
        # JQuery
        if User.query.filter_by(email=email).first():
            return jsonify({'error': 'Utilisateur existe déjà'}), 400

        new_user = User(
            email=email,
            password=generate_password_hash(password),
            role=role,
            name=name,
            created_at=datetime.now()
        )
        db.session.add(new_user)
        db.session.commit()
        
        
        return jsonify({
            'message': 'Utilisateur créé avec succès',
            'user': {
                'id': new_user.id,
                'email': new_user.email,
                'role': new_user.role,
                'name': new_user.name
            }
        })
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@admin_bp.route('/users/<int:user_id>', methods=['PUT'])
@jwt_required()
def update_user(user_id):
    admin_check = admin_required()
    if admin_check:
        return admin_check
    
    try:
        data = request.get_json()
        
        #JQuery
        user = User.query.get(user_id)
        if not user:
            return jsonify({'error': 'Utilisateur non trouvé'}), 404
        if 'name' in data:
            user.name = data['name']
        if 'password' in data:
            user.password = generate_password_hash(data['password'])
        db.session.commit()
        
        return jsonify({'message': 'Utilisateur mis à jour'})
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@admin_bp.route('/users/<int:user_id>', methods=['DELETE'])
@jwt_required()
def delete_user(user_id):
    admin_check = admin_required()
    if admin_check:
        return admin_check
    
    try:
        # Trouver et supprimer l'utilisateur
        user_email = None
        # #JQuery
        # for email, user in users_db.items():
        #     if user['id'] == user_id:
        #         user_email = email
        #         break
        
        # if not user_email:
        #     return jsonify({'error': 'Utilisateur non trouvé'}), 404
        
        # del users_db[user_email]user = User.query.get(user_id)
        user = User.query.get(user_id)
        if not user:
            return jsonify({'error': 'Utilisateur non trouvé'}), 404
        db.session.delete(user)
        db.session.commit()
        return jsonify({'message': 'Utilisateur supprimé'})
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500