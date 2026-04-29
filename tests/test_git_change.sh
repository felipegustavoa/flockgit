#!/bin/bash

set -euo pipefail

TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$TESTS_DIR/helpers.sh"

test_change_to_remote_branch()
{
    local app_dir base_dir output current_branch upstream_ref

    # Change deve criar e rastrear uma branch que existe apenas no remoto.
    app_dir="$(make_temp_app)"
    base_dir="$(mktemp -d)"
    init_remote_pair "$base_dir" main
    git -C "$base_dir/repo1" switch -q -c feature/remote
    echo "two" >> "$base_dir/repo1/file.txt"
    git -C "$base_dir/repo1" commit -qam remote
    git -C "$base_dir/repo1" push -q -u origin feature/remote
    git -C "$base_dir/repo2" fetch -q origin main
    git -C "$base_dir/repo2" switch -q main
    write_config "$app_dir" "dir=$base_dir/repo2 base=main"

    output="$(run_prompt "$app_dir" change feature/remote)"
    current_branch="$(git -C "$base_dir/repo2" branch --show-current)"
    upstream_ref="$(git -C "$base_dir/repo2" rev-parse --abbrev-ref --symbolic-full-name 'feature/remote@{upstream}')"
    assert_eq "feature/remote" "$current_branch" "change should switch to the remote branch"
    assert_eq "origin/feature/remote" "$upstream_ref" "change should track the discovered remote branch"
    assert_contains "$output" "feature/remote - repo2" "change should print the remote target branch"
    print_pass "change remote branch"
}

test_change_with_non_origin_remote()
{
    local app_dir base_dir output current_branch upstream_ref

    # Change deve funcionar com remotes renomeados, como upstream.
    app_dir="$(make_temp_app)"
    base_dir="$(mktemp -d)"
    init_remote_pair "$base_dir" trunk
    git -C "$base_dir/repo1" remote rename origin upstream
    git -C "$base_dir/repo1" push -q -u upstream trunk
    git -C "$base_dir/repo1" switch -q -c feature/x
    echo "two" >> "$base_dir/repo1/file.txt"
    git -C "$base_dir/repo1" commit -qam feat
    git -C "$base_dir/repo1" push -q -u upstream feature/x

    git -C "$base_dir/repo2" remote rename origin upstream
    git -C "$base_dir/repo2" fetch -q upstream trunk
    git -C "$base_dir/repo2" switch -q -c trunk --track upstream/trunk
    write_config "$app_dir" "dir=$base_dir/repo2 base=trunk"

    output="$(run_prompt "$app_dir" change feature/x)"
    current_branch="$(git -C "$base_dir/repo2" branch --show-current)"
    upstream_ref="$(git -C "$base_dir/repo2" rev-parse --abbrev-ref --symbolic-full-name 'feature/x@{upstream}')"
    assert_eq "feature/x" "$current_branch" "change should switch using non-origin remotes"
    assert_eq "upstream/feature/x" "$upstream_ref" "change should track the non-origin remote branch"
    assert_contains "$output" "feature/x - repo2" "change should print the branch switched from non-origin remote"
    print_pass "change non origin remote"
}

test_change_to_remote_branch
test_change_with_non_origin_remote
