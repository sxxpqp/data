FROM maven:3.8.6-openjdk-11-slim AS build

# 2. 设置工作目录
WORKDIR /app

# 3. 将本地的 pom.xml 和 src 目录复制到容器内
# COPY pom.xml /app/
# COPY src /app/src
COPY  . .
# 4. 执行 Maven 构建命令
RUN mvn clean package -DskipTests

# 5. 使用轻量级的 JDK 镜像来运行应用
FROM bitnami/java:11

# 6. 设置工作目录
WORKDIR /app


# COPY ./target/ruoyi-admin.jar /app/ruoyi-admin.jar
# 7. 将打包好的 JAR 文件从 build 镜像中复制到当前镜像中
COPY --from=build /app/ruoyi-admin/target/ruoyi-admin.jar /app/ruoyi-admin.jar
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "/app/ruoyi-admin.jar"]
