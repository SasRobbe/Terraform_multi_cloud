#Dockerfile that runs the fastapi app in ./hangman using uvicorn
FROM python:3.8

WORKDIR /app

COPY requirements.txt requirements.txt

RUN pip install --no-cache-dir --upgrade -r requirements.txt

COPY ./hangman /app/hangman

CMD ["uvicorn", "hangman.main:app", "--host", "0.0.0.0", "--port", "8080"]
EXPOSE 8080