# Files API Reference

## Methods

### `client.files.upload(file: FileInput) -> str`

Upload a file via presigned URL. Returns `file_id`.

Most users don't need to call this directly — `generate()` auto-uploads `FileInput` values.

### `client.files.presign(*, filename, content_type, size) -> PresignResponse`

Get a presigned upload URL. Low-level; prefer `upload()`.

### `client.files.resolve(inp: FileInput) -> dict`

Resolve a `FileInput` to API JSON (`{"type": "url", "url": ...}` or `{"type": "file_id", "file_id": ...}`). Auto-uploads if needed.

### `client.files.resolve_many(inputs: Sequence[FileInput]) -> list[dict]`

Resolve multiple `FileInput` values.

### `client.files.get(file_id: str) -> FileObject`

Get file metadata.

### `client.files.list() -> list[FileObject]`

List all uploaded files.

### `client.files.delete(file_id: str) -> None`

Delete a file.

### `client.files.cleanup(file_ids: Sequence[str]) -> None`

Best-effort delete of temporary files. Errors are logged, never raised.

## Return types

### PresignResponse

| Field | Type | Description |
|---|---|---|
| `file_id` | `str` | Assigned file ID |
| `upload_url` | `str` | Presigned PUT URL |
| `expires_at` | `str` | Expiration timestamp |
| `method` | `str` | HTTP method (default `"PUT"`) |
| `headers` | `Dict[str, str]` | Headers to include in upload |

### FileObject

| Field | Type | Description |
|---|---|---|
| `file_id` | `str` | File identifier |
| `filename` | `str` | Original filename |
| `content_type` | `str` | MIME type |
| `size` | `int` | File size in bytes |
| `status` | `str` | Upload status |
| `created_at` | `str` | Creation timestamp |
| `expires_at` | `str \| None` | Expiration timestamp |

## Example

```python
file_id = client.files.upload(open("photo.jpg", "rb"))
print(f"Uploaded: {file_id}")

files = client.files.list()
for f in files:
    print(f"{f.file_id}: {f.filename} ({f.size} bytes)")

client.files.delete(file_id)
```
