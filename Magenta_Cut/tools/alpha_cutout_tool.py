#!/usr/bin/env python3
"""Magenta (#FF00FF) chroma-key PNG to transparent PNG converter.

With no arguments this opens a Korean desktop UI. It can also be used from the
command line, for example:

    python tools/alpha_cutout_tool.py image1.png image2.png --suffix _alpha

The key color is explicit, never inferred from white corners. The legacy module
and function names are retained for existing launchers. Source files are protected.
"""

from __future__ import annotations

import argparse
import math
import sys
from pathlib import Path
from typing import Iterable

import cv2
import numpy as np
from PIL import Image, ImageDraw, ImageTk


DEFAULT_KEY = "#FF00FF"


def parse_key_color(value: str) -> tuple[int, int, int]:
    raw = value.strip().removeprefix("#")
    if len(raw) != 6 or any(char not in "0123456789abcdefABCDEF" for char in raw):
        raise ValueError("배경색은 #FF00FF처럼 6자리 RGB 값으로 입력하세요.")
    return tuple(int(raw[index:index + 2], 16) for index in (0, 2, 4))


def remove_border_background(
    source: Image.Image,
    hard_tolerance: int = 8,
    soft_tolerance: int = 80,
    feather: float = 0.35,
    decontaminate: bool = True,
    remove_enclosed_holes: bool = True,
    key_color: str = DEFAULT_KEY,
) -> Image.Image:
    """Return an RGBA image keyed against an explicit RGB color.

    hard_tolerance controls pixels considered fully background-colored.
    soft_tolerance controls how far faint antialiasing/effects can be followed
    from the border. The area between both values becomes partially transparent.
    """
    if not 0 <= hard_tolerance < soft_tolerance <= 255:
        raise ValueError("허용 범위는 0 ≤ 완전 제거 < 가장자리 범위 ≤ 255여야 합니다.")
    if not math.isfinite(feather) or not 0 <= feather <= 3:
        raise ValueError("테두리 부드러움은 0~3 사이여야 합니다.")

    rgba = np.asarray(source.convert("RGBA"), dtype=np.uint8).copy()
    original_alpha = rgba[:, :, 3].copy()
    background = np.array(parse_key_color(key_color), dtype=np.float32)
    rgb_float = rgba[:, :, :3].astype(np.float32)
    difference = np.max(np.abs(rgb_float - background), axis=2)

    matching = (difference < float(soft_tolerance)) & (original_alpha > 0)
    if remove_enclosed_holes:
        # Small enclosed gaps count too; white/lavender details do not match magenta.
        exterior = matching
    else:
        passable = (matching | (original_alpha == 0)).astype(np.uint8)
        _, labels = cv2.connectedComponents(passable, connectivity=4)
        border_labels = np.unique(np.concatenate((labels[0], labels[-1], labels[:, 0], labels[:, -1])))
        exterior = matching & np.isin(labels, border_labels[border_labels != 0])
    if not np.any(exterior):
        return Image.fromarray(rgba)

    transition = np.clip(
        (difference - float(hard_tolerance))
        / float(soft_tolerance - hard_tolerance),
        0.0,
        1.0,
    )
    # Smoothstep gives a cleaner edge than a linear transition.
    transition = transition * transition * (3.0 - 2.0 * transition)
    alpha = np.full(difference.shape, 255.0, dtype=np.float32)
    alpha[exterior] = transition[exterior] * 255.0

    if feather > 0.0:
        alpha = cv2.GaussianBlur(alpha, (0, 0), sigmaX=float(feather), sigmaY=float(feather))
    # Feathering must not resurrect fully keyed pixels or increase existing alpha.
    alpha[exterior & (difference <= hard_tolerance)] = 0.0
    key_opacity = alpha / 255.0
    alpha = original_alpha.astype(np.float32) * key_opacity

    if decontaminate:
        # Reverse keyed-background compositing without undoing the source's alpha.
        opacity = key_opacity
        semitransparent = (opacity > 0.015) & (opacity < 0.995)
        safe_opacity = np.maximum(opacity[:, :, None], 0.015)
        recovered = (rgb_float - background[None, None, :] * (1.0 - safe_opacity)) / safe_opacity
        recovered = np.clip(recovered, 0.0, 255.0)
        rgb_float[semitransparent] = recovered[semitransparent]

    output = np.empty_like(rgba)
    output[:, :, :3] = np.clip(rgb_float, 0.0, 255.0).astype(np.uint8)
    output[:, :, 3] = np.clip(np.rint(alpha), 0.0, 255.0).astype(np.uint8)
    output[output[:, :, 3] == 0, :3] = 0  # No hidden magenta during texture filtering.
    return Image.fromarray(output)


def output_path_for(source: Path, output_dir: Path | None, suffix: str) -> Path:
    if any(char in suffix for char in '/\\:*?"<>|'):
        raise ValueError("접미사에는 경로 구분자나 특수문자를 사용할 수 없습니다.")
    folder = output_dir if output_dir is not None else source.parent
    return folder / f"{source.stem}{suffix}.png"


def convert_files(
    sources: Iterable[Path],
    output_dir: Path | None = None,
    suffix: str = "_alpha",
    hard_tolerance: int = 8,
    soft_tolerance: int = 80,
    feather: float = 0.35,
    decontaminate: bool = True,
    remove_enclosed_holes: bool = True,
    overwrite: bool = False,
    key_color: str = DEFAULT_KEY,
) -> list[Path]:
    outputs: list[Path] = []
    inputs = [Path(path).expanduser().resolve() for path in sources]
    folder = Path(output_dir).expanduser().resolve() if output_dir is not None else None
    destinations = [output_path_for(path, folder, suffix).resolve() for path in inputs]
    if len(set(destinations)) != len(destinations):
        raise ValueError("같은 출력 파일명이 겹칩니다. 파일명을 바꾸거나 별도 폴더로 나눠 변환하세요.")
    # Check every output before writing any, including input aliases/hard links.
    for source_path, destination in zip(inputs, destinations):
        if destination in inputs or any(destination.exists() and destination.samefile(item) for item in inputs if item.exists()):
            raise ValueError("원본은 덮어쓸 수 없습니다. 다른 출력 폴더나 _alpha 접미사를 사용하세요.")
        if not source_path.is_file():
            raise FileNotFoundError(f"입력 파일을 찾을 수 없습니다: {source_path}")
        if destination.exists() and not overwrite:
            raise FileExistsError(f"이미 존재하는 파일입니다: {destination}")
    for source_path, destination in zip(inputs, destinations):
        with Image.open(source_path) as image:
            result = remove_border_background(
                image,
                hard_tolerance=hard_tolerance,
                soft_tolerance=soft_tolerance,
                feather=feather,
                decontaminate=decontaminate,
                remove_enclosed_holes=remove_enclosed_holes,
                key_color=key_color,
            )
        destination.parent.mkdir(parents=True, exist_ok=True)
        result.save(destination, format="PNG", optimize=True)
        outputs.append(destination)
    return outputs


def checkerboard(size: tuple[int, int], cell: int = 18) -> Image.Image:
    image = Image.new("RGB", size, "#f6f6f6")
    draw = ImageDraw.Draw(image)
    for y in range(0, size[1], cell):
        for x in range(0, size[0], cell):
            if (x // cell + y // cell) % 2:
                draw.rectangle((x, y, x + cell - 1, y + cell - 1), fill="#d9d9d9")
    return image


def make_preview(image: Image.Image, size: tuple[int, int] = (420, 350), alpha: bool = False, background: str = "checker") -> Image.Image:
    preview = image.convert("RGBA")
    preview.thumbnail(size, Image.Resampling.LANCZOS)
    base = checkerboard(size) if background == "checker" else Image.new("RGB", size, background)
    x = (size[0] - preview.width) // 2
    y = (size[1] - preview.height) // 2
    base.paste(preview, (x, y), preview)
    return base


def launch_gui() -> None:
    import tkinter as tk
    from tkinter import colorchooser, filedialog, messagebox, ttk

    class AlphaToolApp(tk.Tk):
        def __init__(self) -> None:
            super().__init__()
            self.title("마젠타 PNG 배경 제거기")
            self.geometry(f"1040x{min(820, self.winfo_screenheight() - 120)}+30+30")
            self.minsize(900, 660)
            self.files: list[Path] = []
            self.output_dir: Path | None = None
            self.preview_refs: list[ImageTk.PhotoImage] = []

            header = ttk.Label(
                self,
                text="마젠타(#FF00FF) → 투명 PNG · 원본 보존 · 기본 저장: 이름_alpha.png",
                font=("Malgun Gothic", 12, "bold"),
            )
            header.pack(fill="x", padx=16, pady=(14, 8))

            top = ttk.Frame(self)
            top.pack(fill="x", padx=16)
            ttk.Button(top, text="PNG 추가", command=self.add_files).pack(side="left", padx=(0, 6))
            ttk.Button(top, text="선택 삭제", command=self.remove_selected).pack(side="left", padx=6)
            ttk.Button(top, text="출력 폴더 선택", command=self.choose_output).pack(side="left", padx=6)
            self.output_label = ttk.Label(top, text="출력: 각 원본 폴더")
            self.output_label.pack(side="left", padx=12)

            self.file_list = tk.Listbox(self, height=4, selectmode=tk.EXTENDED, exportselection=False)
            self.file_list.pack(fill="x", padx=16, pady=8)
            self.file_list.bind("<<ListboxSelect>>", lambda _event: self.refresh_preview())

            settings = ttk.LabelFrame(self, text="배경 제거 설정")
            settings.pack(fill="x", padx=16, pady=4)
            self.hard_var = tk.IntVar(value=8)
            self.soft_var = tk.IntVar(value=80)
            self.feather_var = tk.DoubleVar(value=0.35)
            self.decontaminate_var = tk.BooleanVar(value=True)
            self.remove_holes_var = tk.BooleanVar(value=True)
            self.overwrite_var = tk.BooleanVar(value=False)
            self.key_var = tk.StringVar(value=DEFAULT_KEY)
            self.keep_name_var = tk.BooleanVar(value=False)
            self.preview_bg_var = tk.StringVar(value="체크무늬")

            self._slider(settings, "완전 제거 허용 범위", self.hard_var, 0, 80, 0)
            self._slider(settings, "가장자리 색 허용 범위", self.soft_var, 1, 220, 1)
            self._slider(settings, "테두리 부드러움", self.feather_var, 0.0, 2.0, 2, resolution=0.05)
            ttk.Checkbutton(settings, text="둘러싸인 마젠타 구멍도 제거", variable=self.remove_holes_var).grid(row=3, column=0, sticky="w", padx=10, pady=5)
            ttk.Checkbutton(settings, text="가장자리 마젠타색 복원", variable=self.decontaminate_var).grid(row=3, column=1, sticky="w", padx=10, pady=5)
            ttk.Checkbutton(settings, text="기존 결과 PNG 덮어쓰기", variable=self.overwrite_var).grid(row=4, column=0, sticky="w", padx=10, pady=5)
            ttk.Button(settings, text="미리보기 갱신", command=self.refresh_preview).grid(row=4, column=2, padx=10, pady=5)
            ttk.Checkbutton(settings, text="별도 폴더에 원래 이름으로 저장", variable=self.keep_name_var).grid(row=4, column=1, sticky="w", padx=10)
            ttk.Label(settings, text="배경색 RGB").grid(row=5, column=0, sticky="w", padx=10)
            key_row = ttk.Frame(settings)
            key_row.grid(row=5, column=1, sticky="w", padx=10)
            ttk.Entry(key_row, textvariable=self.key_var, width=12).pack(side="left")
            ttk.Button(key_row, text="색 선택", command=self.choose_key).pack(side="left", padx=8)
            ttk.Label(settings, text="결과 미리보기 배경").grid(row=6, column=0, sticky="w", padx=10)
            preview_select = ttk.Combobox(settings, textvariable=self.preview_bg_var, values=["체크무늬", "어두운 배경", "흰 배경"], state="readonly", width=18)
            preview_select.grid(row=6, column=1, sticky="w", padx=10, pady=5)
            preview_select.bind("<<ComboboxSelected>>", lambda _event: self.refresh_preview())
            ttk.Label(self, text="※ 피사체에 같은 마젠타색이 있으면 함께 지워집니다. 구멍 제거 옵션과 미리보기를 확인하세요.").pack(anchor="w", padx=16)

            previews = ttk.Frame(self)
            previews.pack(fill="both", expand=True, padx=16, pady=8)
            left = ttk.LabelFrame(previews, text="원본")
            right = ttk.LabelFrame(previews, text="투명 결과 미리보기")
            left.pack(side="left", fill="both", expand=True, padx=(0, 4))
            right.pack(side="left", fill="both", expand=True, padx=(4, 0))
            self.before_label = ttk.Label(left, anchor="center")
            self.after_label = ttk.Label(right, anchor="center")
            self.before_label.pack(fill="both", expand=True)
            self.after_label.pack(fill="both", expand=True)

            bottom = ttk.Frame(self)
            bottom.pack(fill="x", padx=16, pady=(0, 14))
            self.status = ttk.Label(bottom, text="PNG를 추가하세요.")
            self.status.pack(side="left", fill="x", expand=True)
            ttk.Button(bottom, text="목록 전체 변환", command=self.convert).pack(side="right")

        def _slider(self, parent, label, variable, start, end, row, resolution=1) -> None:
            ttk.Label(parent, text=label).grid(row=row, column=0, sticky="w", padx=10, pady=4)
            scale = tk.Scale(
                parent,
                from_=start,
                to=end,
                orient="horizontal",
                variable=variable,
                resolution=resolution,
                length=430,
            )
            scale.grid(row=row, column=1, columnspan=2, sticky="ew", padx=8)

        def add_files(self) -> None:
            selected = filedialog.askopenfilenames(
                title="마젠타 배경 PNG 선택",
                filetypes=(("PNG 이미지", "*.png"), ("모든 파일", "*.*")),
            )
            for raw_path in selected:
                path = Path(raw_path)
                if path not in self.files:
                    self.files.append(path)
                    self.file_list.insert(tk.END, str(path))
            if self.files:
                self.file_list.selection_clear(0, tk.END)
                self.file_list.selection_set(0)
                self.refresh_preview()

        def remove_selected(self) -> None:
            for index in reversed(self.file_list.curselection()):
                self.file_list.delete(index)
                del self.files[index]
            if self.files:
                self.file_list.selection_set(0)
            self.refresh_preview()

        def choose_output(self) -> None:
            selected = filedialog.askdirectory(title="출력 폴더 선택")
            if selected:
                self.output_dir = Path(selected)
                self.output_label.configure(text=f"출력: {self.output_dir}")

        def choose_key(self) -> None:
            color = colorchooser.askcolor(color=DEFAULT_KEY, title="제거할 배경색 선택")[1]
            if color:
                self.key_var.set(color.upper())
                self.refresh_preview()

        def selected_index(self) -> int | None:
            selected = self.file_list.curselection()
            if selected:
                return int(selected[0])
            return 0 if self.files else None

        def refresh_preview(self) -> None:
            index = self.selected_index()
            if index is None:
                self.before_label.configure(image="")
                self.after_label.configure(image="")
                self.status.configure(text="PNG를 추가하세요.")
                return
            try:
                self.status.configure(text="미리보기를 처리하는 중...")
                self.update_idletasks()
                with Image.open(self.files[index]) as source:
                    original = source.convert("RGBA")
                    converted = remove_border_background(
                        original,
                        int(self.hard_var.get()),
                        int(self.soft_var.get()),
                        float(self.feather_var.get()),
                        bool(self.decontaminate_var.get()),
                        bool(self.remove_holes_var.get()),
                        self.key_var.get(),
                    )
                preview_size = (max(200, min(440, self.before_label.winfo_width() - 8)), max(100, min(380, self.before_label.winfo_height() - 8)))
                background = {"체크무늬":"checker", "어두운 배경":"#182230", "흰 배경":"#ffffff"}[self.preview_bg_var.get()]
                before = ImageTk.PhotoImage(make_preview(original, preview_size))
                after = ImageTk.PhotoImage(make_preview(converted, preview_size, alpha=True, background=background))
                self.preview_refs = [before, after]
                self.before_label.configure(image=before)
                self.after_label.configure(image=after)
                self.status.configure(text=f"미리보기: {self.files[index].name}")
            except Exception as exc:  # UI boundary: show a useful message instead of closing.
                messagebox.showerror("미리보기 실패", str(exc))
                self.status.configure(text="미리보기에 실패했습니다.")

        def convert(self) -> None:
            if not self.files:
                messagebox.showinfo("안내", "먼저 PNG를 추가하세요.")
                return
            if self.keep_name_var.get() and self.output_dir is None:
                messagebox.showinfo("출력 폴더 필요", "원래 이름을 유지하려면 원본과 다른 출력 폴더를 선택하세요.")
                return
            try:
                self.status.configure(text="변환 중...")
                self.update_idletasks()
                outputs = convert_files(
                    self.files,
                    output_dir=self.output_dir,
                    suffix="" if self.keep_name_var.get() else "_alpha",
                    hard_tolerance=int(self.hard_var.get()),
                    soft_tolerance=int(self.soft_var.get()),
                    feather=float(self.feather_var.get()),
                    decontaminate=bool(self.decontaminate_var.get()),
                    remove_enclosed_holes=bool(self.remove_holes_var.get()),
                    overwrite=bool(self.overwrite_var.get()),
                    key_color=self.key_var.get(),
                )
                self.status.configure(text=f"완료: {len(outputs)}장 변환")
                messagebox.showinfo("변환 완료", "\n".join(str(path) for path in outputs[:8]) + (f"\n외 {len(outputs) - 8}개" if len(outputs) > 8 else ""))
            except Exception as exc:
                messagebox.showerror("변환 실패", str(exc))
                self.status.configure(text="변환에 실패했습니다.")

    AlphaToolApp().mainloop()


def parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="마젠타(#FF00FF) 배경 PNG를 투명 PNG로 변환합니다.")
    parser.add_argument("images", nargs="*", type=Path, help="변환할 PNG 파일")
    parser.add_argument("--output-dir", type=Path, default=None, help="출력 폴더")
    parser.add_argument("--suffix", default="_alpha", help="출력 파일명 접미사")
    parser.add_argument("--keep-name", action="store_true", help="별도 출력 폴더에 원래 파일명으로 저장")
    parser.add_argument("--key-color", default=DEFAULT_KEY, help="제거할 RGB (기본: #FF00FF)")
    parser.add_argument("--hard", type=int, default=8, help="완전 제거 허용 범위")
    parser.add_argument("--soft", type=int, default=80, help="가장자리 색 허용 범위")
    parser.add_argument("--feather", type=float, default=0.35, help="테두리 부드러움 (0~3)")
    parser.add_argument("--decontaminate", dest="decontaminate", action="store_true", default=True, help="가장자리 색 복원 켜기 (기본)")
    parser.add_argument("--no-decontaminate", dest="decontaminate", action="store_false", help="가장자리 색 복원 끄기")
    parser.add_argument("--keep-holes", action="store_true", help="외곽과 연결되지 않은 마젠타 영역 보존")
    parser.add_argument("--overwrite", action="store_true", help="기존 출력 파일 덮어쓰기")
    return parser.parse_args(argv)


def main(argv: list[str] | None = None) -> int:
    args = parse_args(sys.argv[1:] if argv is None else argv)
    if not args.images:
        launch_gui()
        return 0
    try:
        if args.keep_name and args.output_dir is None:
            raise ValueError("--keep-name에는 --output-dir로 별도 출력 폴더를 지정해야 합니다.")
        outputs = convert_files(
            args.images,
            output_dir=args.output_dir,
            suffix="" if args.keep_name else args.suffix,
            hard_tolerance=args.hard,
            soft_tolerance=args.soft,
            feather=args.feather,
            decontaminate=args.decontaminate,
            remove_enclosed_holes=not args.keep_holes,
            overwrite=args.overwrite,
            key_color=args.key_color,
        )
    except Exception as exc:
        if sys.stderr is not None:
            print(f"ERROR: {exc}", file=sys.stderr)
        else:
            from tkinter import messagebox
            messagebox.showerror("변환 실패", str(exc))
        return 1
    if sys.stdout is not None:
        for path in outputs:
            print(path)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
