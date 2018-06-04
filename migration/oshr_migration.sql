drop table if exists tmp_pid ;

DROP PROCEDURE IF EXISTS create_pid;

CREATE TABLE tmp_pid(
	patient_id bigint,
	isanteplus_id VARCHAR(250),
    st_code VARCHAR(250),
	code_national VARCHAR(250),
    ecid VARCHAR(250)
);


DELIMITER //
CREATE PROCEDURE create_pid()
BEGIN
	DECLARE pid bigint;
    DECLARE isanteplus_id VARCHAR(250);
    DECLARE st_code VARCHAR(250);
	DECLARE code_national VARCHAR(250);
    DECLARE ecid VARCHAR(250);
    DECLARE done TINYINT;
    DECLARE tmpdone TINYINT;
	DECLARE pcur CURSOR FOR SELECT patient_id FROM patient;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

    SET done = FALSE;
        
	OPEN pcur;

	REPEAT
		FETCH pcur INTO pid;
                
		IF done = FALSE THEN
			SET tmpdone = done;

						SELECT identifier
						FROM patient_identifier
						LEFT JOIN patient_identifier_type pidt
						ON identifier_type = pidt.patient_identifier_type_id
						WHERE patient_id = pid
						AND pidt.uuid = "05a29f94-c0ed-11e2-94be-8c13b969e334"
						LIMIT 1 INTO isanteplus_id;

            SELECT identifier
						FROM patient_identifier
						LEFT JOIN patient_identifier_type pidt
						ON identifier_type = pidt.patient_identifier_type_id
						WHERE patient_id = pid
						AND pidt.uuid = "d059f6d0-9e42-4760-8de1-8316b48bc5f1"
						LIMIT 1 INTO st_code;

            SELECT identifier
						FROM patient_identifier
						LEFT JOIN patient_identifier_type pidt
						ON identifier_type = pidt.patient_identifier_type_id
						WHERE patient_id = pid
						AND pidt.uuid = "9fb4533d-4fd5-4276-875b-2ab41597f5dd"
						LIMIT 1 INTO code_national;

            SELECT identifier
						FROM patient_identifier
						LEFT JOIN patient_identifier_type pidt
						ON identifier_type = pidt.patient_identifier_type_id
						WHERE patient_id = pid
						AND pidt.uuid = "f54ed6b9-f5b9-4fd5-a588-8f7561a78401"
						LIMIT 1 INTO ecid;

			IF isanteplus_id IS NULL THEN
				SET isanteplus_id = '';
            END IF;
			IF st_code IS NULL THEN
				SET st_code = '';
            END IF;
			IF code_national IS NULL THEN
				SET code_national = '';
            END IF;
			IF ecid IS NULL THEN
				SET ecid = '';
            END IF; 

			INSERT INTO tmp_pid(patient_id, isanteplus_id, st_code, code_national, ecid) VALUES(pid, isanteplus_id, st_code, code_national, ecid);
            
            SET done = tmpdone;
        END IF;
	UNTIL done = TRUE END REPEAT;
    
    CLOSE pcur;
END //
DELIMITER ;

CALL create_pid();

SELECT pid.isanteplus_id, pid.st_code, pid.code_national, pid.ecid, nam.family_name, nam.given_name, coalesce(per.birthdate, ''), 
coalesce(per.gender, ''), coalesce(adr.address1, ''), coalesce(adr.city_village, ''), coalesce(adr.state_province, ''), 
coalesce(adr.postal_code, '')
FROM patient pat
JOIN person per ON pat.patient_id = per.person_id
JOIN person_name nam ON nam.person_id = per.person_id
JOIN person_address adr ON adr.person_id = per.person_id
JOIN tmp_pid pid ON pat.patient_id = pid.patient_id
INTO OUTFILE '/var/lib/mysql-files/pixpdq.csv'
FIELDS TERMINATED BY ',';
