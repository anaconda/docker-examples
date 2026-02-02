# Stage 1: Use the miniconda base image to create a new conda environment for our runtime
FROM continuumio/miniconda3:25.3.1-1 AS builder

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
FROM debian:13.2-slim@sha256:4bcb9db66237237d03b55b969271728dd3d955eaaa254b9db8a3db94550b1885

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
