#!/usr/bin/env python3
"""Sync Yaak API collections to/from Postman v2.1.0 JSON format.

Usage:
    yaak-sync.py export [--output PATH] [--env] [--workspace NAME]
    yaak-sync.py import [--input PATH] [--workspace NAME]
"""

import argparse
import json
import os
import re
import sqlite3
import string
import random
import subprocess
import sys
import time
from pathlib import Path
from urllib.parse import urlparse, parse_qs, urlencode

YAAK_DB = Path.home() / "Library" / "Application Support" / "app.yaak.desktop" / "db.sqlite"
DEFAULT_OUTPUT_DIR = Path.home() / "Shared"
POSTMAN_SCHEMA = "https://schema.getpostman.com/json/collection/v2.1.0/collection.json"

# Yaak variable syntax: ${[varname]} → Postman: {{varname}}
YAAK_VAR_RE = re.compile(r'\$\{\[\s*(.+?)\s*\]\}')
POSTMAN_VAR_RE = re.compile(r'\{\{(.+?)\}\}')


def yaak_to_postman_vars(s: str) -> str:
    """Convert ${[var]} → {{var}}."""
    return YAAK_VAR_RE.sub(r'{{\1}}', s)


def postman_to_yaak_vars(s: str) -> str:
    """Convert {{var}} → ${[var]}."""
    return POSTMAN_VAR_RE.sub(r'${[\1]}', s)


def random_id(prefix: str, length: int = 10) -> str:
    """Generate Yaak-style IDs like rq_4QEXmqsmxR."""
    chars = string.ascii_letters + string.digits
    return prefix + ''.join(random.choices(chars, k=length))


# ---------------------------------------------------------------------------
# Export: Yaak DB → Postman JSON
# ---------------------------------------------------------------------------

def db_connect():
    if not YAAK_DB.exists():
        sys.exit(f"Yaak DB not found at {YAAK_DB}")
    conn = sqlite3.connect(f"file:{YAAK_DB}?mode=ro", uri=True)
    conn.row_factory = sqlite3.Row
    return conn


def load_workspaces(conn):
    return conn.execute(
        "SELECT id, name, description FROM workspaces WHERE deleted_at IS NULL"
    ).fetchall()


def load_folders(conn, workspace_id: str):
    return conn.execute(
        "SELECT id, name, folder_id, sort_priority FROM folders "
        "WHERE workspace_id = ? AND deleted_at IS NULL ORDER BY sort_priority",
        (workspace_id,),
    ).fetchall()


def load_requests(conn, workspace_id: str):
    return conn.execute(
        "SELECT id, name, url, method, headers, body, body_type, "
        "url_parameters, folder_id, sort_priority, description "
        "FROM http_requests WHERE workspace_id = ? AND deleted_at IS NULL "
        "ORDER BY sort_priority",
        (workspace_id,),
    ).fetchall()


def load_environments(conn, workspace_id: str):
    return conn.execute(
        "SELECT id, name, variables FROM environments "
        "WHERE workspace_id = ? AND deleted_at IS NULL",
        (workspace_id,),
    ).fetchall()


def convert_headers(headers_json: str) -> list:
    headers = json.loads(headers_json) if headers_json else []
    return [
        {"key": h["name"], "value": yaak_to_postman_vars(h["value"]),
         "type": "text", "enabled": h.get("enabled", True)}
        for h in headers if h.get("name")
    ]


def convert_url(url: str, params_json: str) -> dict:
    url = yaak_to_postman_vars(url)
    params = json.loads(params_json) if params_json else []

    # Parse URL for path segments
    try:
        parsed = urlparse(url)
        host_parts = [parsed.scheme + "://" + parsed.netloc] if parsed.netloc else [url]
        path_parts = [p for p in parsed.path.split('/') if p]
    except Exception:
        host_parts = [url]
        path_parts = []

    # Path variables (e.g. :id)
    path_var_matches = re.findall(r':([a-zA-Z_]\w*)', url)
    path_variables = [
        {"id": name, "key": name,
         "value": next((p["value"] for p in params if p.get("name") == name), ""),
         "type": "string", "description": ""}
        for name in path_var_matches
    ]

    # Query params
    query = [
        {"key": p["name"], "value": yaak_to_postman_vars(p.get("value", "")),
         "disabled": not p.get("enabled", True)}
        for p in params
        if p.get("name") and not p["name"].startswith(':')
    ]

    return {
        "raw": url,
        "host": host_parts,
        "path": path_parts,
        "variable": path_variables,
        "query": query,
    }


def convert_body(body_json: str, body_type: str | None) -> dict | None:
    body = json.loads(body_json) if body_json else {}
    text = body.get("text", "")
    if not text:
        return None
    lang = "json" if body_type and "json" in body_type else "text"
    return {
        "mode": "raw",
        "raw": yaak_to_postman_vars(text),
        "options": {"raw": {"language": lang}},
    }


def convert_request(row) -> dict:
    item = {
        "name": row["name"] or row["url"] or "Untitled",
        "request": {
            "method": row["method"],
            "header": convert_headers(row["headers"]),
            "url": convert_url(row["url"], row["url_parameters"]),
            "description": row["description"] or "",
        },
        "response": [],
    }
    body = convert_body(row["body"], row["body_type"])
    if body:
        item["request"]["body"] = body
    return item


def build_folder_tree(folders, requests) -> list:
    """Build nested Postman item array from flat folder + request lists."""
    folder_map: dict[str, dict] = {}
    for f in folders:
        folder_map[f["id"]] = {"name": f["name"], "item": [], "_parent": f["folder_id"]}

    # Place requests into their folders (or root)
    root_items = []
    for r in requests:
        item = convert_request(r)
        fid = r["folder_id"]
        if fid and fid in folder_map:
            folder_map[fid]["item"].append(item)
        else:
            root_items.append(item)

    # Nest child folders into parents
    root_folders = []
    for fid, folder in folder_map.items():
        parent = folder.pop("_parent")
        if parent and parent in folder_map:
            folder_map[parent]["item"].append(folder)
        else:
            root_folders.append(folder)

    return root_folders + root_items


def export_collection(conn, workspace, output: Path):
    wid = workspace["id"]
    folders = load_folders(conn, wid)
    requests = load_requests(conn, wid)

    collection = {
        "info": {
            "name": workspace["name"],
            "description": workspace["description"] or "",
            "schema": POSTMAN_SCHEMA,
        },
        "item": build_folder_tree(folders, requests),
        "variable": [],
    }

    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(json.dumps(collection, indent=2))
    print(f"Exported collection → {output}")


def export_environment(conn, workspace, env_row, output_dir: Path):
    variables = json.loads(env_row["variables"]) if env_row["variables"] else []
    postman_env = {
        "name": env_row["name"],
        "values": [
            {"key": v["name"], "value": yaak_to_postman_vars(v["value"]),
             "type": "default", "enabled": v.get("enabled", True)}
            for v in variables if v.get("name")
        ],
        "_postman_variable_scope": "environment",
    }

    name = f"{workspace['name'].lower()}_environment_{env_row['name'].lower()}.json"
    out = output_dir / name
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(json.dumps(postman_env, indent=2))
    print(f"Exported environment '{env_row['name']}' → {out}")


def pick_workspace(workspaces, name_filter: str | None):
    if not workspaces:
        sys.exit("No workspaces found in Yaak DB")
    if name_filter:
        matches = [w for w in workspaces if w["name"].lower() == name_filter.lower()]
        if not matches:
            available = ', '.join(w['name'] for w in workspaces)
            sys.exit(f"Workspace '{name_filter}' not found. Available: {available}")
        return matches[0]
    if len(workspaces) == 1:
        return workspaces[0]
    print("Multiple workspaces found:")
    for i, w in enumerate(workspaces):
        print(f"  {i + 1}. {w['name']}")
    choice = input("Select workspace number: ").strip()
    try:
        return workspaces[int(choice) - 1]
    except (ValueError, IndexError):
        sys.exit("Invalid selection")


def cmd_export(args):
    conn = db_connect()
    workspaces = load_workspaces(conn)
    ws = pick_workspace(workspaces, args.workspace)

    if args.output:
        output = Path(args.output)
    else:
        output = DEFAULT_OUTPUT_DIR / f"{ws['name'].lower()}_collection.json"

    export_collection(conn, ws, output)

    if args.env:
        envs = load_environments(conn, ws["id"])
        output_dir = output.parent
        for env in envs:
            export_environment(conn, ws, env, output_dir)

    conn.close()


# ---------------------------------------------------------------------------
# Import: Postman JSON → Yaak DB
# ---------------------------------------------------------------------------

def check_yaak_not_running():
    """Warn if Yaak is running (SQLite locking risk)."""
    try:
        result = subprocess.run(
            ["pgrep", "-f", "app.yaak.desktop"], capture_output=True, text=True
        )
        if result.returncode == 0:
            print("WARNING: Yaak appears to be running. Close it before importing to avoid DB locking issues.")
            answer = input("Continue anyway? [y/N] ").strip().lower()
            if answer != 'y':
                sys.exit("Aborted")
    except FileNotFoundError:
        pass  # pgrep not available, skip check


def db_connect_rw():
    if not YAAK_DB.exists():
        sys.exit(f"Yaak DB not found at {YAAK_DB}")
    conn = sqlite3.connect(str(YAAK_DB))
    conn.row_factory = sqlite3.Row
    return conn


def find_or_create_workspace(conn, name: str) -> str:
    row = conn.execute(
        "SELECT id FROM workspaces WHERE name = ? AND deleted_at IS NULL", (name,)
    ).fetchone()
    if row:
        return row["id"]

    wid = random_id("wk_")
    now = time.strftime("%Y-%m-%d %H:%M:%S")
    conn.execute(
        "INSERT INTO workspaces (id, model, created_at, updated_at, name, description) "
        "VALUES (?, 'workspace', ?, ?, ?, '')",
        (wid, now, now, name),
    )
    print(f"Created workspace '{name}' ({wid})")
    return wid


def upsert_folder(conn, workspace_id: str, name: str, parent_folder_id: str | None,
                   existing_folders: dict) -> str:
    """Find or create a folder. Returns folder ID."""
    key = (name, parent_folder_id)
    if key in existing_folders:
        return existing_folders[key]

    fid = random_id("fl_")
    now = time.strftime("%Y-%m-%d %H:%M:%S")
    conn.execute(
        "INSERT INTO folders (id, model, created_at, updated_at, workspace_id, "
        "folder_id, name, sort_priority, description, authentication, authentication_type, headers) "
        "VALUES (?, 'folder', ?, ?, ?, ?, ?, 0, '', '{}', NULL, '[]')",
        (fid, now, now, workspace_id, parent_folder_id, name),
    )
    existing_folders[key] = fid
    print(f"  Created folder: {name}")
    return fid


def postman_headers_to_yaak(headers: list) -> str:
    return json.dumps([
        {"name": h.get("key", ""), "value": postman_to_yaak_vars(h.get("value", "")),
         "enabled": h.get("enabled", not h.get("disabled", False)), "id": None}
        for h in headers
    ])


def postman_body_to_yaak(body: dict | None) -> tuple[str, str | None]:
    """Returns (body_json, body_type)."""
    if not body or not body.get("raw"):
        return '{}', None
    lang = body.get("options", {}).get("raw", {}).get("language", "text")
    body_type = "application/json" if lang == "json" else None
    return json.dumps({"text": postman_to_yaak_vars(body["raw"])}), body_type


def postman_query_to_yaak(query: list) -> str:
    return json.dumps([
        {"name": q.get("key", ""), "value": postman_to_yaak_vars(q.get("value", "")),
         "enabled": not q.get("disabled", False)}
        for q in query
    ])


def import_request(conn, workspace_id: str, folder_id: str | None,
                    item: dict, existing_requests: dict, sort_idx: float):
    req = item.get("request", {})
    name = item.get("name", "Untitled")
    method = req.get("method", "GET")

    # Reconstruct URL from raw or host+path
    url_obj = req.get("url", {})
    if isinstance(url_obj, str):
        url = postman_to_yaak_vars(url_obj)
        url_params = '[]'
    else:
        url = postman_to_yaak_vars(url_obj.get("raw", ""))
        url_params = postman_query_to_yaak(url_obj.get("query", []))

    headers = postman_headers_to_yaak(req.get("header", []))
    body_json, body_type = postman_body_to_yaak(req.get("body"))
    description = req.get("description", "")

    # Match by name + method + folder within workspace
    match_key = (name, method, folder_id)
    if match_key in existing_requests:
        rid = existing_requests[match_key]
        now = time.strftime("%Y-%m-%d %H:%M:%S")
        conn.execute(
            "UPDATE http_requests SET url=?, headers=?, body=?, body_type=?, "
            "url_parameters=?, description=?, updated_at=? WHERE id=?",
            (url, headers, body_json, body_type, url_params, description, now, rid),
        )
        print(f"  Updated request: {method} {name}")
    else:
        rid = random_id("rq_")
        now = time.strftime("%Y-%m-%d %H:%M:%S")
        conn.execute(
            "INSERT INTO http_requests (id, model, workspace_id, created_at, updated_at, "
            "name, url, method, headers, body_type, sort_priority, authentication, "
            "authentication_type, folder_id, body, url_parameters, description) "
            "VALUES (?, 'http_request', ?, ?, ?, ?, ?, ?, ?, ?, ?, '{}', NULL, ?, ?, ?, ?)",
            (rid, workspace_id, now, now, name, url, method, headers, body_type,
             sort_idx, folder_id, body_json, url_params, description),
        )
        print(f"  Created request: {method} {name}")


def import_items(conn, workspace_id: str, items: list, parent_folder_id: str | None,
                 existing_folders: dict, existing_requests: dict, sort_base: float = 0):
    """Recursively import Postman items (folders + requests)."""
    for i, item in enumerate(items):
        sort_idx = sort_base + i
        if "item" in item and "request" not in item:
            # It's a folder
            fid = upsert_folder(conn, workspace_id, item["name"], parent_folder_id, existing_folders)
            import_items(conn, workspace_id, item["item"], fid,
                         existing_folders, existing_requests, sort_idx * 100)
        elif "request" in item:
            import_request(conn, workspace_id, parent_folder_id, item,
                           existing_requests, sort_idx)


def cmd_import(args):
    check_yaak_not_running()

    if args.input:
        input_path = Path(args.input)
    else:
        # Find most recent collection in ~/Shared/
        if not DEFAULT_OUTPUT_DIR.exists():
            sys.exit(f"No --input specified and {DEFAULT_OUTPUT_DIR} doesn't exist")
        collections = sorted(DEFAULT_OUTPUT_DIR.glob("*_collection.json"), key=os.path.getmtime, reverse=True)
        if not collections:
            sys.exit(f"No *_collection.json files found in {DEFAULT_OUTPUT_DIR}")
        input_path = collections[0]
        print(f"Using most recent collection: {input_path}")

    if not input_path.exists():
        sys.exit(f"File not found: {input_path}")

    data = json.loads(input_path.read_text())
    collection_name = data.get("info", {}).get("name", input_path.stem)
    items = data.get("item", [])

    if not items:
        sys.exit("Collection has no items to import")

    conn = db_connect_rw()

    ws_name = args.workspace or collection_name
    workspace_id = find_or_create_workspace(conn, ws_name)

    # Build lookup maps of existing folders and requests
    existing_folders: dict[tuple, str] = {}
    for row in load_folders(conn, workspace_id):
        existing_folders[(row["name"], row["folder_id"])] = row["id"]

    existing_requests: dict[tuple, str] = {}
    for row in load_requests(conn, workspace_id):
        existing_requests[(row["name"], row["method"], row["folder_id"])] = row["id"]

    print(f"Importing into workspace '{ws_name}'...")
    import_items(conn, workspace_id, items, None, existing_folders, existing_requests)

    conn.commit()
    conn.close()
    print("Done.")


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------

def main():
    parser = argparse.ArgumentParser(description="Sync Yaak ↔ Postman collections")
    sub = parser.add_subparsers(dest="command", required=True)

    exp = sub.add_parser("export", help="Export Yaak workspace → Postman collection JSON")
    exp.add_argument("--output", "-o", help=f"Output path (default: ~/Shared/<name>_collection.json)")
    exp.add_argument("--env", action="store_true", help="Also export environments")
    exp.add_argument("--workspace", "-w", help="Workspace name (prompted if multiple)")

    imp = sub.add_parser("import", help="Import Postman collection JSON → Yaak workspace")
    imp.add_argument("--input", "-i", help="Input Postman collection JSON path")
    imp.add_argument("--workspace", "-w", help="Target workspace name (default: collection name)")

    args = parser.parse_args()

    if args.command == "export":
        cmd_export(args)
    elif args.command == "import":
        cmd_import(args)


if __name__ == "__main__":
    main()
