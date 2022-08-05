FROM maven:3.8.6-jdk-11
COPY . .
#RUN chmod +x ./mvnw && ./mvnw -B package
RUN mvn -B package
