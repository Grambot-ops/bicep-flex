FROM python:3.12-alpine

# Install git (temporarily)
RUN apk add --no-cache git

WORKDIR /app

# Clone the repository
RUN git clone https://github.com/gurkanakdeniz/example-flask-crud.git .

# Install dependencies in a single RUN layer.  Use the full path to venv binaries.
RUN python3 -m venv venv \
    && /app/venv/bin/pip install --no-cache-dir --upgrade pip \
    && /app/venv/bin/pip install --no-cache-dir -r requirements.txt

# Set environment variables
ENV FLASK_APP=crudapp.py
# Explicitly include venv/bin in PATH
ENV PATH="/app/venv/bin:$PATH"

EXPOSE 80

CMD ["flask", "run", "--host=0.0.0.0", "--port=80"]