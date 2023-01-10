# build stage
FROM node:lts-alpine@sha256:fda98168118e5a8f4269efca4101ee51dd5c75c0fe56d8eb6fad80455c2f5827 as build-stage

WORKDIR /app

COPY package*.json ./
RUN yarn install --frozen-lockfile

COPY . .
RUN yarn build

# production stage
FROM alpine:3.16@sha256:b95359c2505145f16c6aa384f9cc74eeff78eb36d308ca4fd902eeeb0a0b161b

ENV GID 1000
ENV UID 1000
ENV PORT 8080
ENV SUBFOLDER "/_"
ENV INIT_ASSETS 1

RUN addgroup -S lighttpd -g ${GID} && adduser -D -S -u ${UID} lighttpd lighttpd && \
    apk add -U --no-cache lighttpd

WORKDIR /www

COPY lighttpd.conf /lighttpd.conf
COPY entrypoint.sh /entrypoint.sh
COPY --from=build-stage --chown=${UID}:${GID} /app/dist /www/
COPY --from=build-stage --chown=${UID}:${GID} /app/dist/assets /www/default-assets

USER ${UID}:${GID}

HEALTHCHECK --interval=30s --timeout=5s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://127.0.0.1:${PORT}/ || exit 1

EXPOSE ${PORT}

ENTRYPOINT ["/bin/sh", "/entrypoint.sh"]
