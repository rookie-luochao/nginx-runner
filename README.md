# Nginx-Runner
简单的 Nginx Docker 容器


## Nginx 配置对应的前端项目 Dist 目录格式(构建产物默认需要满足此格式)

```
app/
    __built__/
        xxx.js
        xxx.css
    static/
        xxx.js
        xxx.css
    assets/
        xxx.js
        xxx.css
    sw.js
    favicon.ico
    index.html
```


## 支持的环境变量

### 环境变量 `ENV` 
在 `index.html` 中使用 `__ENV__` 进行占位


### 环境变量 `PROJECT_VERSION`
在 `index.html` 中使用 `__PROJECT_VERSION__` 进行占位


### 环境变量 `APP_CONFIG`

* 在 `index.html` 中使用 `__APP_CONFIG__` 进行占位
* `APP_CONFIG` 变量格式: `key1=value1,key2=value2`
* 使用方法：`docker run -d -p 80:80 -e APP_CONFIG=env=zh,appNameZH=简洁美观的接口文档 ghcr.io/rookie-luochao/openapi-ui:latest`


## 使用方式

### 改造 index.html 文件，加入环境变量占位符

如下代码，包含meta标签：

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <link rel="icon" type="image/svg+xml" href="/logo_mini.svg" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <meta name="env" content="__ENV__" />
    <meta name="app_config" content="__APP_CONFIG__" />
    <title>webapp</title>
  </head>
  <body>
    <div id="root"></div>
    <script type="module" src="/src/index.tsx"></script>
  </body>
</html>
```

### 在项目根目录新建 Dockerfile

如需 pnpm 缓存，使用以下代码：
```dockerfile
# syntax = docker/dockerfile:experimental
FROM --platform=${BUILDPLATFORM:-linux/amd64,linux/arm64} node:20-buster AS builder

ENV PNPM_HOME="/pnpm"
ENV PATH="$PNPM_HOME:$PATH"
RUN corepack enable

WORKDIR /src
COPY ./ /src

RUN --mount=type=cache,target=/src/node_modules,id=myapp_pnpm_module,sharing=locked \
    --mount=type=cache,target=/pnpm/store,id=pnpm_cache \
        pnpm install

RUN --mount=type=cache,target=/src/node_modules,id=myapp_pnpm_module,sharing=locked \
        pnpm run build

FROM --platform=${BUILDPLATFORM:-linux/amd64,linux/arm64} ghcr.io/rookie-luochao/nginx-runner:latest

COPY --from=builder /src/dist /app
```

如果无需 pnpm 缓存，使用以下代码：
```dockerfile
# syntax = docker/dockerfile:experimental
FROM --platform=${BUILDPLATFORM:-linux/amd64,linux/arm64} node:20-buster AS builder

ENV PNPM_HOME="/pnpm"
ENV PATH="$PNPM_HOME:$PATH"
RUN corepack enable

WORKDIR /src
COPY ./ ./

# RUN两次方便观察install和build, 也可以用pnpm cache and locked
RUN pnpm install
RUN npm run build

FROM --platform=${BUILDPLATFORM:-linux/amd64,linux/arm64} ghcr.io/rookie-luochao/nginx-runner:latest

COPY --from=builder /src/dist /app
```

### 打包构建镜像

单架构镜像构建(需要安装 buildx 工具)

```bash
# 本地构建单架构镜
docker build -t myapp:latest .

# 登录 dockerhub
docker login

# 推送镜像到 dockerhub
docker push ydockerhubuser/myapp:latest
```

多架构镜像构建

```bash
# 本地构建多架构镜像但不推送
docker buildx build --platform linux/amd64,linux/arm64 -t myapp:latest --load .

# 本地构建多架构镜像，并且推送 dockerhub
docker buildx build --platform linux/amd64,linux/arm64 -t <your-username>/<image-name>:<tag> --push .
```

### Docker 环境变量注入模式启动

以 `ghcr.io/rookie-luochao/openapi-ui` 为例子进行启动：

```bash
# pull Docker image
docker pull ghcr.io/rookie-luochao/openapi-ui:latest

# start container, nginx reverse proxy custom port, for example: docker run -d -p 8081:80 ghcr.io/rookie-luochao/openapi-ui:latest
docker run -d -p 80:80 -e APP_CONFIG=env=zh,appNameZH=简洁美观的接口文档 ghcr.io/rookie-luochao/openapi-ui:latest
```

### 使用 github-action 构建 docker 镜像

- 项目根目录执行：新建.github文件夹 => 在.github文件夹下面新建workflows文件夹 => 新建 docker-image-ci.yml文件
- 然后贴入一下代码：

```yml
name: Docker Image CI

on:
  push:
    tags:
      - v*

  # 这个选项可以使你手动在 Action tab 页面触发工作流
  workflow_dispatch:

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - name: get version
        id: vars
        run: echo ::set-output name=version::${GITHUB_REF/refs\/tags\/v/}

      - uses: actions/checkout@v4

      - name: set up QEMU
        uses: docker/setup-qemu-action@v3

      - name: set up docker buildx
        uses: docker/setup-buildx-action@v3

      - name: login ghrc hub
        uses: docker/login-action@v3
        with:
          registry: ghcr.io
          username: ${{ github.repository_owner }}
          password: ${{ secrets.GHCR_TOKEN }}

      - name: build and push
        uses: docker/build-push-action@v5
        with:
          push: true
          platforms: linux/amd64,linux/arm64
          tags: |
            ghcr.io/${{ github.repository_owner }}/myapp:${{ steps.vars.outputs.version }}
            ghcr.io/${{ github.repository_owner }}/myapp:latest
```

### 前端获取 Docker 注入的环境变量

前端项目获取 Docker 注入的环境变量，可以参考如下代码：

```ts
import appConfig, { IConfig } from "@/config";

export function getConfig(): IConfig {
  const mateEnv = import.meta.env;
  const defaultAppConfig = {
    appName: mateEnv?.VITE_appName || "",
    appNameZH: mateEnv?.VITE_appNameZH || "",
    baseURL: mateEnv?.VITE_baseURL || "",
    version: mateEnv?.VITE_version || "",
    env: mateEnv?.VITE_env || "",
  };

  // dev mode get env var by src/config.ts file, prod mode get env var by mate, write the mate tag of HTML through docker arg var
  // mate tag name is：app_config, content format is：appName=webapp,baseURL=https://api.com,env=,version=
  if (import.meta.env.DEV) {
    return appConfig;
  } else {
    const appConfigStr = getMeta("app_config");

    if (!appConfigStr) return defaultAppConfig;

    return parseEnvVar(appConfigStr);
  }
}

function getMeta(metaName: string) {
  const metas = document.getElementsByTagName("meta");

  for (let i = 0; i < metas.length; i++) {
    if (metas[i].getAttribute("name") === metaName) {
      return metas[i].getAttribute("content");
    }
  }

  return "";
}

function parseEnvVar(envVarURL: string) {
  const arrs = envVarURL.split(",");

  return arrs.reduce((pre, item) => {
    const keyValues = item.split("=");

    return {
      ...pre,
      [keyValues[0]]: keyValues[1],
    };
  }, {} as IConfig);
}

```