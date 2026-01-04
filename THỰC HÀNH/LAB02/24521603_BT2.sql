---3.18 Tìm số hóa đơn đã mua tất cả các sản phẩm do Singapore sản xuất--
SELECT SOHD
FROM SANPHAM JOIN CTHD ON SANPHAM.MASP = CTHD.MASP
WHERE NUOCSX = 'Singapore'
GROUP BY SOHD
HAVING COUNT(SANPHAM.MASP) = (SELECT COUNT(*) 
			FROM SANPHAM 
			WHERE NUOCSX = 'Singapore');
 ---3.19 Tìm số hóa đơn trong năm 2006 đã mua ít nhất tất cả các sản phẩm do Singapore sản xuất--
SELECT HOADON.SOHD
FROM SANPHAM JOIN CTHD ON SANPHAM.MASP = CTHD.MASP JOIN HOADON ON HOADON.SOHD = CTHD.SOHD
WHERE NUOCSX = 'Singapore' AND YEAR(HOADON.NGHD) = 2006
GROUP BY HOADON.SOHD
HAVING COUNT (SANPHAM.MASP) = (SELECT COUNT(*)
				FROM SANPHAM 
				WHERE NUOCSX = 'Singapore');
---3.20 Có bao nhiêu hóa đơn không phải của khách hàng đăng ký thành viên mua?---
SELECT COUNT (HD.SOHD) AS IS_NOTBUY_KHTV
FROM HOADON HD
WHERE HD.MAKH IS NULL
---3.21 Có bao nhiêu sản phẩm khác nhau được bán ra trong năm 2006---
SELECT COUNT ( DISTINCT MASP) AS SO_HD
FROM CTHD JOIN HOADON ON CTHD.SOHD = HOADON.SOHD
WHERE YEAR(HOADON.NGHD) = 2006
---3.22 Cho biết trị giá hóa đơn cao nhất, thấp nhất là bao nhiêu ?---
SELECT MAX(HOADON.TRIGIA) AS HD_MAX
FROM HOADON
SELECT MIN (HOADON.TRIGIA) AS HD_MIN
FROM HOADON
---3.23 Trị giá trung bình của tất cả các hóa đơn được bán ra trong năm 2006 là bao nhiêu?---
SELECT AVG (HOADON.TRIGIA) AS AVG_VALUE
FROM HOADON
WHERE YEAR(NGHD) = 2006
---3.24 Tính doanh thu bán hàng trong năm 2006---
SELECT SUM (HOADON.TRIGIA)
FROM HOADON
WHERE YEAR(NGHD) = 2006
---3.25 Tìm số hóa đơn có trị giá cao nhất trong năm 2006---
SELECT HOADON.SOHD
FROM HOADON
WHERE YEAR(NGHD) = 2006 AND HOADON.TRIGIA = (SELECT MAX(HOADON.TRIGIA) AS HD_MAX FROM HOADON)
---3.26 Tìm họ tên khách hàng đã mua hóa đơn có trị giá cao nhất trong năm 2006---
SELECT KHACHHANG.HOTEN
FROM KHACHHANG JOIN HOADON ON KHACHHANG.MAKH = HOADON.MAKH
WHERE YEAR(NGHD) = 2006 AND HOADON.TRIGIA = (SELECT MAX(HOADON.TRIGIA) AS HD_MAX FROM HOADON)
---3.27 In ra danh sách 3 khách hàng đầu tiên (MAKH, HOTEN) sắp xếp theo doanh số giảm dần
SELECT TOP 3 MAKH, HOTEN
FROM KHACHHANG
ORDER BY DOANHSO DESC
---3.28 In ra danh sách các sản phẩm (MASP, TENSP) có giá bán bằng 1 trong 3 mức giá cao nhấT---
SELECT MASP, TENSP
FROM SANPHAM
WHERE GIA IN (SELECT DISTINCT TOP 3 GIA
			FROM SANPHAM
			ORDER BY GIA DESC)
---3.29 In ra danh sách các sản phẩm (MASP, TENSP) do “Thai Lan” sản xuất có giá bằng 1 trong 3 mức giá cao nhất (của tất cả các sản phẩm)---
SELECT MASP, TENSP
FROM SANPHAM
WHERE NUOCSX = 'THAI LAN' AND GIA IN (SELECT DISTINCT TOP 3 GIA
										FROM SANPHAM
										ORDER BY GIA DESC)
---3.30 In ra danh sách các sản phẩm (MASP, TENSP) do “Trung Quoc” sản xuất có giá bằng 1 trong 3 mức giá cao nhất (của sản phẩm do “Trung Quoc” sản xuất)
SELECT MASP, TENSP
FROM SANPHAM
WHERE NUOCSX = 'TRUNG QUOC' AND GIA IN (SELECT DISTINCT TOP 3 GIA
										FROM SANPHAM
										WHERE NUOCSX = 'TRUNG QUOC'
										ORDER BY GIA DESC)
---3.31 * In ra danh sách khách hàng nằm trong 3 hạng cao nhất (xếp hạng theo doanh số)
SELECT MAKH, HOTEN
FROM KHACHHANG
WHERE DOANHSO IN (SELECT DISTINCT TOP 3 DOANHSO
				FROM KHACHHANG
				ORDER BY DOANHSO DESC)
---3.32 Tính tổng số sản phẩm do “Trung Quoc” sản xuất.---
SELECT COUNT (SANPHAM.MASP) AS SP_TQSX
FROM SANPHAM
WHERE NUOCSX = 'TRUNG QUOC'
---3.33 Tính tổng số sản phẩm của từng nước sản xuất ---
SELECT NUOCSX, COUNT (SANPHAM.MASP) 
FROM SANPHAM 
GROUP BY NUOCSX
---3.34 Với từng nước sản xuất, tìm giá bán cao nhất, thấp nhất, trung bình của các sản phẩm.---
SELECT NUOCSX, MAX (GIA) AS MAX_VALUE, MIN(GIA) AS MIN_VALUE, AVG(GIA) AS AVG_VALUE
FROM SANPHAM
GROUP BY NUOCSX
---3.35 Tính doanh thu bán hàng mỗi ngày
SELECT NGHD, SUM(TRIGIA) AS DOANHTHU
FROM HOADON
GROUP BY NGHD
---3.36 Tính tổng số lượng của từng sản phẩm bán ra trong tháng 10/2006---
SELECT MASP, SUM (CTHD.SL) AS SL_SP
FROM CTHD JOIN HOADON ON CTHD.SOHD = HOADON.SOHD
WHERE MONTH(NGHD) = 10 AND YEAR(NGHD) = 2006
GROUP BY MASP
---3.37 Tính doanh thu bán hàng của từng tháng trong năm 2006---
SELECT MONTH(NGHD) AS MONTH, SUM(TRIGIA) AS DOANHTHU_MONTH
FROM HOADON
WHERE YEAR(NGHD) = 2006
GROUP BY MONTH(NGHD)
---3.38 Tìm hóa đơn có mua ít nhất 4 sản phẩm khác nhau---
SELECT HD.SOHD
FROM HOADON HD JOIN CTHD ON HD.SOHD = CTHD.SOHD
GROUP BY HD.SOHD
HAVING COUNT (DISTINCT MASP) >=4
---3.39 Tìm hóa đơn có mua 3 sản phẩm do “Viet Nam” sản xuất (3 sản phẩm khác nhau)
SELECT HD.SOHD
FROM HOADON HD JOIN CTHD ON HD.SOHD = CTHD.SOHD JOIN SANPHAM ON CTHD.MASP = SANPHAM.MASP
WHERE NUOCSX = 'VIET NAM'
GROUP BY HD.SOHD
HAVING COUNT (DISTINCT CTHD.MASP) = 3
---3.40 Tìm khách hàng (MAKH, HOTEN) có số lần mua hàng nhiều nhất---
SELECT TOP 1 HOADON.MAKH, HOTEN
FROM HOADON JOIN KHACHHANG ON HOADON.MAKH = KHACHHANG.MAKH
GROUP BY HOADON.MAKH, HOTEN
ORDER BY COUNT(SOHD) DESC
---3.41 Tháng mấy trong năm 2006, doanh số bán hàng cao nhất ?---
SELECT TOP 1 MONTH(NGHD) AS MONTH
FROM HOADON 
GROUP BY MONTH(HOADON.NGHD)
ORDER BY SUM(HOADON.TRIGIA) DESC
---3.42 Tìm sản phẩm (MASP, TENSP) có tổng số lượng bán ra thấp nhất trong năm 2006--
SELECT TOP 1 CTHD.MASP, TENSP
FROM SANPHAM JOIN CTHD ON SANPHAM.MASP = CTHD.MASP
GROUP BY CTHD.MASP, TENSP
ORDER BY COUNT(CTHD.SL) ASC
---3.43 Mỗi nước sản xuất, tìm sản phẩm (MASP,TENSP) có giá bán cao nhất---
SELECT NUOCSX, MASP, TENSP, GIA
FROM SANPHAM SP1
GROUP BY NUOCSX
HAVING GIA = (SELECT MAX(GIA)
				FROM SANPHAM SP2
				WHERE SP1.NUOCSX = SP2.NUOCSX) 
---3.44 Tìm nước sản xuất sản xuất ít nhất 3 sản phẩm có giá bán khác nhau.---
SELECT NUOCSX, COUNT (DISTINCT GIA) AS TYPE_GIA
FROM SANPHAM 
GROUP BY NUOCSX 
HAVING COUNT(GIA) >= 3
---3.45 Trong 10 khách hàng có doanh số cao nhất, tìm khách hàng có số lần mua hàng nhiều nhất---
SELECT TOP 1 KHACHHANG.MAKH,HOTEN, COUNT (SOHD) AS SOLANMUA
FROM KHACHHANG JOIN HOADON ON KHACHHANG.MAKH = HOADON.MAKH
WHERE KHACHHANG.MAKH IN (
        SELECT TOP 10 MAKH
        FROM KHACHHANG
        ORDER BY DOANHSO DESC)
GROUP BY KHACHHANG.MAKH, HOTEN
ORDER BY SOLANMUA DESC;
