# ===== blueprints/psychologist.py =====
from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt
from utils.database import db
from models import User, Assignments

psychologist_bp = Blueprint('psychologist', __name__)

def psychologist_required():
    claims = get_jwt()
    if claims.get('role') != 'psychologist':
        return jsonify({'error': 'Accès psychologue requis'}), 403

@psychologist_bp.route('/patients', methods=['GET'])
@jwt_required()
def get_patients():
    psychologist_check = psychologist_required()
    if psychologist_check:
        return psychologist_check

    try:
        claims = get_jwt()
        psychologist_id = claims.get('user_id')

        # Utiliser la table Assignment pour récupérer les patients assignés
        assignments = Assignments.query.filter_by(psychologist_id=psychologist_id).all()
        patients_list = []
        for assignment in assignments:
            patient = User.query.get(assignment.patient_id)
            if patient:
                patients_list.append({
                    'id': patient.id,
                    'name': patient.name,
                    'email': patient.email,
                    # Ajoute d'autres champs si besoin
                })

        return jsonify({'patients': patients_list})

    except Exception as e:
        return jsonify({'error': str(e)}), 500
    
@psychologist_bp.route('/patients', methods=['POST'])
@jwt_required()
def add_patient():
    psychologist_check = psychologist_required()
    if psychologist_check:
        return psychologist_check

    try:
        claims = get_jwt()
        psychologist_id = claims.get('user_id')
        data = request.get_json()
        patient_id = data.get('id')
        name = data.get('name')
        email = data.get('email')

        # Recherche du patient par id OU par email
        if patient_id:
            patient = User.query.filter_by(id=patient_id, role='patient').first()
        elif email:
            patient = User.query.filter_by(email=email, role='patient').first()
        else:
            return jsonify({'error': 'Email ou ID du patient requis'}), 400

        if not patient:
            return jsonify({'error': "Patient n'existe pas"}), 400

        # Vérifie si déjà assigné
        from models import Assignments
        assignment = Assignments.query.filter_by(psychologist_id=psychologist_id, patient_id=patient.id).first()
        if not assignment:
            assignment = Assignments(psychologist_id=psychologist_id, patient_id=patient.id)
            db.session.add(assignment)
            db.session.commit()

        return jsonify({'message': 'Patient ajouté', 'patient': {'id': patient.id, 'name': patient.name, 'email': patient.email}})
    except Exception as e:
        return jsonify({'error': str(e)}), 500
    
@psychologist_bp.route('/patient/<int:patient_id>', methods=['DELETE'])
@jwt_required()
def delete_assigned_patient(patient_id):
    psychologist_check = psychologist_required()
    if psychologist_check:
        return psychologist_check

    try:
        claims = get_jwt()
        psychologist_id = claims.get('user_id')

        # Vérifier que ce patient est bien assigné à ce psychologue
        assignment = Assignments.query.filter_by(psychologist_id=psychologist_id, patient_id=patient_id).first()
        if not assignment:
            return jsonify({'error': 'Ce patient n\'est pas assigné à ce psychologue'}), 404

        db.session.delete(assignment)
        db.session.commit()
        return jsonify({'message': 'Patient supprimé de la liste du psychologue.'})
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@psychologist_bp.route('/patient/<int:patient_id>', methods=['GET'])
@jwt_required()
def get_patient_details(patient_id):
    psychologist_check = psychologist_required()
    if psychologist_check:
        return psychologist_check

    try:
        claims = get_jwt()
        psychologist_id = claims.get('user_id')

        # Vérifier que ce patient est bien assigné à ce psychologue
        assignment = Assignments.query.filter_by(psychologist_id=psychologist_id, patient_id=patient_id).first()
        if not assignment:
            return jsonify({'error': 'Accès non autorisé à ce patient'}), 403

        patient = User.query.get(patient_id)
        if not patient:
            return jsonify({'error': 'Patient non trouvé'}), 404

        return jsonify({
            'patient': {
                'id': patient.id,
                'name': patient.name,
                'email': patient.email,
                # Ajoute d'autres champs si besoin
            }
        })

    except Exception as e:
        return jsonify({'error': str(e)}), 500
    
@psychologist_bp.route('/search-patients', methods=['GET'])
@jwt_required()
def search_patients():
    psychologist_check = psychologist_required()
    if psychologist_check:
        return psychologist_check

    try:
        claims = get_jwt()
        psychologist_id = claims.get('user_id')
        query = request.args.get('q', '').strip()

        assigned_ids = [a.patient_id for a in Assignments.query.filter_by(psychologist_id=psychologist_id).all()]
        q = User.query.filter(
            User.role == 'patient',
            ~User.id.in_(assigned_ids)
        )
        if query:
            q = q.filter((User.name.ilike(f'%{query}%')) | (User.email.ilike(f'%{query}%')))
        patients = q.all()

        return jsonify({'patients': [
            {'id': p.id, 'name': p.name, 'email': p.email} for p in patients
        ]})
    except Exception as e:
        return jsonify({'error': str(e)}), 500