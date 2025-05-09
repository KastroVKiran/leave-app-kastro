FROM maven:3.9.6-eclipse-temurin-17-alpine AS build
WORKDIR /app
COPY pom.xml .
COPY src ./src
RUN mvn clean package -DskipTests

FROM eclipse-temurin:17-jre-alpine
WORKDIR /app
COPY --from=build /app/target/*.jar app.jar

# Add wait-for-it script for better container startup coordination
RUN apk add --no-cache bash
COPY wait-for-it.sh /wait-for-it.sh
RUN sed -i 's/\r$//' /wait-for-it.sh && chmod +x /wait-for-it.sh

EXPOSE 8090

# Health check
HEALTHCHECK --interval=30s --timeout=3s \
  CMD wget --no-verbose --tries=1 --spider http://localhost:8090/actuator/health || exit 1

ENTRYPOINT ["bash", "/wait-for-it.sh", "mysql:3306", "--timeout=60", "--", "java", "-jar", "app.jar"]
