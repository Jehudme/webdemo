# --- Stage 1: Build ---
FROM maven:3-eclipse-temurin-25 AS build
WORKDIR /app

# Install unzip to handle the JPro release archive
RUN apt-get update && apt-get install -y unzip

# Copy the parent pom and the client module
COPY pom.xml .
COPY webdemo-client/pom.xml ./webdemo-client/
COPY webdemo-client/src ./webdemo-client/src

# 1. Build the project and install to local repo
RUN mvn clean install -pl webdemo-client -am

# 2. Create the JPro production release (.zip file)
RUN mvn jpro:release -pl webdemo-client

# 3. Unzip the release so we can copy it in the next stage
# The zip is named after the artifactId: webdemo-client-jpro.zip
RUN unzip webdemo-client/target/webdemo-client-jpro.zip -d webdemo-client/target/dist

# --- Stage 2: Run ---
FROM eclipse-temurin:25-jre
WORKDIR /app

# Copy the extracted contents from the build stage
# Note: Unzipping 'webdemo-client-jpro.zip' usually creates a subfolder with the same name
COPY --from=build /app/webdemo-client/target/dist/webdemo-client-jpro ./

# Ensure the start script is executable
RUN chmod +x bin/start.sh

# Expose the default JPro port
EXPOSE 8080

# Start the JPro server
# We bind to 0.0.0.0 so Coolify's proxy can reach the container
ENTRYPOINT ["./bin/start.sh", "--host", "0.0.0.0", "--port", "8080"]