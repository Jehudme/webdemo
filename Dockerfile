# --- Stage 1: Build ---
FROM maven:3-eclipse-temurin-25 AS build
WORKDIR /app

# Copy the parent pom and the client module
COPY pom.xml .
COPY webdemo-client/pom.xml ./webdemo-client/
COPY webdemo-client/src ./webdemo-client/src

# Build the project and prepare the JPro distribution
RUN mvn clean install -pl webdemo-client -am
RUN mvn jpro:release -pl webdemo-client

# --- Stage 2: Run ---
FROM eclipse-temurin:25-jre
WORKDIR /app

# Copy the release bundle from the build stage
COPY --from=build /app/webdemo-client/target/jpro/release ./

# Ensure the start script is executable
RUN chmod +x bin/start.sh

# Expose the default JPro port
EXPOSE 8080

# Start the JPro server and bind to 0.0.0.0
ENTRYPOINT ["./bin/start.sh", "--host", "0.0.0.0", "--port", "8080"]