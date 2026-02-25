import secrets
import string
from django.core.management.base import BaseCommand
from app.models import ProductKey

class Command(BaseCommand):
    help = 'Generates unique product keys for the application'

    def add_arguments(self, parser):
        parser.add_argument('count', type=int, help='Number of keys to generate')

    def handle(self, *args, **options):
        count = options['count']
        generated_keys = []

        def generate_random_key():
            # Format: XXXX-XXXX-XXXX-XXXX
            parts = []
            for _ in range(4):
                part = ''.join(secrets.choice(string.ascii_uppercase + string.digits) for _ in range(4))
                parts.append(part)
            return '-'.join(parts)

        self.stdout.write(self.style.SUCCESS(f'Generating {count} product keys...'))

        for _ in range(count):
            while True:
                new_key = generate_random_key()
                if not ProductKey.objects.filter(key=new_key).exists():
                    ProductKey.objects.create(key=new_key)
                    generated_keys.append(new_key)
                    break
        
        self.stdout.write(self.style.SUCCESS(f'Successfully generated {count} keys:'))
        for key in generated_keys:
            self.stdout.write(key)
        
        self.stdout.write(self.style.WARNING('\nIMPORTANT: After copying these keys, delete this file (generate_keys.py) so others cannot generate more keys.'))
