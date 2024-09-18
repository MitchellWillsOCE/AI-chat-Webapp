# Use an official Python runtime as a parent image
FROM python:3.12

# Set the working directory in the container
WORKDIR /ai_chat_app

# Install system dependencies for building some Python packages
RUN apt-get update \
    && apt-get install -y \
    cmake \
    pkg-config \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Copy only the requirements file first to leverage caching
COPY requirements.txt ./

# Create a virtual environment
RUN python -m venv /ai_chat_app/myvenv

# Install dependencies in the virtual environment
RUN /ai_chat_app/myvenv/bin/pip install --no-cache-dir --upgrade pip \
    && /ai_chat_app/myvenv/bin/pip install --no-cache-dir -r requirements.txt

# Copy the rest of the application code
COPY . /ai_chat_app

# Expose port 8000 for the app
EXPOSE 8000

# Use the virtual environment to run Uvicorn
CMD ["/ai_chat_app/myvenv/bin/uvicorn", "ai_chat_app.app.main:app", "--host", "0.0.0.0", "--port", "8000"]
