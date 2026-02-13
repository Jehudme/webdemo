# --- Stage 1: Build ---
FROM maven:3-eclipse-temurin-25 AS build
WORKDIR /app

RUN apt-get update && apt-get install -y unzip

COPY pom.xml .
COPY webdemo-client/pom.xml ./webdemo-client/

RUN mvn dependency:go-offline -pl webdemo-client -am

COPY webdemo-client/src ./webdemo-client/src
RUN mvn clean install -pl webdemo-client -am && \
    mvn jpro:release -pl webdemo-client && \
    unzip webdemo-client/target/webdemo-client-jpro.zip -d webdemo-client/target/dist

# --- Stage 2: Run ---
FROM eclipse-temurin:25-jre
WORKDIR /app

COPY --from=build /app/webdemo-client/target/dist/webdemo-client-jpro ./

# Ensure the start script is executable
RUN chmod +x bin/start.sh

# Expose the default JPro port
EXPOSE 8080

# --- THE FIX ---
# Remove the ENTRYPOINT entirely. 
# Use CMD in shell form to allow the '&&' operator to work at runtime.
CMD rm -f RUNNING_PID && ./bin/start.sh
