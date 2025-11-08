FROM python:3.11-slim-bullseye

WORKDIR /app

COPY api-python.py .

RUN pip install --no-cache-dir Flask==2.3.3 psycopg2-binary==2.9.7

EXPOSE 5000

CMD ["python", "api-python.py"]