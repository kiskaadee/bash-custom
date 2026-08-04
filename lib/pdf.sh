dep_check "lib/pdf.sh" "qpdf" || return 1

# 1. pdf_dc: Decrypts a password-protected PDF document using qpdf.
pdf_dc() {
    # Usage: pdf_dc <input.pdf> [password]
    local input_file="$1"
    local password="$2"

    local nix_secret="/run/secrets/pdf_decrypt_password"
    local user_secret="$HOME/.config/secrets/pdf_decrypt_password"
    local env_file="$HOME/Secrets/.env"

    # Auto-load password from secrets if none provided
    if [[ -z "$password" ]]; then
        if [[ -f "$nix_secret" ]]; then
            password=$(cat "$nix_secret")
        elif [[ -f "$user_secret" ]]; then
            password=$(cat "$user_secret")
        elif [[ -f "$env_file" ]]; then
            local defpass
            defpass=$(grep "^defpass=" "$env_file" 2>/dev/null | cut -d'=' -f2- | tr -d '"' | tr -d "'")
            password="${defpass}"
        fi
    fi

    if [[ -z "$password" ]]; then
        echo "Error: No password provided and default secret not found" >&2
        return 1
    fi

    if [[ ! -f "$input_file" ]]; then
        echo "Error: Input file '$input_file' not found" >&2
        return 1
    fi

    local output_file="${input_file%.pdf}_decrypted.pdf"

    if [[ -f "$output_file" ]]; then
        echo "Error: Output file '$output_file' already exists."
        read -r -p "Do you want to overwrite it? (y/n): " overwrite
        if [[ "$overwrite" != "y" ]]; then
            echo "Operation cancelled."
            return 1
        fi
    fi

    echo "Decrypting $input_file..."
    if qpdf --password="$password" --decrypt "$input_file" "$output_file"; then
        echo "✅ Decryption successful: $output_file"
    else
        local exit_code=$?
        echo "❌ Decryption failed (qpdf exit code: $exit_code)"
        return $exit_code
    fi
}

