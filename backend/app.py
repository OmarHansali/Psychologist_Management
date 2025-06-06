from flask import Flask
from flask_cors import CORS
from config import Config
from utils.database import db, migrate
from utils.mail import mail
from routes.auth import auth_bp
from routes.admin import admin_bp
from routes.psychologist import psychologist_bp
from routes.patient import patient_bp
from routes.appointments import appointments_bp
from routes.chat import chat_bp
from flask_jwt_extended import JWTManager

app = Flask(__name__)
app.config.from_object(Config)
CORS(app)

db.init_app(app)
migrate.init_app(app, db)
mail.init_app(app)

jwt = JWTManager(app)

app.register_blueprint(auth_bp, url_prefix='/api/auth')
app.register_blueprint(admin_bp, url_prefix='/api/admin')
app.register_blueprint(psychologist_bp, url_prefix='/api/psychologist')
app.register_blueprint(patient_bp, url_prefix='/api/patient')
app.register_blueprint(appointments_bp, url_prefix='/api/appointments')
app.register_blueprint(chat_bp, url_prefix='/api/chat')

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)