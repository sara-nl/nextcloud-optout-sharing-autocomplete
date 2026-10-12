# How to build a new release.
1. make a build container
```
docker build -t nextcloud-app-builder .
```

2. Start your container
```
docker run -it -v "$PWD:/app" nextcloud-app-builder /bin/bash
```

3. Build app
```
root@53dad0ccc8a3:/app# npm ci && npm run build
root@53dad0ccc8a3:/app# export RELEASE_VERSION=v1.1.0
root@53dad0ccc8a3:/app# version=$RELEASE_VERSION make -e buildapp
```

The app has no runtime Composer dependencies, so `vendor/` is not part of the release.
Composer is only needed for the development tooling:
```
root@53dad0ccc8a3:/app# composer install
root@53dad0ccc8a3:/app# composer psalm
root@53dad0ccc8a3:/app# composer cs:check
```

4. Extract the tar.gz from build server within your Nextcloud App folder.