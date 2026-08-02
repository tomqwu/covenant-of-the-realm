.DEFAULT_GOAL := help

.PHONY: help setup setup-rpg setup-prototype play play-rpg capture-rpg-ui stop prototype lint docs-check rpg-content-check test test-unit test-rpg test-integration test-multiplayer-e2e check check-mud check-rpg check-prototype

help: ## Show available commands
	@awk 'BEGIN {FS = ":.*## "; printf "Usage: make <target>\n\n"} /^[a-zA-Z_-]+:.*## / {printf "  %-24s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

setup: ## Install locked MUD dependencies and prepare a local database
	@./scripts/setup

setup-rpg: ## Resolve the pinned Godot 4.7.1 development runtime
	@./scripts/setup_rpg

setup-prototype: ## Install the journey prototype dependencies and browsers
	@cd prototypes/journey && npm ci && npx playwright install chromium firefox webkit

play: ## Start the multiplayer server on loopback ports 4000-4002
	@./scripts/play

play-rpg: ## Open the original single-player RPG graybox
	@./scripts/godot --path rpg

capture-rpg-ui: ## Rebuild the RPG scale test and four UI reference screenshots
	@./scripts/godot --path rpg --script res://tools/capture_ui.gd

stop: ## Stop the local multiplayer server
	@cd mud && uv run --project .. evennia stop

prototype: ## Start the preserved single-player journey study
	@cd prototypes/journey && npm run play

lint: ## Run Python lint and repository documentation checks
	@uv run ruff check mud/commands mud/server/conf mud/typeclasses mud/world tests scripts
	@uv run python scripts/check_docs.py
	@uv run python scripts/check_rpg_content.py

docs-check: ## Check local Markdown links
	@uv run python scripts/check_docs.py

rpg-content-check: ## Validate original RPG story graphs and references
	@uv run python scripts/check_rpg_content.py

test: test-unit test-integration test-multiplayer-e2e ## Run multiplayer tests

test-unit: ## Run deterministic rules tests with the 99% branch/statement gate
	@uv run coverage erase
	@uv run coverage run -m pytest tests
	@uv run coverage report

test-rpg: ## Run the headless Godot domain and scene tests
	@./scripts/godot --headless --path rpg --script res://tests/test_runner.gd

test-integration: ## Run isolated Evennia command and world-construction tests
	@cd mud && uv run --project .. evennia test --settings settings.py world.tests

test-multiplayer-e2e: ## Run a real two-client Telnet journey against a live server
	@./scripts/test_multiplayer_e2e

check-mud: lint test ## Run all multiplayer quality gates

check-rpg: rpg-content-check test-rpg ## Run RPG content, rules, and scene gates

check-prototype: ## Run the preserved journey's full unit/E2E/build evidence suite
	@cd prototypes/journey && make check

check: check-mud check-rpg check-prototype ## Run every repository quality gate
