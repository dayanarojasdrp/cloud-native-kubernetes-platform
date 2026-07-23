#!/usr/bin/env python3

import argparse
import pathlib
import textwrap

from PIL import Image, ImageDraw, ImageFont


def load_font(size: int):
    candidates = [
        "/System/Library/Fonts/Menlo.ttc",
        "/System/Library/Fonts/Monaco.ttf",
        "/Library/Fonts/Arial Unicode.ttf",
    ]

    for candidate in candidates:
        path = pathlib.Path(candidate)
        if path.exists():
            return ImageFont.truetype(str(path), size=size)

    return ImageFont.load_default()


def wrap_lines(text: str, width: int) -> list[str]:
    lines: list[str] = []

    for raw_line in text.rstrip().splitlines():
        if not raw_line:
            lines.append("")
            continue

        wrapped = textwrap.wrap(
            raw_line,
            width=width,
            replace_whitespace=False,
            drop_whitespace=False,
        )
        lines.extend(wrapped or [""])

    return lines


def render_terminal(title: str, command: str, output: str, destination: pathlib.Path) -> None:
    width = 1600
    padding = 44
    header_height = 96
    font = load_font(24)
    title_font = load_font(28)
    line_height = 34

    content = f"$ {command}\n\n{output.strip()}\n"
    lines = wrap_lines(content, width=108)
    height = max(900, header_height + padding + (len(lines) * line_height) + padding)

    image = Image.new("RGB", (width, height), "#0f172a")
    draw = ImageDraw.Draw(image)

    draw.rectangle((0, 0, width, header_height), fill="#111827")
    draw.ellipse((32, 34, 54, 56), fill="#ef4444")
    draw.ellipse((66, 34, 88, 56), fill="#f59e0b")
    draw.ellipse((100, 34, 122, 56), fill="#22c55e")
    draw.text((150, 30), title, font=title_font, fill="#e5e7eb")

    y = header_height + 32
    for line in lines:
        fill = "#93c5fd" if line.startswith("$ ") else "#e5e7eb"
        draw.text((padding, y), line, font=font, fill=fill)
        y += line_height

    destination.parent.mkdir(parents=True, exist_ok=True)
    image.save(destination)


def render_architecture(destination: pathlib.Path) -> None:
    width, height = 1600, 1000
    image = Image.new("RGB", (width, height), "#f8fafc")
    draw = ImageDraw.Draw(image)
    title_font = load_font(42)
    box_font = load_font(24)
    small_font = load_font(20)

    draw.text((80, 54), "Cloud Native Kubernetes Platform", font=title_font, fill="#0f172a")
    draw.text((82, 112), "GitOps, Helm, Ingress, TLS, HPA, NetworkPolicy, and persistent PostgreSQL", font=small_font, fill="#475569")

    boxes = [
        ("GitHub Repository", "Helm chart + ArgoCD Applications", 100, 210, 390, 340, "#dbeafe"),
        ("ArgoCD", "auto-sync, self-heal, prune", 605, 210, 995, 340, "#ede9fe"),
        ("Kind Cluster", "local Kubernetes platform", 1210, 210, 1500, 340, "#dcfce7"),
        ("ingress-nginx", "HTTPS users-api.local", 100, 500, 390, 630, "#fef3c7"),
        ("users-api", "Helm release, HPA, probes", 605, 500, 995, 630, "#cffafe"),
        ("PostgreSQL", "PVC + Secret-backed DB_URL", 1210, 500, 1500, 630, "#fee2e2"),
        ("NetworkPolicies", "default deny + explicit allows", 605, 760, 995, 890, "#e2e8f0"),
    ]

    for title, subtitle, x1, y1, x2, y2, fill in boxes:
        draw.rounded_rectangle((x1, y1, x2, y2), radius=14, fill=fill, outline="#334155", width=3)
        draw.text((x1 + 28, y1 + 28), title, font=box_font, fill="#0f172a")
        draw.text((x1 + 28, y1 + 72), subtitle, font=small_font, fill="#334155")

    def arrow(start: tuple[int, int], end: tuple[int, int]) -> None:
        draw.line((start, end), fill="#334155", width=4)
        ex, ey = end
        sx, sy = start
        if ex > sx:
            points = [(ex, ey), (ex - 18, ey - 10), (ex - 18, ey + 10)]
        elif ey > sy:
            points = [(ex, ey), (ex - 10, ey - 18), (ex + 10, ey - 18)]
        else:
            points = [(ex, ey), (ex + 18, ey - 10), (ex + 18, ey + 10)]
        draw.polygon(points, fill="#334155")

    arrow((390, 275), (605, 275))
    arrow((995, 275), (1210, 275))
    arrow((245, 340), (245, 500))
    arrow((390, 565), (605, 565))
    arrow((995, 565), (1210, 565))
    arrow((800, 630), (800, 760))

    destination.parent.mkdir(parents=True, exist_ok=True)
    image.save(destination)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--title")
    parser.add_argument("--command")
    parser.add_argument("--input")
    parser.add_argument("--output", required=True)
    parser.add_argument("--architecture", action="store_true")
    args = parser.parse_args()

    destination = pathlib.Path(args.output)

    if args.architecture:
        render_architecture(destination)
        return

    input_path = pathlib.Path(args.input)
    render_terminal(
        title=args.title,
        command=args.command,
        output=input_path.read_text(),
        destination=destination,
    )


if __name__ == "__main__":
    main()
