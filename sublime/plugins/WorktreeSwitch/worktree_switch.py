import os
import subprocess
from typing import List, Optional, Tuple

import sublime
import sublime_plugin


class WorktreeSwitchCommand(sublime_plugin.WindowCommand):
    def run(self):
        folder = self._get_folder()
        if folder is None:
            sublime.error_message("Worktree Switch: No folder open in this window.")
            return

        worktrees = self._list_worktrees(folder)
        if not worktrees:
            sublime.error_message("Worktree Switch: No worktrees found.")
            return

        current_worktree = self._get_current_worktree(folder)
        worktrees = [(path, branch) for path, branch in worktrees if path != current_worktree]

        if not worktrees:
            sublime.status_message("Worktree Switch: No other worktrees to switch to.")
            return

        items = [
            sublime.QuickPanelItem(branch, details=path)
            for path, branch in worktrees
        ]

        subdir = self._get_subdir(current_worktree)

        def on_select(index: int):
            if index == -1:
                return
            target_path = worktrees[index][0]
            if subdir:
                candidate = os.path.join(target_path, subdir)
                if os.path.isdir(candidate):
                    target_path = candidate
            subprocess.Popen(["subl", target_path])

        self.window.show_quick_panel(items, on_select)

    def _get_folder(self) -> Optional[str]:
        folders = self.window.folders()
        return folders[0] if folders else None

    def _get_current_worktree(self, folder: str) -> Optional[str]:
        result = subprocess.run(
            ["git", "rev-parse", "--show-toplevel"],
            cwd=folder,
            capture_output=True,
            text=True,
        )
        if result.returncode == 0:
            return result.stdout.strip()
        return folder

    def _get_subdir(self, current_worktree: Optional[str]) -> Optional[str]:
        """Get the repo-relative subdirectory of the active file."""
        view = self.window.active_view()
        if view is None or current_worktree is None:
            return None
        filename = view.file_name()
        if filename is None:
            return None
        if not filename.startswith(current_worktree + os.sep):
            return None
        relative = os.path.relpath(filename, current_worktree)
        subdir = os.path.dirname(relative)
        return subdir if subdir else None

    def _list_worktrees(self, folder: str) -> List[Tuple[str, str]]:
        result = subprocess.run(
            ["git", "worktree", "list", "--porcelain"],
            cwd=folder,
            capture_output=True,
            text=True,
        )
        if result.returncode != 0:
            return []

        worktrees = []
        path = None
        for line in result.stdout.splitlines():
            if line.startswith("worktree "):
                path = line[len("worktree "):]
            elif line.startswith("branch "):
                branch = line[len("branch refs/heads/"):]
                if path is not None:
                    worktrees.append((path, branch))
                path = None
        return worktrees
