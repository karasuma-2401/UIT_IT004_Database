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
---2. Hiện thực các ràng buộc toàn vẹn
---2.1 Diện tích của một căn phòng trọ có giá trị từ 10 đến 50 m2---
ALTER TABLE PHONGTRO
ADD CONSTRAINT CHK_DT CHECK (DIENTICH >= 10 AND DIENTICH <=50)
---2.2 Tình trạng thanh toán của phiếu tính tiền nhận một trong hai giá trị "Chưa thanh toán" hoặc "đã thanh toán"
ALTER TABLE PHIEUTINHTIEN
ADD CONSTRAINT CHK_TT CHECK (TINHTRANGTT = 'CHUA THANH TOAN' OR TINHTRANGTT = 'DA THANH TOAN')
---2.3 Sô tiền của mỗi dịch vụ đã sử dụng (ThanhTien) trong chi tiết tính tiền được tính bằng chỉ số đã sử dụng (ChiSoDV) nhân với đơn giá (DonGia) của dịch vụ đó
---Hãy viết viết triggetr để tạo ràng buộc trên cho thao tác thêm một chi tiết sử dụng dịch vụ
CREATE TRIGGER INSERT_THANHTIEN
ON CHITIETTTDV
AFTER INSERT
AS
	IF EXISTS (SELECT THANHTIEN	
				FROM INSERTED I
				JOIN DICHVU DV ON I.MaDV = DV.MaDV
				WHERE THANHTIEN != CHISODV * DONGIA)
	BEGIN
		ROLLBACK TRANSACTION
		PRINT 'THANH TIEN PHAI BANG GIA TRI CUA CHI SO DV NHAN VOI DON GIA'
	END
---3. Hiện thực các câu truy vấn sau:
---3.1 Liệt kê thông tin các phòng trọ (mã, tên phòng) có giá thuê trên 5000,000 VND cùng với thông tin cưu dân (mã, họ tên( đã ký hợp đồng thuê các phòng đó trong năm 2024---
SELECT PT.MaPT , PT.TenPT, CD.MaCD, HOTEN
FROM PHONGTRO PT JOIN HOPDONG HD ON PT.MaPT = HD.MaPT
JOIN CUDAN CD ON HD.MaCD = CD.MaCD
WHERE GiaPT > 5000000 AND YEAR(NGAYKY) = 2024
---3.2 Liệt kê các dịch vụ (mã tên dịch vụ) đã được thanh toán các phiếu tính tiền của cả hia tháng 11 và tháng 12 năm 2024 cho hợp đồng có mã 'HD002'
SELECT DV.MADV, DV.MaDV  
FROM DICHVU DV 
JOIN CHITIETTTDV ON DV.MADV = CHITIETTTDV.MADV
JOIN PHIEUTINHTIEN PTT ON CHITIETTTDV.MaPTT = PTT.MaPTT
WHERE TinhTrangTT = 'DA THANH TOAN' AND MaHD = 'HD002' AND MONTH(NgayTinhTien) = 11 AND YEAR(NgayTinhTien) = 2024
INTERSECT
SELECT DV.MADV, DV.MaDV  
FROM DICHVU DV 
JOIN CHITIETTTDV ON DV.MADV = CHITIETTTDV.MADV
JOIN PHIEUTINHTIEN PTT ON CHITIETTTDV.MaPTT = PTT.MaPTT
WHERE TinhTrangTT = 'DA THANH TOAN' AND MaHD = 'HD002' AND MONTH(NgayTinhTien) = 12 AND YEAR(NgayTinhTien) = 2024
---3.3 Tìm thông tin các phiếu tính tiền (mã phiếu tính tiền, mã hợp đồng) trong năm 2024 và đã sử dụng tất cả các dịch vụ có đơn giá từ 150000VND trở xuống
SELECT PTT.MAPTT, PTT.MAHD
FROM PHIEUTINHTIEN PTT
WHERE YEAR(PTT.NgayTinhTien) = 2024 AND NOT EXISTS (SELECT *
												FROM DICHVU DV
												WHERE DonGia <= 150000
												AND NOT EXISTS (
													SELECT *
													FROM CHITIETTTDV 
													WHERE PTT.MaPTT = CHITIETTTDV.MaPTT
													AND DV.MADV = CHITIETTTDV.MADV))
---C2---
SELECT PTT.MaPTT, MaHD
FROM PHIEUTINHTIEN PTT
JOIN CHITIETTTDV CTDV ON PTT.MaPTT = CTDV.MaPTT
JOIN DICHVU DV ON CTDV.MaDV = DV.MaDV
WHERE DonGia <= 150000 AND YEAR (NgayTinhTien) = 2024
GROUP BY PTT.MaPTT, MaHD
HAVING COUNT(DISTINCT DV.MaDV) = (SELECT COUNT(*) 
								FROM DICHVU
								WHERE DonGia <= 150000)
---3.4 Với mối hợp đồng, hãy cho biết số lượng phiếu tính tiền đã đucợ thanh toán bằng phướng thưc "chuyển khoản" trong nâm 2024. Thông tin hiển thị: Mã hợp, mã cư dân, số lượng
SELECT HD.MAHD, MACD, COUNT(MAPTT) AS SOLUONG
FROM 
LEFT JOIN PHIEUTINHTIEN PTT ON PTT.MaHD = HD.MaHD
WHERE PhuongThucTT = 'CHUYEN KHOAN' AND YEAR (PTT.NgayTinhTien) = 2024
GROUP BY HD.MaHD, MaCD
---3.5 Trong các cư dân có lần ký hợp đồng nhiều nhất, tìm cư dân( mã, họ tên) có tổng số tiền đã thanh toán trong năm 2024 nhiều hơn 15,000,000 VND
---C1:
SELECT A.MACD, A.HOTEN
FROM (SELECT TOP 1 WITH TIES CD.MACD, CD.HoTen, count(HD.MAHD) AS SOLUONG
FROM CUDAN CD JOIN HOPDONG HD ON CD.MaCD = HD.MaCD
GROUP BY CD.MACD, CD.HOTEN
ORDER BY SOLUONG DESC) AS A
INTERSECT
SELECT CD.MACD,CD.HOTEN
FROM CUDAN CD JOIN HOPDONG HD ON CD.MaCD = HD.MaCD
JOIN PHIEUTINHTIEN PTT ON HD.MaHD = PTT.MaHD
WHERE YEAR (PTT.NgayTinhTien) = 2024 AND PTT.TinhTrangTT = 'DA THANH TOAN'
GROUP BY CD.MACD, CD.HoTen
HAVING SUM(PTT.TongTienTT) > 15000000
---C2:
SELECT CD.MaCD, HoTen
FROM CUDAN CD 
JOIN HOPDONG HD ON CD.MaCD = HD.MaCD
JOIN PHIEUTINHTIEN PTT ON HD.MaHD = PTT.MaHD
WHERE YEAR (NgayTinhTien) = 2024 AND CD.MaCD IN (SELECT TOP 1 WITH TIES CD.MaCD
												FROM CUDAN CD JOIN HOPDONG HD ON CD.MaCD = HD.MaCD
												GROUP BY CD.MaCD
												ORDER BY COUNT(HD.MaHD) DESC)
GROUP BY CD.MaCD, HoTen
HAVING SUM(TongTienTT) > 15000000