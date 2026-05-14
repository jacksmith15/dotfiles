import os
import re
import subprocess
from typing import Optional

import sublime
import sublime_plugin


class GithubOpenCommand(sublime_plugin.TextCommand):
    def run(self, edit, mode: str = "current"):
        url = build_github_url(self.view, mode)
        if url:
            self.view.window().run_command("open_url", {"url": url})

    def is_enabled(self, **kwargs) -> bool:
        return _is_github_repo(self.view)


class GithubCopyUrlCommand(sublime_plugin.TextCommand):
    def run(self, edit, mode: str = "current"):
        url = build_github_url(self.view, mode)
        if url:
            sublime.set_clipboard(url)
            sublime.status_message(f"Copied: {url}")

    def is_enabled(self, **kwargs) -> bool:
        return _is_github_repo(self.view)


def _is_github_repo(view: sublime.View) -> bool:
    filename = view.file_name()
    if filename is None:
        return False
    result = _git("rev-parse", "--show-toplevel", cwd=os.path.dirname(filename))
    return result is not None


def build_github_url(view: sublime.View, mode: str) -> Optional[str]:
    filename = view.file_name()
    if filename is None:
        return None

    repo_root = _git("rev-parse", "--show-toplevel", cwd=os.path.dirname(filename))
    if repo_root is None:
        return None

    relative_path = os.path.relpath(filename, repo_root)
    remote_url = _git("remote", "get-url", "origin", cwd=repo_root)
    if remote_url is None:
        return None

    owner_repo = _parse_owner_repo(remote_url)
    if owner_repo is None:
        sublime.error_message("GitHub: could not parse remote URL")
        return None

    ref = _resolve_ref(mode, repo_root)
    if ref is None:
        sublime.error_message("GitHub: could not determine ref")
        return None

    view_type = "blame" if mode == "blame" else "blob"
    url = f"https://github.com/{owner_repo}/{view_type}/{ref}/{relative_path}"
    url += _line_fragment(view)
    return url


def _resolve_ref(mode: str, repo_root: str) -> Optional[str]:
    if mode == "permalink":
        return _git("rev-parse", "HEAD", cwd=repo_root)
    if mode == "default_branch":
        symbolic = _git("symbolic-ref", "refs/remotes/origin/HEAD", cwd=repo_root)
        if symbolic is None:
            return None
        prefix = "refs/remotes/origin/"
        return symbolic[len(prefix):] if symbolic.startswith(prefix) else symbolic
    return _git("rev-parse", "--abbrev-ref", "HEAD", cwd=repo_root)


def _parse_owner_repo(remote_url: str) -> Optional[str]:
    if remote_url.endswith(".git"):
        remote_url = remote_url[:-4]
    match = re.match(r"^git@github\.com:(.+/.+)$", remote_url)
    if match:
        return match.group(1)
    match = re.match(r"^https?://github\.com/(.+/.+)$", remote_url)
    if match:
        return match.group(1)
    return None


def _line_fragment(view: sublime.View) -> str:
    sel = view.sel()
    if not sel:
        return ""
    region = sel[0]
    start_row = view.rowcol(region.begin())[0] + 1
    end_row = view.rowcol(region.end())[0] + 1
    if start_row == end_row:
        return f"#L{start_row}"
    return f"#L{start_row}-L{end_row}"


def _git(*args: str, cwd: str) -> Optional[str]:
    result = subprocess.run(
        ["git", *args],
        cwd=cwd,
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        return None
    return result.stdout.strip()
