# CPA Uganda: builds the app and runs it. Railway (and most hosts) pick this file up by itself.

# ---- 1. build the jar
FROM maven:3.9-eclipse-temurin-21 AS build
WORKDIR /app
COPY pom.xml .
RUN mvn -B -q dependency:go-offline
COPY src ./src
RUN mvn -B -q -DskipTests package

# ---- 2. run it
FROM eclipse-temurin:21-jre
WORKDIR /app
COPY --from=build /app/target/sacco-manager-1.0.0.jar app.jar

# Uganda time, so the dates on entries and the monthly savings interest (1:30 a.m. on the 1st) follow the local clock
ENV TZ=Africa/Kampala
ENV JAVA_TOOL_OPTIONS="-Duser.timezone=Africa/Kampala -XX:MaxRAMPercentage=75"

# The host gives the port in PORT; the database comes from DB_URL, DB_USER and DB_PASSWORD (see DEPLOY.md)
EXPOSE 8082
CMD ["java", "-jar", "app.jar"]
