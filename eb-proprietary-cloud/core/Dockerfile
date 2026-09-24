FROM python:3.11-slim

WORKDIR /opt/proprietary-app

RUN pip install --no-cache-dir Flask==3.0.3 gunicorn==22.0.0

COPY server.py .

ENV PORT=8080
ENV DB_PATH=/opt/proprietary-app/data.db

EXPOSE 8080

CMD ["gunicorn", "--bind", "0.0.0.0:8080", "--workers", "4", "server:app"]
