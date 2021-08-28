FROM python:3.7-slim AS poetry

COPY pyproject.toml poetry.lock* ./

RUN pip install --no-cache-dir poetry && \
  poetry export --without-hashes --output /requirements.txt

# ---------------------------------------------------------

FROM python:3.7-slim

ENV APP_HOME /app
ENV PYTHONUNBUFFERED TRUE

WORKDIR $APP_HOME

COPY --from=poetry /requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app/ .

# Run the web service on container startup.
CMD ["functions-framework", "--target=main", "--signature-type=cloudevent"]
