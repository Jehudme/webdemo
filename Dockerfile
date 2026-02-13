# --- Stage 1: Build ---
# Update to a JDK 25 image
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
# Update to a JRE 25 image
FROM eclipse-temurin:25-jre
WORKDIR /app

# Copy the release bundle from the build stage
COPY --from=build /app/webdemo-client/target/jpro/release ./

# Expose the default JPro port
EXPOSE 8080

# Start the JPro server
ENTRYPOINT ["./bin/start.sh"]