#!/usr/bin/env zsh
# command_maker.sh - Sistema de gerenciamento de comandos documentados

# ============================================
# SISTEMA DE COMANDOS DOCUMENTADOS
# ============================================

# Arquivos de configuracao
COMMANDS_META_FILE=~/.command_maker_meta
COMMANDS_ALIASES_FILE=~/.command_maker_aliases

# Inicializa arquivos se nao existirem
if [[ ! -f "$COMMANDS_META_FILE" ]]; then
    echo "# namespace|alias|command|description" > "$COMMANDS_META_FILE"
fi

if [[ ! -f "$COMMANDS_ALIASES_FILE" ]]; then
    echo "# Command Maker - Aliases (auto-generated)" > "$COMMANDS_ALIASES_FILE"
    echo "# Este arquivo e gerado automaticamente. Nao edite manualmente." >> "$COMMANDS_ALIASES_FILE"
    echo "" >> "$COMMANDS_ALIASES_FILE"
fi

# ============================================
# VALIDACAO DE CONFLITOS
# ============================================

# Lista de comandos protegidos (builtins e comandos criticos)
_CM_PROTECTED_COMMANDS=(
    # Builtins do Zsh/Bash
    "alias" "bg" "bind" "break" "builtin" "caller" "cd" "command" "compgen"
    "complete" "compopt" "continue" "declare" "dirs" "disown" "echo" "enable"
    "eval" "exec" "exit" "export" "false" "fc" "fg" "getopts" "hash" "help"
    "history" "jobs" "kill" "let" "local" "logout" "mapfile" "popd" "printf"
    "pushd" "pwd" "read" "readarray" "readonly" "return" "set" "shift" "shopt"
    "source" "suspend" "test" "times" "trap" "true" "type" "typeset" "ulimit"
    "umask" "unalias" "unset" "wait"
    # Comandos criticos do sistema
    "ls" "cp" "mv" "rm" "mkdir" "rmdir" "touch" "cat" "grep" "find" "sed" "awk"
    "sort" "uniq" "head" "tail" "less" "more" "vi" "vim" "nano" "chmod" "chown"
    "sudo" "su" "apt" "apt-get" "dpkg" "yum" "dnf" "pacman" "brew" "snap"
    "git" "docker" "kubectl" "npm" "node" "python" "python3" "pip" "pip3"
    "make" "gcc" "go" "rust" "cargo" "java" "javac" "ruby" "perl" "php"
    "ssh" "scp" "rsync" "curl" "wget" "tar" "gzip" "gunzip" "zip" "unzip"
    "ps" "top" "htop" "df" "du" "free" "mount" "umount" "fdisk" "lsblk"
    "systemctl" "service" "journalctl" "crontab" "at" "nohup" "screen" "tmux"
    "man" "info" "which" "whereis" "whoami" "who" "w" "id" "groups" "passwd"
    "ping" "netstat" "ss" "ip" "ifconfig" "route" "iptables" "nmap" "nc"
    "date" "cal" "time" "sleep" "watch" "xargs" "tee" "diff" "patch" "file"
    "ln" "stat" "basename" "dirname" "realpath" "mktemp" "yes" "seq" "expr"
    "zsh" "bash" "sh" "dash" "fish" "csh" "tcsh" "ksh"
)

# Verifica se um nome e um comando do sistema
_cm_is_system_command() {
    local name=$1

    # Verifica se esta na lista de comandos protegidos
    for protected in "${_CM_PROTECTED_COMMANDS[@]}"; do
        if [[ "$name" == "$protected" ]]; then
            return 0  # E um comando protegido
        fi
    done

    # Verifica se e um executavel no PATH (ignora aliases e funcoes do command maker)
    if command -v "$name" &>/dev/null; then
        local cmd_type=$(type -w "$name" 2>/dev/null | cut -d: -f2 | tr -d ' ')

        # Se for um comando externo ou builtin, bloqueia
        if [[ "$cmd_type" == "command" ]] || [[ "$cmd_type" == "builtin" ]] || [[ "$cmd_type" == "reserved" ]]; then
            return 0
        fi

        # Se for uma funcao, verifica se e do command maker
        if [[ "$cmd_type" == "function" ]]; then
            # Permite sobrescrever funcoes do proprio command maker
            if [[ "$name" == cm* ]]; then
                return 1  # Permite
            fi
            return 0  # Bloqueia outras funcoes
        fi
    fi

    return 1  # Nao e um comando do sistema
}

# Verifica se ja existe um alias do command maker com esse nome
_cm_is_own_alias() {
    local name=$1
    if [[ -f "$COMMANDS_META_FILE" ]]; then
        grep -q "|${name}|" "$COMMANDS_META_FILE" 2>/dev/null
        return $?
    fi
    return 1
}

# Valida o nome do alias
_cm_validate_alias_name() {
    local name=$1
    local force=${2:-false}

    # Verifica caracteres invalidos
    if [[ ! "$name" =~ ^[a-zA-Z_][a-zA-Z0-9_-]*$ ]]; then
        echo "ERRO: Nome '$name' contem caracteres invalidos."
        echo "      Use apenas letras, numeros, underline e hifen."
        echo "      O nome deve comecar com letra ou underline."
        return 1
    fi

    # Se ja e um alias nosso, permite sobrescrever
    if _cm_is_own_alias "$name"; then
        return 0
    fi

    # Verifica conflito com sistema
    if _cm_is_system_command "$name"; then
        if [[ "$force" == "true" ]]; then
            echo "AVISO: Sobrescrevendo comando do sistema '$name'"
            return 0
        else
            echo "ERRO: '$name' e um comando do sistema e nao pode ser sobrescrito."
            echo "      Comandos do sistema sao protegidos para evitar problemas."
            echo "      Escolha outro nome para seu alias."
            echo ""
            echo "      Sugestoes: ${name}2, my${name}, ${name}_alias"
            return 1
        fi
    fi

    return 0
}

# ============================================
# FUNCAO PRINCIPAL: CRIAR COMANDO
# ============================================

# Funcao para criar comando documentado (renomeada para evitar conflito com builtin)
# Uso: cm <namespace> <alias> <comando> <descricao> [--force]
cm() {
    local namespace=$1
    local name=$2
    local cmd=$3
    local desc=$4
    local force=false

    # Verifica flag --force
    if [[ "$5" == "--force" ]] || [[ "$4" == "--force" ]]; then
        force=true
        if [[ "$4" == "--force" ]]; then
            desc=""
        fi
    fi

    # Validacao de campos obrigatorios
    if [[ -z "$namespace" ]] || [[ -z "$name" ]] || [[ -z "$cmd" ]] || [[ -z "$desc" ]]; then
        echo "Uso: cm <namespace> <alias> <comando> <descricao> [--force]"
        echo ""
        echo "Opcoes:"
        echo "  --force    Permite sobrescrever comandos do sistema (use com cuidado)"
        return 1
    fi

    # Valida o nome do alias
    if ! _cm_validate_alias_name "$name" "$force"; then
        return 1
    fi

    # Cria o alias
    alias "$name"="$cmd"

    # Remove entrada antiga do metadata se existir
    if [[ -f "$COMMANDS_META_FILE" ]]; then
        sed -i "/^${namespace}|${name}|/d" "$COMMANDS_META_FILE"
    fi

    # Remove entrada antiga do arquivo de aliases se existir
    if [[ -f "$COMMANDS_ALIASES_FILE" ]]; then
        sed -i "/^alias ${name}=/d" "$COMMANDS_ALIASES_FILE"
    fi

    # Adiciona metadata
    echo "${namespace}|${name}|${cmd}|${desc}" >> "$COMMANDS_META_FILE"

    # Adiciona ao arquivo de aliases (formato que pode ser sourced)
    echo "alias ${name}=\"${cmd}\"" >> "$COMMANDS_ALIASES_FILE"
}

# ============================================
# FUNCOES DE BUSCA E LISTAGEM
# ============================================

# Lista comandos
cm-find() {
    local namespace=$1

    if [[ ! -f "$COMMANDS_META_FILE" ]]; then
        echo "Nenhum comando documentado encontrado"
        return 1
    fi

    if [[ -z "$namespace" ]]; then
        echo "Todos os comandos documentados:\n"
        awk -F'|' 'NR>1 && NF>=4 {
            printf "  \033[1;36m%-15s\033[0m -> \033[0;90m[%s]\033[0m %s\n", $2, $1, $4
        }' "$COMMANDS_META_FILE" | sort

        echo "\nDica: use 'cm-find <namespace>' para filtrar"
        echo "   Namespaces disponiveis: $(cm-find-namespaces)"
    else
        echo "Comandos do namespace '\033[1;33m${namespace}\033[0m':\n"
        awk -F'|' -v ns="$namespace" 'NR>1 && $1==ns && NF>=4 {
            printf "  \033[1;36m%-15s\033[0m -> %s\n            \033[0;90mComando: %s\033[0m\n\n", $2, $4, $3
        }' "$COMMANDS_META_FILE"
    fi
}

# Lista namespaces disponiveis
cm-find-namespaces() {
    if [[ ! -f "$COMMANDS_META_FILE" ]]; then
        return 1
    fi
    awk -F'|' 'NR>1 && NF>=1 {print $1}' "$COMMANDS_META_FILE" | sort -u | tr '\n' ', ' | sed 's/,$//'
}

# Busca comandos por palavra-chave
cm-find-search() {
    local query=$1

    if [[ -z "$query" ]]; then
        echo "Uso: cm-find-search <palavra-chave>"
        return 1
    fi

    if [[ ! -f "$COMMANDS_META_FILE" ]]; then
        echo "Nenhum comando documentado encontrado"
        return 1
    fi

    echo "Buscando por '\033[1;33m${query}\033[0m':\n"

    local results=$(awk -F'|' -v q="$query" 'NR>1 && tolower($0) ~ tolower(q) && NF>=4 {
        printf "  \033[1;36m%-15s\033[0m -> \033[0;90m[%s]\033[0m %s\n            \033[0;90mComando: %s\033[0m\n\n", $2, $1, $4, $3
    }' "$COMMANDS_META_FILE")

    if [[ -z "$results" ]]; then
        echo "  Nenhum resultado encontrado"
    else
        echo "$results"
    fi
}

# Mostra detalhes de um comando especifico
cm-find-show() {
    local alias_name=$1

    if [[ -z "$alias_name" ]]; then
        echo "Uso: cm-find-show <alias>"
        return 1
    fi

    if [[ ! -f "$COMMANDS_META_FILE" ]]; then
        echo "Nenhum comando documentado encontrado"
        return 1
    fi

    local info=$(awk -F'|' -v a="$alias_name" 'NR>1 && $2==a && NF>=4 {
        printf "Alias: \033[1;36m%s\033[0m\n", $2
        printf "Namespace: \033[1;33m%s\033[0m\n", $1
        printf "Descricao: %s\n", $4
        printf "Comando: \033[0;90m%s\033[0m\n", $3
    }' "$COMMANDS_META_FILE")

    if [[ -z "$info" ]]; then
        echo "Alias '$alias_name' nao encontrado"
    else
        echo "$info"
    fi
}

# ============================================
# FUNCOES DE GERENCIAMENTO
# ============================================

# Remove comando documentado
cm-rm() {
    local alias_name=$1

    if [[ -z "$alias_name" ]]; then
        echo "Uso: cm-rm <alias>"
        return 1
    fi

    if [[ ! -f "$COMMANDS_META_FILE" ]]; then
        echo "Nenhum comando documentado encontrado"
        return 1
    fi

    # Remove do arquivo de metadata
    sed -i "/|${alias_name}|/d" "$COMMANDS_META_FILE"

    # Remove do arquivo de aliases
    if [[ -f "$COMMANDS_ALIASES_FILE" ]]; then
        sed -i "/^alias ${alias_name}=/d" "$COMMANDS_ALIASES_FILE"
    fi

    # Remove o alias da sessao atual
    unalias "$alias_name" 2>/dev/null

    echo "Comando '$alias_name' removido"
}

# ============================================
# ADICIONAR COMANDOS INTERATIVAMENTE
# ============================================

# Adiciona comando de forma interativa
cm-add() {
    echo "========================================"
    echo "       ADICIONAR NOVO COMANDO          "
    echo "========================================"
    echo ""

    # Mostra namespaces existentes
    local existing_ns=$(cm-find-namespaces)
    if [[ -n "$existing_ns" ]]; then
        echo "Namespaces existentes: $existing_ns"
        echo ""
    fi

    # Input: Namespace
    echo -n "Namespace (ex: git, docker, custom): "
    read namespace
    if [[ -z "$namespace" ]]; then
        echo "Namespace e obrigatorio"
        return 1
    fi

    # Input: Nome do alias
    echo -n "Nome do alias (ex: gs, dps): "
    read alias_name
    if [[ -z "$alias_name" ]]; then
        echo "Nome do alias e obrigatorio"
        return 1
    fi

    # Valida caracteres do nome
    if [[ ! "$alias_name" =~ ^[a-zA-Z_][a-zA-Z0-9_-]*$ ]]; then
        echo "ERRO: Nome '$alias_name' contem caracteres invalidos."
        echo "      Use apenas letras, numeros, underline e hifen."
        return 1
    fi

    # Verifica se e um comando do sistema
    if _cm_is_system_command "$alias_name" && ! _cm_is_own_alias "$alias_name"; then
        echo ""
        echo "AVISO: '$alias_name' e um comando do sistema!"
        echo "       Tipo: $(type -w "$alias_name" 2>/dev/null || echo "comando protegido")"
        echo ""
        echo -n "Deseja sobrescrever mesmo assim? (s/N): "
        read confirm
        if [[ ! "$confirm" =~ ^[sS]$ ]]; then
            echo "Cancelado. Sugestoes: ${alias_name}2, my${alias_name}"
            return 1
        fi
        echo "AVISO: Voce optou por sobrescrever um comando do sistema."
    # Verifica se ja e um alias nosso
    elif _cm_is_own_alias "$alias_name"; then
        echo -n "Alias '$alias_name' ja existe no Command Maker. Sobrescrever? (s/N): "
        read confirm
        if [[ ! "$confirm" =~ ^[sS]$ ]]; then
            echo "Cancelado"
            return 1
        fi
    # Verifica se e um alias de outra fonte
    elif alias "$alias_name" &>/dev/null; then
        echo -n "Alias '$alias_name' ja existe. Sobrescrever? (s/N): "
        read confirm
        if [[ ! "$confirm" =~ ^[sS]$ ]]; then
            echo "Cancelado"
            return 1
        fi
    fi

    # Input: Comando
    echo -n "Comando (ex: git status): "
    read cmd
    if [[ -z "$cmd" ]]; then
        echo "Comando e obrigatorio"
        return 1
    fi

    # Input: Descricao
    echo -n "Descricao (ex: Mostra status do git): "
    read description
    if [[ -z "$description" ]]; then
        echo "Descricao e obrigatoria"
        return 1
    fi

    echo ""
    echo "Resumo:"
    echo "  Namespace:   $namespace"
    echo "  Alias:       $alias_name"
    echo "  Comando:     $cmd"
    echo "  Descricao:   $description"
    echo ""
    echo -n "Confirma a criacao? (S/n): "
    read confirm

    if [[ "$confirm" =~ ^[nN]$ ]]; then
        echo "Cancelado"
        return 1
    fi

    # Cria o comando
    cm "$namespace" "$alias_name" "$cmd" "$description"

    echo ""
    echo "Comando '$alias_name' criado com sucesso!"
    echo "O alias ja esta disponivel e sera carregado automaticamente em novos terminais."
}

# Adiciona multiplos comandos em sequencia
cm-add-batch() {
    echo "========================================"
    echo "    ADICIONAR MULTIPLOS COMANDOS       "
    echo "========================================"
    echo ""
    echo "Pressione Ctrl+C para finalizar"
    echo ""

    local count=0
    while true; do
        echo "----------------------------------------"
        cm-add
        count=$((count + 1))
        echo ""
        echo -n "Adicionar outro comando? (S/n): "
        read continue_adding
        if [[ "$continue_adding" =~ ^[nN]$ ]]; then
            break
        fi
        echo ""
    done

    echo ""
    echo "Total de comandos adicionados: $count"
}

# Edita comando existente
cm-edit() {
    local alias_name=$1

    if [[ -z "$alias_name" ]]; then
        echo "Uso: cm-edit <alias>"
        return 1
    fi

    if [[ ! -f "$COMMANDS_META_FILE" ]]; then
        echo "Nenhum comando documentado encontrado"
        return 1
    fi

    # Busca informacoes do comando
    local info=$(awk -F'|' -v a="$alias_name" 'NR>1 && $2==a {print $1"|"$2"|"$3"|"$4}' "$COMMANDS_META_FILE")

    if [[ -z "$info" ]]; then
        echo "Comando '$alias_name' nao encontrado"
        return 1
    fi

    # Parse das informacoes
    local old_namespace=$(echo "$info" | cut -d'|' -f1)
    local old_name=$(echo "$info" | cut -d'|' -f2)
    local old_command=$(echo "$info" | cut -d'|' -f3)
    local old_description=$(echo "$info" | cut -d'|' -f4)

    echo "========================================"
    echo "      EDITAR COMANDO: $alias_name      "
    echo "========================================"
    echo ""
    echo "Valores atuais:"
    echo "  Namespace:   $old_namespace"
    echo "  Alias:       $old_name"
    echo "  Comando:     $old_command"
    echo "  Descricao:   $old_description"
    echo ""
    echo "Pressione Enter para manter o valor atual"
    echo ""

    # Namespace
    echo -n "Namespace [$old_namespace]: "
    read new_namespace
    new_namespace=${new_namespace:-$old_namespace}

    # Nome
    echo -n "Nome do alias [$old_name]: "
    read new_name
    new_name=${new_name:-$old_name}

    # Valida o novo nome se for diferente do antigo
    if [[ "$new_name" != "$old_name" ]]; then
        if [[ ! "$new_name" =~ ^[a-zA-Z_][a-zA-Z0-9_-]*$ ]]; then
            echo "ERRO: Nome '$new_name' contem caracteres invalidos."
            return 1
        fi

        if _cm_is_system_command "$new_name" && ! _cm_is_own_alias "$new_name"; then
            echo ""
            echo "AVISO: '$new_name' e um comando do sistema!"
            echo -n "Deseja usar esse nome mesmo assim? (s/N): "
            read confirm
            if [[ ! "$confirm" =~ ^[sS]$ ]]; then
                echo "Cancelado."
                return 1
            fi
        fi
    fi

    # Comando
    echo -n "Comando [$old_command]: "
    read new_command
    new_command=${new_command:-$old_command}

    # Descricao
    echo -n "Descricao [$old_description]: "
    read new_description
    new_description=${new_description:-$old_description}

    echo ""
    echo "Novos valores:"
    echo "  Namespace:   $new_namespace"
    echo "  Alias:       $new_name"
    echo "  Comando:     $new_command"
    echo "  Descricao:   $new_description"
    echo ""
    echo -n "Confirma a edicao? (S/n): "
    read confirm

    if [[ "$confirm" =~ ^[nN]$ ]]; then
        echo "Cancelado"
        return 1
    fi

    # Remove comando antigo
    cm-rm "$old_name" &>/dev/null

    # Cria novo comando
    cm "$new_namespace" "$new_name" "$new_command" "$new_description"

    echo "Comando atualizado com sucesso!"
}

# ============================================
# MENU INTERATIVO
# ============================================

cm-menu() {
    if [[ ! -f "$COMMANDS_META_FILE" ]]; then
        echo "# namespace|alias|command|description" > "$COMMANDS_META_FILE"
    fi

    echo "========================================"
    echo "        COMMAND MAKER - MENU           "
    echo "========================================"
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
    echo -n "Escolha uma opcao: "
    read option

    case $option in
        1)
            echo ""
            cm-find
            ;;
        2)
            echo ""
            echo -n "Digite o namespace: "
            read ns
            cm-find "$ns"
            ;;
        3)
            echo ""
            echo -n "Digite a busca: "
            read query
            cm-find-search "$query"
            ;;
        4)
            echo ""
            echo -n "Digite o nome do alias: "
            read name
            cm-find-show "$name"
            ;;
        5)
            echo ""
            cm-add
            ;;
        6)
            echo ""
            echo -n "Digite o nome do alias: "
            read name
            cm-edit "$name"
            ;;
        7)
            echo ""
            echo -n "Digite o nome do alias: "
            read name
            cm-rm "$name"
            ;;
        0)
            echo "Ate logo!"
            return 0
            ;;
        *)
            echo "Opcao invalida"
            ;;
    esac

    echo ""
    echo -n "Pressione Enter para continuar..."
    read
    cm-menu
}

# ============================================
# CARREGAMENTO DOS ALIASES
# ============================================

# Carrega todos os aliases salvos
cm-reload() {
    if [[ -f "$COMMANDS_ALIASES_FILE" ]]; then
        source "$COMMANDS_ALIASES_FILE"
        echo "Aliases recarregados de $COMMANDS_ALIASES_FILE"
    fi
}

# Carrega aliases automaticamente ao iniciar
if [[ -f "$COMMANDS_ALIASES_FILE" ]]; then
    source "$COMMANDS_ALIASES_FILE"
fi

echo "Command Maker carregado! Execute 'cm-menu' para comecar."
echo "Comandos: cm, cm-add, cm-find, cm-rm, cm-edit, cm-menu"
