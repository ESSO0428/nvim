SHELL := /bin/bash

LVIM_DATA := $(HOME)/.local/share/lvim
LVIM_STATE := $(HOME)/.local/state/lvim
NVIM_DATA := $(HOME)/.local/share/nvim
NVIM_STATE := $(HOME)/.local/state/nvim

.PHONY: migrate-help migrate-list \
	migrate-sessions migrate-scratch migrate-snacks migrate-bookmarks migrate-shada migrate-undo \
	migrate-all

define copy_dir
	@if [ -d "$(1)" ]; then \
		mkdir -p "$(2)"; \
		cp -a "$(1)"/. "$(2)"/; \
		echo "[copied] $(1) -> $(2)"; \
	else \
		echo "[skip] missing $(1)"; \
	fi
endef

define copy_file
	@if [ -f "$(1)" ]; then \
		mkdir -p "$$(dirname "$(2)")"; \
		cp -f "$(1)" "$(2)"; \
		echo "[copied] $(1) -> $(2)"; \
	else \
		echo "[skip] missing $(1)"; \
	fi
endef

migrate-help:
	@printf '%s\n' \
	  'LunarVim -> Neovim user-data migration targets:' \
	  '  make migrate-sessions   # $(LVIM_DATA)/sessions -> $(NVIM_DATA)/sessions' \
	  '  make migrate-scratch    # $(LVIM_DATA)/scratch -> $(NVIM_DATA)/scratch' \
	  '  make migrate-snacks     # $(LVIM_DATA)/snacks -> $(NVIM_DATA)/snacks' \
	  '  make migrate-bookmarks  # $(LVIM_DATA)/nvim_bookmarks -> $(NVIM_DATA)/nvim_bookmarks' \
	  '  make migrate-shada      # $(LVIM_STATE)/shada/main.shada -> $(NVIM_STATE)/shada/main.shada' \
	  '  make migrate-undo       # $(LVIM_STATE)/undo -> $(NVIM_STATE)/undo' \
	  '  make migrate-all        # run all of the above' \
	  '' \
	  'Behavior:' \
	  '  - overwrite existing Neovim data' \
	  '  - skip missing LunarVim sources' \
	  '  - do not touch plugins/packages (lazy, mason, etc.)'

migrate-list: migrate-help

migrate-sessions:
	$(call copy_dir,$(LVIM_DATA)/sessions,$(NVIM_DATA)/sessions)

migrate-scratch:
	$(call copy_dir,$(LVIM_DATA)/scratch,$(NVIM_DATA)/scratch)

migrate-snacks:
	$(call copy_dir,$(LVIM_DATA)/snacks,$(NVIM_DATA)/snacks)

migrate-bookmarks:
	$(call copy_dir,$(LVIM_DATA)/nvim_bookmarks,$(NVIM_DATA)/nvim_bookmarks)

migrate-shada:
	$(call copy_file,$(LVIM_STATE)/shada/main.shada,$(NVIM_STATE)/shada/main.shada)

migrate-undo:
	$(call copy_dir,$(LVIM_STATE)/undo,$(NVIM_STATE)/undo)

migrate-all: migrate-sessions migrate-scratch migrate-snacks migrate-bookmarks migrate-shada migrate-undo
