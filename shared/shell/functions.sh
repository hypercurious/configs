# Shared shell functions (POSIX-compatible; sourced by bash and zsh on any OS).

# Copy stdin to the system clipboard, whatever the platform provides.
clipcopy() {
    if command -v pbcopy >/dev/null 2>&1; then
        pbcopy
    elif command -v wl-copy >/dev/null 2>&1; then
        wl-copy
    elif command -v xclip >/dev/null 2>&1; then
        xclip -selection clipboard
    elif command -v clip.exe >/dev/null 2>&1; then
        clip.exe
    else
        cat
    fi
}

# mkdir + cd
mkcd() {
    mkdir -p "$1" && cd "$1" || return 1
}

# Find the main application pod for the current Kubernetes namespace and put a
# ready-to-use `kubectl exec` command on the clipboard.
#
# Namespaces rarely share a name with their main deployment, so the mapping is
# site-specific: set KPOD_SERVICE_MAP in ~/.shell.local as a comma-separated
# list of <namespace-substring>:<service> pairs, e.g.
#
#   KPOD_SERVICE_MAP='api:api-server,web:web-frontend'
#
# The first pair whose substring appears in the namespace wins. Namespaces that
# match nothing fall back to using the namespace as the service name.
kpod() {
    namespace=$(kubectl config view --minify -o jsonpath='{..namespace}')

    if [ -z "$namespace" ]; then
        echo "No namespace set in the current kubectl context"
        return 1
    fi

    # Walk the map with parameter expansion only: word splitting differs
    # between sh, bash and zsh, so avoid relying on it.
    service=""
    rest=${KPOD_SERVICE_MAP:-}
    while [ -n "$rest" ]; do
        pair=${rest%%,*}
        case "$rest" in
            *,*) rest=${rest#*,} ;;
            *)   rest="" ;;
        esac

        [ -n "$pair" ] || continue
        substring=${pair%%:*}
        # The variable is quoted inside the pattern so it is matched as a
        # literal substring; zsh would not treat it as a glob anyway.
        case "$namespace" in
            *"$substring"*)
                service=${pair#*:}
                break
                ;;
        esac
    done
    [ -n "$service" ] || service="$namespace"

    pod=$(kubectl get pods \
        --field-selector=status.phase=Running \
        --sort-by=.metadata.creationTimestamp \
        -o custom-columns=NAME:.metadata.name \
        --no-headers \
        | grep -E "^${service}-[a-z0-9]+-[a-z0-9]+$" \
        | tail -n 1)

    if [ -z "$pod" ]; then
        echo "No running pod found for service '$service' in namespace '$namespace'"
        return 1
    fi

    exec_cmd="kubectl exec -it $pod -- "
    echo "$exec_cmd"
    printf "%s" "$exec_cmd" | clipcopy
}
