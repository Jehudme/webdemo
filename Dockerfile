# --- Stage 1: Build ---
FROM maven:3-eclipse-temurin-25 AS build
WORKDIR /app

# Install unzip to extract the JPro release
RUN apt-get update && apt-get install -y unzip

# 1. Cache dependencies: Copy ONLY pom files first
COPY pom.xml .
COPY webdemo-client/pom.xml ./webdemo-client/

# 2. Download dependencies (this layer is cached until poms change)
RUN mvn dependency:go-offline -pl webdemo-client -am

# 3. Copy source code and build
COPY webdemo-client/src ./webdemo-client/src
RUN mvn clean install -pl webdemo-client -am && \
    mvn jpro:release -pl webdemo-client && \
    unzip webdemo-client/target/webdemo-client-jpro.zip -d webdemo-client/target/dist

# --- Stage 2: Run ---
FROM eclipse-temurin:25-jre
WORKDIR /app

# Copy the unzipped release contents
COPY --from=build /app/webdemo-client/target/dist/webdemo-client-jpro ./

# Ensure the start script is executable
RUN chmod +x bin/start.sh

# Expose the default JPro port
EXPOSE 8080

# Start the JPro server without the unrecognized --host flags
# It binds to 0.0.0.0 by default in server mode
ENTRYPOINT ["./bin/start.sh"]
