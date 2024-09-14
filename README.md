# Nginx-Runner
简单的 Nginx Docker 容器


# 配置

## Dist目录格式
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


# 支持的环境变量

## 环境变量 `ENV` 
在 `index.html` 中使用 `__ENV__` 进行占位


## 环境变量 `PROJECT_VERSION`
在 `index.html` 中使用 `__PROJECT_VERSION__` 进行占位


## 环境变量 `APP_CONFIG`

* 在 `index.html` 中使用 `__APP_CONFIG__` 进行占位
* `APP_CONFIG` 变量格式: `key1=value1,key2=value2`
* 使用方法：`docker run -d -p 80:80 -e APP_CONFIG=env=zh,appNameZH=简洁美观的接口文档 ghcr.io/rookie-luochao/openapi-ui:latest`
