# filepath: c:\Users\PC\Desktop\Flutter\backend\utils\database.py
from flask_sqlalchemy import SQLAlchemy
from flask_migrate import Migrate

db = SQLAlchemy()
migrate = Migrate()