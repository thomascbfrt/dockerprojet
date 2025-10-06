# BASE SERVER CONFIGURATION
# General
SERVER_HOST = '0.0.0.0'
SERVER_PORT = 5001
DEBUG = False
# CORS Configuration
ENABLE_CORS = False  # CORS géré par nginx

# SQL PRODUCTION DB CONNECTION CONFIGURATION
SQLDB_SETTINGS = {
    "db": 'myrames-prod-db',
    "user": 'mariaUsr',
    "password": 'mariaPwd',
    "host": 'sqldatabase',
    "port": 3306
}

# MONGODB HISTORY DB CONNECTION CONFIGURATION
MONGODB_SETTINGS = {
    "db": "history-db",
    "host": "nosqldatabase",
    "port": 27017,
    "username": "mongoUsr",
    "password": "mongoPass",
    "authentication_source": "admin"
}
