FROM python:3.10.22-slim-trixie

COPY . .

RUN pip install -r requirements.txt

CMD ["python", "-m", "fastapi" ,"dev", "--app" ,"app", "--port", "8000"]