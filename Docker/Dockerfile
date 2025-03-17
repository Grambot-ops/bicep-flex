FROM python:3.13-alpine

# Install dependencies and set up the project
RUN apk add --no-cache git \
    && git clone https://github.com/gurkanakdeniz/example-flask-crud.git \
    && cd /example-flask-crud \
    && python3 -m venv venv \
    && /example-flask-crud/venv/bin/pip install --upgrade pip \
    && /example-flask-crud/venv/bin/pip install -r requirements.txt \
    && /example-flask-crud/venv/bin/flask db init \
    && /example-flask-crud/venv/bin/flask db migrate -m "entries table" \
    && /example-flask-crud/venv/bin/flask db upgrade

# Set environment variables
ENV FLASK_APP=crudapp.py
ENV PATH="/example-flask-crud/venv/bin:$PATH"
WORKDIR /example-flask-crud

# Change this line to expose port 80 instead of 5000
EXPOSE 80

# Change the run command to use port 80
CMD ["flask", "run", "--host=0.0.0.0", "--port=80"]