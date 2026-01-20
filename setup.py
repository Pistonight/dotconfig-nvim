# std data path is: vim.fn.stdpath("data")
#  - Linux: ~/.local/share/nvim
#  - Windows: %LOCALAPPDATA%\nvim-data (~\AppData\Local\nvim-data)
# std config path is: vim.fn.stdpath("config")
#  - Linux: ~/.config/nvim
#  - Windows: %LOCALAPPDATA%\nvim (~\AppData\Local\nvim)

# data paths:
# STD_DATA/
# - lazy/lazy.nvim        # Lazy.nvim package manager
# - mason/                # Mason LSP package manager
# - piston/               # Data referenced by this (my) config
#   - aicoder/            # AI Coding Diffs
#   - undodir/            # VIM Undo Dir
#   - .yank               # Temporary Host Yank File
#
# config paths:
# STD_CONFIG/
# - setup.py              # This file
# - init.lua              # Config Entry Point
# .. (TODO)
#
"""
Usage: setup.py [command]

Commands:
  nuke            Nuke existing configurations and everything you installed
  apply           Apply updated configurations
  merge PART      Merge configurations of PART
    PART: [claudecode]
  repack          Pack local configurations for update
"""

import json
import os
import shutil
import subprocess
import sys

def main():
    commands = {
        "nuke": nuke,
        "apply": apply,
        "merge": merge,
        "repack": repack,
    }

    if len(sys.argv) < 2:
        usage()
        sys.exit(1)

    command = sys.argv[1]

    if command in ("-h", "--help"):
        usage()
        sys.exit(0)

    if command not in commands:
        print(f"Unknown command: {command}")
        usage()
        sys.exit(1)

    commands[command]()

# === COMMANDS =================================================================

def nuke():
    """Nuke existing configurations."""
    # TODO: Implement nuke command
    print("nuke: not implemented")


def apply():
    """Apply updated configurations."""
    info = read_info()
    data_path = get_std_data_path()

    for rel_path in info["shaft"]["data-paths"]:
        dir_path = os.path.join(data_path, rel_path)
        if not os.path.isdir(dir_path):
            os.makedirs(dir_path)
            print(f"created: {dir_path}")

    lazy = info["lazy"]
    lazy_path = os.path.join(data_path, lazy["data-path"])
    checkout_repo(lazy_path, lazy["repo"], lazy["tag"], False, None)


def merge():
    """Merge configurations of a part."""
    if len(sys.argv) < 3:
        print("merge: missing PART argument")
        usage()
        sys.exit(1)
    part = sys.argv[2]
    merge_funcs = {
        "claudecode": merge_claudecode,
    }
    if part not in merge_funcs:
        print(f"merge: unknown part '{part}'")
        sys.exit(1)
    merge_funcs[part]()


def merge_claudecode():
    """Merge claudecode configurations."""
    info = read_info()
    claude = info["claude"]

    data_path = get_std_data_path()
    config_path = get_std_config_path()

    repo_path = os.path.join(data_path, claude["data-path"])
    patch_path = os.path.join(config_path, claude["patch"])
    base_commit = claude["commit"]

    if not os.path.isdir(repo_path):
        print(f"merge claudecode: repo not found at {repo_path}")
        sys.exit(1)

    if is_worktree_dirty(repo_path):
        print(f"merge claudecode: dirty worktree at {repo_path}")
        sys.exit(1)

    result = subprocess.run(
        ["git", "-C", repo_path, "diff", base_commit, "HEAD"],
        capture_output=True,
        text=True,
        check=True,
    )

    with open(patch_path, "w") as f:
        f.write(result.stdout)

    print(f"patch written to {patch_path}")


def repack():
    """Pack local configurations for update."""
    info = read_info()
    claude = info["claude"]

    data_path = get_std_data_path()
    config_path = get_std_config_path()

    repo_path = os.path.join(data_path, claude["data-path"])
    local_path = os.path.join(config_path, claude["config-path"])
    patch_path = os.path.join(config_path, claude["patch"])
    base_commit = claude["commit"]
    sparse_paths = claude["sparse"]

    if not os.path.isdir(local_path):
        print(f"repack: local config not found at {local_path}")
        sys.exit(1)

    # Set up the repo with sparse checkout and shallow clone
    checkout_repo(repo_path, claude["repo"], base_commit, True, sparse_paths)

    # Replace each sparse path in the repo with the local config version
    for sparse_path in sparse_paths:
        # Remove trailing slash if present for path operations
        sparse_dir = sparse_path.rstrip("/")

        repo_sparse_path = os.path.join(repo_path, sparse_dir)
        local_sparse_path = os.path.join(local_path, sparse_dir)

        if not os.path.exists(local_sparse_path):
            print(f"repack: local path not found: {local_sparse_path}")
            continue

        # Delete the directory in the repo
        if os.path.exists(repo_sparse_path):
            rmdir(repo_sparse_path)

        # Copy the local version to the repo
        shutil.copytree(local_sparse_path, repo_sparse_path)
        print(f"copied: {local_sparse_path} -> {repo_sparse_path}")

    # Generate diff from the dirty working tree
    result = subprocess.run(
        ["git", "-C", repo_path, "diff"],
        capture_output=True,
        text=True,
        check=True,
    )

    if not result.stdout.strip():
        print("repack: no changes detected")
        return

    # Write the patch
    write_patch(patch_path, result.stdout)
    print(f"repack: patch written to {patch_path}")

    # Restore the work tree
    restore_work_tree(repo_path)


def usage():
    """Print usage information."""
    print((__doc__ or "").strip())

# === HELPERS =================================================================

def get_std_config_path():
    if sys.platform == "win32":
        local_app_data = os.environ.get("LOCALAPPDATA", "")
        return os.path.join(local_app_data, "nvim")
    else:
        return os.path.expanduser("~/.config/nvim")


def get_std_data_path():
    if sys.platform == "win32":
        local_app_data = os.environ.get("LOCALAPPDATA", "")
        return os.path.join(local_app_data, "nvim-data")
    else:
        return os.path.expanduser("~/.local/share/nvim")


def read_info():
    config_path = get_std_config_path()
    info_path = os.path.join(config_path, "info.json")
    with open(info_path, "r") as f:
        return json.load(f)


def rmdir(path):
    path = os.path.abspath(path)
    if not os.path.exists(path):
        return
    try:
        shutil.rmtree(path)
        return
    except Exception:
        pass
    try:
        if sys.platform == "win32":
            subprocess.run(
                ["powershell", "-NoLogo", "-NoProfile", "-Command", f"rm -rf '{path}'"],
                check=True,
            )
        else:
            subprocess.run(["rm", "-rf", path], check=True)
        return
    except Exception:
        pass
    if sys.platform == "win32":
        subprocess.run(
            ["powershell", "-NoLogo", "-NoProfile", "-Command", f"Remove-Item -Recurse -Force '{path}'"],
            check=True,
        )
    else:
        print(f"fail to remove {path}")
        exit(1)


def is_worktree_dirty(path):
    """Check if a git worktree has uncommitted changes."""
    result = subprocess.run(
        ["git", "-C", path, "status", "--porcelain"],
        capture_output=True,
        text=True,
    )
    return bool(result.stdout.strip())


def write_patch(path, content):
    """Write patch content to file, normalizing line endings on Windows."""
    if sys.platform == "win32":
        content = content.replace("\r\n", "\n")
    with open(path, "w", newline="\n") as f:
        f.write(content)


def apply_patch(patch_path, repo_path):
    """Apply a patch file to a repo. Handles CRLF issues on Windows."""
    result = subprocess.run(
        ["git", "-C", repo_path, "apply", patch_path],
        capture_output=True,
        text=True,
    )
    if result.returncode == 0:
        return

    if sys.platform == "win32":
        with open(patch_path, "r") as f:
            content = f.read()
        if "\r\n" in content:
            temp_patch = patch_path + ".tmp"
            try:
                write_patch(temp_patch, content)
                subprocess.run(
                    ["git", "-C", repo_path, "apply", temp_patch],
                    check=True,
                )
                return
            finally:
                if os.path.exists(temp_patch):
                    os.remove(temp_patch)

    # Re-raise the original error
    subprocess.run(
        ["git", "-C", repo_path, "apply", patch_path],
        check=True,
    )


def restore_work_tree(path):
    """Restore all uncommitted changes in a git worktree."""
    subprocess.run(
        ["git", "-C", path, "checkout", "."],
        check=True,
    )


def checkout_repo(path, repo, ref, shallow, sparse):
    path = os.path.abspath(path)
    if os.path.exists(path):
        if is_worktree_dirty(path):
            print(f"checkout_repo: unclean work tree at {path}")
            exit(1)
    else:
        os.makedirs(path)
        subprocess.run(["git", "-C", path, "init"], check=True)
        subprocess.run(
            ["git", "-C", path, "remote", "add", "origin", f"https://github.com/{repo}"],
            check=True,
        )

    if sparse:
        subprocess.run(
            ["git", "-C", path, "config", "core.sparseCheckout", "true"],
            check=True,
        )
        sparse_file = os.path.join(path, ".git", "info", "sparse-checkout")
        os.makedirs(os.path.dirname(sparse_file), exist_ok=True)
        with open(sparse_file, "w") as f:
            f.write("\n".join(sparse) + "\n")

    subprocess.run(
        ["git", "-C", path, "config", "advice.detachedHead", "false"],
        check=True,
    )

    if shallow:
        subprocess.run(["git", "-C", path, "fetch", "--depth", "1", "origin", ref], check=True,)
        subprocess.run(["git", "-C", path, "checkout", "FETCH_HEAD"], check=True,)
    else:
        subprocess.run(["git", "-C", path, "fetch", "origin"], check=True,)
        subprocess.run(["git", "-C", path, "checkout", ref], check=True,)


if __name__ == "__main__":
    main()
