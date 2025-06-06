from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt
from datetime import datetime
from utils.database import db
from models import Appointments

appointments_bp = Blueprint('appointments', __name__)

@appointments_bp.route('', methods=['GET'])
@jwt_required()
def get_appointments():
    try:
        claims = get_jwt()
        user_id = claims.get('user_id')
        role = claims.get('role')

        if role == 'psychologist':
            appointments = Appointments.query.filter_by(psychologist_id=user_id).order_by(Appointments.datetime).all()
        elif role == 'patient':
            appointments = Appointments.query.filter_by(patient_id=user_id).order_by(Appointments.datetime).all()
        else:
            return jsonify({'error': 'Rôle non autorisé'}), 403

        appointments_list = [{
            'id': apt.id,
            'psychologist_id': apt.psychologist_id,
            'patient_id': apt.patient_id,
            'datetime': apt.datetime.isoformat() if apt.datetime else None,
            'duration': apt.duration,
            'notes': apt.notes,
            'status': apt.status,
            'created_at': apt.created_at.isoformat() if apt.created_at else None
        } for apt in appointments]

        return jsonify({'appointments': appointments_list})

    except Exception as e:
        return jsonify({'error': str(e)}), 500

@appointments_bp.route('', methods=['POST'])
@jwt_required()
def create_appointment():
    try:
        claims = get_jwt()
        user_id = claims.get('user_id')
        role = claims.get('role')

        data = request.get_json()
        datetime_str = data.get('datetime')
        duration = data.get('duration', 60)
        notes = data.get('notes', '')
        
        if not datetime_str:
            return jsonify({'error': 'Date et heure requises'}), 400

        dt = datetime.fromisoformat(datetime_str)

        if role == 'psychologist':
            psychologist_id = user_id
            patient_id = data.get('patient_id')
            if not patient_id:
                return jsonify({'error': 'Patient ID requis'}), 400
        elif role == 'patient':
            patient_id = user_id
            psychologist_id = data.get('psychologist_id')
            if not psychologist_id:
                return jsonify({'error': 'Psychologist ID requis'}), 400
        else:
            return jsonify({'error': 'Rôle non autorisé'}), 403

        appointment = Appointments(
            psychologist_id=psychologist_id,
            patient_id=patient_id,
            datetime=dt,
            duration=duration,
            notes=notes,
            status='scheduled',
            created_at=datetime.now()
        )
        db.session.add(appointment)
        db.session.commit()

        return jsonify({
            'appointment': {
                'id': appointment.id,
                'psychologist_id': appointment.psychologist_id,
                'patient_id': appointment.patient_id,
                'datetime': appointment.datetime.isoformat(),
                'duration': appointment.duration,
                'notes': appointment.notes,
                'status': appointment.status,
                'created_at': appointment.created_at.isoformat()
            }
        })

    except Exception as e:
        return jsonify({'error': str(e)}), 500

@appointments_bp.route('/<int:appointment_id>', methods=['PUT'])
@jwt_required()
def update_appointment(appointment_id):
    try:
        claims = get_jwt()
        user_id = claims.get('user_id')
        role = claims.get('role')

        appointment = Appointments.query.get(appointment_id)
        if not appointment:
            return jsonify({'error': 'Rendez-vous non trouvé'}), 404

        # Vérifier l'accès
        if not ((role == 'psychologist' and appointment.psychologist_id == user_id) or
                (role == 'patient' and appointment.patient_id == user_id)):
            return jsonify({'error': 'Accès non autorisé'}), 403

        data = request.get_json()

        # Mettre à jour les champs autorisés
        if 'status' in data:
            appointment.status = data['status']
        if 'notes' in data:
            appointment.notes = data['notes']

        db.session.commit()

        return jsonify({
            'appointment': {
                'id': appointment.id,
                'psychologist_id': appointment.psychologist_id,
                'patient_id': appointment.patient_id,
                'datetime': appointment.datetime.isoformat(),
                'duration': appointment.duration,
                'notes': appointment.notes,
                'status': appointment.status,
                'created_at': appointment.created_at.isoformat()
            }
        })

    except Exception as e:
        return jsonify({'error': str(e)}), 500
    
@appointments_bp.route('/<int:appointment_id>', methods=['DELETE'])
@jwt_required()
def delete_appointment(appointment_id):
    try:
        claims = get_jwt()
        user_id = claims.get('user_id')
        role = claims.get('role')

        appointment = Appointments.query.get(appointment_id)
        if not appointment:
            return jsonify({'error': 'Rendez-vous non trouvé'}), 404

        # Vérifier l'accès
        if not ((role == 'psychologist' and appointment.psychologist_id == user_id) or
                (role == 'patient' and appointment.patient_id == user_id)):
            return jsonify({'error': 'Accès non autorisé'}), 403

        db.session.delete(appointment)
        db.session.commit()
        return jsonify({'message': 'Rendez-vous supprimé'})

    except Exception as e:
        return jsonify({'error': str(e)}), 500