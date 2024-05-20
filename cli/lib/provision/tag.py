#!/usr/bin/env python

class Tag:
    x11 = Tag("x11")
    wsl = Tag("wsl")

    def __init__(self, name: str) -> None:
        self.name = name


class Tags:
    def __init__(self, tags: list[Tag]) -> None:
        self.tags = tags

    def has(self, tag: Tag) -> bool:
        return any(t.name == tag.name for t in self.tags)

    @staticmethod
    def default() -> "Tags":
        # TODO: Intelligently choose default list of tags
        # - Ideas:
        #     - Detect WSL
        #     - Detect X11
        return Tags([Tag.x11])

    @staticmethod
    def parse(tag_names: str) -> "Tags":
        return Tags([Tag(tag_name) for tag_name in tag_names.split(",")])
