"""Serve the Flutter release build locally, with SPA deep-link fallback."""
import argparse
from functools import partial
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import urlsplit


class FlutterHandler(SimpleHTTPRequestHandler):
    def send_head(self):
        path = Path(self.translate_path(urlsplit(self.path).path))
        if not path.exists() and not path.suffix:
            self.path = "/index.html"
        return super().send_head()


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--port", type=int, default=5555)
    args = parser.parse_args()
    directory = Path(__file__).resolve().parents[1] / "build" / "web"
    if not (directory / "index.html").is_file():
        parser.error("First run: flutter build web --no-web-resources-cdn")
    server = ThreadingHTTPServer(("127.0.0.1", args.port), partial(FlutterHandler, directory=str(directory)))
    print(f"Library preview: http://127.0.0.1:{args.port}", flush=True)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass
    finally:
        server.server_close()
