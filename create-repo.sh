#!/bin/bash
# create-repo.sh

set -e

REPO_DIR="apt-repo"
DIST="stable"
COMPONENT="main"
ARCH="all"

echo "Criando repositorio APT..."

# Limpa e cria estrutura
rm -rf "$REPO_DIR"
mkdir -p "$REPO_DIR/pool/main"
mkdir -p "$REPO_DIR/dists/$DIST/$COMPONENT/binary-$ARCH"

# Copia pacote .deb
echo "Copiando pacote..."
cp dist/*.deb "$REPO_DIR/pool/main/"

# Gera arquivo Packages
echo "Gerando Packages..."
cd "$REPO_DIR"

# Gera Packages
dpkg-scanpackages pool/ 2>/dev/null > "dists/$DIST/$COMPONENT/binary-$ARCH/Packages"

gzip -k -f "dists/$DIST/$COMPONENT/binary-$ARCH/Packages"

# Gera Release para o componente
echo "Gerando Release..."
cat > "dists/$DIST/Release" << EOF
Origin: Command Maker
Label: Command Maker
Suite: $DIST
Codename: $DIST
Version: 1.0
Architectures: $ARCH
Components: $COMPONENT
Description: Command Maker APT Repository
EOF

# Gera index.html
cat > index.html << 'EOF'
<!DOCTYPE html>
<html lang="pt-BR">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Command Maker - APT Repository</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: 'Segoe UI', system-ui, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 20px;
        }
        .container {
            background: white;
            border-radius: 20px;
            padding: 50px;
            max-width: 800px;
            box-shadow: 0 20px 60px rgba(0,0,0,0.3);
        }
        h1 { color: #667eea; margin-bottom: 10px; font-size: 2.5em; }
        .subtitle { color: #666; margin-bottom: 30px; font-size: 1.2em; }
        .install-box {
            background: #f7f7f7;
            padding: 20px;
            border-radius: 10px;
            margin: 20px 0;
            border-left: 4px solid #667eea;
        }
        code {
            background: #2d2d2d;
            color: #f8f8f2;
            padding: 15px;
            border-radius: 5px;
            display: block;
            overflow-x: auto;
            font-family: 'Monaco', 'Courier New', monospace;
            margin: 10px 0;
            font-size: 14px;
        }
        .step { margin: 30px 0; }
        .step h3 { color: #764ba2; margin-bottom: 15px; }
        .feature { display: flex; align-items: center; margin: 15px 0; }
        .feature::before {
            content: "✓";
            color: #667eea;
            font-weight: bold;
            font-size: 20px;
            margin-right: 10px;
        }
        a { color: #667eea; text-decoration: none; }
        a:hover { text-decoration: underline; }
    </style>
</head>
<body>
    <div class="container">
        <h1>Command Maker</h1>
        <p class="subtitle">Crie e gerencie aliases para Zsh organizados por namespace</p>

        <div class="step">
            <h3>Instalacao</h3>
            <div class="install-box">
                <p><strong>1. Adicione o repositorio:</strong></p>
                <code>echo "deb [trusted=yes] https://lpaivareis.github.io/command_maker stable main" | sudo tee /etc/apt/sources.list.d/command-maker.list</code>

                <p style="margin-top: 20px;"><strong>2. Instale o pacote:</strong></p>
                <code>sudo apt-get update && sudo apt-get install command-maker</code>
            </div>
        </div>

        <div class="step">
            <h3>Recursos</h3>
            <div class="feature">Aliases organizados por namespace</div>
            <div class="feature">Protecao contra sobrescrita de comandos do sistema</div>
            <div class="feature">Persistencia automatica dos aliases</div>
            <div class="feature">Menu interativo</div>
            <div class="feature">Busca avancada</div>
        </div>

        <div class="step">
            <h3>Comandos</h3>
            <code>cm &lt;ns&gt; &lt;alias&gt; &lt;cmd&gt; &lt;desc&gt;  # Criar alias
cm-add                            # Adicionar interativamente
cm-find                           # Listar aliases
cm-menu                           # Menu interativo</code>
        </div>

        <div class="step">
            <h3>Links</h3>
            <p>
                <a href="https://github.com/lpaivareis/command_maker" target="_blank">GitHub</a> |
                <a href="https://github.com/lpaivareis/command_maker/issues" target="_blank">Issues</a> |
                <a href="https://github.com/lpaivareis/command_maker/blob/main/README.md" target="_blank">Documentacao</a>
            </p>
        </div>
    </div>
</body>
</html>
EOF

cd ..

echo ""
echo "Repositorio APT criado em: $REPO_DIR"
echo ""
echo "Conteudo do Packages:"
cat "$REPO_DIR/dists/$DIST/$COMPONENT/binary-$ARCH/Packages"
echo ""
echo "Para fazer deploy: make deploy"
