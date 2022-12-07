# build image
FROM python:3.9-slim-bullseye
WORKDIR /code
RUN apt-get update && \
    apt-get install libgdal-dev build-essential --no-install-recommends -y && \
    apt-get clean
COPY ./requirements.txt /code/requirements.txt
RUN python -m venv --copies /code/venv && \
    . /code/venv/bin/activate && \
    pip install --no-cache-dir --upgrade -r /code/requirements.txt
COPY ./app /code/app

ENV PATH /code/venv/bin:$PATH
CMD ["uvicorn", "app.main:app", "--proxy-headers", "--host", "0.0.0.0", "--port", "80"]
