from celery import shared_task
from celery.utils.log import get_task_logger
import pandas as pd
from datetime import datetime
import io
import os
from sqlalchemy import create_engine, Column, Integer, String, DateTime
from sqlalchemy.orm import sessionmaker, declarative_base
from celery_app import celery

logger = get_task_logger(__name__)

# Build database URL from environment if not provided
DATABASE_URL = os.getenv('SQLALCHEMY_DATABASE_URI') or (
    f"mysql+pymysql://{os.getenv('DB_USER','root')}:{os.getenv('DB_PASSWORD','rootpassword')}@{os.getenv('DB_HOST','localhost')}:{os.getenv('DB_PORT','3306')}/{os.getenv('DB_NAME','flask_app')}"
)

# SQLAlchemy setup (independent from Flask app)
engine = create_engine(DATABASE_URL, pool_pre_ping=True)
Session = sessionmaker(bind=engine)
Base = declarative_base()


class User(Base):
    __tablename__ = 'users'
    id = Column(Integer, primary_key=True)
    name = Column(String(100), nullable=False)
    city = Column(String(100), nullable=False)
    email = Column(String(100), nullable=False, unique=True)
    age = Column(Integer)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)


@celery.task(bind=True)
def process_bulk_upload(self, file_data, filename):
    """Background task: process bulk CSV upload and insert into DB."""
    try:
        df = pd.read_csv(io.BytesIO(file_data))
        total = len(df)
        uploaded = 0
        failed = []
        session = Session()

        for idx, row in df.iterrows():
            try:
                # Reporting progress
                self.update_state(state='PROCESSING', meta={'current': idx + 1, 'total': total})

                name = str(row['name']).strip() if pd.notna(row['name']) else None
                city = str(row['city']).strip() if pd.notna(row['city']) else None
                email = str(row['email']).strip() if pd.notna(row['email']) else None
                age = int(row['age']) if 'age' in row and pd.notna(row['age']) else None

                if not name or not city or not email:
                    failed.append({'row': idx + 2, 'error': 'Missing required fields (name, city, email)'})
                    continue

                exists = session.query(User).filter_by(email=email).first()
                if exists:
                    failed.append({'row': idx + 2, 'error': f'Email "{email}" already exists'})
                    continue

                if age is not None and (age < 0 or age > 150):
                    failed.append({'row': idx + 2, 'error': 'Age must be between 0 and 150'})
                    continue

                user = User(name=name, city=city, email=email, age=age)
                session.add(user)
                uploaded += 1

            except Exception as e:
                failed.append({'row': idx + 2, 'error': str(e)})
                continue

        session.commit()
        session.close()

        return {
            'status': 'SUCCESS',
            'message': f'Successfully uploaded {uploaded} users',
            'uploaded_count': uploaded,
            'failed_count': len(failed),
            'failed_records': failed,
            'timestamp': datetime.utcnow().isoformat()
        }

    except Exception as e:
        logger.exception('Error in process_bulk_upload')
        raise



from datetime import datetime, timedelta
from sqlalchemy.exc import SQLAlchemyError


BATCH_SIZE = 1000


@celery.task(bind=True, name="delete_old_users")
def delete_old_users(self):

    session = Session()

    total_deleted = 0
    deleted_users = []

    try:

        one_year_ago = datetime.utcnow() - timedelta(days=365)

        while True:

            users = (
                session.query(User)
                .filter(User.created_at < one_year_ago)
                .limit(BATCH_SIZE)
                .all()
            )

            if not users:
                break

            batch_deleted = []

            for user in users:

                batch_deleted.append({
                    "id": user.id,
                    "name": user.name,
                    "email": user.email,
                    "city": user.city,
                    "created_at": user.created_at.isoformat()
                })

                session.delete(user)

            session.commit()

            deleted_users.extend(batch_deleted)

            total_deleted += len(batch_deleted)

        return {
            "task_id": self.request.id,
            "status": "success",
            "total_deleted": total_deleted,
            "deleted_users": deleted_users
        }

    except SQLAlchemyError as exc:

        session.rollback()

        raise self.retry(
            exc=exc,
            countdown=60,
            max_retries=3
        )

    finally:
        session.close()



