FROM python:3.12-alpine

# Install dependencies and set up the project
RUN apk add --no-cache git \
    && git clone https://github.com/gurkanakdeniz/example-flask-crud.git \
    && cd /example-flask-crud \
    && python3 -m venv venv \
    && . venv/bin/activate \
    && pip install --upgrade pip \
    && pip install -r requirements.txt \
    && flask db init \
    && flask db migrate -m "entries table" \
    && flask db upgrade

# Set environment variables
ENV FLASK_APP=crudapp.py
WORKDIR /example-flask-crud

# Change this line to expose port 80 
EXPOSE 80

# Change the run command to use port 80
CMD ["flask", "run", "--host=0.0.0.0", "--port=80"]