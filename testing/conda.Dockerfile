# Stage 1: Use the miniconda base image to create a new conda environment for our runtime
FROM continuumio/miniconda3:v25.11.1-1@sha256:5df7c31c16e90e4ea370836770feed507a1cf51c6e8aad835c65fb26b9eca941 AS builder

# Install a test plugin which will inject HTTP headers to trigger server-side behavior
COPY ./testing/conda-test-header-plugin ./conda-test-header-plugin
RUN conda run --name base --live-stream pip install --no-deps ./conda-test-header-plugin

# Install the required tools
RUN conda install \
    --name base \
    --channel https://repo.anaconda.cloud/repo/anaconda-tools \
    --override-channels \
    anaconda-registration

# Create the conda environment
RUN --mount=type=secret,id=ANACONDA_AUTH_API_KEY \
  conda create \
  --prefix /env \
  numpy
