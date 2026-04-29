#!/bin/bash

set -euo pipefail

TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$TESTS_DIR/helpers.sh"

test_update_with_upstream()
{
    local app_dir base_dir output last_commit

    # Update deve fazer pull da branch atual quando houver upstream configurado.
    app_dir="$(make_temp_app)"
    base_dir="$(mktemp -d)"
    init_remote_pair "$base_dir" main
    echo "two" >> "$base_dir/repo1/file.txt"
    git -C "$base_dir/repo1" commit -qam second
    git -C "$base_dir/repo1" push -q
    write_config "$app_dir" "dir=$base_dir/repo2 base=main"

    output="$(run_prompt "$app_dir" update)"
    last_commit="$(git -C "$base_dir/repo2" log --oneline -1)"
    assert_contains "$output" "main - repo2" "update should print the repo status after pull"
    assert_contains "$last_commit" "second" "update should bring the latest upstream commit"
    print_pass "update with upstream"
}

test_update_without_upstream()
{
    local app_dir repo_dir output

    # Repositório sem upstream não deve falhar nem tentar inventar um remote.
    app_dir="$(make_temp_app)"
    repo_dir="$(mktemp -d)"
    init_repo "$repo_dir" main
    write_config "$app_dir" "dir=$repo_dir base=main"

    output="$(run_prompt "$app_dir" update)"
    assert_contains "$output" "[no-remote]" "update without upstream should keep the no-remote state"
    print_pass "update without upstream"
}

test_update_with_non_origin_remote()
{
    local app_dir base_dir output upstream_ref

    # Update não pode depender do remote se chamar origin.
    app_dir="$(make_temp_app)"
    base_dir="$(mktemp -d)"
    init_remote_pair "$base_dir" trunk
    git -C "$base_dir/repo2" remote rename origin upstream
    git -C "$base_dir/repo2" fetch -q upstream trunk
    git -C "$base_dir/repo2" switch -q -c trunk --track upstream/trunk
    write_config "$app_dir" "dir=$base_dir/repo2 base=trunk"

    output="$(run_prompt "$app_dir" update)"
    upstream_ref="$(git -C "$base_dir/repo2" rev-parse --abbrev-ref --symbolic-full-name 'trunk@{upstream}')"
    assert_contains "$output" "trunk - repo2" "update should run normally with non-origin remotes"
    assert_eq "upstream/trunk" "$upstream_ref" "update should preserve the configured upstream"
    print_pass "update with non origin remote"
}

test_update_with_upstream
test_update_without_upstream
test_update_with_non_origin_remote
