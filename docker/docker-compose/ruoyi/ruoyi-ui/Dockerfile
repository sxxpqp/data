# 选择一个 Node.js 官方镜像作为基础镜像
FROM node:18 AS build

# 设置工作目录
WORKDIR /app

# 复制 package.json 和 package-lock.json
COPY package*.json ./

# 安装项目依赖
RUN npm install --registry=https://registry.npmmirror.com

# 复制项目文件
COPY . .
RUN chmod +x ./node_modules/.bin/*
# 构建项目
RUN npm run build:prod

# 选择一个轻量级的 nginx 镜像来部署静态文件
FROM nginx:alpine

# 将构建好的静态文件复制到 nginx 容器中的指定目录
COPY --from=build /app/dist /usr/share/nginx/html
COPY ./nginx.conf /etc/nginx/conf.d/default.conf
# 暴露容器的 80 端口
EXPOSE 80

# 启动 nginx 服务
CMD ["nginx", "-g", "daemon off;"]
