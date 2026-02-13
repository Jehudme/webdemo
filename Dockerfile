# --- Stage 1: Build & Cache ---
FROM maven:3-eclipse-temurin-25 AS build
WORKDIR /app

# 1. Cache dependencies: Copy ONLY pom files first
# This layer is only rebuilt if your pom.xml changes
COPY pom.xml .
COPY webdemo-client/pom.xml ./webdemo-client/

# 2. Download dependencies (The "Reset Cache" point)
# To force a fresh download, build with: docker build --no-cache .
RUN mvn dependency:go-offline -pl webdemo-client -am

# 3. Copy source and compile
COPY webdemo-client/src ./webdemo-client/src
RUN mvn install -pl webdemo-client -am -DskipTests

# --- Stage 2: Run ---
# We use the Maven image again to run the app using 'mvn jpro:run'
FROM maven:3-eclipse-temurin-25
WORKDIR /app

# Copy the project from the build stage
COPY --from=build /app /app

# Expose JPro port
EXPOSE 8080

# --- CRITICAL FIXES ---
# 1. We use ONLY 'CMD' (no ENTRYPOINT) to avoid the /bin/sh error.
# 2. We delete RUNNING_PID at runtime to prevent the "already running" error.
# 3. We use Maven to start the application directly.
CMD rm -f RUNNING_PID webdemo-client/RUNNING_PID && \
    mvn jpro:run -pl webdemo-client -Dhttp.port=8080
