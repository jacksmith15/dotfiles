import re

import sublime
import sublime_plugin


class SplitString(sublime_plugin.TextCommand):

    MATCH = r"^(?P<indent>\s*)(?P<prefix>[rbuf]?)(?P<quotechar>[\"'])(?P<string>.*)[\"']"

    def parse_line(self, line_length):
        line = self.view.line(self.view.sel()[0])
        line_string = self.view.substr(line)
        if len(line_string) <= line_length:
            raise ValueError("String is already short enough.")
        if "\n" in line_string:
            raise ValueError("No support for multi-line selections.")
        parsed = re.match(self.MATCH, line_string)
        if not parsed:
            raise ValueError("Line {line_string} is not a string".format(line_string=line_string))
        return line, parsed.groupdict()

    def run(self, edit, line_length=92, block_indent=4):
        line, groups = self.parse_line(line_length)
        string = groups.pop("string")
        indent = groups.pop("indent")
        string_component_length = (
            line_length  # Max length of a lint
            - len(indent)  # We're already indented this far
            - block_indent  # We're going to nest inside another block
            - 2  # Quote characters
            - (1 if groups["prefix"] else 0)  # There's another char if we use a prefix
        )
        string_line = lambda substr: "{indent}{prefix}{quotechar}{substr}{quotechar}".format(
            indent=" " * block_indent + indent,
            substr=substr,
            **groups
        )
        string_components = (
                [indent + "("]
                + [
                    string_line(string[i:i + string_component_length])
                    for i in range(0, len(string), string_component_length)
                ]
                + [indent + ")\n"]
        )
        output = "\n".join(string_components)
        self.view.replace(edit, line, output)
