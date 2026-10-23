# Optional starter: copy to the repository root only after the runtime, build
# and deployment contract are documented. Pin the base image (prefer a digest),
# run as a non-root user, add a HEALTHCHECK and never copy secrets.
ARG BASE_IMAGE
FROM ${BASE_IMAGE}
WORKDIR /app
COPY . .
