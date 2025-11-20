FROM python:3.11-slim-bullseye

WORKDIR /app

COPY APIs/api-python.py .

RUN pip install --no-cache-dir Flask==2.3.3 psycopg2-binary==2.9.7 python-dotenv==1.0.0 flasgger==0.9.7.1

EXPOSE 5000

CMD ["python", "api-python.py"]