import sys
import subprocess
import numpy as np
from PIL import Image

# ---------------- CONFIG ----------------

WIDTH = 160
HEIGHT = 200
COLORS = 16
FPS = 2

INPUT_VIDEO = sys.argv[1]
OUTPUT_BIN = sys.argv[2]

AUDIO_RATE = 4000
AUDIO_EVERY_N_BYTES = 8

# --------- GAMMA LUT (TUA) ---------------

intens = np.array([
0,100,127,147,163,179,191,203,
215,223,231,239,243,247,251,255
], dtype=np.uint8)

gamma4 = np.zeros(256, dtype=np.uint8)

for i in range(256):
    gamma4[i] = np.argmin(np.abs(intens - i))

# -------------- RGB444 -------------------
def rgb444_bytes(r8, g8, b8):
    r4 = r8 >> 4
    g4 = g8 >> 4
    b4 = b8 >> 4
    v = (g4 << 12) | (r4 << 8) | b4
    return v.to_bytes(2, "big")

# -------------- AUDIO 6 BIT --------------

def audio_6bit(sample8):
    return sample8 >> 2


# -------------- PIPE VIDEO ---------------

video_cmd = [
    "ffmpeg",
    "-i", INPUT_VIDEO,
    "-vf", f"scale={WIDTH}:{HEIGHT},fps={FPS}",
    "-f", "rawvideo",
    "-pix_fmt", "rgb24",
    "-"
]

video_pipe = subprocess.Popen(video_cmd, stdout=subprocess.PIPE)

# -------------- PIPE AUDIO ---------------

audio_cmd = [
    "ffmpeg",
    "-i", INPUT_VIDEO,
    "-vn",
    "-ac", "1",
    "-ar", str(AUDIO_RATE),
    "-af", "volume=20",
    "-f", "u8",
    "-"
]

audio_pipe = subprocess.Popen(audio_cmd, stdout=subprocess.PIPE)

frame_size = WIDTH * HEIGHT * 3

# =========================================

with open(OUTPUT_BIN, "wb") as out:

    frame_num = 0

    while True:

        raw = video_pipe.stdout.read(frame_size)

        if len(raw) < frame_size:
            break

        frame_num += 1
        print("frame", frame_num)

        # ---------- numpy image ----------

        arr = np.frombuffer(raw, dtype=np.uint8)
        arr = arr.reshape((HEIGHT, WIDTH, 3))

        img = Image.fromarray(arr, "RGB")

        qimg = img.quantize(
            colors=COLORS,
            method=Image.MEDIANCUT,
            dither=Image.FLOYDSTEINBERG
        )
  
        # ---------- palette ----------

        pal = qimg.getpalette()[:COLORS * 3]

        for i in range(COLORS):

            r8 = pal[i*3 + 0]
            g8 = pal[i*3 + 1]
            b8 = pal[i*3 + 2]

            out.write(rgb444_bytes(r8, g8, b8))

        # ---------- pixel indicizzati ----------

        pixels = np.array(qimg)

        even = bytearray()
        odd = bytearray()

        for y in range(HEIGHT):

            row = pixels[y]

            for x in range(0, WIDTH, 2):

                p1 = int(row[x]) & 0x0F
                p2 = int(row[x+1]) & 0x0F

                byte = (p1 << 4) | p2

                byte_col = (x // 2)

                if (byte_col % 2) == 0:
                    even.append(byte)
                else:
                    odd.append(byte)

        if len(even) != 8000 or len(odd) != 8000:
            raise RuntimeError("errore dimensioni")

        # ---------- interleaving audio ----------

        video_stream = even + odd

        byte_counter = 0

        for vb in video_stream:

            if byte_counter == 0:

                a = audio_pipe.stdout.read(1)

                if a:
                    s6 = audio_6bit(a[0])
                    #print("sanple ",s6)
                else:
                    s6 = 32

                out.write(bytes([s6]))
				
            out.write(bytes([vb]))
            byte_counter += 1

            if byte_counter >= AUDIO_EVERY_N_BYTES:

                byte_counter = 0


print("OK ->", OUTPUT_BIN)