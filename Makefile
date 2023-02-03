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
IMG_REPO_BASE ?= keybrl
IMG_REPO ?= $(IMG_REPO_BASE)/$(IMG_NAME)
IMG_TAG ?= latest
ARCHS ?= amd64 arm64

# 构建镜像
$(BUILD_TARGETS):
	@echo ================ Image Info ================
	@echo Repo:      $(IMG_REPO)
	@echo Tag:       $(IMG_TAG)
	@echo Platforms: $(ARCHS)
	@echo ============================================
	for arch in $(ARCHS); do \
      echo "Building image $(IMG_REPO):$(IMG_TAG)-$${arch} for linux/$${arch} platform ..." ; \
      docker buildx build \
        --platform "linux/$${arch}" \
        -t "$(IMG_REPO):$(IMG_TAG)-$${arch}" \
        --target "$(IMG_NAME)" . ; \
    done

# 推送镜像
$(PUSH_TARGETS):
	docker push "$(IMG_REPO):$(IMG_TAG)-arm64"
	docker push "$(IMG_REPO):$(IMG_TAG)-amd64"
	docker manifest create --amend "$(IMG_REPO):$(IMG_TAG)" \
      "$(IMG_REPO):$(IMG_TAG)-arm64" \
      "$(IMG_REPO):$(IMG_TAG)-amd64"
	docker manifest push "$(IMG_REPO):$(IMG_TAG)"

# 构建推送镜像
$(BUILDPUSH_TARGETS): buildpush-%: build-% push-%
