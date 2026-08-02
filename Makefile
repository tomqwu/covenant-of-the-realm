.DEFAULT_GOAL := help

.PHONY: help setup setup-rpg setup-prototype rpg-import-assets play play-rpg package-rpg play-rpg-package capture-rpg-ui stop prototype lint docs-check rpg-content-check rpg-asset-check test test-unit test-rpg test-rpg-e2e test-rpg-input check-rpg-package test-integration test-multiplayer-e2e check check-mud check-rpg check-prototype

help: ## Show available commands
	@awk 'BEGIN {FS = ":.*## "; printf "Usage: make <target>\n\n"} /^[a-zA-Z_-]+:.*## / {printf "  %-24s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

setup: ## Install locked MUD dependencies and prepare a local database
	@./scripts/setup

setup-rpg: ## Resolve the pinned Godot 4.7.1 development runtime
	@./scripts/setup_rpg

rpg-import-assets: ## Import source textures through the pinned Godot editor pipeline
	@./scripts/godot --quiet --editor --headless --path rpg --quit

setup-prototype: ## Install the journey prototype dependencies and browsers
	@cd prototypes/journey && npm ci && npx playwright install chromium firefox webkit

play: ## Start the multiplayer server on loopback ports 4000-4002
	@./scripts/play

play-rpg: ## Open the original single-player RPG graybox
	@./scripts/godot --path rpg

package-rpg: rpg-import-assets ## Export a reproducible Godot resource pack into ignored build/rpg
	@mkdir -p build/rpg
	@./scripts/godot --quiet --headless --path rpg --export-pack "Playable Pack" ../build/rpg/covenant-of-the-realm.pck

play-rpg-package: package-rpg ## Build and launch the same resource pack validated by CI
	@./scripts/godot --main-pack build/rpg/covenant-of-the-realm.pck

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
	@uv run python scripts/check_rpg_assets.py

docs-check: ## Check local Markdown links
	@uv run python scripts/check_docs.py

rpg-content-check: ## Validate original RPG story graphs and references
	@uv run python scripts/check_rpg_content.py

rpg-asset-check: ## Validate RPG pixel dimensions, animation layout, and provenance metadata
	@uv run python scripts/check_rpg_assets.py

test: test-unit test-integration test-multiplayer-e2e ## Run multiplayer tests

test-unit: ## Run deterministic rules tests with the 99% branch/statement gate
	@uv run coverage erase
	@uv run coverage run -m pytest tests
	@uv run coverage report

test-rpg: rpg-import-assets ## Run the headless Godot domain and scene tests
	@./scripts/godot --headless --path rpg --script res://tests/test_runner.gd

test-rpg-e2e: rpg-import-assets ## Play the complete Godot chapter path headlessly, including save resume and replay
	@./scripts/godot --headless --path rpg --script res://tests/e2e_runner.gd

test-rpg-input: rpg-import-assets ## Exercise real semantic input events, focus navigation, movement, interaction, and pause
	@./scripts/godot --headless --path rpg --script res://tests/input_runner.gd

check-rpg-package: ## Export the Godot pack twice, compare bytes, and boot it headlessly
	@./scripts/check_rpg_package

test-integration: ## Run isolated Evennia command and world-construction tests
	@cd mud && uv run --project .. evennia test --settings settings.py world.tests

test-multiplayer-e2e: ## Run a real two-client Telnet journey against a live server
	@./scripts/test_multiplayer_e2e

check-mud: lint test ## Run all multiplayer quality gates

check-rpg: rpg-content-check rpg-asset-check test-rpg test-rpg-e2e test-rpg-input check-rpg-package ## Run RPG content, assets, rules, input, full-flow, and package gates

check-prototype: ## Run the preserved journey's full unit/E2E/build evidence suite
	@cd prototypes/journey && make check

check: check-mud check-rpg check-prototype ## Run every repository quality gate
