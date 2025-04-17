# Build stage
FROM maven:3.9.6-eclipse-temurin-21 AS build
WORKDIR /app
COPY frontend/pom.xml .
COPY frontend/src ./src
RUN mvn clean package -DskipTests

# Run stage
FROM eclipse-temurin:21-jre-alpine
WORKDIR /app
COPY --from=build /app/target/*.jar app.jar

# Install JavaFX dependencies
RUN apk add --no-cache openjfx

EXPOSE 3000
CMD ["java", "-jar", "app.jar"] 