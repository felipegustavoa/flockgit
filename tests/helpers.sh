#!/bin/bash

set -euo pipefail

TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$TESTS_DIR/.." && pwd)"
RED=$'\e[31m'
GREEN=$'\e[32m'
RESET=$'\e[0m'

fail()
{
    printf "%sFAIL:%s %s\n" "$RED" "$RESET" "$1" >&2
    exit 1
}

assert_eq()
{
    local expected="$1"
    local actual="$2"
    local message="$3"

    [[ "$expected" == "$actual" ]] || fail "$message (expected: '$expected', actual: '$actual')"
}

assert_contains()
{
    local haystack="$1"
    local needle="$2"
    local message="$3"

    [[ "$haystack" == *"$needle"* ]] || fail "$message (missing: '$needle')"
}

assert_file_contains()
{
    local file="$1"
    local needle="$2"
    local message="$3"

    grep -Fq "$needle" "$file" || fail "$message (missing: '$needle' in $file)"
}

assert_status()
{
    local expected="$1"
    local actual="$2"
    local message="$3"

    [[ "$expected" -eq "$actual" ]] || fail "$message (expected status: '$expected', actual: '$actual')"
}

make_temp_app()
{
    local tmp_dir

    # Cada suíte trabalha sobre uma cópia isolada do projeto para evitar efeitos colaterais.
    tmp_dir="$(mktemp -d)"
    cp -R "$PROJECT_ROOT" "$tmp_dir/app"
    printf "%s\n" "$tmp_dir/app"
}

init_repo()
{
    local repo_dir="$1"
    local branch_name="${2:-main}"

    git init -q "$repo_dir"
    git -C "$repo_dir" config user.name tester
    git -C "$repo_dir" config user.email tester@example.com
    echo "one" > "$repo_dir/file.txt"
    git -C "$repo_dir" add file.txt
    git -C "$repo_dir" commit -q -m init
    git -C "$repo_dir" branch -M "$branch_name"
}

init_remote_pair()
{
    local base_dir="$1"
    local branch_name="${2:-main}"

    # Cria um remoto bare e dois clones para testar sync/change em cenários reais de Git.
    git init -q --bare "$base_dir/remote.git"
    git clone -q "$base_dir/remote.git" "$base_dir/repo1" >/dev/null 2>&1 || true
    git -C "$base_dir/repo1" config user.name tester
    git -C "$base_dir/repo1" config user.email tester@example.com
    echo "one" > "$base_dir/repo1/file.txt"
    git -C "$base_dir/repo1" add file.txt
    git -C "$base_dir/repo1" commit -q -m init
    git -C "$base_dir/repo1" branch -M "$branch_name"
    git -C "$base_dir/repo1" push -q -u origin "$branch_name"

    git clone -q "$base_dir/remote.git" "$base_dir/repo2" >/dev/null 2>&1 || true
    git -C "$base_dir/repo2" config user.name tester
    git -C "$base_dir/repo2" config user.email tester@example.com
}

run_prompt()
{
    local app_dir="$1"
    shift

    bash "$app_dir/prompt.sh" "$@"
}

run_prompt_capture()
{
    local app_dir="$1"
    shift

    # Mantém stdout, stderr e status separados para asserts mais específicos.
    TEST_STDOUT_FILE="$(mktemp)"
    TEST_STDERR_FILE="$(mktemp)"

    if bash "$app_dir/prompt.sh" "$@" >"$TEST_STDOUT_FILE" 2>"$TEST_STDERR_FILE"; then
        TEST_STATUS=0
    else
        TEST_STATUS=$?
    fi
}

write_config()
{
    local app_dir="$1"
    shift

    printf "%s\n" "$@" > "$app_dir/config"
}

print_pass()
{
    printf "%sPASS:%s %s\n" "$GREEN" "$RESET" "$1"
}
