import json
import random
import time
import logging
from datetime import datetime
from faker import Faker
import os

# Configure logging
log_dir = "/app/logs"
os.makedirs(log_dir, exist_ok=True)

# Setup multiple log files
app_log = logging.getLogger('app')
app_handler = logging.FileHandler(f'{log_dir}/app.log')
app_handler.setFormatter(logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s'))
app_log.addHandler(app_handler)
app_log.setLevel(logging.INFO)

access_log = logging.getLogger('access')
access_handler = logging.FileHandler(f'{log_dir}/access.log')
access_handler.setFormatter(logging.Formatter('%(message)s'))
access_log.addHandler(access_handler)
access_log.setLevel(logging.INFO)

error_log = logging.getLogger('error')
error_handler = logging.FileHandler(f'{log_dir}/error.log')
error_handler.setFormatter(logging.Formatter('%(asctime)s - %(levelname)s - %(message)s'))
error_log.addHandler(error_handler)
error_log.setLevel(logging.ERROR)

fake = Faker()

# Sample data generators
def generate_user_activity():
    users = ['john_doe', 'jane_smith', 'bob_johnson', 'alice_brown', 'charlie_wilson']
    actions = ['login', 'logout', 'view_page', 'click_button', 'download_file', 'upload_file']
    
    return {
        'timestamp': datetime.now().isoformat(),
        'user_id': random.choice(users),
        'action': random.choice(actions),
        'ip_address': fake.ipv4(),
        'user_agent': fake.user_agent(),
        'session_id': fake.uuid4(),
        'duration_ms': random.randint(100, 5000)
    }

def generate_web_access():
    methods = ['GET', 'POST', 'PUT', 'DELETE']
    status_codes = [200, 301, 302, 400, 401, 403, 404, 500, 502, 503]
    paths = ['/api/users', '/api/orders', '/login', '/dashboard', '/products', '/cart']
    
    status = random.choice(status_codes)
    return f'{fake.ipv4()} - - [{datetime.now().strftime("%d/%b/%Y:%H:%M:%S %z")}] "{random.choice(methods)} {random.choice(paths)} HTTP/1.1" {status} {random.randint(100, 10000)} "{fake.url()}" "{fake.user_agent()}"'

def generate_application_event():
    events = [
        'User authentication successful',
        'Database connection established',
        'Cache cleared successfully',
        'Scheduled job completed',
        'Configuration updated',
        'Service health check passed'
    ]
    levels = ['INFO', 'DEBUG', 'WARN']
    
    return {
        'level': random.choice(levels),
        'message': random.choice(events),
        'module': random.choice(['auth', 'database', 'cache', 'scheduler', 'config']),
        'thread_id': random.randint(1000, 9999)
    }

def generate_error_event():
    errors = [
        'Database connection timeout',
        'Invalid user credentials',
        'File not found',
        'Network connection failed',
        'Memory allocation error',
        'Service unavailable'
    ]
    
    return {
        'error_type': random.choice(['DatabaseError', 'AuthenticationError', 'FileNotFoundError', 'NetworkError']),
        'message': random.choice(errors),
        'stack_trace': f'at line {random.randint(1, 1000)} in {random.choice(["auth.py", "db.py", "api.py"])}',
        'user_id': fake.uuid4() if random.random() > 0.3 else None
    }

def main():
    print("Starting log generator...")
    
    while True:
        try:
            # Generate different types of logs
            if random.random() < 0.4:  # 40% chance for user activity
                user_activity = generate_user_activity()
                app_log.info(json.dumps(user_activity))
            
            if random.random() < 0.3:  # 30% chance for web access
                access_entry = generate_web_access()
                access_log.info(access_entry)
            
            if random.random() < 0.2:  # 20% chance for application event
                app_event = generate_application_event()
                app_log.info(json.dumps(app_event))
            
            if random.random() < 0.1:  # 10% chance for error
                error_event = generate_error_event()
                error_log.error(json.dumps(error_event))
            
            # Random sleep between 1-5 seconds
            time.sleep(random.uniform(1, 5))
            
        except KeyboardInterrupt:
            print("Stopping log generator...")
            break
        except Exception as e:
            print(f"Error in log generator: {e}")
            time.sleep(5)

if __name__ == "__main__":
    main()