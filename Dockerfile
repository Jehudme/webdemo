# --- Stage 1: Build ---
FROM maven:3-eclipse-temurin-25 AS build
WORKDIR /app
RUN apt-get update && apt-get install -y unzip

# 1. Copy ONLY the pom files first (ROOT and CLIENT)
COPY pom.xml .
COPY webdemo-client/pom.xml ./webdemo-client/

# 2. Download dependencies (This layer is cached unless a POM changes)
# 'dependency:go-offline' prepares the repo without needing source code
RUN mvn dependency:go-offline -pl webdemo-client -am

# 3. NOW copy the source code (This will invalidate cache only for these steps)
COPY webdemo-client/src ./webdemo-client/src

# 4. Build and Package (Uses the dependencies already in the cached layer)
RUN mvn clean install -pl webdemo-client -am && \
    mvn jpro:release -pl webdemo-client && \
    unzip webdemo-client/target/webdemo-client-jpro.zip -d webdemo-client/target/dist

# --- Stage 2: Run ---
FROM eclipse-temurin:25-jre
WORKDIR /app
COPY --from=build /app/webdemo-client/target/dist/webdemo-client-jpro ./
RUN chmod +x bin/start.sh
EXPOSE 8080
ENTRYPOINT ["./bin/start.sh", "--host", "0.0.0.0", "--port", "8080"]