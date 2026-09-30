# syntax=docker/dockerfile:1
#
# A single Dockerfile builds every Ballerina service in this
# repository. The service is selected with the SERVICE_DIR build
# argument, so all services share one reviewed build definition:
#
#   docker build --build-arg SERVICE_DIR=order-service .
#
# The build stage compiles the service and renames the artefact to
# a stable name so the runtime stage never has to guess it. The
# runtime stage is the JRE-only Swan Lake image that Ballerina
# officially supports, and it contains no Ballerina toolchain.
#
# Configuration is injected at run time as environment variables,
# which Ballerina maps onto each service's `configurable` values
# (MONGODB_CONNECTION_URL -> mongoConnectionUrl).

ARG BALLERINA_VERSION=2201.13.6

# ---------- build ----------
FROM ballerina/swan-lake:${BALLERINA_VERSION}-jre17 AS build
ARG SERVICE_DIR
WORKDIR /home/ballerina
# Only the selected service is sent to the daemon and the builder.
COPY ${SERVICE_DIR}/ ./
RUN ballerina build --skip-tests \
    && mv target/bin/*.jar target/bin/service.jar

# ---------- runtime ----------
FROM ballerina/swan-lake:${BALLERINA_VERSION}-jre17
ARG SERVICE_PORT=8080
WORKDIR /home/ballerina
COPY --from=build /home/ballerina/target/bin/service.jar /home/ballerina/service.jar
EXPOSE ${SERVICE_PORT}
ENTRYPOINT ["java", "-jar", "/home/ballerina/service.jar"]
