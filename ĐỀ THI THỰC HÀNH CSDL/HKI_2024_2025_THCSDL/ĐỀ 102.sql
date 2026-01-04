CREATE DATABASE QLPT
CREATE TABLE PHONGTRO (
	MaPT char(5) Primary Key,
	TenPT nvarchar(50),
	DienTich float,
	GiaPT money,
	TinhTrangPT nvarchar(20)
)
CREATE TABLE CUDAN (
	MaCD char(5) Primary Key,
	HoTen nvarchar(50),
	CCCD nvarchar(12),
	DiaChi nvarchar(100),
	SoDT varchar(15),
	NgayThue smalldatetime,
	TrangThaiCD nvarchar(15)
)
CREATE TABLE HOPDONG (
	MaHD char(5) Primary Key,
	MaCD char(5),
	MaPT char(5),
	NgayKy smalldatetime,
	NgayHetHan smalldatetime,
	TrangThaiHD nvarchar(20),
	CONSTRAINT FK_HopDong_CuDan FOREIGN KEY (MaCD) REFERENCES CUDAN(MaCD),
	CONSTRAINT FK_HopDong_PhongTro FOREIGN KEY (MaPT) REFERENCES PHONGTRO(MaPT)
)
CREATE TABLE DICHVU (
	MaDV char(5) Primary Key,
	TenDV nvarchar(50),
	DonGia money
)
CREATE TABLE PHIEUTINHTIEN (
	MaPTT char(5) Primary Key,
	MaHD char(5)
	SoTienDichVu money,
	SoTienThuePT money,
	TongTienTT money,
	NgayTinhTien smalldatetime,
	TinhTrangTT nvarchar(20),
	PhuongThucTT nvarchar(20),
	CONSTRAINT FK_PhieuTT_HopDong FOREIGN KEY (MaHD) REFERENCES HOPDONG(MaHD)
)
CREATE TABLE CHITIETTTDV (
	MaPTT CHAR(5),
	MaDV CHAR(5),
	ChiSoDV FLOAT,
	ThanhTien MONEY
	CONSTRAINT PK_ChiTietTTDV PRIMARY KEY (MaPTT, MaDV),
	CONSTRAINT FK_ChiTiet_PhieuTT FOREIGN KEY (MaPTT) REFERENCES PHIEUTINHTIEN(MaPTT),
	CONSTRAINT FK_ChiTiet_DichVu FOREIGN KEY (MaDV) REFERENCES DICHVU(MaDV)
)
---2. Hiện thực các ràng buộc toàn vẹn---
---2.1 Giá thuê phòng trọ có giá trị trong khoảng 500000VND đến 20000000VND 
ALTER TABLE PHONGTRO
ADD CONSTRAINT CHK_GIAPT CHECK (GiaPT >= 500000 and GiaPT <= 20000000)
---2.2 Trạng thái cư dân chỉ nhận một trong hai giá trị "Đang ở" hoặc "Đã rời đi"
ALTER TABLE CUDAN
ADD CONSTRAINT CHK_TTCD CHECK (TrangThaiCD IN ('Dang o', 'Da roi di'))
---2.3 Số tiền của mỗi dịch vụ đã sử dụng (ThanhTien) trong chi tiết tính tiền dược tinhs bằng chỉ số đã sử dụng (ChiSoDV) nhân với đơn giá (DonGia) của dịch vụ đó. Hãy viết trigger để tạo ràng buộc tren cho thao tác sửa một một chi tiết sử dụng dịch
CREATE TRIGGER UPDATED_THANHTIEN
ON CHITIETTTDV
AFTER UPDATE
AS 
	IF EXISTS (SELECT * 
			FROM DICHVU DV 
			JOIN INSERTED I ON DV.MaDV = I.MADV
			WHERE ThanhTien != ChiSoDV * DonGia)
	BEGIN 
		ROLLBACK TRANSACTION
		PRINT 'THANH TIEN KHAC CHI SO DICH VU NHAN DON GIA'
	END
---3. Hiện thực các câu truy vấn sau:
---3.1 Liệt kê thông tin các cư dân (mã, họ tên) cùng thôn tin phòng trọ (mã, tên phòng) mà cư dân đó đã ký hợp đồng với trạng thái hợp đồng 'đã hết hạn' trong năm 2024
SELECT CD.MACD, CD.HOTEN 
FROM PHONGTRO PT JOIN HOPDONG HD ON PT.MaPT = HD.MaPT
JOIN CUDAN CD ON HD.MaCD = CD.MaCD
WHERE HD.TrangThaiHD = 'DA HET HAN' AND YEAR(HD.NgayKy) = 2024
---3.2 Tìm các hợp đồng (mã hợp đồng, mã phòng trọ) đã thanh toán các phiếu tính tiền trong năm 2024 nhưng không sử dụng dịch vụ nào có chỉ số từ 5 trở lên trong những chi tiết của phiếu tính tiền
SELECT HD.MAHD, HD.MAPT
FROM HOPDONG HD JOIN PHIEUTINHTIEN PTT ON HD.MaHD = PTT.MaHD
WHERE YEAR(NgayTinhTien) = 2024 
EXCEPT 
SELECT HD.MAHD, HD.MAPT
FROM HOPDONG HD JOIN PHIEUTINHTIEN PTT ON HD.MaHD = PTT.MaHD
JOIN CHITIETTTDV ON PTT.MaPTT = CHITIETTTDV.MaPTT
WHERE YEAR(NgayTinhTien) = 2024 AND CHITIETTTDV.ChiSoDV > 5
---3.3 Tìm thông tin các dịch vụ (mã, tên dịch vụ) có đơn giá trên 10000 VND và có trong chi tiết của tất cả các phiếu tính tiền ngày 15/12/2024
SELECT MADV, TenDV
FROM DICHVU DV
WHERE DV.DonGia > 10000 AND NOT EXISTS (SELECT * 
										FROM PHIEUTINHTIEN PTT
										WHERE PTT.NgayTinhTien = '2024-12-15'
										AND NOT EXISTS (SELECT *
														FROM CHITIETTTDV 
														WHERE DV.MaDV = CHITIETTTDV.MaDV
														AND PTT.MaPTT = CHITIETTTDV.MaPTT))
---3.4 Với mỗi hợp đồng đã hết hạn, hãy cho biết số lượng phiếu tính tiền trong năm 2024 đã được thanh toán. Thông tin hiển thị: Mã hợp đồng, mã cư dân, số lượng
SELECT HD.MAHD, HD.MACD, COUNT(MAPTT) AS SOLUONG
FROM HOPDONG HD 
LEFT JOIN PHIEUTINHTIEN PTT ON HD.MaHD = PTT.MaHD
WHERE YEAR(PTT.NgayTinhTien) = 2024 AND TrangThaiHD = 'DA HET HAN'
GROUP BY HD.MaHD, HD.MaCD
---3.5 Trong các cư dân có sô lần ký hợp đồng ít nhất, tìm cư dân (mã, họ tên) có tổng số tiền đã thanh toán trong năm 2024 nhiều hơn 50000000 VND
---C1
SELECT A.MACD, A.HOTEN
FROM  (SELECT TOP 1 WITH TIES CD.MACD, CD.HOTEN, COUNT(MAHD) AS SOLUONG
FROM CUDAN CD  JOIN HOPDONG HD ON CD.MaCD = HD.MaCD
GROUP BY CD.MACD, CD.HoTen
ORDER BY SOLUONG ASC) AS A
INTERSECT 
SELECT CD.MACD, CD.HOTEN
FROM CUDAN CD JOIN HOPDONG HD ON CD.MaCD = HD.MaCD
JOIN PHIEUTINHTIEN PTT ON HD.MaHD = PTT.MaHD
WHERE YEAR(PTT.NgayTinhTien) = 2024
GROUP BY CD.MaCD, CD.HoTen
HAVING SUM(PTT.TongTienTT) > 5000000
---C2
SELECT CD.MACD, CD.HOTEN
FROM CUDAN CD JOIN HOPDONG HD ON CD.MaCD = HD.MaCD
JOIN PHIEUTINHTIEN PTT ON HD.MaHD = PTT.MaHD
WHERE YEAR(PTT.NgayTinhTien) = 2024 AND CD.MaCD IN (SELECT TOP 1 WITH TIES CD.MACD
													FROM CUDAN CD  JOIN HOPDONG HD ON CD.MaCD = HD.MaCD
													GROUP BY CD.MACD, CD.HoTen
													ORDER BY COUNT(MaHD) ASC)
GROUP BY CD.MaCD, CD.HoTen
HAVING SUM(PTT.TongTienTT) > 5000000
