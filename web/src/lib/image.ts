import { UserError } from '../data/ctx.ts';

const MAX_EDGE = 1600;
const THUMB_HEIGHT = 720;

interface Decoded {
  src: CanvasImageSource;
  w: number;
  h: number;
  close: () => void;
}

async function decode(blob: Blob): Promise<Decoded> {
  try {
    const bmp = await createImageBitmap(blob, { imageOrientation: 'from-image' });
    return { src: bmp, w: bmp.width, h: bmp.height, close: () => bmp.close() };
  } catch {
    const url = URL.createObjectURL(blob);
    const img = new Image();
    img.src = url;
    try {
      await img.decode();
    } catch {
      URL.revokeObjectURL(url);
      throw new UserError('Nie udało się odczytać zdjęcia — wybierz plik JPG lub PNG');
    }
    return { src: img, w: img.naturalWidth, h: img.naturalHeight, close: () => URL.revokeObjectURL(url) };
  }
}

function toJpeg(canvas: HTMLCanvasElement, quality: number): Promise<Blob> {
  return new Promise((resolve, reject) =>
    canvas.toBlob((b) => (b ? resolve(b) : reject(new UserError('Nie udało się przygotować zdjęcia'))), 'image/jpeg', quality),
  );
}

function canvasOf(w: number, h: number): [HTMLCanvasElement, CanvasRenderingContext2D] {
  const c = document.createElement('canvas');
  c.width = Math.max(1, Math.round(w));
  c.height = Math.max(1, Math.round(h));
  const g = c.getContext('2d');
  if (!g) throw new UserError('Przeglądarka nie obsługuje obróbki zdjęć');
  g.imageSmoothingQuality = 'high';
  return [c, g];
}

/**
 * Zmniejsza zdjęcie (dłuższy bok ≤ 1600 px) i koduje je od nowa jako JPEG.
 * Nowy plik nie ma EXIF — znika GPS i dane aparatu; obrót z EXIF jest już zastosowany.
 */
export async function processPhoto(file: Blob): Promise<Blob> {
  const img = await decode(file);
  try {
    const scale = Math.min(1, MAX_EDGE / Math.max(img.w, img.h));
    const [c, g] = canvasOf(img.w * scale, img.h * scale);
    g.drawImage(img.src, 0, 0, c.width, c.height);
    return await toJpeg(c, 0.85);
  } finally {
    img.close();
  }
}

interface Cell {
  x: number;
  y: number;
  w: number;
  h: number;
}

function layout(n: number): { w: number; h: number; cells: Cell[] } {
  const W = MAX_EDGE;
  const GAP = 8;
  const half = (W - GAP) / 2;
  if (n === 2) return { w: W, h: 1000, cells: [{ x: 0, y: 0, w: half, h: 1000 }, { x: half + GAP, y: 0, w: half, h: 1000 }] };
  const H = 1200;
  const q = (H - GAP) / 2;
  return {
    w: W,
    h: H,
    cells: [
      { x: 0, y: 0, w: half, h: H },
      { x: half + GAP, y: 0, w: half, h: q },
      { x: half + GAP, y: q + GAP, w: half, h: q },
    ],
  };
}

async function scaledToHeight(blob: Blob, height: number, quality: number): Promise<Blob> {
  const img = await decode(blob);
  try {
    const scale = Math.min(1, height / img.h);
    const [c, g] = canvasOf(img.w * scale, img.h * scale);
    g.drawImage(img.src, 0, 0, c.width, c.height);
    return await toJpeg(c, quality);
  } finally {
    img.close();
  }
}

/**
 * Zgłoszenie w apce ma jedno zdjęcie (fileUrl + thumbUrl), więc 2–3 zdjęcia łączymy w jeden
 * kolaż — firma w apce widzi wszystkie. Miniatura jak w apce: 720 px wysokości, JPEG 75%.
 */
export async function composeRequestMedia(photos: Blob[]): Promise<{ file: Blob; thumb: Blob }> {
  if (!photos.length) throw new UserError('Brak zdjęć');
  let file = photos[0];
  if (photos.length > 1) {
    const { w, h, cells } = layout(Math.min(photos.length, 3));
    const [c, g] = canvasOf(w, h);
    g.fillStyle = '#ffffff';
    g.fillRect(0, 0, w, h);
    for (let i = 0; i < cells.length; i++) {
      const cell = cells[i];
      const img = await decode(photos[i]);
      try {
        g.fillStyle = '#eef1f8';
        g.fillRect(cell.x, cell.y, cell.w, cell.h);
        const s = Math.min(cell.w / img.w, cell.h / img.h);
        const dw = img.w * s;
        const dh = img.h * s;
        g.drawImage(img.src, cell.x + (cell.w - dw) / 2, cell.y + (cell.h - dh) / 2, dw, dh);
      } finally {
        img.close();
      }
    }
    file = await toJpeg(c, 0.85);
  }
  return { file, thumb: await scaledToHeight(file, THUMB_HEIGHT, 0.75) };
}
