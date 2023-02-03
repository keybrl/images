# 构建目标
BUILD_TARGETS := \
  build-kits \
  build-devkits \
  build-devkits-gui
PUSH_TARGETS := \
  push-kits \
  push-devkits \
  push-devkits-gui
BUILDPUSH_TARGETS := \
  buildpush-kits \
  buildpush-devkits \
  buildpush-devkits-gui

# 从构建目标获取的构建信息
%-kits: IMG_NAME ?= kits
%-devkits: IMG_NAME ?= devkits
%-devkits-gui: IMG_NAME ?= devkits-gui

# 构建的信息
IMG_REPO_BASE ?= docker.io/keybrl
IMG_REPO ?= $(IMG_REPO_BASE)/$(IMG_NAME)
IMG_TAG ?= latest
ARCHS ?= amd64 arm64
BUILD_ARCH ?= $(shell docker version -f json | jq '.Server.Arch' -r)
EXTRA_DOCKER_BUILD_ARGS ?=

.PHONY: build-all push-all buildpush-all
build-all: $(BUILD_TARGETS)
push-all: $(PUSH_TARGETS)
buildpush-all: $(BUILDPUSH_TARGETS)

# 构建镜像
.PHONY: $(BUILD_TARGETS)
$(BUILD_TARGETS):
	@echo ================ Image Info ================
	@echo Repo: $(IMG_REPO)
	@echo Tag:  $(IMG_TAG)
	@echo Archs:      $(ARCHS)
	@echo Build Arch: $(BUILD_ARCH)
	@echo ============================================
	for arch in $(ARCHS); do \
      echo "Building image $(IMG_REPO):$(IMG_TAG)-$${arch} for linux/$${arch} platform ..." ; \
      docker buildx build \
        --platform "linux/$${arch}" \
        -t "$(IMG_REPO):$(IMG_TAG)-$${arch}" \
        $(EXTRA_DOCKER_BUILD_ARGS) \
        --target "$(IMG_NAME)" . || exit $$? ; \
      if [ "$${arch}" = "$(BUILD_ARCH)" ]; then \
        docker tag "$(IMG_REPO):$(IMG_TAG)-$${arch}" "$(IMG_REPO):$(IMG_TAG)" ; \
      fi ; \
    done

# 推送镜像
.PHONY: $(PUSH_TARGETS)
$(PUSH_TARGETS):
	for arch in $(ARCHS); do \
      echo "Pushing image $(IMG_REPO):$(IMG_TAG)-$${arch} for linux/$${arch} platform ..." ; \
      docker push "$(IMG_REPO):$(IMG_TAG)-$${arch}" ; \
      img_tags="$${img_tags} $(IMG_REPO):$(IMG_TAG)-$${arch}" ; \
    done && \
    docker manifest create --amend "$(IMG_REPO):$(IMG_TAG)" $${img_tags}
	@echo "Pushing manifest list of the image $(IMG_REPO):$(IMG_TAG) ..."
	docker manifest push "$(IMG_REPO):$(IMG_TAG)"

# 构建推送镜像
.PHONY: $(BUILDPUSH_TARGETS)
$(BUILDPUSH_TARGETS): buildpush-%: build-% push-%
