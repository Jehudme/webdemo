# --- Stage 1: Build ---
FROM maven:3-eclipse-temurin-25 AS build
WORKDIR /app
COPY pom.xml .
COPY webdemo-client/pom.xml ./webdemo-client/
RUN mvn dependency:go-offline -pl webdemo-client -am
COPY webdemo-client/src ./webdemo-client/src
RUN mvn install -pl webdemo-client -am -DskipTests

# --- Stage 2: Run ---
FROM maven:3-eclipse-temurin-25
WORKDIR /app

# Install native dependencies for JavaFX/JPro fonts
RUN apt-get update && apt-get install -y \
    libfontconfig1 \
    libpango-1.0-0 \
    libpangoft2-1.0-0 \
    libfreetype6 \
    libglib2.0-0 \
    && rm -rf /var/lib/apt/lists/*

COPY --from=build /app /app

EXPOSE 8080

# Disable browser launch and server visibility for headless Docker
CMD rm -f webdemo-client/RUNNING_PID && \
    mvn jpro:run -pl webdemo-client -Dhttp.port=8080 -DopenURLOnStartup=false -Dvisible=false
