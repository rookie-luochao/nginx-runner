# Webrunner

Simple webapp runner

# Configuration

## `APP_ROOT`

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

## `ENV` 

be used to replace `__ENV__` in `index.html`

## `PROJECT_VERSION` 

be used to replace `__PROJECT_VERSION__` in `index.html`

## `APP_CONFIG` or `APP_CONFIG__*`

be used to replace `__APP_CONFIG__` in `index.html`

* format: `key1=value1,key2=value2`
* `APP_CONFIG__*` will join to `APP_CONFIG`
* all `APP_CONFIG` will be sub_filter, like `value1` instead of `__key1__`