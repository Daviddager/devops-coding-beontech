FROM python:3.10.22-slim-trixie

ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONPATH=/app:/app/api

WORKDIR /app

COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

COPY api ./api

# AWS RDS/DocumentDB CA bundle referenced by MONGO_URI (tlsCAFile).
RUN python -c "import ssl, certifi, urllib.request; ctx = ssl.create_default_context(cafile=certifi.where()); open('/app/global-bundle.pem', 'wb').write(urllib.request.urlopen('https://truststore.pki.rds.amazonaws.com/global/global-bundle.pem', context=ctx).read())"

EXPOSE 8000

CMD ["python", "-m", "uvicorn", "api.main:app", "--host", "0.0.0.0", "--port", "8000"]
