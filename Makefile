 # 获取当前 Makefile 所在目录
WORKDIR := $(dir $(dir $(abspath $(lastword $(MAKEFILE_LIST)))))

# 构建目标
BUILD_TARGETS := \
  build-kits
PUSH_TARGETS := \
  push-kits
BUILDPUSH_TARGETS := \
  buildpush-kits

# 从构建目标获取的构建信息
%-kits: IMG_NAME ?= kits

# 构建的信息
IMG_REPO_BASE ?= keybrl
IMG_REPO ?= $(IMG_REPO_BASE)/$(IMG_NAME)
IMG_TAG ?= latest
DOCKERFILE ?= dockerfiles/$(IMG_NAME).dockerfile


# 构建镜像
$(BUILD_TARGETS):
	@echo ================ Image Info ================
	@echo Repo: $(IMG_REPO)
	@echo Tag:  $(IMG_TAG)
	@echo ============================================
	cd $(WORKDIR) && docker buildx build \
      --platform linux/arm64 \
      -f "$(DOCKERFILE)" \
      -t "$(IMG_REPO):$(IMG_TAG)-arm64" .
	cd $(WORKDIR) && docker buildx build \
      --platform linux/amd64 \
      -f "$(DOCKERFILE)" \
      -t "$(IMG_REPO):$(IMG_TAG)-amd64" .

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
