from celery.schedules import crontab
from celery_app import celery

celery.conf.beat_schedule = {
    "delete-old-users-every-minute": {
        "task": "delete_old_users",
        "schedule": crontab(minute="*"),  # Runs every minute
    },
}
