# # Use an official Python runtime as a parent image
# FROM public.ecr.aws/docker/library/python:3.11-bullseye

# # Set the working directory in the container
# WORKDIR /usr/src/app

# # Copy the current directory contents into the container at /usr/src/app
# COPY . .

# # Install any needed packages specified in requirements.txt
# RUN pip install --no-cache-dir -r requirements.txt

# # Make port 5000 available to the world outside this container
# EXPOSE 5000

# # Define environment variable
# ENV FLASK_APP=app.py
# ENV FLASK_RUN_HOST=0.0.0.0

# # Run flask application
# CMD ["flask", "run"]
# --- Base image (slim = smaller & faster) ---
#     FROM public.ecr.aws/docker/library/python:3.11-slim-bullseye

#     # --- OS & Python hygiene ---
#     ENV PYTHONDONTWRITEBYTECODE=1 \
#         PYTHONUNBUFFERED=1
    
#     WORKDIR /app
    
#     # --- Install deps with cache-friendly layers ---
#     # If you need build tools (e.g., for some wheels), uncomment apt packages:
#     # RUN apt-get update && apt-get install -y --no-install-recommends build-essential curl && rm -rf /var/lib/apt/lists/*
#     COPY requirements.txt .
#     RUN pip install --upgrade pip && \
#         pip install --no-cache-dir -r requirements.txt && \
#         pip install --no-cache-dir gunicorn
    
#     # --- Copy app code last (so deps cache stays hot) ---
#     COPY . .
    
#     # --- Networking & health ---
#     EXPOSE 5000
#     ENV PORT=5000
#     # Prefer probing a cheap health endpoint you add in Flask (see note below)
#     HEALTHCHECK --interval=10s --timeout=2s --retries=3 \
#       CMD python - <<'PY' || exit 1
#     import os, sys, urllib.request
#     url=f"http://127.0.0.1:{os.environ.get('PORT','5000')}/healthz"
#     try:
#         with urllib.request.urlopen(url, timeout=2) as r:
#             sys.exit(0 if r.status==200 else 1)
#     except Exception:
#         sys.exit(1)
#     PY
    
#     # --- Start the app with Gunicorn ---
#     # IMPORTANT: "app:app" assumes your module is "app.py" and it defines `app = Flask(__name__)`
#     CMD ["gunicorn", "-w", "2", "-b", "0.0.0.0:5000", "app:app"]
#     Use an official Python runtime as a parent image
# ---- Base: small, secure, current Debian ----
    FROM public.ecr.aws/docker/library/python:3.11-slim-bookworm

    # Hygiene + predictable buffering/caching
    ENV PYTHONDONTWRITEBYTECODE=1 \
        PYTHONUNBUFFERED=1 \
        PIP_NO_CACHE_DIR=1 \
        PORT=5000
    
    # Create unprivileged user
    RUN addgroup --system app && adduser --system --ingroup app app
    
    WORKDIR /app
    
    # ---- Dependencies first (better layer caching) ----
    COPY requirements.txt .
    RUN python -m pip install --upgrade pip && \
        pip install --no-cache-dir -r requirements.txt && \
        pip install --no-cache-dir gunicorn
    
    # ---- App code last ----
    COPY . .
    RUN chown -R app:app /app
    
    # ---- Container networking & health ----
    EXPOSE 5000
    HEALTHCHECK --interval=10s --timeout=2s --retries=3 \
      CMD python - <<'PY' || exit 1
    import os, sys, urllib.request
    url=f"http://127.0.0.1:{os.environ.get('PORT','5000')}/healthz"
    try:
        with urllib.request.urlopen(url, timeout=2) as r:
            sys.exit(0 if r.status==200 else 1)
    except Exception:
        sys.exit(1)
    PY
    
    # ---- Run as non-root with Gunicorn ----
    USER app
    
    # WEB_CONCURRENCY / THREADS tunables can be set via task env
    ENV WEB_CONCURRENCY=2 GUNICORN_THREADS=8 GUNICORN_TIMEOUT=30
    # "app:app" assumes app.py exposes Flask instance `app`
    CMD ["gunicorn", "-w", "2", "--threads", "8", "--timeout", "30", "-b", "0.0.0.0:5000", "app:app"]
    
