----CÂU 1.2 Thêm vào thuộc tính GHICHU có kiểu dữ liệu varchar(20) cho quan hệ SANPHAM.
ALTER TABLE SANPHAM ADD GHICHU VARCHAR(20)
----CÂU 1.3 Thêm vào thuộc tính LOAIKH có kiểu dữ liệu là tinyint cho quan hệ KHACHHANG.
ALTER TABLE KHACHHANG ADD LOAIKH TINYINT
----CÂU 1.4 Sửa kiểu dữ liệu của thuộc tính GHICHU trong quan hệ SANPHAM thành varchar(100)
ALTER TABLE SANPHAM ALTER COLUMN GHICHU VARCHAR(100)
----CÂU 1.5 Xóa thuộc tính GHICHU trong quan hệ SANPHAM
ALTER TABLE SANPHAM DROP COLUMN GHICHU
----CÂU 1.6 Làm thế nào để thuộc tính LOAIKH trong quan hệ KHACHHANG có thể lưu các giá trị là: “Vang lai”, “Thuong xuyen”, “Vip”, …
ALTER TABLE KHACHHANG ALTER COLUMN LOAIKH VARCHAR(100)
----CÂU 1.7 Đơn vị tính của sản phẩm chỉ có thể là (“cay”,”hop”,”cai”,”quyen”,”chuc”)
ALTER TABLE SANPHAM ADD CONSTRAINT CHK_DVT
CHECK (DVT = 'cay' OR DVT = 'hop' OR DVT ='cai' OR DVT = 'quyen' OR DVT = 'chuc') 
----CÂU 1.8 Giá bán của sản phẩm từ 500 đồng trở lên.
ALTER TABLE SANPHAM ADD CONSTRAINT CHK_GB CHECK (GIA >= 500)
----CAU 1.9 Mỗi lần mua hàng, khách hàng phải mua ít nhất 1 sản phẩm
ALTER TABLE KHACHHANG ADD CONSTRAINT CHK_NDK CHECK (NGDK > NGSINH)
---Câu 1.11. Ngày mua hàng (NGHD) của một khách hàng thành viên sẽ lớn hơn hoặc bằng ngày khách hàng đó đăng ký thành viên (NGDK)
CREATE TRIGGER  NGHD_HOADON_INSERTED
ON HOADON
AFTER INSERT
AS
DECLARE @NG_MUAHANG SMALLDATETIME
DECLARE @NG_DANGKY SMALLDATETIME
SELECT @NG_MUAHANG = NGHD, @NG_DANGKY = NGDK
FROM KHACHHANG, INSERTED
WHERE KHACHHANG.MAKH = INSERTED.MAKH
IF  @NG_MUAHANG < @NG_DANGKY
BEGIN
	rollback transaction
	print 'ngay mua hang phai lon hon ngay dang ky'
END
---Câu 1.12. Ngày bán hàng (NGHD) của một nhân viên phải lớn hơn hoặc bằng ngày nhân viên đó vào làm
CREATE TRIGGER NGAYBANHANG_HOADON_INSERTED 
ON HOADON 
AFTER INSERT
AS 
DECLARE @NG_BANHANG SMALLDATETIME
DECLARE @NG_VAOLAM SMALLDATETIME
SELECT @NG_BANHANG = NGHD, @NG_VAOLAM = NGVL
FROM NHANVIEN, INSERTED
WHERE NHANVIEN.MANV = INSERTED.MANV
IF @NG_BANHANG < @NG_VAOLAM
BEGIN 
	ROLLBACK TRANSACTION 
	PRINT 'NGAY BAN HANG PHAI LON HOAC BANG NGAY VAO LAM'
END
---Câu 1.13. Mỗi một hóa đơn phải có ít nhất một chi tiết hóa đơn.
CREATE TRIGGER CTHD_DELETE
ON CTHD
AFTER DELETE
AS 
IF (EXISTS (SELECT * FROM DELETED JOIN HOADON HD ON DELETED.SOHD = HD.SOHD))
BEGIN 
	ROLLBACK TRANSACTION 
	PRINT 'MOI HOA DON PHAI CO IT NHAT MOT CHI TIET HOA DON'
END
---Câu 1.14. Trị giá của một hóa đơn là tổng thành tiền (số lượng*đơn giá) của các chi tiết thuộc hóa đơn đó.
CREATE TRIGGER 
---Câu 1.15. Doanh số của một khách hàng là tổng trị giá các hóa đơn mà khách hàng thành viên đó đã mua.
---CÂU 2.2 Tạo quan hệ SANPHAM1 chứa toàn bộ dữ liệu của quan hệ SANPHAM. Tạo quan hệ KHACHHANG1 chứa toàn bộ dữ liệu của quan hệ KHACHHANG
SELECT * INTO SANPHAM1 FROM SANPHAM
SELECT * INTO KHACHHANG1 FROM KHACHHANG
---CÂU 2.3 Cập nhật giá tăng 5% đối với những sản phẩm do “Thai Lan” sản xuất (cho quan hệ SANPHAM1)
UPDATE SANPHAM1
SET GIA = GIA* 1.05 
WHERE NUOCSX = 'Thai Lan'
---CÂU 2.4 Cập nhật giá giảm 5% đối với những sản phẩm do “Trung Quoc” sản xuất có giá từ 10.000 trở xuống (cho quan hệ SANPHAM1)
UPDATE SANPHAM1
SET GIA = GIA* 0.95 
WHERE NUOCSX = 'Trung Quoc' AND GIA <= 10000
---CÂU 2.5 Cập nhật giá trị LOAIKH là “Vip” đối với những khách hàng đăng ký thành viên trước ngày 1/1/2007 có doanh số từ 10.000.000 trở lên hoặc khách hàng đăng ký thành viên từ 1/1/2007 trở về sau có doanh số từ 2.000.000 trở lên (cho quan hệ KHACHHANG1)
UPDATE KHACHHANG1 
SET LOAIKH = 'Vip' 
WHERE (NGDK < '2007-1-1' AND DOANHSO >= 10000000) OR  (NGDK >= '2007-1-1' AND DOANHSO >= 20000000)
----CÂU 3.1 In ra danh sách các sản phẩm (MASP,TENSP) do “Trung Quoc” sản xuất.
SELECT MASP, TENSP
FROM SANPHAM
WHERE NUOCSX = 'Trung Quoc'
----CÂU 3.2 In ra danh sách các sản phẩm (MASP, TENSP) có đơn vị tính là “cay”, ”quyen”.
SELECT MASP, TENSP
FROM SANPHAM
WHERE DVT = 'cay' OR DVT = 'quyen'
----CÂU 3.3 In ra danh sách các sản phẩm (MASP,TENSP) có mã sản phẩm bắt đầu là “B” và kết thúc là “01”.
SELECT MASP, TENSP
FROM SANPHAM
WHERE MASP LIKE 'B%01'
----CÂU 3.4 In ra danh sách các sản phẩm (MASP,TENSP) do “Trung Quốc” sản xuất có giá từ 30.000 đến 40.000.
SELECT MASP, TENSP
FROM SANPHAM 
WHERE NUOCSX = 'Trung Quoc' OR (GIA >= 30000 AND GIA <= 40000)
----CÂU 3.5 In ra danh sách các sản phẩm (MASP,TENSP) do “Trung Quoc” hoặc “Thai Lan” sản xuất có giá từ 30.000 đến 40.000
SELECT MASP, TENSP
FROM SANPHAM
WHERE (NUOCSX = 'Trung Quoc' OR NUOCSX = 'Thai Lan') AND (GIA >= 30000 AND GIA <= 40000)
----CÂU 3.6 In ra các số hóa đơn, trị giá hóa đơn bán ra trong ngày 1/1/2007 và ngày 2/1/2007
SELECT SOHD, TRIGIA
FROM HOADON
WHERE NGHD >= '2007-1-1' AND NGHD <= '2007-1-2'
---CÂU 3.7 In ra các số hóa đơn, trị giá hóa đơn trong tháng 1/2007, sắp xếp theo ngày (tăng dần) và trị giá của hóa đơn (giảm dần)
SELECT SOHD, TRIGIA
FROM HOADON 
WHERE MONTH(NGHD) ='1' AND YEAR(NGHD) ='2007'
ORDER BY NGHD ASC, TRIGIA DESC
---CÂU 3.8 In ra danh sách các khách hàng (MAKH, HOTEN) đã mua hàng trong ngày 1/1/2007
SELECT KH.MAKH, HOTEN
FROM KHACHHANG KH JOIN HOADON HD
ON KH.MAKH = HD.MAKH
WHERE NGHD = '2007-1-1'
---CÂU 3.9 In ra số hóa đơn, trị giá các hóa đơn do nhân viên có tên “Nguyen Van B” lập trong ngày 28/10/2006
SELECT SOHD, TRIGIA
FROM HOADON HD JOIN NHANVIEN NV
ON HD.MANV = NV.MANV
WHERE NGHD = '2006-10-28'
---CÂU 3.10 In ra danh sách các sản phẩm (MASP,TENSP) được khách hàng có tên “Nguyen Van A” mua trong tháng 10/2006.
SELECT SP.MASP, TENSP
FROM SANPHAM SP JOIN CTHD ON SP.MASP = CTHD.MASP 
JOIN HOADON HD ON HD.SOHD = CTHD.SOHD
JOIN KHACHHANG KH ON HD.MAKH = KH.MAKH
WHERE KH.HOTEN ='Nguyen Van A' AND (MONTH(HD.NGHD) = '10' AND YEAR (HD.NGHD) = '2006')
---CÂU 3.11 Tìm các số hóa đơn đã mua sản phẩm có mã số “BB01” hoặc “BB02”
SELECT SOHD
FROM CTHD
WHERE MASP = 'BB01' OR MASP = 'BB02'
---CÂU 3.12 Tìm các số hóa đơn đã mua sản phẩm có mã số “BB01” hoặc “BB02”, mỗi sản phẩm mua với số lượng từ 10 đến 20.
SELECT SOHD 
FROM CTHD 
WHERE MASP = 'BB01' OR MASP = 'BB02' AND (SL >= 10 AND SL <=20)
---CÂU 3.13 Tìm các số hóa đơn mua cùng lúc 2 sản phẩm có mã số “BB01” và “BB02”, mỗi sản phẩm mua với số lượng từ 10 đến 20
SELECT SOHD
FROM CTHD
WHERE MASP = 'BB01' AND (SL >= 10 AND SL <=20)
INTERSECT --- CÓ THỂ KẾT 
SELECT SOHD
FROM CTHD
WHERE MASP = 'BB02' AND (SL >= 10 AND SL <=20)

---CÂU 3.14 In ra danh sách các sản phẩm (MASP,TENSP) do “Trung Quoc” sản xuất hoặc các sản phẩm được bán ra trong ngày 1/1/2007
SELECT MASP, TENSP
FROM SANPHAM
WHERE NUOCSX = 'Trung Quoc'
UNION
SELECT SP.MASP, TENSP
FROM SANPHAM SP JOIN CTHD ON SP.MASP = CTHD.MASP
JOIN HOADON HD ON HD.SOHD = CTHD.SOHD
WHERE NGHD = '2007-1-1'
---CÂU 3.15 In ra danh sách các sản phẩm (MASP,TENSP) không bán được
SELECT MASP, TENSP
FROM SANPHAM 
EXCEPT 
SELECT SP.MASP, TENSP
FROM CTHD JOIN SANPHAM SP ON CTHD.MASP = SP.MASP
---CÂU 3.16 In ra danh sách các sản phẩm (MASP,TENSP) không bán được trong năm 2006.
SELECT MASP, TENSP
FROM SANPHAM
EXCEPT
SELECT SP.MASP, TENSP
FROM SANPHAM SP JOIN CTHD ON SP.MASP = CTHD.MASP
JOIN HOADON HD ON HD.SOHD = CTHD.SOHD
---CÂU 3.17 In ra danh sách các sản phẩm (MASP,TENSP) do “Trung Quoc” sản xuất không bán được trong năm 2006.
SELECT MASP, TENSP
FROM SANPHAM
WHERE NUOCSX = 'Trung Quoc'
EXCEPT
SELECT SP.MASP, TENSP
FROM SANPHAM SP JOIN CTHD ON SP.MASP = CTHD.MASP
JOIN HOADON HD ON HD.SOHD = CTHD.SOHD
