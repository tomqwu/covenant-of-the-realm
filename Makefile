.DEFAULT_GOAL := help

.PHONY: help setup setup-prototype play stop prototype lint docs-check test test-unit test-integration test-multiplayer-e2e check check-mud check-prototype

help: ## Show available commands
	@awk 'BEGIN {FS = ":.*## "; printf "Usage: make <target>\n\n"} /^[a-zA-Z_-]+:.*## / {printf "  %-24s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

setup: ## Install locked MUD dependencies and prepare a local database
	@./scripts/setup

setup-prototype: ## Install the journey prototype dependencies and browsers
	@cd prototypes/journey && npm ci && npx playwright install chromium firefox webkit

play: ## Start the multiplayer server on loopback ports 4000-4002
	@./scripts/play

stop: ## Stop the local multiplayer server
	@cd mud && uv run --project .. evennia stop

prototype: ## Start the preserved single-player journey study
	@cd prototypes/journey && npm run play

lint: ## Run Python lint and repository documentation checks
	@uv run ruff check mud/commands mud/server/conf mud/typeclasses mud/world tests scripts
	@uv run python scripts/check_docs.py

docs-check: ## Check local Markdown links
	@uv run python scripts/check_docs.py

test: test-unit test-integration test-multiplayer-e2e ## Run multiplayer tests

test-unit: ## Run deterministic rules tests with the 99% branch/statement gate
	@uv run coverage erase
	@uv run coverage run -m pytest tests
	@uv run coverage report

test-integration: ## Run isolated Evennia command and world-construction tests
	@cd mud && uv run --project .. evennia test --settings settings.py world.tests

test-multiplayer-e2e: ## Run a real two-client Telnet journey against a live server
	@./scripts/test_multiplayer_e2e

check-mud: lint test ## Run all multiplayer quality gates

check-prototype: ## Run the preserved journey's full unit/E2E/build evidence suite
	@cd prototypes/journey && make check

check: check-mud check-prototype ## Run every repository quality gate
