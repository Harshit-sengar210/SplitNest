import cv2
import numpy as np
import glob

def remove_bg(img_path, out_path):
    img = cv2.imread(img_path)
    if img is None: return
    
    bg_color = np.array([251, 249, 248], dtype=np.float32) # BGR
    img_f = img.astype(np.float32)
    diff = np.linalg.norm(img_f - bg_color, axis=2)
    
    alpha = np.clip((diff - 10) * (255.0 / 50.0), 0, 255).astype(np.uint8)
    
    mask = np.zeros((img.shape[0]+2, img.shape[1]+2), np.uint8)
    cv2.floodFill(img.copy(), mask, (0, 0), (0, 255, 0), (10, 10, 10), (10, 10, 10), cv2.FLOODFILL_MASK_ONLY | (255 << 8))
    
    flood_mask = mask[1:-1, 1:-1]
    flood_mask = cv2.GaussianBlur(flood_mask, (7, 7), 0)
    fg_mask = cv2.bitwise_not(flood_mask)
    
    rgba = cv2.cvtColor(img, cv2.COLOR_BGR2BGRA)
    rgba[:, :, 3] = fg_mask
    
    cv2.imwrite(out_path, rgba)
    print(f"Saved {out_path}")

for f in glob.glob('assets/images/3d_*.png'):
    remove_bg(f, f)

