FROM node:24-alpine@sha256:06d7adf3e0ef61a13f1d28682726366f97a15aa1888c934d3ecec86c33918b53 AS build
WORKDIR /site
COPY index.html ./
COPY website ./website
COPY designs ./designs
ARG SOURCE_COMMIT
RUN node --test website/deploy/build.test.mjs && node website/verify.mjs && node website/deploy/build.mjs

FROM nginxinc/nginx-unprivileged:stable-alpine@sha256:f5116ed4606f3eb015dd4a8e28cb9b351476dc0ad4bc6e9f93b19cec130cdf03
COPY website/deploy/nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build /site/dist/template-website/ /srv/template-website/
USER 101
EXPOSE 8080
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget -q -O /dev/null http://127.0.0.1:8080/healthz || exit 1
