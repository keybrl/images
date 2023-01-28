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
ARCH ?= amd64
IMG_TAG ?= latest
DOCKERFILE ?= dockerfiles/$(IMG_NAME).dockerfile


# 构建镜像
$(BUILD_TARGETS):
	@echo ================ Image Info ================
	@echo Repo: $(IMG_REPO)
	@echo Tag:  $(IMG_TAG)
	@echo ============================================
	cd $(WORKDIR) && docker buildx build \
      --platform linux/$(ARCH) \
	  --build-arg "ARCH=$(ARCH)" \
      -f "$(DOCKERFILE)" \
      -t "$(IMG_REPO):$(IMG_TAG)" .

# 推送镜像
$(PUSH_TARGETS):
	docker push "$(IMG_REPO):$(IMG_TAG)"

# 构建推送镜像
$(BUILDPUSH_TARGETS): buildpush-%: build-% push-%
