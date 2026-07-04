from django.apps import AppConfig


class UsersConfig(AppConfig):
    default_auto_field = 'django.db.models.BigAutoField'
    name = 'users'

    def ready(self):
        """
        يتم تنفيذ هذا الكود عند بدء Django
        """
        # تهيئة Firebase Admin SDK
        try:
            from .fcm_service import FCMService
            FCMService.initialize()
            print('✅ Firebase initialized on Django startup')
        except Exception as e:
            print(f'⚠️ Warning: Could not initialize Firebase on startup: {e}')
