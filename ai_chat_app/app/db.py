from tinydb import TinyDB

db = TinyDB('db.json')
users_table = db.table('users')
chat_history_table = db.table('chat_history')
