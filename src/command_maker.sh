#!/bin/bash
# command_maker.sh - Sistema de gerenciamento de comandos documentados

# ============================================
# 🏷️  SISTEMA DE COMANDOS DOCUMENTADOS
# ============================================

# Arquivo de metadata
COMMANDS_META_FILE=~/.command_maker_meta

# Inicializa arquivo de metadata se não existir
if [ ! -f "$COMMANDS_META_FILE" ]; then
    echo "# namespace|alias|command|description" > "$COMMANDS_META_FILE"
fi

# Função para criar comando documentado
command() {
    local namespace=$1
    local name=$2
    local cmd=$3
    local desc=$4
    
    # Validação
    if [ -z "$namespace" ] || [ -z "$name" ] || [ -z "$cmd" ] || [ -z "$desc" ]; then
        echo "❌ Uso: command <namespace> <alias> <comando> <descrição>"
        return 1
    fi
    
    # Cria o alias
    alias $name="$cmd"
    
    # Remove entrada antiga se existir
    if [ -f "$COMMANDS_META_FILE" ]; then
        sed -i.bak "/^${namespace}|${name}|/d" "$COMMANDS_META_FILE"
    fi
    
    # Adiciona metadata
    echo "${namespace}|${name}|${cmd}|${desc}" >> "$COMMANDS_META_FILE"
}

# Lista comandos
lsa() {
    local namespace=$1
    
    if [ ! -f "$COMMANDS_META_FILE" ]; then
        echo "❌ Nenhum comando documentado encontrado"
        return 1
    fi
    
    if [ -z "$namespace" ]; then
        echo "📋 Todos os comandos documentados:\n"
        awk -F'|' 'NR>1 {
            printf "  \033[1;36m%-15s\033[0m → \033[0;90m[%s]\033[0m %s\n", $2, $1, $4
        }' "$COMMANDS_META_FILE" | sort
        
        echo "\n💡 Dica: use 'lsa <namespace>' para filtrar"
        echo "   Namespaces disponíveis: $(lsa-namespaces)"
    else
        echo "📋 Comandos do namespace '\033[1;33m${namespace}\033[0m':\n"
        awk -F'|' -v ns="$namespace" 'NR>1 && $1==ns {
            printf "  \033[1;36m%-15s\033[0m → %s\n            \033[0;90mComando: %s\033[0m\n\n", $2, $4, $3
        }' "$COMMANDS_META_FILE"
    fi
}

# Lista namespaces disponíveis
lsa-namespaces() {
    if [ ! -f "$COMMANDS_META_FILE" ]; then
        return 1
    fi
    awk -F'|' 'NR>1 {print $1}' "$COMMANDS_META_FILE" | sort -u | tr '\n' ', ' | sed 's/,$//'
}

# Busca comandos por palavra-chave
lsa-search() {
    local query=$1
    
    if [ -z "$query" ]; then
        echo "❌ Uso: lsa-search <palavra-chave>"
        return 1
    fi
    
    if [ ! -f "$COMMANDS_META_FILE" ]; then
        echo "❌ Nenhum comando documentado encontrado"
        return 1
    fi
    
    echo "🔍 Buscando por '\033[1;33m${query}\033[0m':\n"
    
    local results=$(awk -F'|' -v q="$query" 'NR>1 && tolower($0) ~ tolower(q) {
        printf "  \033[1;36m%-15s\033[0m → \033[0;90m[%s]\033[0m %s\n            \033[0;90mComando: %s\033[0m\n\n", $2, $1, $4, $3
    }' "$COMMANDS_META_FILE")
    
    if [ -z "$results" ]; then
        echo "  ❌ Nenhum resultado encontrado"
    else
        echo "$results"
    fi
}

# Mostra detalhes de um comando específico
lsa-show() {
    local alias_name=$1
    
    if [ -z "$alias_name" ]; then
        echo "❌ Uso: lsa-show <alias>"
        return 1
    fi
    
    if [ ! -f "$COMMANDS_META_FILE" ]; then
        echo "❌ Nenhum comando documentado encontrado"
        return 1
    fi
    
    local info=$(awk -F'|' -v a="$alias_name" 'NR>1 && $2==a {
        printf "📌 Alias: \033[1;36m%s\033[0m\n", $2
        printf "🏷️  Namespace: \033[1;33m%s\033[0m\n", $1
        printf "📝 Descrição: %s\n", $4
        printf "⚙️  Comando: \033[0;90m%s\033[0m\n", $3
    }' "$COMMANDS_META_FILE")
    
    if [ -z "$info" ]; then
        echo "❌ Alias '$alias_name' não encontrado"
    else
        echo "$info"
    fi
}

# Remove comando documentado
command-rm() {
    local alias_name=$1
    
    if [ -z "$alias_name" ]; then
        echo "❌ Uso: command-rm <alias>"
        return 1
    fi
    
    if [ ! -f "$COMMANDS_META_FILE" ]; then
        echo "❌ Nenhum comando documentado encontrado"
        return 1
    fi
    
    # Remove do arquivo
    sed -i.bak "/|${alias_name}|/d" "$COMMANDS_META_FILE"
    
    # Remove o alias
    unalias "$alias_name" 2>/dev/null
    
    echo "✅ Comando '$alias_name' removido"
}

# ============================================
# ➕ ADICIONAR COMANDOS INTERATIVAMENTE
# ============================================

# Adiciona comando de forma interativa
command-add() {
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║           ➕ ADICIONAR NOVO COMANDO                        ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo ""
    
    # Mostra namespaces existentes
    local existing_ns=$(lsa-namespaces)
    if [ ! -z "$existing_ns" ]; then
        echo "📂 Namespaces existentes: $existing_ns"
        echo ""
    fi
    
    # Input: Namespace
    echo -n "🏷️  Namespace (ex: git, docker, custom): "
    read namespace
    if [ -z "$namespace" ]; then
        echo "❌ Namespace é obrigatório"
        return 1
    fi
    
    # Input: Nome do alias
    echo -n "📝 Nome do alias (ex: gs, dps): "
    read alias_name
    if [ -z "$alias_name" ]; then
        echo "❌ Nome do alias é obrigatório"
        return 1
    fi
    
    # Verifica se alias já existe
    if alias "$alias_name" &>/dev/null; then
        echo "⚠️  Alias '$alias_name' já existe. Deseja sobrescrever? (s/N): "
        read confirm
        if [[ ! "$confirm" =~ ^[sS]$ ]]; then
            echo "❌ Cancelado"
            return 1
        fi
    fi
    
    # Input: Comando
    echo -n "⚙️  Comando (ex: git status): "
    read cmd
    if [ -z "$cmd" ]; then
        echo "❌ Comando é obrigatório"
        return 1
    fi
    
    # Input: Descrição
    echo -n "💬 Descrição (ex: Mostra status do git): "
    read description
    if [ -z "$description" ]; then
        echo "❌ Descrição é obrigatória"
        return 1
    fi
    
    echo ""
    echo "📋 Resumo:"
    echo "  Namespace:   $namespace"
    echo "  Alias:       $alias_name"
    echo "  Comando:     $cmd"
    echo "  Descrição:   $description"
    echo ""
    echo -n "✅ Confirma a criação? (S/n): "
    read confirm
    
    if [[ "$confirm" =~ ^[nN]$ ]]; then
        echo "❌ Cancelado"
        return 1
    fi
    
    # Cria o comando
    command "$namespace" "$alias_name" "$cmd" "$description"
    
    echo ""
    echo "✅ Comando '$alias_name' criado com sucesso!"
    echo "💡 Para tornar permanente, adicione ao ~/.zshrc:"
    echo ""
    echo "   command $namespace $alias_name \"$cmd\" \"$description\""
    echo ""
    
    # Oferece adicionar ao arquivo
    echo -n "📝 Deseja adicionar automaticamente ao ~/.zshrc? (s/N): "
    read add_to_file
    
    if [[ "$add_to_file" =~ ^[sS]$ ]]; then
        # Adiciona ao final da seção de comandos
        echo "" >> ~/.zshrc
        echo "command $namespace $alias_name \"$cmd\" \"$description\"" >> ~/.zshrc
        echo "✅ Adicionado ao ~/.zshrc"
        echo "💡 Execute 'source ~/.zshrc' para recarregar"
    fi
}

# Adiciona múltiplos comandos em sequência
command-add-batch() {
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║        ➕ ADICIONAR MÚLTIPLOS COMANDOS                     ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo ""
    echo "💡 Pressione Ctrl+C para finalizar"
    echo ""
    
    local count=0
    while true; do
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        command-add
        count=$((count + 1))
        echo ""
        echo -n "➕ Adicionar outro comando? (S/n): "
        read continue
        if [[ "$continue" =~ ^[nN]$ ]]; then
            break
        fi
        echo ""
    done
    
    echo ""
    echo "✅ Total de comandos adicionados: $count"
}

# Edita comando existente
command-edit() {
    local alias_name=$1
    
    if [ -z "$alias_name" ]; then
        echo "❌ Uso: command-edit <alias>"
        return 1
    fi
    
    if [ ! -f "$COMMANDS_META_FILE" ]; then
        echo "❌ Nenhum comando documentado encontrado"
        return 1
    fi
    
    # Busca informações do comando
    local info=$(awk -F'|' -v a="$alias_name" 'NR>1 && $2==a {print $1"|"$2"|"$3"|"$4}' "$COMMANDS_META_FILE")
    
    if [ -z "$info" ]; then
        echo "❌ Comando '$alias_name' não encontrado"
        return 1
    fi
    
    # Parse das informações
    local old_namespace=$(echo "$info" | cut -d'|' -f1)
    local old_name=$(echo "$info" | cut -d'|' -f2)
    local old_command=$(echo "$info" | cut -d'|' -f3)
    local old_description=$(echo "$info" | cut -d'|' -f4)
    
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║              ✏️  EDITAR COMANDO: $alias_name                  "
    echo "╚════════════════════════════════════════════════════════════╝"
    echo ""
    echo "📋 Valores atuais:"
    echo "  Namespace:   $old_namespace"
    echo "  Alias:       $old_name"
    echo "  Comando:     $old_command"
    echo "  Descrição:   $old_description"
    echo ""
    echo "💡 Pressione Enter para manter o valor atual"
    echo ""
    
    # Namespace
    echo -n "🏷️  Namespace [$old_namespace]: "
    read new_namespace
    new_namespace=${new_namespace:-$old_namespace}
    
    # Nome
    echo -n "📝 Nome do alias [$old_name]: "
    read new_name
    new_name=${new_name:-$old_name}
    
    # Comando
    echo -n "⚙️  Comando [$old_command]: "
    read new_command
    new_command=${new_command:-$old_command}
    
    # Descrição
    echo -n "💬 Descrição [$old_description]: "
    read new_description
    new_description=${new_description:-$old_description}
    
    echo ""
    echo "📋 Novos valores:"
    echo "  Namespace:   $new_namespace"
    echo "  Alias:       $new_name"
    echo "  Comando:     $new_command"
    echo "  Descrição:   $new_description"
    echo ""
    echo -n "✅ Confirma a edição? (S/n): "
    read confirm
    
    if [[ "$confirm" =~ ^[nN]$ ]]; then
        echo "❌ Cancelado"
        return 1
    fi
    
    # Remove comando antigo
    command-rm "$old_name" &>/dev/null
    
    # Cria novo comando
    command "$new_namespace" "$new_name" "$new_command" "$new_description"
    
    echo "✅ Comando atualizado com sucesso!"
    echo "💡 Lembre-se de atualizar também no ~/.zshrc manualmente"
}

# Lista comandos de forma interativa para seleção
command-menu() {
    if [ ! -f "$COMMANDS_META_FILE" ]; then
        # Cria arquivo se não existir
        echo "# namespace|alias|command|description" > "$COMMANDS_META_FILE"
    fi
    
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║              📋 COMMAND MAKER - MENU                       ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo ""
    echo "1. Listar todos os comandos"
    echo "2. Listar por namespace"
    echo "3. Buscar comando"
    echo "4. Ver detalhes de comando"
    echo "5. Adicionar novo comando"
    echo "6. Editar comando"
    echo "7. Remover comando"
    echo "0. Sair"
    echo ""
    echo -n "Escolha uma opção: "
    read option
    
    case $option in
        1)
            echo ""
            lsa
            ;;
        2)
            echo ""
            echo -n "Digite o namespace: "
            read ns
            lsa "$ns"
            ;;
        3)
            echo ""
            echo -n "Digite a busca: "
            read query
            lsa-search "$query"
            ;;
        4)
            echo ""
            echo -n "Digite o nome do alias: "
            read name
            lsa-show "$name"
            ;;
        5)
            echo ""
            command-add
            ;;
        6)
            echo ""
            echo -n "Digite o nome do alias: "
            read name
            command-edit "$name"
            ;;
        7)
            echo ""
            echo -n "Digite o nome do alias: "
            read name
            command-rm "$name"
            ;;
        0)
            echo "👋 Até logo!"
            return 0
            ;;
        *)
            echo "❌ Opção inválida"
            ;;
    esac
    
    echo ""
    echo -n "Pressione Enter para continuar..."
    read
    command-menu
}

echo "✅ Command Maker carregado! Execute 'command-menu' para começar."