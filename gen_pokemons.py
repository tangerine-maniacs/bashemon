#! /usr/bin/env python
import sys
sys.setrecursionlimit(10000)

from tqdm import tqdm
import numpy as np
import cv2

def get_sub_image(image:np.ndarray, sub_index:int) -> np.ndarray:
    ipos = sub_index // 15, sub_index % 15
    gpos = ipos[0] * 128 + ipos[0], ipos[1] * 64 + ipos[1]
    rpos = gpos[0] + 2 * 32, gpos[1] + 1 * 32

    return image[rpos[0]:rpos[0] + 32, rpos[1]:rpos[1] + 32]

def fill(image:np.ndarray, pos:tuple, color:int) -> None:

    this = image[pos]
    image[pos] = color

    if (this == color):
        return;

    # Check all sides
    # pos = (y, x)
    if (pos[0] != 0 and image[pos[0] - 1, pos[1]] == this):
        fill(image, (pos[0] - 1, pos[1]), color)

    if (pos[1] != 0 and image[pos[0], pos[1] - 1] == this):
        fill(image, (pos[0], pos[1] - 1), color)

    if (pos[0] != image.shape[0] - 1 and image[pos[0] + 1, pos[1]] == this):
        fill(image, (pos[0] + 1, pos[1]), color)

    if (pos[1] != image.shape[1] - 1 and image[pos[0], pos[1] + 1] == this):
        fill(image, (pos[0], pos[1] + 1), color)

IMAGE_PATH = "all_pokes.png"
# CHARS = " */@"[::-1]
CHARS = " ░▒▓█"[::-1]
image = cv2.imread(IMAGE_PATH, cv2.IMREAD_GRAYSCALE)
text = [] 

for i in tqdm(range(151)):
    # Get image
    small_image = get_sub_image(image, i)
    im_max, im_min = np.max(small_image), np.min(small_image)

    # Fill background with lightest color
    fill(small_image, (0, 0), im_max)

    # Normalize
    dist = im_max - im_min
    relation = 255 / dist

    small_image = (np.array(small_image, dtype=np.float32) - im_min) * relation 

    # Convert to txt
    for line in small_image: 
        text.append("".join(CHARS[int(v // (255 // len(CHARS) + 1))] for v in line) + "\n")

# Write
with open("smallsprites.txt", "w") as f:
    f.writelines(text)


