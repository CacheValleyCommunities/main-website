# Build Stage: Use Hugo to generate the static site
ARG NODE_VERSION=16
FROM mcr.microsoft.com/devcontainers/javascript-node:${NODE_VERSION} as build

ARG VARIANT=hugo
ARG VERSION=latest

# Install Hugo and necessary dependencies
RUN apt-get update && apt-get install -y ca-certificates openssl git curl golang-go  && \
    rm -rf /var/lib/apt/lists/* && \
    case ${VERSION} in \
    latest) \
    export VERSION=$(curl -s https://api.github.com/repos/gohugoio/hugo/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4)}') ;;\
    esac && \
    echo ${VERSION} && \
    case $(uname -m) in \
    aarch64) \
    export ARCH=ARM64 ;; \
    *) \
    export ARCH=64bit ;; \
    esac && \
    echo ${ARCH} && \
    wget -O ${VERSION}.tar.gz https://github.com/gohugoio/hugo/releases/download/v${VERSION}/${VARIANT}_${VERSION}_Linux-${ARCH}.tar.gz && \
    tar xf ${VERSION}.tar.gz && \
    mv hugo /usr/bin/hugo

# Set working directory
WORKDIR /app

# Copy all Hugo app files into the container
COPY . /app

# Generate the static site with Hugo
RUN hugo --minify

# Production Stage: Use Nginx to serve the static files
FROM nginx:alpine as production

# Copy the generated static site from the build stage to the Nginx web server's directory
COPY --from=build /app/public /usr/share/nginx/html

# Expose port 80 for the web server
EXPOSE 80

# Start Nginx to serve the static site
CMD ["nginx", "-g", "daemon off;"]
