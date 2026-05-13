from flask import Flask, request, jsonify
from flask_cors import CORS
from flask_sqlalchemy import SQLAlchemy
from datetime import datetime
import os

app = Flask(__name__)

# Database Configuration
app.config['SQLALCHEMY_DATABASE_URI'] = (
    f"mysql+pymysql://{os.getenv('DB_USER', 'root')}:"
    f"{os.getenv('DB_PASSWORD', 'rootpassword')}@"
    f"{os.getenv('DB_HOST', 'localhost')}:"
    f"{os.getenv('DB_PORT', '3306')}/"
    f"{os.getenv('DB_NAME', 'flask_app')}"
)
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
app.config['JSON_SORT_KEYS'] = False

db = SQLAlchemy(app)
CORS(app)

# Database Models
class User(db.Model):
    __tablename__ = 'users'
    
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(100), nullable=False)
    city = db.Column(db.String(100), nullable=False)
    email = db.Column(db.String(100), unique=True, nullable=False)
    age = db.Column(db.Integer)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    def to_dict(self):
        return {
            'id': self.id,
            'name': self.name,
            'city': self.city,
            'email': self.email,
            'age': self.age,
            'created_at': self.created_at.isoformat(),
            'updated_at': self.updated_at.isoformat()
        }

# Home endpoint
@app.route("/")
def hello():
    return {"message": "Good morning from Shreyas K N! Welcome to CRUD API with MySQL. Happy coding! All the best"}

# Original greeting endpoint
@app.route('/greeting')
def greeting():
    data = request.args
    name = data.get('Name')
    city = data.get('City')
    if not name or not city:
        return {
            "Message": "Name and City fields are required"
        }, 403
    return {
        "Greeting": f"Hello {name}",
        "Message": f"How are things at {city}?",
    }, 200

# ==================== CRUD Operations ====================

# CREATE - Add new user
@app.route('/api/users', methods=['POST'])
def create_user():
    try:
        data = request.json
        
        # Validation
        if not data or not data.get('name') or not data.get('email') or not data.get('city'):
            return jsonify({'error': 'name, email, and city are required'}), 400
        
        # Check if email already exists
        if User.query.filter_by(email=data.get('email')).first():
            return jsonify({'error': 'Email already exists'}), 409
        
        user = User(
            name=data.get('name'),
            city=data.get('city'),
            email=data.get('email'),
            age=data.get('age')
        )
        db.session.add(user)
        db.session.commit()
        
        return jsonify({
            'message': 'User created successfully',
            'user': user.to_dict()
        }), 201
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500

# READ - Get all users
@app.route('/api/users', methods=['GET'])
def get_users():
    try:
        page = request.args.get('page', 1, type=int)
        per_page = request.args.get('per_page', 10, type=int)
        
        users = User.query.paginate(page=page, per_page=per_page)
        
        return jsonify({
            'users': [user.to_dict() for user in users.items],
            'total': users.total,
            'pages': users.pages,
            'current_page': page
        }), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500

# READ - Get single user by ID
@app.route('/api/users/<int:user_id>', methods=['GET'])
def get_user(user_id):
    try:
        user = User.query.get(user_id)
        if not user:
            return jsonify({'error': 'User not found'}), 404
        return jsonify(user.to_dict()), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500

# UPDATE - Modify user
@app.route('/api/users/<int:user_id>', methods=['PUT'])
def update_user(user_id):
    try:
        user = User.query.get(user_id)
        if not user:
            return jsonify({'error': 'User not found'}), 404
        
        data = request.json
        
        # Update only provided fields
        if 'name' in data:
            user.name = data['name']
        if 'city' in data:
            user.city = data['city']
        if 'email' in data:
            # Check if new email is unique
            if data['email'] != user.email and User.query.filter_by(email=data['email']).first():
                return jsonify({'error': 'Email already exists'}), 409
            user.email = data['email']
        if 'age' in data:
            user.age = data['age']
        
        db.session.commit()
        
        return jsonify({
            'message': 'User updated successfully',
            'user': user.to_dict()
        }), 200
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500

# DELETE - Remove user
@app.route('/api/users/<int:user_id>', methods=['DELETE'])
def delete_user(user_id):
    try:
        user = User.query.get(user_id)
        if not user:
            return jsonify({'error': 'User not found'}), 404
        
        db.session.delete(user)
        db.session.commit()
        
        return jsonify({'message': 'User deleted successfully'}), 200
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500

# Health check endpoint
@app.route('/health', methods=['GET'])
def health():
    return jsonify({'status': 'healthy'}), 200

# Initialize database on app startup
def init_db():
    """Initialize database tables on app startup"""
    try:
        with app.app_context():
            db.create_all()
            print("✅ Database tables initialized successfully")
    except Exception as e:
        print(f"⚠️ Error initializing database: {e}")

if __name__ == "__main__":
    # Initialize database before running the app
    init_db()
    app.run(host="0.0.0.0", port=5000, debug=False)
