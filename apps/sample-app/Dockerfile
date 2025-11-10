# Use official Python image as the base
FROM python:3.11-slim

# Set working directory
WORKDIR /app

# Copy requirements and install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy the application code
COPY src/ ./src

# Set the command to run the app
CMD ["python", "src/app.py"]