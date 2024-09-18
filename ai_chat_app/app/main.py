from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from fastapi.templating import Jinja2Templates
from fastapi.responses import HTMLResponse
from .routes import router

app = FastAPI()

# Middleware for handling CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Mounting the static files
app.mount("/ai_chat_app/static", StaticFiles(directory='ai_chat_app/static'), name="static")

# Setting up the Jinja2 templates
templates = Jinja2Templates(directory="ai_chat_app/templates")

# Include your API routes
app.include_router(router)

# Define a route to serve the homepage
@app.get("/", response_class=HTMLResponse)
async def read_root(request: Request):
    return templates.TemplateResponse("index.html", {"request": request})
