# Makefile (ajustado)

.PHONY: all build repo clean install uninstall deploy

VERSION = 1.0.0
PACKAGE = command-maker

all: build repo

build:
	@echo "🔨 Construindo pacote..."
	@chmod +x build.sh
	@./build.sh

repo:
	@echo "🏗️  Criando repositório APT..."
	@chmod +x create-repo.sh
	@./create-repo.sh

clean:
	@echo "🧹 Limpando..."
	@rm -rf build dist apt-repo

install:
	@echo "📦 Instalando localmente..."
	@sudo dpkg -i dist/$(PACKAGE)_$(VERSION)_all.deb

uninstall:
	@echo "🗑️  Desinstalando..."
	@sudo apt-get remove $(PACKAGE)

deploy:
	@echo "📤 Preparando deploy..."
	@# Salva branch atual
	@git stash
	@# Muda para gh-pages
	@git checkout gh-pages
	@# Remove arquivos antigos do repo
	@rm -rf dists pool index.html
	@# Copia novos arquivos
	@git checkout main -- apt-repo
	@cp -r apt-repo/* .
	@rm -rf apt-repo
	@# Commit e push
	@git add .
	@git commit -m "Update repository - v$(VERSION)" || echo "Nada para commitar"
	@git push origin gh-pages
	@# Volta para main
	@git checkout main
	@git stash pop || echo "Nada no stash"
	@echo "✅ Deploy concluído!"
	@echo "🌐 Repositório disponível em: https://seu-usuario.github.io/command-maker/"