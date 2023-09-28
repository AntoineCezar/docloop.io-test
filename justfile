set dotenv-load

PYTHON_VERSION := env_var_or_default("PYTHON_VERSION", "3")
VENV_TOOL := "python" + PYTHON_VERSION + " -m venv"
VIRTUAL_ENV := ".venv"

PIP := VIRTUAL_ENV / "bin" / "pip"
POETRY := VIRTUAL_ENV / "bin" / "poetry"
ISORT := VIRTUAL_ENV / "bin" / "isort"
PYCLN := VIRTUAL_ENV / "bin" / "pycln"
BLACK := VIRTUAL_ENV / "bin" / "black"
RUFF := VIRTUAL_ENV / "bin" / "ruff"
MYPY := VIRTUAL_ENV / "bin" / "mypy"
PYTEST := VIRTUAL_ENV / "bin" / "pytest"
UVICORN := VIRTUAL_ENV / "bin" / "uvicorn"

@_help:
    just --list --unsorted

# Display some justfile vars values
@_vars:
    echo "PYTHON_VERSION: {{PYTHON_VERSION}}"
    echo "VENV_TOOL: {{VENV_TOOL}}"
    echo "VIRTUAL_ENV: {{VIRTUAL_ENV}}"

# Create/Update the development environment
develop: _ensure_poetry
    {{POETRY}} install

_create_venv:
    {{VENV_TOOL}} {{VIRTUAL_ENV}}
    {{PIP}}  install -U pip

_install_poetry: _ensure_venv
    {{PIP}} install poetry

# Lock project dependencies
lock: _ensure_poetry
    {{POETRY}} lock

# Format code
format: _ensure_isort _ensure_black
    {{ISORT}} src
    {{BLACK}} src

# Fix code
fix: _fix_imports _fix_style format

# Run all tests
test: _ensure_pytest
    {{PYTEST}} tests

# Check code types, style and format
lint: _check_types _check_style _check_format

_check_types: _ensure_mypy
    {{MYPY}} --install-types --non-interactive src

_check_style: _ensure_ruff
    {{RUFF}} check src
    {{RUFF}} check tests

_fix_imports: _ensure_pycln
    {{PYCLN}} --all src
    {{PYCLN}} --all tests

_fix_style: _ensure_ruff
    {{RUFF}} check --fix-only src
    {{RUFF}} check --fix-only tests

_check_format: _ensure_isort _ensure_black
    {{ISORT}} --check src
    {{BLACK}} --check src
    {{ISORT}} --check tests
    {{BLACK}} --check tests

_ensure_venv:
    @{{ if path_exists(VIRTUAL_ENV) == "true" { "" } else { "just _create_venv" } }}

_ensure_poetry:
    @{{ if path_exists(POETRY) == "true" { "" } else { "just _install_poetry" } }}

_ensure_mypy:
    {{ if path_exists(MYPY) == "true" { "" } else { "just develop" } }}

_ensure_ruff:
    {{ if path_exists(RUFF) == "true" { "" } else { "just develop" } }}

_ensure_pycln:
    {{ if path_exists(PYCLN) == "true" { "" } else { "just develop" } }}

_ensure_isort:
    {{ if path_exists(ISORT) == "true" { "" } else { "just develop" } }}

_ensure_black:
    {{ if path_exists(BLACK) == "true" { "" } else { "just develop" } }}

_ensure_pytest:
    {{ if path_exists(PYTEST) == "true" { "" } else { "just develop" } }}

serve: develop
    {{UVICORN}} media_service:app --reload