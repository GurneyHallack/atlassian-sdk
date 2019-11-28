FROM alpine:3.10 AS builder

# Maintainers on this project are the following:
LABEL authors="Guy Couronné <guy.couronne@gmail.com>"

ARG ATLAS_VERSION=8.0.16
ARG ATLAS_URL="https://packages.atlassian.com/content/repositories/atlassian-public/com/atlassian/amps/atlassian-plugin-sdk/${ATLAS_VERSION}/atlassian-plugin-sdk-${ATLAS_VERSION}.tar.gz"
ARG ATLAS_SDK_SHA256=a0594d1e7adca41ca740524f189fd66c94ba2e74a1025d0c0193e977df628876

# Download Atlassian SDK
RUN /bin/sh -c set -eux;  \
   apk add --no-cache --virtual .build-deps \
        curl \
        dumb-init \
        openssl \
        gzip \
        tar \
    ;\ 
    mkdir -p /usr/share/atlassian-sdk; \
    curl -jkSL -o /tmp/atlassian-plugin-sdk.tar.gz $ATLAS_URL; \
    echo "$ATLAS_SDK_SHA256  /tmp/atlassian-plugin-sdk.tar.gz" | sha256sum -c -; \
	tar -xzf /tmp/atlassian-plugin-sdk.tar.gz -C /usr/share/atlassian-sdk --strip-components=1; \
	rm -f /tmp/atlassian-plugin-sdk.tar.gz; \
	apk del .build-deps;


FROM maven:3-ibmjava-8-alpine

# Maintainers on this project are the following:
LABEL authors="Guy Couronné <guy.couronne@gmail.com>"

# Create directory for sources using the same practice as the ruby images
RUN mkdir -p /usr/src/app
WORKDIR /usr/src/app

# Copy atlassian-sdk from builder
COPY --from=builder /usr/share/atlassian-sdk /usr/share/atlassian-sdk

# Add tini
RUN apk add --no-cache tini

# Do not use the standalone executable inside Atlassian SDK but the latest one
ENV \
    ATLAS_MVN=$MAVEN_HOME/bin/mvn \
    PATH=${PATH}:/usr/share/atlassian-sdk/bin/
 
# Reuse maven repository
VOLUME ["$MAVEN_CONFIG", "/usr/src/app"]
 
# Ports http
# Confluence, JIRA, FeCru (FishEye & Crucible), Crowd, RefApp (what is it ?), Bamboo, Bitbucket | Stash, ctk-server (what is it ?)
EXPOSE 1990 2990 3990 4990 5990 6990 7990 8990
 
# Healthcheck
HEALTHCHECK CMD [ "atlas-version" ]
 
# Set the default running command of the AMPS image to be running the
# application in debug mode.
CMD ["atlas-help"]

# Tini is now available at /sbin/tini
ENTRYPOINT ["/sbin/tini", "--"]
