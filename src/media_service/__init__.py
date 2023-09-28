from pathlib import Path

from fastapi import FastAPI, HTTPException, Request, Response, UploadFile
from fastapi.responses import FileResponse
from fastapi.staticfiles import StaticFiles
from fastapi.templating import Jinja2Templates

from media_service.file_manager import FileManager

PACKAGE_DIR = Path(__file__).parent
STATIC_DIR = PACKAGE_DIR / "static"
TEMPLATES_DIR = PACKAGE_DIR / "templates"
DATA_DIR = Path(".") / "data"


app = FastAPI()
app.mount("/static", StaticFiles(directory=STATIC_DIR), name="static")
templates = Jinja2Templates(directory=TEMPLATES_DIR)


@app.get("/")
async def root(request: Request) -> Response:
    file_manager = FileManager(DATA_DIR)

    return templates.TemplateResponse(
        "root.html.j2",
        {
            "request": request,
            "files": await file_manager.list(),
        },
    )


@app.post("/upload/")
async def upload(request: Request, file: UploadFile) -> Response:
    file_manager = FileManager(DATA_DIR)

    return templates.TemplateResponse(
        "file_list_item.html.j2",
        {
            "request": request,
            "file": await file_manager.add(file),
        },
    )


@app.get("/preview/{file_id}.jpg")
async def preview(file_id: str) -> FileResponse:
    file_manager = FileManager(DATA_DIR)

    try:
        preview = await file_manager.preview(file_id)
    except FileManager.NotFound as e:
        raise HTTPException(status_code=404, detail=str(e))

    return FileResponse(preview)
