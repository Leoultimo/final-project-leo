FROM python:3.11-slim

WORKDIR /app




# Copy requirements and install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY . .

# Expose port (adjust based on your app)
EXPOSE 5000

# Run application
CMD ["python", "app.py"]