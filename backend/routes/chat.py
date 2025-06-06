from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt
from datetime import datetime
from utils.database import db
from models import Conversations, Messages

chat_bp = Blueprint('chat', __name__)

@chat_bp.route('/conversations', methods=['GET'])
@jwt_required()
def get_conversations():
    try:
        claims = get_jwt()
        user_id = claims.get('user_id')
        role = claims.get('role')

        if role == 'psychologist':
            conversations = Conversations.query.filter_by(psychologist_id=user_id).all()
        elif role == 'patient':
            conversations = Conversations.query.filter_by(patient_id=user_id).all()
        else:
            return jsonify({'error': 'Rôle non autorisé'}), 403

        result = []
        for conv in conversations:
            last_message = Messages.query.filter_by(conversation_id=conv.id).order_by(Messages.sent_at.desc()).first()
            unread_count = Messages.query.filter_by(conversation_id=conv.id, read=False).filter(Messages.sender_id != user_id).count()
            result.append({
                'id': conv.id,
                'psychologist_id': conv.psychologist_id,
                'patient_id': conv.patient_id,
                'last_message': {
                    'id': last_message.id,
                    'sender_id': last_message.sender_id,
                    'content': last_message.content,
                    'sent_at': last_message.sent_at.isoformat() if last_message.sent_at else None
                } if last_message else None,
                'unread_count': unread_count
            })

        return jsonify({'conversations': result})

    except Exception as e:
        import traceback
        print(traceback.format_exc())
        return jsonify({'error': str(e)}), 500

@chat_bp.route('/messages/<int:conversation_id>', methods=['GET'])
@jwt_required()
def get_messages(conversation_id):
    try:
        claims = get_jwt()
        user_id = claims.get('user_id')

        conversation = Conversations.query.get(conversation_id)
        if not conversation or (user_id not in [conversation.psychologist_id, conversation.patient_id]):
            return jsonify({'error': 'Accès non autorisé'}), 403

        messages = Messages.query.filter_by(conversation_id=conversation_id).order_by(Messages.sent_at).all()
        messages_list = [{
            'id': msg.id,
            'sender_id': msg.sender_id,
            'content': msg.content,
            'sent_at': msg.sent_at.isoformat() if msg.sent_at else None
        } for msg in messages]

        return jsonify({'messages': messages_list})

    except Exception as e:
        import traceback
        print(traceback.format_exc())
        return jsonify({'error': str(e)}), 500

@chat_bp.route('/messages', methods=['POST'])
@jwt_required()
def send_message():
    try:
        claims = get_jwt()
        user_id = claims.get('user_id')
        role = claims.get('role')

        data = request.get_json()
        conversation_id = data.get('conversation_id')
        content = data.get('content')

        if not conversation_id or not content:
            return jsonify({'error': 'Conversation ID et contenu requis'}), 400

        conversation = Conversations.query.get(conversation_id)
        if not conversation or (user_id not in [conversation.psychologist_id, conversation.patient_id]):
            return jsonify({'error': 'Accès non autorisé'}), 403

        message = Messages(
            conversation_id=conversation_id,
            sender_id=user_id,
            content=content,
            sent_at=datetime.now()
        )
        db.session.add(message)
        db.session.commit()

        return jsonify({
            'message': {
                'id': message.id,
                'sender_id': message.sender_id,
                'content': message.content,
                'sent_at': message.sent_at.isoformat() if message.sent_at else None
            }
        })

    except Exception as e:
        import traceback
        print(traceback.format_exc())
        return jsonify({'error': str(e)}), 500
    
@chat_bp.route('/messages/<int:conversation_id>/seen', methods=['POST'])
@jwt_required()
def mark_messages_as_seen(conversation_id):
    try:
        claims = get_jwt()
        user_id = claims.get('user_id')

        conversation = Conversations.query.get(conversation_id)
        if not conversation or (user_id not in [conversation.psychologist_id, conversation.patient_id]):
            return jsonify({'error': 'Accès non autorisé'}), 403

        # Marque tous les messages non lus envoyés par l'autre utilisateur comme lus
        updated = Messages.query.filter_by(conversation_id=conversation_id, read=False).filter(Messages.sender_id != user_id).update({'read': True})
        db.session.commit()

        return jsonify({'updated': updated}), 200

    except Exception as e:
        import traceback
        print(traceback.format_exc())
        return jsonify({'error': str(e)}), 500

@chat_bp.route('/conversations', methods=['POST'])
@jwt_required()
def create_conversation():
    try:
        claims = get_jwt()
        user_id = claims.get('user_id')
        role = claims.get('role')
        data = request.get_json()

        if user_id is None:
            return jsonify({'error': 'user_id manquant dans le JWT'}), 401
    
        if role == 'psychologist':
            psychologist_id = user_id
            patient_id = data.get('patient_id')
        elif role == 'patient':
            patient_id = user_id
            psychologist_id = data.get('psychologist_id')
        else:
            return jsonify({'error': 'Rôle non autorisé'}), 403

        if psychologist_id is None or patient_id is None:
            return jsonify({'error': 'psychologist_id et patient_id requis'}), 400

        # Check if conversation already exists
        conversation = Conversations.query.filter_by(
            psychologist_id=psychologist_id, patient_id=patient_id
        ).first()
        if not conversation:
            conversation = Conversations(
                psychologist_id=psychologist_id,
                patient_id=patient_id,
                created_at=datetime.now()
            )
            db.session.add(conversation)
            db.session.commit()

        return jsonify({
            'conversation': {
                'id': conversation.id,
                'psychologist_id': conversation.psychologist_id,
                'patient_id': conversation.patient_id,
                'created_at': conversation.created_at.isoformat() if conversation.created_at else None
            }
        })

    except Exception as e:
        import traceback
        print(traceback.format_exc())
        return jsonify({'error': str(e)}), 500