# Command Maker 🛠️

Sistema inteligente para criar e gerenciar comandos personalizados no Zsh.

## 🚀 Instalação

### Via APT (Recomendado)
```bash
# Adicionar repositório
echo "deb [trusted=yes] https://seu-usuario.github.io/command-maker/apt-repo stable main" | sudo tee /etc/apt/sources.list.d/command-maker.list

# Instalar
sudo apt-get update
sudo apt-get install command-maker
```

### Build local
```bash
# Clonar repositório
git clone https://github.com/seu-usuario/command-maker.git
cd command-maker

# Build
make build

# Instalar
make install
```

## 📚 Uso

### Menu interativo
```bash
command-menu
```

### Adicionar comando
```bash
command-add
```

### Listar comandos
```bash
lsa              # Todos
lsa git          # Por namespace
lsa-search docker # Buscar
```

### Editar/Remover
```bash
command-edit gs
command-rm gs
```

## ✨ Recursos

- ✅ Comandos organizados por namespace
- ✅ Documentação integrada
- ✅ Busca avançada
- ✅ Interface interativa
- ✅ Fácil de usar

## 🔧 Desenvolvimento
```bash
make build    # Construir pacote
make repo     # Criar repositório APT
make deploy   # Deploy para GitHub Pages
make clean    # Limpar builds
```

## 📄 Licença

MIT