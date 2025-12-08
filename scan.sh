#!/usr/bin/env bash
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

TARGET_FILES=("setup_bun.js" "bun_environment.js")
TARGET_DIRS=(".truffler-cache")

FOUND_FILES=()
FOUND_COUNT=0
FOUND_DIRS=()
FOUND_DIRS_COUNT=0

LOG_FILE="scan_results_$(date +%Y%m%d_%H%M%S).log"

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1" | tee -a "$LOG_FILE"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1" | tee -a "$LOG_FILE"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1" | tee -a "$LOG_FILE"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$LOG_FILE"
}

scan_filesystem() {
    FOUND_COUNT=0
    FOUND_FILES=()
    FOUND_DIRS_COUNT=0
    FOUND_DIRS=()
    
    local search_paths="/"
    
    print_info "Starting filesystem scan..."
    print_info "Searching for files: ${TARGET_FILES[*]}"
    print_info "Searching for directories: ${TARGET_DIRS[*]}"
    print_info "Search paths: $search_paths"
    print_info "Results will be saved to: $LOG_FILE"
    echo ""
    
    local find_args=()
    find_args+=("$search_paths")
    find_args+=("(")
    
    local first_file=true
    for target_file in "${TARGET_FILES[@]}"; do
        if [ "$first_file" = false ]; then
            find_args+=("-o")
        fi
        find_args+=("(" "-type" "f" "-name" "$target_file" ")")
        first_file=false
    done
    
    for target_dir in "${TARGET_DIRS[@]}"; do
        find_args+=("-o")
        find_args+=("(" "-type" "d" "-name" "$target_dir" ")")
    done
    
    find_args+=(")")
    
    print_info "Scanning filesystem..."
    echo "" | tee -a "$LOG_FILE"
    
    while IFS= read -r item; do
        if [ -n "$item" ]; then
            if [ -f "$item" ]; then
                print_success "Found file: $item"
                FOUND_FILES+=("$item")
                FOUND_COUNT=$((FOUND_COUNT + 1))
            elif [ -d "$item" ]; then
                print_success "Found directory: $item"
                FOUND_DIRS+=("$item")
                FOUND_DIRS_COUNT=$((FOUND_DIRS_COUNT + 1))
            fi
        fi
    done < <(find "${find_args[@]}" 2>/dev/null || true)
    
    echo ""
    print_info "Scan complete!"
    print_info "Total files found: $FOUND_COUNT"
    print_info "Total directories found: $FOUND_DIRS_COUNT"
    print_info "Full results saved to: $LOG_FILE"
}

handle_vulnerabilities() {
    local -a vulnerable_files=("$@")
    local has_bun_files=false
    local has_truffler_dirs=false
    
    if [ ${#vulnerable_files[@]} -gt 0 ]; then
        has_bun_files=true
    fi
    
    if [ ${FOUND_DIRS_COUNT} -gt 0 ]; then
        has_truffler_dirs=true
    fi
    
    if [ "$has_bun_files" = false ] && [ "$has_truffler_dirs" = false ]; then
        print_success "No vulnerable files or directories found on this system."
        
        local marker_file="$HOME/.sha1-hulud-null-find-v03.txt"
        echo "SHA-1 Hulud Scan - No vulnerabilities found" > "$marker_file"
        echo "Scan Date: $(date)" >> "$marker_file"
        echo "Hostname: $(hostname)" >> "$marker_file"
        print_info "Created marker file: $marker_file"
        
        return 0
    fi
    
    echo ""
    print_warning "⚠️  VULNERABILITIES DETECTED ⚠️"
    
    if [ "$has_bun_files" = true ]; then
        print_warning "Found ${#vulnerable_files[@]} potentially vulnerable bun file(s)"
        echo "" | tee -a "$LOG_FILE"
        
        print_info "Vulnerable bun files:" | tee -a "$LOG_FILE"
        for file in "${vulnerable_files[@]}"; do
            echo "  - $file" | tee -a "$LOG_FILE"
        done
        
        local marker_file="$HOME/.sha1-hulud-bun-find-v03.txt"
        {
            echo "SHA-1 Hulud Scan - BUN VULNERABILITIES DETECTED"
            echo "Scan Date: $(date)"
            echo "Hostname: $(hostname)"
            echo "Total files found: ${#vulnerable_files[@]}"
            echo ""
            echo "Vulnerable files:"
            for file in "${vulnerable_files[@]}"; do
                echo "  - $file"
            done
        } > "$marker_file"
        print_warning "Created marker file: $marker_file"
    fi
    
    if [ "$has_truffler_dirs" = true ]; then
        echo ""
        print_warning "Found ${FOUND_DIRS_COUNT} truffler-cache director(y/ies)"
        echo "" | tee -a "$LOG_FILE"
        
        print_info "Truffler cache directories:" | tee -a "$LOG_FILE"
        for dir in "${FOUND_DIRS[@]}"; do
            echo "  - $dir" | tee -a "$LOG_FILE"
        done
        
        local marker_file="$HOME/.sha1-hulud-truffler-find-v03.txt"
        {
            echo "SHA-1 Hulud Scan - TRUFFLER VULNERABILITIES DETECTED"
            echo "Scan Date: $(date)"
            echo "Hostname: $(hostname)"
            echo "Total directories found: ${FOUND_DIRS_COUNT}"
            echo ""
            echo "Truffler cache directories:"
            for dir in "${FOUND_DIRS[@]}"; do
                echo "  - $dir"
            done
        } > "$marker_file"
        print_warning "Created marker file: $marker_file"
    fi
    
    echo ""
    print_warning "Action Required:"
    print_info "These files/directories may be associated with the SHA-1 Hulud vulnerability."
    print_info "Please review these items and take appropriate action."
    
    return 1
}

main() {
    echo ""
    print_info "SHA-1 Hulud Vulnerability Scanner"
    print_info "=================================="
    echo ""
    
    scan_filesystem
    
    set +e
    handle_vulnerabilities "${FOUND_FILES[@]+"${FOUND_FILES[@]}"}"
    local exit_code=$?
    set -e
    
    echo ""
    
    exit $exit_code
}

main
