from pydantic import BaseModel

class LoginRequest(BaseModel):
    username: str
    password: str

class ChatRequest(BaseModel):
    prompt: str
    user_id: str
    
class TimeData(BaseModel):
    timeTaken: int
