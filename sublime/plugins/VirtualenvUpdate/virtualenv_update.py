import os
import re
from pathlib import Path
from typing import Optional, List

import sublime
import sublime_plugin


class VenvDetector:
    def get_virtualenv(self, directory: Path) -> Optional[Path]:
        ...


class LocalVenv(VenvDetector):
    def __init__(self, venv_directory_names: List[str]) -> None:
        self.venv_directory_names = venv_directory_names

    def get_virtualenv(self, directory: Path) -> Optional[Path]:
        for name in self.venv_directory_names:
            venv_path = directory / name
            if venv_path.exists() and venv_path.is_dir():
                return venv_path.resolve()


class MicromambaVenv(VenvDetector):
    ENV_NAME_PATTERN = re.compile(r"^name:\s+(?P<name>.*)")

    def __init__(self, environment_file_names: List[str]):
        self.environment_file_names = environment_file_names
        self._cache: dict = {}

    def get_virtualenv(self, directory: Path) -> Optional[Path]:
        mamba_root_prefix = Path.home() / "micromamba"
        if directory in self._cache:
            return self._cache[directory]
        for name in self.environment_file_names:
            environment_file_path = directory / name
            if not environment_file_path.exists() or not environment_file_path.is_file():
                continue
            print(f"Found environment file: {environment_file_path}")
            for line in environment_file_path.read_text().splitlines():
                match = self.ENV_NAME_PATTERN.match(line)
                if not match:
                    continue
                environment_name = match.groupdict()["name"].strip()
                print(f"Found environment name: {environment_name}")
                result = Path(mamba_root_prefix) / "envs" / environment_name
                self._cache[directory] = result.resolve()
                return self._cache[directory]


class VirtualenvUpdateHook(sublime_plugin.EventListener):
    """Supports dynamically updating the project virtualenv based on file in focus.

    LSP-pyright supports reading the virtualenv from the project data. To get
    monorepo support, this hook tracks the virtualenv based on the file currently
    in focus.
    """
    VENV_DIRECTORY_NAMES = [".venv"]

    @property
    def venv_detectors(self) -> List[VenvDetector]:
        if not hasattr(self, "_venv_detectors"):
            self._venv_detectors = [
                LocalVenv([".venv"]),
                MicromambaVenv(["environment.devenv.yml"]),
            ]
        return self._venv_detectors

    def on_activated(self, view: sublime.View):
        filename = view.file_name()
        if filename is None:
            return
        if not filename.endswith(".py"):
            return
        configured_virtualenv = self.get_configured_virtualenv(view)
        if configured_virtualenv is None:
            # Don't add project config if it doesn't exist
            return

        target_virtualenv = self.detect_virtualenv(Path(filename))
        if target_virtualenv is None:
            return

        if configured_virtualenv == target_virtualenv:
            # Skip if it already matches
            return
        self.set_configured_virtualenv(view, target_virtualenv)

    def virtualenv_matches(self, configured_virtualenv: Path, path: Path) -> bool:
        if configured_virtualenv.parent in path.resolve().parents:
            return True
        return False

    def detect_virtualenv(self, path: Path) -> Optional[Path]:
        for parent in path.parents:
            venv = self.get_virtualenv(parent)
            if venv:
                return venv
        return None

    def get_virtualenv(self, directory: Path) -> Optional[Path]:
        for detector in self.venv_detectors:
            venv = detector.get_virtualenv(directory)
            if venv and venv.exists():
                return venv
        return None

    def get_configured_virtualenv(self, view: sublime.View) -> Optional[Path]:
        if "configured_virtualenv" in self.state:
            return self.state["configured_virtualenv"]
        window = view.window()
        if window is None:
            return None
        project_data = window.project_data() or {}
        virtualenv = project_data.get("virtualenv")
        return Path(virtualenv) if virtualenv else None

    def set_configured_virtualenv(self, view: sublime.View, target_virtualenv: Path):
        window = view.window()
        if window is None:
            return
        project_data = window.project_data() or {}
        project_data["virtualenv"] = str(target_virtualenv)
        window.set_project_data(project_data)
        self.state["configured_virtualenv"] = target_virtualenv

    @property
    def state(self) -> dict:
        if not hasattr(self, "_state"):
            self._state = {}
        return self._state
