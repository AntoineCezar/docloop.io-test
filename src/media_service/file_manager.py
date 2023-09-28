import json
import subprocess
from pathlib import Path
from typing import TypedDict
from uuid import uuid4

from fastapi import UploadFile


class NotFound(Exception):
    pass


class FileMeta(TypedDict):
    id: str
    name: str


class FileManager:
    NotFound = NotFound

    def __init__(self, data_dir: Path) -> None:
        self._data_dir = data_dir
        self._data_dir.mkdir(exist_ok=True)

    async def list(self) -> list[FileMeta]:
        return [
            json.loads(ondisk_meta.read_text())
            for ondisk_meta in self._data_dir.glob("*.json")
        ]

    async def add(self, file: UploadFile) -> FileMeta:
        file_id = uuid4().hex
        meta: FileMeta = {
            "id": file_id,
            "name": file.filename or file_id,
        }

        on_disk_data = self._data_dir / file_id
        on_disk_meta = on_disk_data.with_suffix(".json")

        on_disk_data.write_bytes(data=await file.read())
        on_disk_meta.write_text(json.dumps(meta))

        return meta

    async def get(self, file_id: str) -> Path:
        file = self._data_dir / file_id
        file_meta = file.with_suffix(".json")

        if not file.exists() or not file_meta.exists():
            raise NotFound(f"File {file_id}")

        return file

    async def preview(self, file_id: str) -> Path:
        file = await self.get(file_id)
        file_preview = file.with_suffix(".jpg")

        if not file_preview.exists():
            pdf_to_jpg(file, file_preview)

        return file_preview


def pdf_to_jpg(src: Path, dst: Path) -> None:
    dst.write_bytes(
        subprocess.check_output(
            [
                "pdftoppm",
                "-jpeg",
                "-f",
                "1",
                "-l",
                "1",
                str(src),
            ]
        )
    )
