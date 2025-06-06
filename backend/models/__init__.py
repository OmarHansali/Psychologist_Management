from utils.database import db

class User(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    email = db.Column(db.String(255), unique=True, nullable=False)
    password = db.Column(db.String(255), nullable=False)
    role = db.Column(db.String(50), nullable=False)
    name = db.Column(db.String(255))
    created_at = db.Column(db.DateTime)

class Appointments(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    psychologist_id = db.Column(db.Integer, db.ForeignKey('user.id', ondelete='SET NULL'), nullable=True)
    patient_id = db.Column(db.Integer, db.ForeignKey('user.id', ondelete='SET NULL'), nullable=True)
    datetime = db.Column(db.DateTime, nullable=False)
    duration = db.Column(db.Integer, default=60)
    notes = db.Column(db.Text)
    status = db.Column(db.String(50), default='scheduled')
    created_at = db.Column(db.DateTime)

class Conversations(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    psychologist_id = db.Column(db.Integer, db.ForeignKey('user.id', ondelete='SET NULL'), nullable=True)
    patient_id = db.Column(db.Integer, db.ForeignKey('user.id', ondelete='SET NULL'), nullable=True)
    created_at = db.Column(db.DateTime, default=db.func.now())

class Messages(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    conversation_id = db.Column(db.Integer, db.ForeignKey('conversations.id', ondelete='CASCADE'), nullable=False)
    sender_id = db.Column(db.Integer, db.ForeignKey('user.id', ondelete='SET NULL'), nullable=True)
    content = db.Column(db.Text)
    sent_at = db.Column(db.DateTime, default=db.func.now())
    read = db.Column(db.Boolean, default=False)

class Assignments(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    psychologist_id = db.Column(db.Integer, db.ForeignKey('user.id', ondelete='SET NULL'), nullable=False)
    patient_id = db.Column(db.Integer, db.ForeignKey('user.id', ondelete='SET NULL'), nullable=False)
    assigned_at = db.Column(db.DateTime, default=db.func.now())

    # Optionnel : relations pour accès direct
    psychologist = db.relationship('User', foreign_keys=[psychologist_id])
    patient = db.relationship('User', foreign_keys=[patient_id])