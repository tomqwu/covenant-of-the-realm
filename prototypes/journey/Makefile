.DEFAULT_GOAL := help

.PHONY: help setup play check lint test

help: ## Show available commands
	@awk 'BEGIN {FS = ":.*## "; printf "Usage: make <target>\n\n"} /^[a-zA-Z_-]+:.*## / {printf "  %-10s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

setup: ## Install or resolve dependencies for the detected runtime
	@./scripts/setup

play: ## Build, serve, and open the production game locally
	@npm run play

check: ## Run every non-mutating repository check
	@./scripts/check all

lint: ## Run formatting, lint, and type checks
	@./scripts/check lint

test: ## Run tests
	@./scripts/check test
