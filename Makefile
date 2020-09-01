CARGO := cargo
CLIPPY_COMMAND := rustup run nightly cargo clippy --release
CLIPPY_ARGS := -Dclippy

default: test

.PHONY: test # Run cargo test
test:
	$(CARGO) test

.PHONY: check-bin # Check the compilation of the binary
check-bin:
	$(CARGO) check --bin artichoke

.PHONY: check-lib # Check the compilation of the library
check-lib:
	$(CARGO) check --lib

.PHONY: check # Quickly validate all binaries compiles
check: | check-lib check-bin

.PHONY: lint-bin # Lints the binary with clippy
lint-bin:
	$(CLIPPY_COMMAND) --bin artichoke -- $(CLIPPY_ARGS)

.PHONY: lint-lib # Lints the libarry with clippy
lint-lib:
	$(CLIPPY_COMMAND) --lib -- $(CLIPPY_ARGS)

.PHONY: lint # Lint all binaries against clippy
lint: | lint-lib lint-bin

.PHONY: outdated # List outdated dependency information
outdated:
	$(CARGO) outdated -R

.PHONY: update # Update dependencies
update:
	$(CARGO) update

.PHONY: install # Installs the project using cargo
install:
	@-$(CARGO) uninstall artichoke
	$(CARGO) install

.PHONY: clean # Cleanup older compilation results
clean:
	$(CARGO) clean

.PHONY: fmt # Formats the source files using rustfmt
fmt:
	$(CARGO) fmt -- --write-mode overwrite

.PHONY: help # Shows the available tasks
help:
	@echo "Available options:"
	@grep '^.PHONY: [^#]\+ #' Makefile | cut -d: -f2- | sed 's/#/-/' | sort


PROJECTS := . ffi
RUST_FILES := $(foreach dir,$(PROJECTS),$(shell find $(dir)/src -name *.rs))

MODE := debug

ifeq ($(MODE),release)
	RUST_FLAGS=--release
endif

FFI_PROJECT := artichoke_ffi
APP_DIR := app
ANDROID_TARGETS := aarch64-linux-android armv7-linux-androideabi x86_64-linux-android i686-linux-android
ANDROID_LIBS := $(foreach target,$(ANDROID_TARGETS),target/$(target)/$(MODE)/lib$(FFI_PROJECT).so)

target/%/$(MODE)/lib$(FFI_PROJECT).so: $(RUST_FILES)
	cross build -p $(FFI_PROJECT) --target $* $(RUST_FLAGS)

android: $(ANDROID_LIBS)
	-cp target/aarch64-linux-android/$(MODE)/lib$(FFI_PROJECT).so \
		$(APP_DIR)/android/app/src/main/jniLibs/arm64-v8a/lib$(FFI_PROJECT).so

	-cp target/armv7-linux-androideabi/$(MODE)/lib$(FFI_PROJECT).so \
		$(APP_DIR)/android/app/src/main/jniLibs/armeabi-v7a/lib$(FFI_PROJECT).so

	-cp target/x86_64-linux-android/$(MODE)/lib$(FFI_PROJECT).so \
		$(APP_DIR)/android/app/src/main/jniLibs/x86_64/lib$(FFI_PROJECT).so

	-cp target/i686-linux-android/$(MODE)/lib$(FFI_PROJECT).so \
		$(APP_DIR)/android/app/src/main/jniLibs/x86/lib$(FFI_PROJECT).so

target/universal/$(MODE)/lib$(FFI_PROJECT).a: $(RUST_FILES)
	cargo lipo $(RUST_FLAGS)

ios: target/universal/$(MODE)/lib$(FFI_PROJECT).a
	-cp $< $(APP_DIR)/ios/libs/lib$(FFI_PROJECT).a

.PHONY: android ios
