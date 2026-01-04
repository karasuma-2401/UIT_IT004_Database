--////I. Ngôn ngữ định nghĩa dữ liệu (Data Definition Language):///--
--1. Tạo quan hệ và khai báo tất cả các ràng buộc khóa chính, khóa ngoại. Thêm vào 3 thuộc tính GHICHU, DIEMTB, XEPLOAI cho quan hệ HOCVIEN.--
ALTER TABLE HOCVIEN 
ADD 
    GHICHU    NVARCHAR(10),
    DIEMTB    NUMERIC(4, 2),
    XEPLOAI   VARCHAR(10);
--2. Mã học viên là một chuỗi 5 ký tự, 3 ký tự đầu là mã lớp, 2 ký tự cuối cùng là số thứ tự học viên trong lớp. VD: “K1101”--
ALTER TABLE HOCVIEN ADD CONSTRAINT CHK_MAHV CHECK (MAHV LIKE '[K][0-9][0-9][0-9][0-9]')
--3. Thuộc tính GIOITINH chỉ có giá trị là “Nam” hoặc “Nu”.--
ALTER TABLE HOCVIEN ADD CONSTRAINT CHECK_GTHV CHECK (GIOITINH IN ('NAM', 'NU'))
ALTER TABLE GIAOVIEN ADD CONSTRAINT CHECK_GTGV CHECK (GIOITINH IN ('NAM', 'NU'))
--4. Điểm số của một lần thi có giá trị từ 0 đến 10 và cần lưu đến 2 số lẽ (VD: 6.22).--
ALTER TABLE KETQUATHI ADD CONSTRAINT CHK_DIEM CHECK (DIEM BETWEEN 0 AND 10)
--5. Kết quả thi là “Dat” nếu điểm từ 5 đến 10 và “Khong dat” nếu điểm nhỏ hơn 5.--
ALTER TABLE KETQUATHI ADD CONSTRAINT CHK_KQUA CHECK 
((KQUA = 'DAT' AND DIEM BETWEEN 5 AND 10) OR (KQUA = 'KHONG DAT' AND DIEM < 5))
--6. Học viên thi một môn tối đa 3 lần.--
ALTER TABLE KETQUATHI ADD CONSTRAINT CHK_LANTHI CHECK (LANTHI <=3)
--7. Học kỳ chỉ có giá trị từ 1 đến 3.--
ALTER TABLE GIANGDAY ADD CONSTRAINT CHK_HOCKY CHECK (HOCKY BETWEEN 1 AND 3)
--8. Học vị của giáo viên chỉ có thể là “CN”, “KS”, “Ths”, ”TS”, ”PTS”.--
ALTER TABLE GIAOVIEN ADD CONSTRAINT CHK_HOCVI CHECK (HOCVI IN ('CN', 'KS', 'Ths', 'TS', 'PTS'))
--9. Lớp trưởng của một lớp phải là học viên của lớp đó.--
ALTER TABLE LOP ADD CONSTRAINT FK_LT FOREIGN KEY (TRGLOP) REFERENCES HOCVIEN(MAHV)
--10. Trưởng khoa phải là giáo viên thuộc khoa và có học vị “TS” hoặc “PTS”.--

--11. Học viên ít nhất là 18 tuổi.--
ALTER TABLE HOCVIEN ADD CONSTRAINT CHK_TUOI CHECK (YEAR(GETDATE()) - YEAR(NGSINH) >=18)
--12. Giảng dạy một môn học ngày bắt đầu (TUNGAY) phải nhỏ hơn ngày kết thúc (DENNGAY).-- 
-- data bị conflict r thầy ơi--
ALTER TABLE GIANGDAY ADD CONSTRAINT CHK_GIANGDAY CHECK (TUNGAY < DENNGAY)
--13. Giáo viên khi vào làm ít nhất là 22 tuổi.--
ALTER TABLE GIAOVIEN ADD CONSTRAINT CHK_TGLAMVIEC CHECK (YEAR(NGVL) - YEAR(NGSINH) >= 22)
--14. Tất cả các môn học đều có số tín chỉ lý thuyết và tín chỉ thực hành chênh lệch nhau không quá 3.--
ALTER TABLE MONHOC ADD CONSTRAINT CHK_TINCHI CHECK (ABS(TCLT - TCTH) <= 3) 
--15. Học viên chỉ được thi một môn học nào đó khi lớp của học viên đã học xong môn học này.--
CREATE TRIGGER HVTHI15_KETQUATHI_INSERT
ON KETQUATHI 
AFTER INSERT
AS
	IF EXISTS( SELECT *
				FROM INSERTED I
				JOIN HOCVIEN HV ON I.MAHV = HV.MAHV
				JOIN GIANGDAY GD ON HV.MALOP = HV.MALOP AND I.MAMH = GD.MAMH
				WHERE I.NGTHI < GD.DENNGAY)
	BEGIN 
		ROLLBACK TRANSACTION
		PRINT 'LOI, HOC VIEN CHI DUOC THI MON NAY KHI LOP DA HOC XONG'
	END
--16. Mỗi học kỳ của một năm học, một lớp chỉ được học tối đa 3 môn.--
CREATE TRIGGER LOP16_GIANGDAY_INSERT 
ON GIANGDAY
FOR INSERT, UPDATE
AS 
	IF (SELECT COUNT(*)
	FROM INSERTED I, GIANGDAY GD
	WHERE I.MALOP = GD.MALOP AND I.HOCKY = GD.HOCKY) > 3
BEGIN 
	ROLLBACK TRANSACTION
	PRINT 'MOI HOC KY CUA NAM HOC, MOT LOP CHI HOC TOI DA 3 MON'
END
--17. Sỉ số của một lớp bằng với số lượng học viên thuộc lớp đó.--
CREATE TRIGGER LOP17_GIANGDAY_INSERT
ON LOP
AFTER INSERT
AS
	DECLARE @SISO TINYINT
	DECLARE @SLHOCVIEN TINYINT
	DECLARE @MALOP CHAR(3)
	SELECT @SISO = SISO, @MALOP = MALOP
	FROM INSERTED I
	SELECT @SLHOCVIEN = COUNT (MAHV)
	FROM HOCVIEN
	WHERE MALOP = @MALOP
	IF (@SISO != @SLHOCVIEN)
	BEGIN 
		ROLLBACK TRANSACTION
		PRINT 'LOI, SI SO CUA LOP PHAI BANG SO LUONG VIEN THUOC LOP DO'
	END
--18. Trong quan hệ DIEUKIEN giá trị của thuộc tính MAMH và MAMH_TRUOC trong cùng một bộ không được giống nhau (“A”,”A”) và cũng không tồn tại hai bộ (“A”,”B”) và (“B”,”A”).
CREATE TRIGGER DIEUKIEN18_INSERT
ON DIEUKIEN
AFTER INSERT
AS
	IF EXISTS(SELECT *FROM inserted 
				WHERE MAMH  = MAMH_TRUOC)
	BEGIN 
		ROLLBACK TRANSACTION 
		PRINT 'MON HOC HIEN TAI VA MON HOC TRUOC KHONG DUOC TURNG NHAU'
		RETURN
	END
	IF EXISTS (SELECT * FROM INSERTED I
				JOIN DIEUKIEN DK ON I.MAMH = DK.MAMH_TRUOC AND I.MAMH_TRUOC = DK.MAMH)
	BEGIN
		ROLLBACK TRANSACTION
		PRINT 'LOI TON TAI VONG LAP TRONG DIEU KIEN MON HOC'
		RETURN
	END
--19. Các giáo viên có cùng học vị, học hàm, hệ số lương thì mức lương bằng nhau.
CREATE TRIGGER MAGV19_GIAOVIEN_INSERT
ON GIAOVIEN
AFTER INSERT
AS 
	IF (SELECT COUNT(*) FROM INSERTED I , GIAOVIEN GV
		WHERE I.HOCHAM = GV.HOCHAM AND I.HOCVI = GV.HOCVI AND I.HESO = GV.HESO AND I.MUCLUONG != GV.MUCLUONG) > 0
	BEGIN 
		ROLLBACK TRANSACTION
		PRINT 'GIAO VIEN CO CUNG HOC VI, HOC HAM THI HE SO LUONG PHIA BANG NHAU'
	END
--20. Học viên chỉ được thi lại (lần thi >1) khi điểm của lần thi trước đó dưới 5.
CREATE TRIGGER LANLAI20_KETQUATHI_INSERT
ON KETQUATHI
AFTER INSERT
AS
	DECLARE @LANTHI TINYINT
	DECLARE @MAHV CHAR(5)
	DECLARE @DIEM NUMERIC (4,2)
	SELECT @LANTHI = KETQUATHI.LANTHI + 1, @MAHV = I.MAHV, @DIEM = KETQUATHI.DIEM
	FROM INSERTED I JOIN KETQUATHI ON I.MAHV = KETQUATHI.MAHV
	WHERE I.MAMH = KETQUATHI.MAMH
	IF (@DIEM > 5)
	BEGIN 
		ROLLBACK TRANSACTION
		PRINT 'DIEM CUA LAN THI TRUOC DO PHAI DUOI 5'
	END
--21. Ngày thi của lần thi sau phải lớn hơn ngày thi của lần thi trước (cùng học viên, cùng môn học).
CREATE TRIGGER NGAYTHI_KETQUATHI_INSERT
ON KETQUATHI
AFTER INSERT
AS
	IF (SELECT COUNT (*) 
		FROM INSERTED I, KETQUATHI
		WHERE I.LANTHI > KETQUATHI.LANTHI AND I.MAHV = KETQUATHI.MAHV 
		AND I.MAMH = KETQUATHI.MAMH AND I.NGTHI > KETQUATHI.NGTHI) = 0
	BEGIN 
		ROLLBACK TRANSACTION
		PRINT 'NGAY THI LAN SAU PHAI LON HON NGYA THI LAN TRUOC DO'
	END
--22. Học viên chỉ được thi những môn mà lớp của học viên đó đã học xong.
CREATE TRIGGER HVTHI22_KETQUATHI_INSERT
ON KETQUATHI 
AFTER INSERT
AS
	IF EXISTS( SELECT *
				FROM INSERTED I
				JOIN HOCVIEN HV ON I.MAHV = HV.MAHV
				JOIN GIANGDAY GD ON HV.MALOP = HV.MALOP AND I.MAMH = GD.MAMH
				WHERE I.NGTHI < GD.DENNGAY)
	BEGIN 
		ROLLBACK TRANSACTION
		PRINT 'LOI, HOC VIEN CHI DUOC THI MON NAY KHI LOP DA HOC XONG'
	END
--23. Khi phân công giảng dạy một môn học, phải xét đến thứ tự trước sau giữa các môn học (sau khi học xong những môn học phải học trước mới được học những môn liền sau).
CREATE TRIGGER PHANCONG23_GIANGDAY_INSERT
ON GIANGDAY
AFTER INSERT
AS 
	IF EXISTS (SELECT *
				FROM INSERTED I JOIN DIEUKIEN DK ON I.MAMH = DK.MAMH
				WHERE NOT EXISTS (SELECT *
									FROM GIANGDAY GD
									WHERE GD.MALOP = I.MALOP
									AND GD.MAMH = DK.MAMH_TRUOC
									AND GD.DENNGAY < I.TUNGAY)
			)
	BEGIN 
		ROLLBACK TRANSACTION
		PRINT 'LOI, TRUOC KHI PHAN GIANGDAY, PHAI XET THU TU TRUOC SAU GIUA CAC MON'
	END
--24. Giáo viên chỉ được phân công dạy những môn thuộc khoa giáo viên đó phụ trách--
CREATE TRIGGER PHANCONG24_GIANGDAY_INSERT
ON GIANGDAY
AFTER INSERT
AS
	IF EXISTS( SELECT *
				FROM INSERTED I 
				JOIN MONHOC MH ON I.MAMH = MH.MAMH
				JOIN GIAOVIEN GV ON I.MAGV = GV.MAGV
				WHERE MH.MAKHOA != GV.MAKHOA)
	BEGIN
		ROLLBACK TRANSACTION
		PRINT 'GIAO VIEN CHI DUOC DAY CAC MON THUOC KHOA MINH PHU TRACH'
	END
--//// II. Ngôn ngữ thao tác dữ liệu (Data Manipulation Language):///--
--1. Tăng hệ số lương thêm 0.2 cho những giáo viên là trưởng khoa.
UPDATE GIAOVIEN 
SET HESO = HESO + 0.2
WHERE MAGV IN (SELECT TRGKHOA FROM KHOA)
---2. Cập nhật giá trị điểm trung bình tất cả các môn học (DIEMTB) của mỗi học viên (tất cả các môn học đều có hệ số 1 và nếu học viên thi một môn nhiều lần, chỉ lấy điểm của lần thi sau cùng).--
UPDATE HOCVIEN
SET DIEMTB = (SELECT AVG(DIEM) 
			  FROM KETQUATHI
			  WHERE LANTHI = (SELECT MAX(LANTHI) FROM KETQUATHI KQT 
							  WHERE KETQUATHI.MAHV = KQT.MAHV 
							  GROUP BY MAHV)
					AND HOCVIEN.MAHV = KETQUATHI.MAHV
			  GROUP BY MAHV) 
--3. Cập nhật giá trị cho cột GHICHU là “Cam thi” đối với trường hợp: học viên có một môn bất kỳ thi lần thứ 3 dưới 5 điểm.--
UPDATE HOCVIEN
SET GHICHU = 'CAM THI'
WHERE MAHV IN (SELECT MAHV FROM KETQUATHI 
			   WHERE LANTHI = 3 AND DIEM < 5)
--4. Cập nhật giá trị cho cột XEPLOAI trong quan hệ HOCVIEN như sau:
--	Nếu DIEMTB >= 9 thì XEPLOAI =”XS”
--	Nếu 8  DIEMTB < 9 thì XEPLOAI = “G”
--	Nếu 6.5  DIEMTB < 8 thì XEPLOAI = “K”
--	Nếu 5  DIEMTB < 6.5 thì XEPLOAI = “TB”
--	Nếu DIEMTB < 5 thì XEPLOAI = ”Y”
UPDATE HOCVIEN
SET XEPLOAI = (
	CASE
		WHEN DIEMTB >= 9 THEN 'XS'
		WHEN DIEMTB >= 8 AND DIEMTB < 9 THEN 'G'
		WHEN DIEMTB >= 6.5 AND DIEMTB < 8 THEN 'K'
		WHEN DIEMTB >= 5 AND DIEMTB < 6.5 THEN 'TB'
		WHEN DIEMTB < 5 THEN 'Y'
	END
)
--//// III. Ngôn ngữ truy vấn dữ liệu:///--
--1. In ra danh sách (mã học viên, họ tên, ngày sinh, mã lớp) lớp trưởng của các lớp.--
select MAHV, HV.HO, HV.TEN, NGSINH, HV.MALOP
FROM HOCVIEN HV JOIN LOP ON HV.MALOP = LOP.MALOP
WHERE LOP.TRGLOP = MAHV
--2. In ra bảng điểm khi thi (mã học viên, họ tên , lần thi, điểm số) môn CTRR của lớp “K12”, sắp xếp theo tên, họ học viên.--
SELECT HV.MAHV, HO, TEN, LANTHI, DIEM
FROM KETQUATHI JOIN HOCVIEN HV ON KETQUATHI.MAHV = HV.MAHV
WHERE MAMH = 'CTRR' AND MALOP = 'K12'
ORDER BY TEN, HO
--3. In ra danh sách những học viên (mã học viên, họ tên) và những môn học mà học viên đó thi lần thứ nhất đã đạt--
SELECT HV.MAHV, HO, TEN, MAMH
FROM HOCVIEN HV JOIN KETQUATHI ON HV.MAHV = KETQUATHI.MAHV
WHERE LANTHI = '1' AND KQUA = 'DAT' 
--4. In ra danh sách học viên (mã học viên, họ tên) của lớp “K11” thi môn CTRR không đạt (ở lần thi 1)--
SELECT HV.MAHV, HO, TEN
FROM HOCVIEN HV JOIN KETQUATHI ON HV.MAHV = KETQUATHI.MAHV 
WHERE MALOP = 'K11' AND MAMH = 'CTRR' AND KQUA = 'KHONG DAT' AND LANTHI = '1'
--5. * Danh sách học viên (mã học viên, họ tên) của lớp “K” thi môn CTRR không đạt (ở tất cả các lần thi).--
SELECT HV.MAHV, HO, TEN
FROM HOCVIEN HV JOIN KETQUATHI ON HV.MAHV = KETQUATHI.MAHV
WHERE MALOP LIKE 'K' AND MAMH = 'CTRR'
EXCEPT 
SELECT HV.MAHV, HO, TEN
FROM HOCVIEN HV JOIN KETQUATHI ON HV.MAHV = KETQUATHI.MAHV
WHERE MALOP LIKE 'K' AND MAMH = 'CTRR' AND KQUA = 'DAT'
--6. Tìm tên những môn học mà giáo viên có tên “Tran Tam Thanh” dạy trong học kỳ 1 năm 2006.--
SELECT MH.MAMH
FROM MONHOC MH JOIN GIANGDAY GD ON MH.MAMH = GD.MAMH JOIN GIAOVIEN GV ON GV.MAGV = GD.MAGV
WHERE GV.HOTEN = 'Tran Tam Thanh' AND HOCKY = 1 AND NAM = 2006
--7. Tìm những môn học (mã môn học, tên môn học) mà giáo viên chủ nhiệm lớp “K11” dạy trong học kỳ 1 năm 2006.--
SELECT MH.MAMH, TENMH
FROM LOP JOIN GIANGDAY GD ON LOP.MALOP = GD.MALOP JOIN MONHOC MH ON MH.MAMH = GD.MAMH
WHERE GD.MALOP = 'K11' AND HOCKY = 1 AND NAM = 2006 AND MAGVCN = MAGV
--8. Tìm họ tên lớp trưởng của các lớp mà giáo viên có tên “Nguyen To Lan” dạy môn “Co So Du Lieu”.--
SELECT HO, TEN
FROM LOP JOIN GIANGDAY GD ON LOP.MALOP = GD.MALOP JOIN MONHOC ON MONHOC.MAMH = GD.MAMH 
JOIN HOCVIEN HV ON HV.MALOP = LOP.MALOP JOIN GIAOVIEN GV ON GV.MAGV = GD.MAGV
WHERE LOP.TRGLOP = HV.MAHV AND GV.HOTEN = 'NGUYEN TO LAN' AND TENMH = 'CO SO DU LIEU'
--9. In ra danh sách những môn học (mã môn học, tên môn học) phải học liền trước môn “Co So Du Lieu”.--
SELECT MH.MAMH, TENMH
FROM MONHOC MH JOIN DIEUKIEN DK ON MH.MAMH = DK.MAMH_TRUOC
WHERE DK.MAMH = (SELECT MAMH FROM MONHOC WHERE TENMH = 'CO SO DU LIEU')
--10. Môn “Cau Truc Roi Rac” là môn bắt buộc phải học liền trước những môn học (mã môn học, tên môn học) nào.--
SELECT MH.MAMH, TENMH
FROM MONHOC MH JOIN DIEUKIEN DK ON MH.MAMH = DK.MAMH
WHERE DK.MAMH_TRUOC = (SELECT MAMH FROM MONHOC WHERE TENMH = 'CAU TRUC ROI RAC')
--11. Tìm họ tên giáo viên dạy môn CTRR cho cả hai lớp “K11” và “K12” trong cùng học kỳ 1 năm 2006--
SELECT GV.HOTEN
FROM GIAOVIEN GV JOIN GIANGDAY GD ON GV.MAGV = GD.MAGV
WHERE MALOP = 'K11' AND HOCKY = 1 AND NAM = 2006
INTERSECT
SELECT GV.HOTEN
FROM GIAOVIEN GV JOIN GIANGDAY GD ON GV.MAGV = GD.MAGV
WHERE MALOP = 'K12' AND HOCKY = 1 AND NAM = 2006
--12. Tìm những học viên (mã học viên, họ tên) thi không đạt môn CSDL ở lần thi thứ 1 nhưng chưa thi lại môn này.--
SELECT HV.MAHV, HO, TEN
FROM HOCVIEN HV JOIN KETQUATHI KQT ON HV.MAHV = KQT.MAHV 
WHERE MAMH = 'CSDL' AND KQUA = 'KHONG DAT' 
EXCEPT 
SELECT HV.MAHV, HO, TEN
FROM HOCVIEN HV JOIN KETQUATHI KQT ON HV.MAHV = KQT.MAHV
WHERE MAMH  = 'CSDL' AND LANTHI = 2
--13. Tìm giáo viên (mã giáo viên, họ tên) không được phân công giảng dạy bất kỳ môn học nào.--
SELECT GV.MAGV, GV.HOTEN
FROM GIAOVIEN GV 
EXCEPT 
SELECT GV.MAGV, GV.HOTEN
FROM GIAOVIEN GV JOIN GIANGDAY GD ON GV.MAGV = GD.MAGV
--14. Tìm giáo viên (mã giáo viên, họ tên) không được phân công giảng dạy bất kỳ môn học nào thuộc khoa giáo viên đó phụ trách--
SELECT GV.MAGV, GV.HOTEN
FROM GIAOVIEN GV JOIN KHOA ON GV.MAKHOA = KHOA.MAKHOA
EXCEPT 
SELECT GV.MAGV, GV.HOTEN
FROM GIAOVIEN GV JOIN GIANGDAY GD ON GV.MAGV = GD.MAGV JOIN MONHOC MH ON MH.MAMH = GD.MAMH
WHERE GV.MAKHOA = MH.MAKHOA
--15. Tìm họ tên các học viên thuộc lớp “K11” thi một môn bất kỳ quá 3 lần vẫn “Khong dat” hoặc thi lần thứ 2 môn CTRR được 5 điểm.
SELECT HV.HO, HV.TEN
FROM HOCVIEN HV JOIN KETQUATHI ON HV.MAHV = KETQUATHI.MAHV
WHERE MALOP = 'K11' AND LANTHI = 4 AND KQUA = 'KHONG DAT'
UNION
SELECT HV.HO, HV.TEN
FROM HOCVIEN HV JOIN KETQUATHI ON HV.MAHV = KETQUATHI.MAHV
WHERE MALOP = 'K11' AND LANTHI = 2 AND MAMH = 'CTRR' AND DIEM = 5
--16. Tìm họ tên giáo viên dạy môn CTRR cho ít nhất hai lớp trong cùng một học kỳ của một năm học.--
SELECT GV.HOTEN 
FROM GIAOVIEN GV JOIN GIANGDAY GD ON GV.MAGV = GD.MAGV
WHERE MAMH = 'CTRR' 
GROUP BY GV.HOTEN, HOCKY, NAM
HAVING COUNT(MALOP) >= 2
--17. Danh sách học viên và điểm thi môn CSDL (chỉ lấy điểm của lần thi sau cùng).
SELECT KQT.MAHV, HO, TEN, DIEM
FROM HOCVIEN HV JOIN KETQUATHI KQT ON HV.MAHV = KQT.MAHV
WHERE MAMH = 'CSDL' AND LANTHI = (SELECT COUNT(LANTHI) 
FROM KETQUATHI 
WHERE MAMH = 'CSDL' AND HV.MAHV = KETQUATHI.MAHV)
--18. Danh sách học viên và điểm thi môn “Co So Du Lieu” (chỉ lấy điểm cao nhất của các lần thi)--
SELECT KQT.MAHV, HO, TEN, DIEM
FROM HOCVIEN HV JOIN KETQUATHI KQT ON HV.MAHV = KQT.MAHV JOIN MONHOC MH ON KQT.MAMH = MH.MAMH
WHERE KQT.MAMH = 'CSDL' AND DIEM = (SELECT MAX(DIEM) 
FROM KETQUATHI JOIN MONHOC ON KETQUATHI.MAMH = MONHOC.MAMH
WHERE TENMH = 'CO SO DU LIEU' AND HV.MAHV = KETQUATHI.MAHV)
--19. Khoa nào (mã khoa, tên khoa) được thành lập sớm nhất.--
SELECT MAKHOA, TENKHOA
FROM KHOA 
WHERE NGTLAP = (SELECT MIN(NGTLAP) FROM KHOA KH)
--20. Có bao nhiêu giáo viên có học hàm là “GS” hoặc “PGS”.
SELECT MAGV, HOTEN
FROM GIAOVIEN
WHERE HOCHAM = 'GS' 
UNION
SELECT MAGV, HOTEN
FROM GIAOVIEN
WHERE HOCHAM = 'PGS'
--21. Thống kê có bao nhiêu giáo viên có học vị là “CN”, “KS”, “Ths”, “TS”, “PTS” trong mỗi khoa--
SELECT COUNT (MAGV) SOLUONGGV
FROM GIAOVIEN GV JOIN KHOA ON GV.MAKHOA = KHOA.MAKHOA
WHERE HOCVI IN ('CN', 'KS', 'THS', 'TS', 'PTS')
GROUP BY KHOA.MAKHOA
--22. Mỗi môn học thống kê số lượng học viên theo kết quả (đạt và không đạt).--
SELECT MAMH, KQUA, COUNT(MAHV) 'Số học viên'
FROM KETQUATHI
GROUP BY MAMH, KQUA
ORDER BY MAMH
--23. Tìm giáo viên (mã giáo viên, họ tên) là giáo viên chủ nhiệm của một lớp, đồng thời dạy cho lớp đó ít nhất một môn học.--
SELECT GV.MAGV, HOTEN
FROM GIAOVIEN GV JOIN GIANGDAY GD ON GV.MAGV = GD.MAGV JOIN LOP ON LOP.MALOP = GD.MALOP
WHERE LOP.MAGVCN = GV.MAGV 
GROUP BY GV.MAGV, HOTEN
HAVING COUNT (MAMH) >= 1
--24. Tìm họ tên lớp trưởng của lớp có sỉ số cao nhất.--
SELECT HO, TEN
FROM HOCVIEN HV JOIN LOP ON HV.MALOP = LOP.MALOP
WHERE HV.MAHV = LOP.TRGLOP AND SISO = (SELECT MAX(SISO) FROM LOP)
--25. * Tìm họ tên những LOPTRG thi không đạt quá 3 môn (mỗi môn đều thi không đạt ở tất cả các lần thi).--
SELECT HV.HO, HV.TEN
FROM HOCVIEN HV JOIN LOP L ON HV.MAHV = L.TRGLOP
WHERE HV.MAHV IN (
    SELECT KQ1.MAHV
    FROM KETQUATHI KQ1
    WHERE NOT EXISTS (
        SELECT *
        FROM KETQUATHI KQ2
        WHERE KQ2.MAHV = KQ1.MAHV
          AND KQ2.MAMH = KQ1.MAMH
          AND KQ2.KQUA = 'Dat'
    )
    GROUP BY KQ1.MAHV
    HAVING COUNT(DISTINCT KQ1.MAMH) > 3
)
--26. Tìm học viên (mã học viên, họ tên) có số môn đạt điểm 9,10 nhiều nhất.--
--C1:
SELECT HV.MAHV, HO, TEN
FROM HOCVIEN HV JOIN KETQUATHI KQT ON HV.MAHV = KQT.MAHV
WHERE KQT.DIEM >= 9
GROUP BY HV.MAHV, HO, TEN
HAVING COUNT(*) >= ALL (SELECT COUNT(*) 
						FROM KETQUATHI 
						WHERE DIEM >= 9
						GROUP BY MAHV)
--C2:
SELECT TOP 1 WITH TIES HV.MAHV, HO, TEN
FROM HOCVIEN HV 
JOIN KETQUATHI KQT ON HV.MAHV = KQT.MAHV
WHERE KQT.DIEM >= 9
GROUP BY HV.MAHV, HO, TEN
ORDER BY COUNT(DISTINCT MAMH) DESC;
--27. Trong từng lớp, tìm học viên (mã học viên, họ tên) có số môn đạt điểm 9,10 nhiều nhất.--
SELECT A.MALOP, A.MAHV, HV.HO, HV.TEN
FROM HOCVIEN HV JOIN (SELECT HOCVIEN.MAHV, HOCVIEN.MALOP, COUNT(KETQUATHI.MAMH) AS SOMONMAXDIEM
                      FROM KETQUATHI JOIN HOCVIEN ON KETQUATHI.MAHV = HOCVIEN.MAHV
                      WHERE KETQUATHI.DIEM >= 9 
                      GROUP BY HOCVIEN.MAHV, HOCVIEN.MALOP) AS A
ON HV.MAHV = A.MAHV
WHERE A.SOMONMAXDIEM = (SELECT MAX(B.SOMONMAXDIEM)
                        FROM (SELECT HOCVIEN.MAHV, HOCVIEN.MALOP, COUNT(KETQUATHI.MAMH) AS SOMONMAXDIEM
                              FROM KETQUATHI JOIN HOCVIEN ON KETQUATHI.MAHV = HOCVIEN.MAHV
                              WHERE KETQUATHI.DIEM >= 9 
                              GROUP BY HOCVIEN.MAHV, HOCVIEN.MALOP) AS B
                        WHERE A.MALOP = B.MALOP 
    )
--28. Trong từng học kỳ của từng năm, mỗi giáo viên phân công dạy bao nhiêu môn học, bao nhiêu lớp--
SELECT MaGV, COUNT(DISTINCT MaMH) 'Số môn học', COUNT(DISTINCT MALOP) 'Số lớp'
FROM GiangDay
GROUP BY NAM, HOCKY, MAGV
--29. Trong từng học kỳ của từng năm, tìm giáo viên (mã giáo viên, họ tên) giảng dạy nhiều nhất.--
SELECT A.HOCKY, A.NAM, A.MAGV, HOTEN
FROM GIAOVIEN GV JOIN (SELECT HOCKY, NAM, MAGV, COUNT(*) AS SLGIANGDAY
				FROM GIANGDAY
				GROUP BY HOCKY, NAM, MAGV) AS A
ON GV.MAGV = A.MAGV
WHERE A.SLGIANGDAY = (SELECT MAX (B.SLGIANGDAY) 
                      FROM (SELECT HOCKY,NAM, MAGV, COUNT(*) AS SLGIANGDAY
                      FROM GIANGDAY
                      GROUP BY HOCKY, NAM, MAGV) AS B
                      WHERE A.HOCKY = B.HOCKY AND A.NAM = B.NAM)
ORDER BY A.NAM, A.HOCKY, A.SLGIANGDAY DESC
--30. Tìm môn học (mã môn học, tên môn học) có nhiều học viên thi không đạt (ở lần thi thứ 1) nhất.--
SELECT TOP 1 MH.MAMH, TENMH
FROM MONHOC MH JOIN KETQUATHI KQT ON MH.MAMH = KQT.MAMH
WHERE LANTHI = 1 AND KQUA = 'KHONG DAT'
GROUP BY MH.MAMH, TENMH
ORDER BY COUNT(*) DESC
--31. Tìm học viên (mã học viên, họ tên) thi môn nào cũng đạt (chỉ xét lần thi thứ 1).--
SELECT DISTINCT HV.MAHV, HO, TEN 
FROM HOCVIEN HV JOIN KETQUATHI KQT ON HV.MAHV = KQT.MAHV
WHERE LANTHI = 1
EXCEPT 
SELECT DISTINCT HV.MAHV, HO, TEN
FROM HOCVIEN HV JOIN KETQUATHI KQT ON HV.MAHV = KQT.MAHV
WHERE LANTHI = 1 AND KQUA = 'KHONG DAT'
--32. * Tìm học viên (mã học viên, họ tên) thi môn nào cũng đạt (chỉ xét lần thi sau cùng).--
SELECT HV.MAHV, HO, TEN
FROM HOCVIEN HV JOIN KETQUATHI KQT ON KQT.MAHV =HV.MAHV
WHERE KQUA='DAT' AND LANTHI = (SELECT MAX(LANTHI)
FROM KETQUATHI
WHERE KQT.MAMH = KETQUATHI.MAMH AND HV.MAHV = KETQUATHI.MAHV)
GROUP BY HV.MAHV, HO, TEN
HAVING COUNT(*)= ( SELECT COUNT(DISTINCT MAMH)
                        FROM KETQUATHI
                        WHERE HV.MAHV = KETQUATHI.MAHV)
--33. * Tìm học viên (mã học viên, họ tên) đã thi tất cả các môn đều đạt (chỉ xét lần thi thứ 1).--
SELECT DISTINCT HV.MAHV, HO, TEN
FROM HOCVIEN HV
WHERE NOT EXISTS (
		SELECT * 
		FROM MONHOC
		WHERE NOT EXISTS (SELECT * 
						FROM KETQUATHI
						WHERE LANTHI = 1 AND KQUA = 'DAT'
						AND KETQUATHI.MAMH = MONHOC.MAMH
						)
				)
-- 34. * Tìm học viên (mã học viên, họ tên) đã thi tất cả các môn đều đạt (chỉ xét lần thi sau cùng).--
SELECT DISTINCT HV.MAHV, HO, TEN
FROM HOCVIEN HV
WHERE NOT EXISTS (
		SELECT * 
		FROM MONHOC
		WHERE NOT EXISTS (SELECT * 
						FROM KETQUATHI
						WHERE LANTHI = (SELECT MAX (LANTHI) FROM KETQUATHI WHERE MAHV = HV.MAHV GROUP BY MAHV) 
						AND KQUA = 'DAT'
						AND KETQUATHI.MAMH = MONHOC.MAMH)
						)
--35. ** Tìm học viên (mã học viên, họ tên) có điểm thi cao nhất trong từng môn (lấy điểm ở lần thi sau cùng).
SELECT A.MAMH, A.MAHV,HV.HO, HV.TEN
FROM HOCVIEN HV JOIN (SELECT KQT1.MAHV, KQT1.MAMH, KQT1.DIEM AS FINALDIEM 
                      FROM KETQUATHI KQT1
                      WHERE KQT1.LANTHI = ( SELECT MAX(LANTHI) FROM KETQUATHI AS KQT2
                                            WHERE KQT1.MAHV = KQT2.MAHV 
                                            AND KQT1.MAMH = KQT2.MAMH)
                    ) AS A
ON HV.MAHV = A.MAHV
WHERE A.FINALDIEM = ( SELECT MAX(B.FINALDIEM)
                      FROM( SELECT KQT1.MAHV, KQT1.MAMH, KQT1.DIEM AS FINALDIEM 
						    FROM KETQUATHI KQT1
						    WHERE KQT1.LANTHI = ( SELECT MAX(LANTHI) FROM KETQUATHI AS KQT2
                                            WHERE KQT1.MAHV = KQT2.MAHV 
                                            AND KQT1.MAMH = KQT2.MAMH)) AS B
					  WHERE B.MAMH = A.MAMH)