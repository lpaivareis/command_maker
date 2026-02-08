# Makefile - Command Maker

.PHONY: all build repo clean install uninstall deploy install-local uninstall-local

VERSION = 1.0.0
PACKAGE = command-maker
SRC_PATH = $(shell pwd)/src/command_maker.sh
INSTALL_PATH = /usr/share/command-maker/command_maker.sh
ZSHRC = $(HOME)/.zshrc
MARKER = \# Command Maker

all: build repo

build:
	@echo "Construindo pacote..."
	@chmod +x build.sh
	@./build.sh

repo:
	@echo "Criando repositorio APT..."
	@chmod +x create-repo.sh
	@./create-repo.sh

clean:
	@echo "Limpando..."
	@rm -rf build dist apt-repo

# Instalacao via pacote .deb (requer sudo)
install: build
	@echo "Instalando pacote .deb..."
	@sudo dpkg -i dist/$(PACKAGE)_$(VERSION).deb
	@echo ""
	@echo "Adicionando ao ~/.zshrc..."
	@if ! grep -q "$(MARKER)" "$(ZSHRC)" 2>/dev/null; then \
		echo "" >> "$(ZSHRC)"; \
		echo "$(MARKER)" >> "$(ZSHRC)"; \
		echo "if [[ -f $(INSTALL_PATH) ]]; then" >> "$(ZSHRC)"; \
		echo "    source $(INSTALL_PATH)" >> "$(ZSHRC)"; \
		echo "fi" >> "$(ZSHRC)"; \
		echo "Referencia adicionada ao ~/.zshrc"; \
	else \
		echo "Referencia ja existe no ~/.zshrc"; \
	fi
	@echo ""
	@echo "Instalacao concluida! Execute: source ~/.zshrc"

uninstall:
	@echo "Desinstalando pacote..."
	@sudo apt-get remove -y $(PACKAGE)
	@echo "Removendo referencia do ~/.zshrc..."
	@sed -i '/$(MARKER)/,/^fi$$/d' "$(ZSHRC)" 2>/dev/null || true
	@echo "Desinstalacao concluida!"

# Instalacao local (sem pacote .deb, apenas source direto)
install-local:
	@echo "Instalando localmente (sem pacote)..."
	@if ! grep -q "$(MARKER)" "$(ZSHRC)" 2>/dev/null; then \
		echo "" >> "$(ZSHRC)"; \
		echo "$(MARKER)" >> "$(ZSHRC)"; \
		echo "if [[ -f $(SRC_PATH) ]]; then" >> "$(ZSHRC)"; \
		echo "    source $(SRC_PATH)" >> "$(ZSHRC)"; \
		echo "fi" >> "$(ZSHRC)"; \
		echo "Referencia adicionada ao ~/.zshrc"; \
	else \
		echo "Referencia ja existe no ~/.zshrc"; \
	fi
	@echo ""
	@echo "Instalacao local concluida! Execute: source ~/.zshrc"

uninstall-local:
	@echo "Removendo instalacao local..."
	@sed -i '/$(MARKER)/,/^fi$$/d' "$(ZSHRC)" 2>/dev/null || true
	@rm -f $(HOME)/.command_maker_meta 2>/dev/null || true
	@echo "Referencia removida do ~/.zshrc"
	@echo "Arquivo de metadata removido"
	@echo "Arquivo de aliases mantido em: ~/.command_maker_aliases"

deploy:
	@echo "Preparando deploy..."
	@git stash
	@git checkout gh-pages
	@rm -rf dists pool index.html
	@git checkout main -- apt-repo
	@cp -r apt-repo/* .
	@rm -rf apt-repo
	@git add .
	@git commit -m "Update repository - v$(VERSION)" || echo "Nada para commitar"
	@git push origin gh-pages
	@git checkout main
	@git stash pop || echo "Nada no stash"
	@echo "Deploy concluido!"

help:
	@echo "Command Maker - Makefile"
	@echo ""
	@echo "Comandos disponiveis:"
	@echo "  make build          - Construir pacote .deb"
	@echo "  make install        - Instalar via .deb e adicionar ao ~/.zshrc"
	@echo "  make uninstall      - Desinstalar pacote e remover do ~/.zshrc"
	@echo "  make install-local  - Instalar apenas adicionando source ao ~/.zshrc"
	@echo "  make uninstall-local- Remover source do ~/.zshrc"
	@echo "  make repo           - Criar repositorio APT"
	@echo "  make deploy         - Deploy para GitHub Pages"
	@echo "  make clean          - Limpar builds"
	@echo "  make help           - Mostrar esta ajuda"
