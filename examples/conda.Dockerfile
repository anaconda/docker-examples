# Stage 1: Use the miniconda base image to create a new conda environment for our runtime
FROM continuumio/miniconda3:v25.11.1-1@sha256:5df7c31c16e90e4ea370836770feed507a1cf51c6e8aad835c65fb26b9eca941 AS builder

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
FROM debian:13.2-slim@sha256:e711a7b30ec1261130d0a121050b4ed81d7fb28aeabcf4ea0c7876d4e9f5aca2

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
