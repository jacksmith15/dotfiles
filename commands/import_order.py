#!/usr/bin/env python3
import ast
from enum import Enum
import importlib
from itertools import groupby, tee
import os
import re
import sys
from typing import Iterator, List, NamedTuple, Optional


class ImportType(Enum):
    STANDARD = 0
    THIRD_PARTY = 1
    LOCAL = 2

    @staticmethod
    def from_base(base: str) -> "ImportType":
        origin = importlib.util.find_spec(base).origin
        for segment in reversed(origin.split(os.path.sep)):
            if re.match(r"python3\..*", segment):
                return ImportType.STANDARD
            if segment == "site-packages":
                return ImportType.THIRD_PARTY
        return ImportType.LOCAL


class Import(NamedTuple):
    base: str

    module: List[str]
    name: List[str]
    alias: Optional[str] = None

    @property
    def import_type(self):
        return ImportType.from_base(self.base)

    def render(self):
        if not self.module:
            if not self.alias:
                return f"import {'.'.join(self.name)}"
            return f"import {'.'.join(self.name)} as {self.alias}"
        if not self.alias:
            return f"from {'.'.join(self.module)} import {'.'.join(self.name)}"
        return f"from {'.'.join(self.module)} import {'.'.join(self.name)} as {self.alias}"


class ImportGroup(NamedTuple):
    base: str

    module: List[str]
    imports: List[Import]

    @property
    def import_type(self):
        return ImportType.from_base(self.base)

    def render(self):
        names = ", ".join(
            sorted(
                (".".join(imp.name) + (f" as {imp.alias}" if imp.alias else ""))
                for imp in self.imports
            )
        )
        if not self.module:
            return f"import {names}"
        return f"from {'.'.join(self.module)} import {names}"


def main(module_path: str):
    imports = list(get_grouped_imports(module_path))
    for previous, current in pairwise(imports):
        print(previous.render())
        if previous.import_type is not current.import_type:
            print("")
    if imports:
        print(imports[-1].render())


def get_grouped_imports(module_path: str) -> Iterator[ImportGroup]:
    imports = get_ordered_imports(module_path)
    for key, group in groupby(imports, key=lambda imp: '.'.join(imp.module)):
        values = list(group)
        yield ImportGroup(base=values[0].base, module=values[0].module, imports=values)


def get_ordered_imports(module_path: str) -> List[Import]:
    return sorted(
        get_imports(module_path),
        key=lambda imp: (imp.import_type.value, ".".join(imp.module) or ".".join(imp.name)),
    )


def get_imports(module_path: str) -> Iterator[Import]:
    with open(module_path) as file:
        root = ast.parse(file.read(), module_path)

    for node in ast.iter_child_nodes(root):
        if isinstance(node, ast.Import):
            module = []
        elif isinstance(node, ast.ImportFrom):
            module = node.module.split(".")
        else:
            continue

        for n in node.names:
            base = module[0] if module else n.name.split(".")[0]
            yield Import(base=base, module=module, name=n.name.split("."), alias=n.asname)



def pairwise(iterable):
    """s -> (s0,s1), (s1,s2), (s2, s3), ..."""
    a, b = tee(iterable)
    next(b, None)
    return zip(a, b)




if __name__ == "__main__":
    main(sys.argv[1])
