# Command Maker

Sistema inteligente para criar e gerenciar aliases personalizados no Zsh, organizados por namespaces.

## Instalacao

### Via APT (Recomendado)

```bash
# Adicionar repositorio
echo "deb [trusted=yes] https://lpaivareis.github.io/command-maker/apt-repo stable main" | sudo tee /etc/apt/sources.list.d/command-maker.list

# Instalar
sudo apt-get update
sudo apt-get install command-maker
```

### Build Local

```bash
# Clonar repositorio
git clone https://github.com/lpaivareis/command-maker.git
cd command-maker

# Build e instalar
make build
make install
```

### Manual (sem pacote)

```bash
# Adicionar ao ~/.zshrc
echo 'source /caminho/para/command_maker.sh' >> ~/.zshrc
source ~/.zshrc
```

## Comandos Disponiveis

| Comando | Descricao |
|---------|-----------|
| `cm` | Criar alias diretamente |
| `cm-add` | Adicionar alias interativamente |
| `cm-find` | Listar todos os aliases |
| `cm-find <namespace>` | Listar aliases de um namespace |
| `cm-find-search <termo>` | Buscar aliases |
| `cm-find-show <alias>` | Ver detalhes de um alias |
| `cm-edit <alias>` | Editar alias existente |
| `cm-rm <alias>` | Remover alias |
| `cm-menu` | Menu interativo |
| `cm-reload` | Recarregar aliases |

## Uso

### Menu Interativo

```bash
cm-menu
```

Abre um menu com todas as opcoes disponiveis.

### Criar Alias Diretamente

```bash
cm <namespace> <alias> <comando> <descricao>
```

Exemplo:
```bash
cm git gs "git status" "Mostra status do repositorio"
cm docker dps "docker ps" "Lista containers em execucao"
cm custom ll "ls -la" "Lista arquivos detalhados"
```

### Criar Alias Interativamente

```bash
cm-add
```

O sistema guia voce pelo processo de criacao.

### Listar Aliases

```bash
# Todos os aliases
cm-find

# Por namespace
cm-find git
cm-find docker

# Buscar por termo
cm-find-search status
```

### Editar e Remover

```bash
# Editar
cm-edit gs

# Remover
cm-rm gs
```

## Validacao de Seguranca

O Command Maker protege contra sobrescrita acidental de comandos do sistema.

### Comandos Protegidos

- Builtins do shell: `cd`, `echo`, `export`, `alias`, etc.
- Comandos essenciais: `ls`, `cp`, `mv`, `rm`, `grep`, etc.
- Ferramentas de desenvolvimento: `git`, `docker`, `npm`, `python`, etc.

### Exemplo de Protecao

```bash
$ cm test ls "ls -la" "Lista arquivos"
ERRO: 'ls' e um comando do sistema e nao pode ser sobrescrito.
      Comandos do sistema sao protegidos para evitar problemas.
      Escolha outro nome para seu alias.

      Sugestoes: ls2, myls, ls_alias
```

### Forcar Sobrescrita (Use com Cuidado)

```bash
cm test ls "ls -la" "Lista arquivos" --force
```

### Validacao de Nomes

Nomes de alias devem:
- Comecar com letra ou `_`
- Conter apenas letras, numeros, `_` e `-`
- Nao conter espacos

## Arquivos de Configuracao

| Arquivo | Descricao |
|---------|-----------|
| `~/.command_maker_meta` | Metadata dos aliases (namespace, descricao) |
| `~/.command_maker_aliases` | Aliases em si (carregado automaticamente) |

### Estrutura do Metadata

```
# namespace|alias|command|description
git|gs|git status|Mostra status do repositorio
docker|dps|docker ps|Lista containers
```

### Estrutura do Arquivo de Aliases

```bash
# Command Maker - Aliases (auto-generated)
alias gs="git status"
alias dps="docker ps"
```

## Namespaces

Namespaces organizam seus aliases por categoria:

```bash
# Criar aliases em diferentes namespaces
cm git gs "git status" "Status do git"
cm git ga "git add ." "Adiciona todos arquivos"
cm docker dps "docker ps" "Lista containers"
cm k8s kgp "kubectl get pods" "Lista pods"

# Listar por namespace
cm-find git      # Mostra apenas aliases do git
cm-find docker   # Mostra apenas aliases do docker
```

## Desenvolvimento

```bash
make build      # Construir pacote .deb
make install    # Instalar localmente
make uninstall  # Desinstalar
make repo       # Criar repositorio APT
make deploy     # Deploy para GitHub Pages
make clean      # Limpar builds
```

### Estrutura do Projeto

```
command_maker/
├── src/
│   ├── command_maker.sh      # Script principal
│   └── default_commands.sh   # Comandos padrao (opcional)
├── DEBIAN/
│   ├── control               # Metadata do pacote
│   ├── postinst              # Script pos-instalacao
│   └── prerm                 # Script pre-remocao
├── build.sh                  # Script de build
├── create-repo.sh            # Criacao do repo APT
├── makefile                  # Automacao
└── README.md                 # Documentacao
```

## Licenca

MIT
