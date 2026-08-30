# Stage 1: Use the miniconda base image to create a new conda environment for our runtime
FROM continuumio/miniconda3:26.7.1-1@sha256:eca594d684f495c1a02beff33a9fab53aec8c5830eaf431bb149912dc6c9e4c1 AS builder

# Install the required tools
RUN conda install \
    --name base \
    --channel https://repo.anaconda.cloud/repo/anaconda-tools \
    --override-channels \
    anaconda-registration

# Copy environment file(s) only, for better caching
COPY ./environment.yml ./environment.yml

# Create the conda environment
#
# The ANACONDA_AUTH_API_KEY must be passed in as a secret, like:
#   docker build --secret id=ANACONDA_AUTH_API_KEY
RUN --mount=type=secret,id=ANACONDA_AUTH_API_KEY \
  conda env create \
  --prefix /env \
  --file environment.yml

# Stage 2: Starting from a slim debian image, copy the conda environment, app code, and run
FROM debian:13.3-slim@sha256:77ba0164de17b88dd0bf6cdc8f65569e6e5fa6cd256562998b62553134a00ef0

# Copy in the prepared conda environment
COPY --from=builder /env /env

# Place the conda environment in the PATH
ENV PATH="/env/bin:${PATH}"

# Set the working directory
WORKDIR /app

# Copy in the app code
COPY app.py ./

# Expose the port and run the service
EXPOSE 8000
ENTRYPOINT ["uvicorn", "app:app", "--host",  "0.0.0.0",  "--port", "8000"]
