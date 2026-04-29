#!/bin/bash

set -euo pipefail

TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$TESTS_DIR/helpers.sh"

test_help_command()
{
    local app_dir output

    # Garante que o comando de help continue listando os subcomandos suportados.
    app_dir="$(make_temp_app)"
    output="$(run_prompt "$app_dir" -h)"
    assert_contains "$output" "Commands:" "help should list commands"
    print_pass "help command"
}

test_invalid_command()
{
    local app_dir output

    # Comando inválido deve falhar com exit 1 e explicar o erro ao usuário.
    app_dir="$(make_temp_app)"
    run_prompt_capture "$app_dir" stat

    output="$(cat "$TEST_STDOUT_FILE")"
    assert_status 1 "$TEST_STATUS" "invalid command should return exit 1"
    assert_contains "$output" "Command not found: stat" "invalid command should explain the failure"
    print_pass "invalid command"
}

test_status_clean_and_dirty()
{
    local app_dir repo_dir output

    # Valida os dois estados básicos do status: repositório limpo e sujo.
    app_dir="$(make_temp_app)"
    repo_dir="$(mktemp -d)"
    init_repo "$repo_dir" main
    printf "dir=%s base=main\n" "$repo_dir" > "$app_dir/config"

    output="$(run_prompt "$app_dir" status)"
    assert_contains "$output" "main - $(basename "$repo_dir")" "clean repo should print current branch"

    echo "dirty" >> "$repo_dir/file.txt"
    output="$(run_prompt "$app_dir" status)"
    assert_contains "$output" "[dirty" "dirty repo should be marked"
    print_pass "status clean and dirty"
}

test_change_local_branch()
{
    local app_dir repo_dir current_branch output

    # "change" deve trocar corretamente para uma branch que já existe localmente.
    app_dir="$(make_temp_app)"
    repo_dir="$(mktemp -d)"
    init_repo "$repo_dir" main
    git -C "$repo_dir" switch -q -c feature/local
    git -C "$repo_dir" switch -q main
    printf "dir=%s base=main\n" "$repo_dir" > "$app_dir/config"

    output="$(run_prompt "$app_dir" change feature/local)"
    current_branch="$(git -C "$repo_dir" branch --show-current)"
    assert_eq "feature/local" "$current_branch" "change should switch to a local branch"
    assert_contains "$output" "feature/local - $(basename "$repo_dir")" "change should print the target branch"
    print_pass "change local branch"
}

test_change_missing_branch_keeps_current()
{
    local app_dir repo_dir current_before current_after output

    # Por decisão de produto, branch inexistente não é erro e não muda a branch atual.
    app_dir="$(make_temp_app)"
    repo_dir="$(mktemp -d)"
    init_repo "$repo_dir" main
    write_config "$app_dir" "dir=$repo_dir base=main"

    current_before="$(git -C "$repo_dir" branch --show-current)"
    run_prompt_capture "$app_dir" change does-not-exist

    current_after="$(git -C "$repo_dir" branch --show-current)"
    output="$(cat "$TEST_STDOUT_FILE")"
    assert_status 0 "$TEST_STATUS" "missing branch should keep the success exit code"
    assert_eq "$current_before" "$current_after" "missing branch should not change the current branch"
    assert_contains "$output" "main - $(basename "$repo_dir")" "missing branch should still print current status"
    print_pass "change missing branch"
}

test_summary_flag()
{
    local app_dir repo_dir output

    # O resumo final é opt-in por comando e deve refletir os contadores da execução.
    app_dir="$(make_temp_app)"
    repo_dir="$(mktemp -d)"
    init_repo "$repo_dir" main
    printf "dir=%s base=main\n" "$repo_dir" > "$app_dir/config"

    output="$(run_prompt "$app_dir" status --summary)"
    assert_contains "$output" "Summary: processed=1 skipped=0 failures=0" "summary flag should print counters"
    print_pass "summary flag"
}

test_non_git_directory_is_ignored()
{
    local app_dir fake_dir output

    # Diretórios que existem mas não são Git devem ser ignorados silenciosamente.
    app_dir="$(make_temp_app)"
    fake_dir="$(mktemp -d)"
    printf "dir=\"%s\" base=main\n" "$fake_dir" > "$app_dir/config"

    output="$(run_prompt "$app_dir" status)"
    assert_eq "" "$output" "non-git directories should be ignored"
    print_pass "non git directory ignored"
}

# Executa a suíte de CLI em uma ordem simples de leitura.
test_help_command
test_invalid_command
test_status_clean_and_dirty
test_change_local_branch
test_change_missing_branch_keeps_current
test_summary_flag
test_non_git_directory_is_ignored
