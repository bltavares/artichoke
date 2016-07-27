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
