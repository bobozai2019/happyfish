"""Serve the Godot Web export with the isolation headers required by its template."""

from __future__ import annotations

import argparse
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer


class GodotWebHandler(SimpleHTTPRequestHandler):
	def end_headers(self) -> None:
		self.send_header("Cross-Origin-Opener-Policy", "same-origin")
		self.send_header("Cross-Origin-Embedder-Policy", "require-corp")
		self.send_header("Cross-Origin-Resource-Policy", "cross-origin")
		super().end_headers()


def main() -> None:
	parser = argparse.ArgumentParser()
	parser.add_argument("--directory", default="build/web")
	parser.add_argument("--port", type=int, default=8060)
	args = parser.parse_args()

	handler = lambda *handler_args, **handler_kwargs: GodotWebHandler(
		*handler_args, directory=args.directory, **handler_kwargs
	)
	server = ThreadingHTTPServer(("127.0.0.1", args.port), handler)
	print(f"Serving {args.directory} at http://127.0.0.1:{args.port}")
	server.serve_forever()


if __name__ == "__main__":
	main()
