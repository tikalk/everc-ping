# node.js ms on kubertnetes using build-x on MacOsx

## ⏳ Requirements

- [`docker`](https://docs.docker.com/get-docker/)
- [`docker-compose`](https://docs.docker.com/compose/)

Optional - yet recommanded:

## 🥅 Todays Goal's

Deploy a microservice architecture app using `docker-compose` building for multipulr architectures with buildx

- redis
- api      (./src/api)
- consumer (./src/pinger)
- client   (./src/poller)

### Background on ping appUsing buildx

## Why❓

- Why should I be using this ❓

  Apple is on a roll with its current lineup of M1-based Macs, which now includes the compact Mac mini, the stylish iMac, the silent MacBook Air, and the beastly MacBook Pro.

  Thanks to their ARM architecture, M1-based Macs are extremely power-efficient and offer better performance than many comparable PCs. There’s just one major problem with them: they don’t exactly make it easy to run Linux.

  If you own a mac with M1 and you need images that heven't been built for `macos/arm64` ...
  [Read more here]()

## What❗

- Docker images can support multiple architectures, which means 
  that a single image may contain variants for different architectures, and sometimes for different operating systems, such as Windows.
  
  When running an image with multi-architecture support, docker automatically selects the image variant that matches your OS and architecture.
  
  Most of the Docker Official Images on Docker Hub provide a variety of architectures. For example, the `busybox` image supports `amd64`, `arm32v5`, `arm32v6`, `arm32v7`, `arm64v8`, `i386`, `ppc64le`, and `s390x`. 
  
  When running this image on an x86_64 / amd64 machine, the `amd64` variant is pulled and run.

- This does not require any special configuration in the container itself as it uses `qemu-static` from the Docker for Mac VM.
  Because of this, you can run an ARM container, like the `arm32v7` or `ppc64le` variants of the `busybox` image.

## Buildx by exmaple ❗

> Please note this was executed on MacOs Mnteray 12.3.1 with Apple M1

### setup buildx

`docker buildx ls`  

```sh
NAME/NODE       DRIVER/ENDPOINT STATUS  PLATFORMS
desktop-linux   docker
  desktop-linux desktop-linux   running linux/arm64, linux/amd64, linux/riscv64, linux/ppc64le, linux/s390x, linux/386, linux/arm/v7, linux/arm/v6
default *       docker
  default       default         running linux/arm64, linux/amd64, linux/riscv64, linux/ppc64le, linux/s390x, linux/386, linux/arm/v7, linux/arm/v6
```

Crate your build-x builder - in this case reuse the `default`

```sh
docker buildx create --use default
```

### use buildx to build for `linux/amd64` and `linux/arm64`

Using the same `docker-compose.yml` as foundation sepcifying buildx:

```yml
...
build: 
  context: ./src/api/
  x-bake:
  platforms:
    - linux/amd64
    - linux/arm64
```

The full file:

```sh
cat<<EOF>>docker-compose-buildx.yml
version: "3.2"

volumes:
  redis_data: {}

services:
  redis:
    image: redis
    container_name: redis
    ports:
      - 6379:6379
    command: redis-server --requirepass 'MyS3cr3t'
    volumes:
      - redis_data:/data

  api:
    image: ${DOCKER_REPO:-registry.gitlab.com/tikal-external/academy-public/images}/nodejs-ping:${DOCKER_VERSION:-latest}
    build: 
      context: ./src/api/
      x-bake:
        platforms:
          - linux/amd64
          - linux/arm64
    ports:
      - 8080:8080
    environment:
      NODE_ENV: "docker"
    depends_on:
      - redis

  consumer:
    image: ${DOCKER_REPO:-registry.gitlab.com/tikal-external/academy-public/images}/pinger:${DOCKER_VERSION:-latest}
    build:
      context: ./src/pinger/
      x-bake:
        platforms:
          - linux/amd64
          - linux/arm64
    environment:
      API_URL: http://api:8080
    depends_on:
      - api

  client:
    image: ${DOCKER_REPO:-registry.gitlab.com/tikal-external/academy-public/images}/poller:${DOCKER_VERSION:-latest}
    build:
      context: ./src/poller/
      x-bake:
        platforms:
          - linux/amd64
          - linux/arm64
    environment:
      API_URL: http://api:8080
    depends_on:
      - api

EOF
```

#### Run buildx bake -f `docker-compose-buildx.yml`

Build locally:

```sh

docker buildx bake -f docker-compose-buildx.yml
```

Build & Push with `--push` (requires docker login):

```sh
DOCKER_REPO=<docker-io-username>
docker login 
docker buildx bake -f docker-compose-buildx.yml --push
```

### Check your registry for multipule arch images

```sh
docker buildx imagetools inspect docker.io/hagzag/nodejs-ping
Name:      docker.io/hagzag/nodejs-ping:latest
MediaType: application/vnd.docker.distribution.manifest.list.v2+json
Digest:    sha256:49185ed70fe970384c63623dacd62b095c9b8fb825ae705dc7d8c491c8af83de

Manifests:
  Name:      docker.io/hagzag/nodejs-ping:latest@sha256:50a031db229d1eada57ebacce6cacac4566eb976b2d96a81020c8c109ee5a412
  MediaType: application/vnd.docker.distribution.manifest.v2+json
  Platform:  linux/amd64

  Name:      docker.io/hagzag/nodejs-ping:latest@sha256:350cf6bda5fc335d20c74adb124f3ea3bc9903f04079293a412abc1221cdbfca
  MediaType: application/vnd.docker.distribution.manifest.v2+json
  Platform:  linux/arm64

```

---

⏭️ Running ping-app on kubernetes ...
