from dotenv import load_dotenv
import os

# Load environment variables from .env file FIRST
load_dotenv()

from celery import Celery

# Module-level Celery instance (configured from env by default)
broker = os.getenv('CELERY_BROKER_URL', 'amqp://rabbituser:rabbitpass@rabbitmq.messaging.svc.cluster.local:5672//')
backend = os.getenv('CELERY_RESULT_BACKEND', 'redis://redis-master.cache.svc.cluster.local:6379/0')

celery = Celery('flask_api', broker=broker, backend=backend)

# ✅ Auto-discover tasks - IMPORTANT for task registration
celery.autodiscover_tasks(['tasks'])

# Import tasks to register them with Celery
import tasks


def make_celery(app):
    """Attach Flask app context to Celery tasks by setting a ContextTask."""
    celery.conf.update(app.config)

    class ContextTask(celery.Task):
        def __call__(self, *args, **kwargs):
            with app.app_context():
                return self.run(*args, **kwargs)

    celery.Task = ContextTask
    return celery


def init_celery(app):
    """Backward-compatible helper to create celery with app context."""
    return make_celery(app)
