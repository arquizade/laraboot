PHP_IMAGE=php:8.4-cli
COMPOSER_IMAGE=composer:2
APP_DIR=$(shell pwd)
APP_NAME=$(shell basename $(APP_DIR))

.PHONY: setup start down require stack artisan help check_port dev

setup:
	docker run --rm -v "$(APP_DIR)":/app $(COMPOSER_IMAGE) install --ignore-platform-reqs
	cp .env.example .env
	docker run --rm -v "$(APP_DIR)":/app -w /app $(PHP_IMAGE) php artisan key:generate
	@echo ""
	@echo "Setup complete. Run: make start"

port ?= 80

# Helper to check if port is busy
check_port:
	@if lsof -Pi :$(port) -sTCP:LISTEN -t >/dev/null ; then \
		echo "Error: Port $(port) is already in use by another process."; \
		lsof -Pi :$(port) -sTCP:LISTEN; \
		exit 1; \
	fi

start: check_port
	@echo "Starting in background on http://localhost:$(port)"
	@docker run -d --rm \
		-v "$(APP_DIR)":/app \
		-w /app \
		-p $(port):8000 \
		--name $(APP_NAME) \
		$(PHP_IMAGE) php artisan serve --host=0.0.0.0 --port=8000

dev: check_port
	@echo "Starting in foreground on http://localhost:$(port)"
	@docker run -it --rm \
		-v "$(APP_DIR)":/app \
		-w /app \
		-p $(port):8000 \
		$(PHP_IMAGE) php artisan serve --host=0.0.0.0 --port=8000

stop:
	@echo "Stopping container $(APP_NAME)..."
	docker stop $(APP_NAME)

require:
	@if [ -z "$(package)" ]; then echo "Error: package is required. Usage: make require package=vendor/package"; exit 1; fi
	docker run --rm -v "$(APP_DIR)":/app $(COMPOSER_IMAGE) require $(package) --ignore-platform-reqs

stack:
	@if [ -z "$(name)" ]; then echo "Error: name is required. Usage: make stack name=ai"; exit 1; fi
	@echo "Loading stack: $(name)"
	curl -fsSL https://raw.githubusercontent.com/arquizade/laraboot/main/stacks/$(name).sh | bash -s "$(APP_DIR)"

artisan:
	docker run --rm -v "$(APP_DIR)":/app -w /app $(PHP_IMAGE) php artisan $(filter-out artisan,$(MAKECMDGOALS))

%:
	@:

# Define a variable for the terminal width
WIDTH := $(shell tput cols 2>/dev/null || echo 80)

help:
	@printf '%*s\n' "$(WIDTH)" '' | tr ' ' '-'
	@echo "Laraboot Makefile commands:"
	@printf '%*s\n' "$(WIDTH)" '' | tr ' ' '-'
	@echo ""
	@echo "  make setup                                     install deps, copy .env, generate key"
	@echo "  make dev [port=80]                             start server with logs (foreground)"
	@echo "  make start [port=80]                           start server quietly (background)"
	@echo "  make stop                                      stop running container"
	@echo "  make require package=vendor/package            install a single composer package"
	@echo "  make stack name=ai                             install a predefined stack"
	@echo "  make artisan <command>                         run any artisan command"
	@echo "  make artisan make:controller UserController    run artisan with arguments"
	@echo ""
	@printf '%*s\n' "$(WIDTH)" '' | tr ' ' '-'
