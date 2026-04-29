#!/bin/bash

set -euo pipefail

TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$TESTS_DIR/helpers.sh"

test_config_accepts_inline_comment()
{
    local app_dir repo_dir output

    # Comentários no fim da linha não devem invalidar a entrada do config.
    app_dir="$(make_temp_app)"
    repo_dir="$(mktemp -d)"
    init_repo "$repo_dir" main
    write_config "$app_dir" "dir=$repo_dir base=main # repo principal"

    output="$(run_prompt "$app_dir" status)"
    assert_contains "$output" "main - $(basename "$repo_dir")" "inline comments should be ignored"
    print_pass "config inline comment"
}

test_config_accepts_quoted_path()
{
    local app_dir root_dir repo_dir output

    # Caminhos com espaço entre aspas devem ser aceitos pelo parser.
    app_dir="$(make_temp_app)"
    root_dir="$(mktemp -d)"
    repo_dir="$root_dir/repo com espaco"
    init_repo "$repo_dir" main
    write_config "$app_dir" "dir=\"$repo_dir\" base=main"

    output="$(run_prompt "$app_dir" status)"
    assert_contains "$output" "main - $(basename "$repo_dir")" "quoted paths should be parsed correctly"
    print_pass "config quoted path"
}

test_config_rejects_unknown_key()
{
    local app_dir stderr_output

    # Chaves desconhecidas devem falhar com mensagem clara.
    app_dir="$(make_temp_app)"
    write_config "$app_dir" "dir=/tmp bass=main"

    run_prompt_capture "$app_dir" status
    stderr_output="$(cat "$TEST_STDERR_FILE")"
    assert_status 1 "$TEST_STATUS" "unknown keys should fail config validation"
    assert_contains "$stderr_output" "Unknown key: bass" "unknown key should be reported"
    print_pass "config unknown key"
}

test_config_requires_valid_entries()
{
    local app_dir stderr_output

    # Um config sem nenhuma entrada válida deve impedir a execução.
    app_dir="$(make_temp_app)"
    write_config "$app_dir" "# vazio" "" "foo=bar"

    run_prompt_capture "$app_dir" status
    stderr_output="$(cat "$TEST_STDERR_FILE")"
    assert_status 1 "$TEST_STATUS" "config without valid entries should fail"
    assert_contains "$stderr_output" "Configuration file with no repositories defined" "missing valid entries should be reported"
    print_pass "config requires valid entries"
}

test_config_accepts_inline_comment
test_config_accepts_quoted_path
test_config_rejects_unknown_key
test_config_requires_valid_entries
