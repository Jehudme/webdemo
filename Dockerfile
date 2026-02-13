# --- Stage 1: Dependency Cache ---
# We use a dedicated stage to download dependencies.
# This layer stays cached as long as your pom.xml files don't change.
FROM maven:3-eclipse-temurin-25 AS deps
WORKDIR /app
COPY pom.xml .
COPY webdemo-client/pom.xml webdemo-client/
RUN mvn dependency:go-offline -pl webdemo-client -am

# --- Stage 2: Application Builder ---
# This stage compiles the code and creates the JPro standalone distribution.
FROM deps AS builder
COPY webdemo-client/src webdemo-client/src
RUN mvn install -pl webdemo-client -am -DskipTests && \
    mvn jpro:release -pl webdemo-client

# --- Stage 3: Extraction ---
# Use a lightweight stage to unzip the release so the final image remains clean.
FROM alpine:latest AS extractor
RUN apk add --no-cache unzip
COPY --from=builder /app/webdemo-client/target/webdemo-client-jpro.zip /tmp/
RUN unzip /tmp/webdemo-client-jpro.zip -d /app

# --- Stage 4: Production Runtime ---
# This is the final image. It contains NO Maven and is optimized for production.
FROM eclipse-temurin:25-jre-noble
WORKDIR /app

# 1. Install required native libraries for JPro/JavaFX font rendering.
# This prevents the 'UnsatisfiedLinkError' for libpango.
RUN apt-get update && apt-get install -y --no-install-recommends \
    libfontconfig1 \
    libpango-1.0-0 \
    libpangoft2-1.0-0 \
    libfreetype6 \
    libglib2.0-0 \
    && rm -rf /var/lib/apt/lists/*

# 2. Copy the standalone distribution from the extractor stage.
COPY --from=extractor /app/webdemo-client-jpro ./

# 3. Security: Create and use a non-root user.
RUN groupadd -r jpro && useradd -r -g jpro jpro && \
    chown -R jpro:jpro /app
USER jpro

# 4. Networking: Expose the standard JPro port.
EXPOSE 8080

# 5. Professional Startup:
# - Clear the stale lock file to prevent "already running" errors.
# - Launch using the optimized JPro start script (not Maven).
CMD ["/bin/sh", "-c", "rm -f RUNNING_PID && ./bin/start.sh"]