#!/bin/bash
# build.sh

set -e

VERSION="1.0.0"
PACKAGE_NAME="command-maker"
BUILD_DIR="build"
DEB_DIR="$BUILD_DIR/${PACKAGE_NAME}_${VERSION}"

echo "╔════════════════════════════════════════════════════════════╗"
echo "║         📦 Building ${PACKAGE_NAME} v${VERSION}                 "
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Limpa builds anteriores
echo "🧹 Limpando builds anteriores..."
rm -rf "$BUILD_DIR" dist
mkdir -p "$BUILD_DIR"

# Cria estrutura de diretórios
echo "📁 Criando estrutura..."
mkdir -p "$DEB_DIR/DEBIAN"
mkdir -p "$DEB_DIR/usr/share/command-maker"

# Copia arquivos
echo "📄 Copiando arquivos..."
cp -r DEBIAN/* "$DEB_DIR/DEBIAN/"
cp src/command_maker.sh "$DEB_DIR/usr/share/command-maker/"
cp src/default_commands.sh "$DEB_DIR/usr/share/command-maker/"

# Define permissões
echo "🔐 Configurando permissões..."
chmod 755 "$DEB_DIR/DEBIAN/postinst"
chmod 755 "$DEB_DIR/DEBIAN/prerm"
chmod 644 "$DEB_DIR/usr/share/command-maker/"*

# Calcula tamanho instalado
INSTALLED_SIZE=$(du -sk "$DEB_DIR/usr" | cut -f1)
echo "Installed-Size: $INSTALLED_SIZE" >> "$DEB_DIR/DEBIAN/control"

# Constrói o pacote
echo "🔨 Construindo pacote .deb..."
dpkg-deb --build "$DEB_DIR"

# Move para diretório de saída
echo "📦 Movendo para dist/..."
mkdir -p dist
mv "${BUILD_DIR}/${PACKAGE_NAME}_${VERSION}.deb" "dist/"

echo ""
echo "✅ Pacote criado: dist/${PACKAGE_NAME}_${VERSION}.deb"
echo ""
echo "📦 Para testar localmente:"
echo "   make install"
echo ""
echo "🗑️  Para remover:"
echo "   make uninstall"