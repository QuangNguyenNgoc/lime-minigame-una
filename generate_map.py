import cv2
import numpy as np
import os
import sys


def simplify_image(img_path, idx):
    # Load image
    img = cv2.imread(img_path)
    if img is None:
        print(f"[Canh bao] Khong tim thay anh: {img_path}. Se thay the bang nen den.")
        # Kích thước mặc định của ROI (1692x860) nếu thiếu ảnh
        img = np.zeros((860, 1692, 3), dtype=np.uint8)

    # Resize để đảm bảo tất cả ảnh bằng chằn chặn nhau (phòng khi ROI bị xê dịch)
    img = cv2.resize(img, (1692, 860))

    # 1. Làm mờ để xoá vân đất (Bilateral filter giữ cạnh)
    blurred = cv2.bilateralFilter(img, d=9, sigmaColor=75, sigmaSpace=75)

    # 2. Rút gọn màu (K-means Posterization)
    Z = blurred.reshape((-1, 3))
    Z = np.float32(Z)
    criteria = (cv2.TERM_CRITERIA_EPS + cv2.TERM_CRITERIA_MAX_ITER, 10, 1.0)
    K = 5  # Ép bức ảnh xuống chỉ còn 5 màu cơ bản
    ret, label, center = cv2.kmeans(Z, K, None, criteria, 10, cv2.KMEANS_RANDOM_CENTERS)
    center = np.uint8(center)
    res = center[label.flatten()]
    quantized = res.reshape((img.shape))

    # 3. Tìm vách núi/cạnh (Canny)
    gray = cv2.cvtColor(blurred, cv2.COLOR_BGR2GRAY)
    edges = cv2.Canny(gray, 40, 120)
    # Làm viền đen dày lên để dễ nhìn
    kernel = np.ones((3, 3), np.uint8)
    edges = cv2.dilate(edges, kernel, iterations=1)

    # 4. Đè viền đen lên ảnh đã rút gọn màu
    quantized[edges > 0] = [0, 0, 0]

    # 5. Đánh số góc (viền đen, chữ trắng cho dễ nổi)
    font = cv2.FONT_HERSHEY_DUPLEX
    text = f"Khu {idx}"
    # Viền đen
    cv2.putText(quantized, text, (50, 120), font, 3, (0, 0, 0), 12, cv2.LINE_AA)
    # Chữ trắng
    cv2.putText(quantized, text, (50, 120), font, 3, (255, 255, 255), 4, cv2.LINE_AA)

    return quantized


def main():
    data_dir = os.path.join(
        os.path.dirname(os.path.abspath(__file__)), "data", "map_capture"
    )

    if not os.path.exists(data_dir):
        print(
            f"[Loi] Khong tim thay thu muc {data_dir}. Vui long tao thu muc va chup anh tu 1.png den 8.png."
        )
        sys.exit(1)

    processed_imgs = []
    print("Bat dau xu ly tung khu vuc...")
    for i in range(1, 9):
        path = os.path.join(data_dir, f"{i}.png")
        print(f" - Dang xu ly: {i}.png")
        p_img = simplify_image(path, i)
        processed_imgs.append(p_img)

    print("Dang ghep luoi 4x2...")
    # Ghép ngang từng hàng
    row1 = np.hstack([processed_imgs[0], processed_imgs[1]])
    row2 = np.hstack([processed_imgs[2], processed_imgs[3]])
    row3 = np.hstack([processed_imgs[4], processed_imgs[5]])
    row4 = np.hstack([processed_imgs[6], processed_imgs[7]])

    # Ghép dọc 4 hàng
    final_map = np.vstack([row1, row2, row3, row4])

    out_path = os.path.join(data_dir, "final_map_2D.png")
    cv2.imwrite(out_path, final_map)
    print(f"\n=================================")
    print(f"HOAN THANH! Ban do 2D da duoc luu tai:")
    print(f"{out_path}")
    print(f"=================================")


if __name__ == "__main__":
    main()
