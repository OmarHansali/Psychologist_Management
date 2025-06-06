# ===== blueprints/patient.py =====
from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt
from utils.database import db
from models import User

patient_bp = Blueprint('patient', __name__)

def patient_required():
    claims = get_jwt()
    if claims.get('role') != 'patient':
        return jsonify({'error': 'Accès patient requis'}), 403

@patient_bp.route('/profile', methods=['GET'])
@jwt_required()
def get_profile():
    patient_check = patient_required()
    if patient_check:
        return patient_check

    try:
        claims = get_jwt()
        patient_id = claims.get('user_id')

        patient = User.query.filter_by(id=patient_id, role='patient').first()
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

@patient_bp.route('/psychologist', methods=['GET'])
@jwt_required()
def get_assigned_psychologist():
    patient_check = patient_required()
    if patient_check:
        return patient_check

    try:
        claims = get_jwt()
        patient_id = claims.get('user_id')
        from models import Assignments, User

        # Cherche l'assignement actif pour ce patient
        assignment = Assignments.query.filter_by(patient_id=patient_id).order_by(Assignments.assigned_at.desc()).first()
        if not assignment or not assignment.psychologist_id:
            return jsonify({'error': 'Aucun psychologue assigné'}), 404

        psychologist = User.query.filter_by(id=assignment.psychologist_id, role='psychologist').first()
        if not psychologist:
            return jsonify({'error': 'Psychologue non trouvé'}), 404

        return jsonify({
            'psychologist': {
                'id': psychologist.id,
                'name': psychologist.name,
                'email': psychologist.email
            }
        })
    except Exception as e:
        import traceback
        print(traceback.format_exc())
        return jsonify({'error': str(e)}), 500

@patient_bp.route('/psychologists', methods=['GET'])
@jwt_required()
def get_psychologists():
    patient_check = patient_required()
    if patient_check:
        return patient_check

    try:
        # Récupère les paramètres de recherche (optionnels)
        search = request.args.get('q', '').strip()

        query = User.query.filter_by(role='psychologist')
        if search:
            search = f"%{search.lower()}%"
            query = query.filter(
                (User.name.ilike(search)) | (User.email.ilike(search))
            )
        psychologists = query.all()
        result = []
        for psy in psychologists:
            result.append({
                'id': psy.id,
                'name': psy.name,
                'email': psy.email
            })
        return jsonify({'psychologists': result})

    except Exception as e:
        import traceback
        print(traceback.format_exc())
        return jsonify({'error': str(e)}), 500
    

@patient_bp.route('/psychologist', methods=['POST'])
@jwt_required()
def assign_psychologist():
    patient_check = patient_required()
    if patient_check:
        return patient_check

    try:
        claims = get_jwt()
        patient_id = claims.get('user_id')
        data = request.get_json()
        psychologist_id = data.get('psychologist_id')

        if not psychologist_id:
            return jsonify({'error': 'psychologist_id requis'}), 400

        from models import Assignments, User
        psychologist = User.query.filter_by(id=psychologist_id, role='psychologist').first()
        if not psychologist:
            return jsonify({'error': "Psychologue n'existe pas"}), 400

        patient = User.query.filter_by(id=patient_id, role='patient').first()
        if not patient:
            return jsonify({'error': "Patient n'existe pas"}), 400

        # Vérifie si déjà assigné
        assignment = Assignments.query.filter_by(psychologist_id=psychologist_id, patient_id=patient_id).first()
        if not assignment:
            assignment = Assignments(psychologist_id=psychologist_id, patient_id=patient_id)
            db.session.add(assignment)
            db.session.commit()

        return jsonify({'message': 'Psychologue assigné', 'psychologist': {'id': psychologist.id, 'name': psychologist.name, 'email': psychologist.email}})
    except Exception as e:
        import traceback
        print(traceback.format_exc())
        return jsonify({'error': str(e)}), 500

@patient_bp.route('/psychologist', methods=['DELETE'])
@jwt_required()
def unassign_psychologist():
    patient_check = patient_required()
    if patient_check:
        return patient_check

    try:
        claims = get_jwt()
        patient_id = claims.get('user_id')
        from models import Assignments

        # Cherche l'assignement actif pour ce patient
        assignment = Assignments.query.filter_by(patient_id=patient_id).order_by(Assignments.assigned_at.desc()).first()
        if not assignment:
            return jsonify({'error': 'Aucun psychologue assigné'}), 404

        db.session.delete(assignment)
        db.session.commit()

        return jsonify({'message': 'Assignement au psychologue annulé'}), 200

    except Exception as e:
        import traceback
        print(traceback.format_exc())
        return jsonify({'error': str(e)}), 500