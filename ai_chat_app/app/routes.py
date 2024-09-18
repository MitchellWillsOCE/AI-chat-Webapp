# routes.py
import csv
from fastapi import APIRouter, HTTPException
from .requests import LoginRequest, ChatRequest, TimeData
import random
import llama_cpp
import llama_cpp.llama_tokenizer
import os
from tinydb import TinyDB, Query

router = APIRouter()

# Setup caching
cache_dir = "./app/cache_dir" 
cache = llama_cpp.llama_cache.LlamaDiskCache(cache_dir)

# Load the Llama model
model = "Qwen/Qwen1.5-0.5B-Chat-GGUF"
llama = llama_cpp.Llama.from_pretrained(
    repo_id="Qwen/Qwen1.5-0.5B-Chat-GGUF",
    filename="*q8_0.gguf",
    tokenizer=llama_cpp.llama_tokenizer.LlamaHFTokenizer.from_pretrained(
        "Qwen/Qwen1.5-0.5B"
    ),
    verbose=False,
)

# Enable caching
llama.set_cache(cache)

# Initialize TinyDB
db = TinyDB('db.json')
users_table = db.table('users')
chat_history_table = db.table('chat_history')

@router.post("/api/register")
async def register(request: LoginRequest):
    if users_table.search(Query().username == request.username):
        raise HTTPException(status_code=400, detail="Username already exists")
    users_table.insert({'username': request.username, 'password': request.password})
    return {"message": "User registered successfully"}

@router.post("/api/login")
async def login(request: LoginRequest):
    user = users_table.search(Query().username == request.username)
    if user and user[0]['password'] == request.password:
        session_id = str(random.randint(1000, 9999))
        return {"session_id": session_id}
    raise HTTPException(status_code=401, detail="Unauthorized")


async def get_and_concatenate_chat_history(user_id: str) -> str:
    # Query the database to get chat history for the specified user_id
    Chat = Query()
    chat_history = chat_history_table.search(Chat.user_id == user_id)

    # Check if there is any chat history
    if not chat_history:
        return "No chat history found for the user."
    all_chats = []

    # Loop through each record and concatenate the prompt and response
    for chat in chat_history:
        prompt = chat.get('prompt', '')
        response = chat.get('response', '')
        
        # Append prompt and response to the list, formatted nicely
        all_chats.append(f"Prompt: {prompt}\nResponse: {response}\n")

    # Join all chats into a single string
    concatenated_chat_history = "\n".join(all_chats)
    
    return concatenated_chat_history

@router.post("/api/generate")
async def generate_text(request: ChatRequest):
    user = users_table.search(Query().username == request.user_id)
    if not user:
        raise HTTPException(status_code=401, detail="Session Expired")
    
    # create full_prompt
    user_id = request.user_id
    chat_history_string = await get_and_concatenate_chat_history(user_id)

    full_prompt = str(chat_history_string) + str(request.prompt)

    messages = [{"role": "user", "content": full_prompt}]
    response = llama.create_chat_completion_openai_v1(
        model=model, messages=messages, stream=True
    )
    response_text = ""
    for chunk in response:
        if chunk.choices[0].delta.content is not None:
            response_text += chunk.choices[0].delta.content
    chat_history_table.insert({'user_id': request.user_id, 'prompt': request.prompt, 'response': response_text})
    return {"response": response_text}

@router.get("/api/chat_history/{user_id}")
async def get_chat_history(user_id: str):
    user = users_table.search(Query().username == user_id)
    if not user:
        raise HTTPException(status_code=401, detail="Unauthorized")
    chat_history = chat_history_table.search(Query().user_id == user_id)
    return {"chat_history": chat_history}

@router.delete("/api/clear_chat_history/{user_id}")
async def clear_chat_history(user_id: str):
    user = users_table.search(Query().username == user_id)
    if not user:
        raise HTTPException(status_code=401, detail="Unauthorized")
    chat_history_table.remove(Query().user_id == user_id)
    return {"detail": "Chat history cleared"}

GENERATION_TIMES_FILE = 'generation_times.csv'

# Ensure the CSV file exists and has a header row
if not os.path.exists(GENERATION_TIMES_FILE):
    with open(GENERATION_TIMES_FILE, 'w', newline='') as file:
        writer = csv.writer(file)
        writer.writerow(["timeTaken"])  # Write header


@router.post('/api/store-time')
async def store_time(data: TimeData):
    time_taken = data.timeTaken

    try:
        # Append the new time to the CSV file
        with open(GENERATION_TIMES_FILE, 'a', newline='') as file:
            writer = csv.writer(file)
            writer.writerow([time_taken])

        return {'status': 'success', 'message': 'Time stored successfully.'}
    except Exception as e:
        raise HTTPException(status_code=500, detail="Could not store time due to an internal error.")

@router.get('/api/get-times')
async def get_times():
    try:
        # Read the times from the CSV file
        times = []
        with open(GENERATION_TIMES_FILE, 'r') as file:
            reader = csv.DictReader(file)
            for row in reader:
                times.append(int(row['timeTaken']))

        return {'times': times}
    except Exception as e:
        raise HTTPException(status_code=500, detail="Could not retrieve times due to an internal error.")

