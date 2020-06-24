create or replace PACKAGE BODY PKG_2020MAIN IS

-- Global Variable
gv_runID NUMBER;
gv_dateFormat VARCHAR2(35) := get_param('Date_Format', 'Date Format 1');
gv_dateFormatWithoutDash VARCHAR2(35) := get_param('Date_Format', 'Date Format 2');
gv_diriectory VARCHAR2(35) := get_param('UTL Report', 'Directory');

-- Forward Declaration
PROCEDURE programRun;
PROCEDURE endOfProgram (p_run VARCHAR2);
PROCEDURE averageForecast;
FUNCTION holiday(p_date DATE) RETURN BOOLEAN;
PROCEDURE managingUTL;
PROCEDURE managingXML;


-- Managing Program Run
PROCEDURE programRun IS
--
-- Author: Beomsang Kim
-- Created Date: 30-MAY-2020
-- Modified Date: 01-JUN-2020
-- Purpose: Indicating start of the programming
--          Preventing same time multiple run
--
v_runID NUMBER;
--
BEGIN
    SELECT seq_runID.NEXTVAL INTO v_runID FROM dual;
    gv_runID := v_runID;
        INSERT INTO RUN_TABLE(RUN_ID, RUN_START, RUN_END, OUTCOME, REMARKS)
        VALUES (V_runID, sysdate, NULL, NULL, 'START PROGRAM');
--        
END; --programRun


PROCEDURE endOfProgram (p_run VARCHAR2) IS
--
v_run VARCHAR(25) := p_run;
--
BEGIN
    IF UPPER(v_run) LIKE '%END%' THEN
        UPDATE run_table
        SET RUN_END = sysdate,
        OUTCOME = 'SUCESS',
        REMARKS = 'RUN completed sucessfully'
        WHERE run_ID = gv_runID;
    ELSE 
        UPDATE run_table
        SET RUN_END = sysdate,
        OUTCOME = 'FAIL',
        REMARKS = 'The program run failed'
        WHERE run_ID = gv_runID;
    END IF;
    COMMIT;
END; -- endOfProgram 


--Entry Module
PROCEDURE RM16_forecast IS
--
-- Author: Beomsang Kim
-- Created Date: 30-MAY-2020
-- Modified Date: 01-JUN-2020
-- Purpose: Entry Module
--
--
v_procedureName VARCHAR(25) := 'RM16_forecast';

BEGIN

COMMON.LOG('The entry module '|| v_procedureName || ' was started');
programRun;
averageForecast;
managingUTL;
managingXML;
endOfprogram('END');
COMMON.LOG('The entry module '|| v_procedureName || ' finished the task');
END;

--Forecasting
FUNCTION holiday(p_date DATE)RETURN BOOLEAN IS
--
-- Author: Beomsang Kim
-- Created Date: 30-MAY-2020
-- Modified Date: 01-JUN-2020
-- Purpose: Return true when the forecasted day is holiday
--          Return false when the forecasted day is not holiday
--          called by avereageForecast
--
v_holiday VARCHAR2(1);
BEGIN
SELECT '1' INTO v_holiday
FROM dbp_holiday
WHERE holiday_date = p_date;

RETURN TRUE;

EXCEPTION 
    WHEN NO_DATA_FOUND THEN 
    RETURN FALSE;

END; --holiday


PROCEDURE averageForecast IS
--
-- Author: Beomsang Kim
-- Created Date: 30-MAY-2020
-- Modified Date: 01-JUN-2020
-- Purpose: Inserting forecated values into LOCAL_RM16 table
--
v_ferecastDay DATE;
v_changeDate DATE := sysdate;
v_procedureName VARCHAR(25) := 'averageForecast';
v_meterType VARCHAR(35);
--
BEGIN
    v_meterType := get_param('LOCAL_RM16', 'METERTYPE');
    COMMON.LOG('In procedure ' || v_procedureName);
   
FOR counter IN 1..14
LOOP
    v_ferecastDay := TRUNC(sysdate) + counter;
    COMMON.LOG('The forecasted day is ' || v_ferecastDay);
    IF NOT HOLIDAY(v_ferecastDay) THEN
        INSERT INTO LOCAL_RM16 (TNI, METERTYPE, LR, FRMP, CHANGE_DATE, DAY, HH, VOLUME)
        (SELECT TNI, v_meterType, lr, frmp, v_changeDate, v_ferecastDay, hh, AVERAGE
        FROM V_NEM_AVERAGE a
        WHERE TO_CHAR(v_ferecastDay, 'D') = a.dayNum);
        COMMIT;
       
    ELSE
    COMMON.LOG('The forecasted day ' || v_ferecastDay || ' is holiday');
        INSERT INTO LOCAL_RM16 (TNI, METERTYPE, LR, FRMP, CHANGE_DATE, DAY, HH, VOLUME)
        (SELECT TNI, v_meterType, LR, FRMP, v_changeDate, v_ferecastDay, hh, AVERAGE
         FROM V_NEM_AVERAGE a
         WHERE a.dayNum = 9);
         COMMIT;
    END IF;
   
END LOOP;
--
EXCEPTION
WHEN OTHERS THEN
COMMON.LOG('The procedure '||v_procedureName||' failed to the insert');
--
END; --averageForecast


--Producing Document
Procedure managingUTL IS
--
-- Author: Beomsang Kim
-- Created Date: 30-MAY-2020
-- Modified Date: 05-JUN-2020
-- Purpose: Producing UTL report about total voulme of forecasted volems today
--          Stoaring into U13340106_DIR
--
v_procedureName VARCHAR2(35) := 'managingUTL';
v_filePointer utl_file.file_type;
v_dir VARCHAR2(35) := 'U13340106_DIR';
v_UTLFileName VARCHAR2(35);
v_totalVolume NUMBER;
v_pageWidth NUMBER := 80;
v_PageNum VARCHAR(255);
v_reportHeading VARCHAR2(35);
v_reportFooter VARCHAR2(35);
--
FUNCTION f_centre(p_text VARCHAR2) RETURN VARCHAR2 IS
v_textWidth NUMBER;
BEGIN
    v_textWidth := LENGTH(p_text) / 2;
    RETURN LPAD(p_text, (v_pageWidth/2) + v_textWidth, ' ');
END; 
--
BEGIN
--
SELECT seq_page.NEXTVAL INTO v_pageNum 
FROM dual;
--
v_reportHeading := get_param('UTL Report', 'Report Heading');
v_reportFooter := get_param('UTL Report', 'Report Footer');
    SELECT 'U13340106_'||to_char(sysdate, gv_dateFormatWithoutDash)||'.dat' INTO v_UTLFileName
    FROM DUAL;
    
        SELECT SUM(VOLUME) INTO v_totalVolume
        FROM LOCAL_RM16
        WHERE day = TRUNC(sysdate + 1)
        AND day <= TRUNC(sysdate + 14);
        
    v_filePointer := utl_file.fopen(v_dir, v_utlFileName, 'A');
    utl_file.put_line(v_filePointer, f_centre(v_reportHeading));
    utl_file.put_line(v_filePointer, 'Date: '||to_char(sysdate, gv_dateFormat)||
    LPAD('Page '||v_PageNum, 62));
    utl_file.new_line(v_filePointer);
    utl_file.put_line(v_filePointer, 'This file was created by '||USER);
    utl_file.new_line(v_filePointer); 
    utl_file.put_line(v_filePointer, 'Today total  '||LPAD(v_totalVolume, 10, '0')||
    ' forecasted volumes are stored in LOCAL_RM16 table');
    utl_file.new_line(v_filePointer);
    utl_file.put_line(v_filePointer, f_centre(v_reportFooter));
    utl_file.fclose(v_filePointer); 
--    
EXCEPTION
  WHEN UTL_FILE.INVALID_OPERATION THEN
     UTL_FILE.FCLOSE(v_filePointer);
    COMMON.LOG('In the Procedure '||v_procedureName||' file could not be opened or operated on as requested.');  
  WHEN OTHERS THEN
    COMMON.LOG('other trouble'||SQLCODE||SQLERRM);
    
END;

PROCEDURE ManagingXML IS
--
-- Author: Beomsang Kim
-- Created Date: 30-MAY-2020
-- Modified Date: 05-JUN-2020
-- Purpose: Producing XML file about 1 day after's each TNI total
--          Stoaring into U13340106_DIR
--
v_procedureName VARCHAR2(35) := 'ManagingXML';
v_filePointer utl_file.file_type; 
v_utlFileName VARCHAR2(35);
Ctx               DBMS_XMLGEN.ctxHandle;
xml               CLOB := NULL;
temp_xml          CLOB := NULL;
v_rowSetTag       VARCHAR2(35):= get_param('LOCAL_RM16', 'METERTYPE');
v_rowTag          VARCHAR2(35) := get_param('TAG', 'Row  Tag');

QUERY    VARCHAR2(2000) := 'SELECT tni, sum(volume) tni_total 
                            FROM LOCAL_RM16
                            WHERE DAY = TRUNC(SYSDATE + 1) GROUP BY tni';
BEGIN
   Ctx := DBMS_XMLGEN.newContext(QUERY);
   DBMS_XMLGen.setRowsetTag( Ctx, v_rowSetTag );
   DBMS_XMLGen.setRowTag( Ctx, v_rowTag );
   temp_xml := DBMS_XMLGEN.getXML(Ctx);
   COMMON.LOG('In procedure ' || v_procedureName);
--
        IF temp_xml IS NOT NULL THEN
            IF xml IS NOT NULL THEN
                DBMS_LOB.APPEND( xml, temp_xml );
            ELSE
                xml := temp_xml;
            END IF;
        END IF;
        DBMS_XMLGEN.closeContext( Ctx );
        COMMON.LOG('The XML file '||v_utlFileName||' is generated');
        
    SELECT 'U13340106_'||to_char(sysdate, gv_dateFormat)||'.xml' INTO v_utlFileName
    FROM dual;        
    v_filePointer := utl_file.fopen(gv_diriectory, v_utlFileName, 'A'); 
    utl_file.put_line(v_filePointer, substr(xml, 1, 1950));
    utl_file.fclose(v_filePointer); 
    COMMON.LOG('The XML file '||v_utlFileName||' is storeed into '||gv_diriectory );
    
END; --managingXML


END PKG_2020MAIN;