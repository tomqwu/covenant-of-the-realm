.DEFAULT_GOAL := help

.PHONY: help setup setup-rpg setup-prototype rpg-import-assets play play-rpg package-rpg play-rpg-package capture-rpg-ui stop prototype lint docs-check rpg-content-check rpg-asset-check test test-unit test-rpg test-rpg-e2e test-rpg-input test-rpg-performance check-rpg-package test-integration test-multiplayer-e2e check check-mud check-rpg check-prototype

help: ## Show available commands
	@awk 'BEGIN {FS = ":.*## "; printf "Usage: make <target>\n\n"} /^[a-zA-Z_-]+:.*## / {printf "  %-24s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

setup: ## Install locked MUD dependencies and prepare a local database
	@./scripts/setup

setup-rpg: ## Resolve the pinned Godot 4.7.1 development runtime
	@./scripts/setup_rpg

rpg-import-assets: ## Import source textures through the pinned Godot editor pipeline
	@./scripts/godot_checked --quiet --editor --headless --path rpg --quit

setup-prototype: ## Install the journey prototype dependencies and browsers
	@cd prototypes/journey && npm ci && npx playwright install chromium firefox webkit

play: ## Start the multiplayer server on loopback ports 4000-4002
	@./scripts/play

play-rpg: ## Open the original single-player RPG graybox
	@./scripts/godot --path rpg

package-rpg: rpg-import-assets ## Export a local Godot pack and SHA-256 provenance manifest into ignored build/rpg
	@./scripts/package_rpg

play-rpg-package: package-rpg ## Build and launch a local pack through the validated export path
	@./scripts/godot --main-pack build/rpg/covenant-of-the-realm.pck

capture-rpg-ui: ## Rebuild the RPG scale test and UI reference screenshots
	@./scripts/godot_checked --path rpg --script res://tools/capture_ui.gd

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

rpg-asset-check: ## Validate RPG pixel dimensions, metadata, and deterministic regeneration
	@uv run python scripts/check_rpg_assets.py
	@./scripts/check_rpg_asset_reproducibility

test: test-unit test-integration test-multiplayer-e2e ## Run multiplayer tests

test-unit: ## Run deterministic rules tests with the 99% branch/statement gate
	@uv run coverage erase
	@uv run coverage run -m pytest tests
	@uv run coverage report

test-rpg: rpg-import-assets ## Run the headless Godot domain and scene tests
	@./scripts/godot_checked --headless --path rpg --script res://tests/test_runner.gd

test-rpg-e2e: rpg-import-assets ## Play the complete Godot chapter path headlessly, including save resume and replay
	@./scripts/godot_checked --headless --path rpg --script res://tests/e2e_runner.gd

test-rpg-input: rpg-import-assets ## Exercise real semantic input events, focus navigation, movement, interaction, and pause
	@./scripts/godot_checked --headless --path rpg --script res://tests/input_runner.gd

test-rpg-performance: rpg-import-assets ## Benchmark deterministic movement, battle resolution, and scene cleanup
	@./scripts/godot_checked --headless --disable-render-loop --fixed-fps 60 --path rpg --script res://tests/performance_runner.gd

check-rpg-package: ## Compare warm and clean-cache PCK exports, then probe and boot the pack
	@./scripts/check_rpg_package

test-integration: ## Run isolated Evennia command and world-construction tests
	@cd mud && uv run --project .. evennia test --settings settings.py world.tests

test-multiplayer-e2e: ## Run a real two-client Telnet journey against a live server
	@./scripts/test_multiplayer_e2e

check-mud: lint test ## Run all multiplayer quality gates

check-rpg: rpg-content-check rpg-asset-check test-rpg test-rpg-e2e test-rpg-input test-rpg-performance check-rpg-package ## Run RPG content, assets, rules, input, performance, full-flow, and package gates

check-prototype: ## Run the preserved journey's full unit/E2E/build evidence suite
	@cd prototypes/journey && make check

check: check-mud check-rpg check-prototype ## Run every repository quality gate
