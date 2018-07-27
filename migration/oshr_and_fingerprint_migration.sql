drop table if exists tmp_pid ;

DROP PROCEDURE IF EXISTS create_pid;

CREATE TABLE tmp_pid(
	patient_id bigint,
	isanteplus_id VARCHAR(250),
	st_code VARCHAR(250),
	code_national VARCHAR(250),
	ecid VARCHAR(250),
	old_id VARCHAR(250),
	fingerprint_id VARCHAR(250)
);


DELIMITER //
CREATE PROCEDURE create_pid()
BEGIN
	DECLARE pid bigint;
    DECLARE isanteplus_id VARCHAR(250);
    DECLARE st_code VARCHAR(250);
	DECLARE code_national VARCHAR(250);
    DECLARE ecid VARCHAR(250);
    DECLARE old_id VARCHAR(250);
    DECLARE fingerprint_id VARCHAR(250);
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
						WHERE patient_id = pid AND voided = 0
						AND pidt.uuid = "05a29f94-c0ed-11e2-94be-8c13b969e334"
						LIMIT 1 INTO isanteplus_id;

            SELECT identifier
						FROM patient_identifier
						LEFT JOIN patient_identifier_type pidt
						ON identifier_type = pidt.patient_identifier_type_id
						WHERE patient_id = pid AND voided = 0
						AND pidt.uuid = "d059f6d0-9e42-4760-8de1-8316b48bc5f1"
						LIMIT 1 INTO st_code;

            SELECT identifier
						FROM patient_identifier
						LEFT JOIN patient_identifier_type pidt
						ON identifier_type = pidt.patient_identifier_type_id
						WHERE patient_id = pid AND voided = 0
						AND pidt.uuid = "9fb4533d-4fd5-4276-875b-2ab41597f5dd"
						LIMIT 1 INTO code_national;

            SELECT identifier
						FROM patient_identifier
						LEFT JOIN patient_identifier_type pidt
						ON identifier_type = pidt.patient_identifier_type_id
						WHERE patient_id = pid AND voided = 0
						AND pidt.uuid = "f54ed6b9-f5b9-4fd5-a588-8f7561a78401"
						LIMIT 1 INTO ecid;

            SELECT identifier
						FROM patient_identifier
						LEFT JOIN patient_identifier_type pidt
						ON identifier_type = pidt.patient_identifier_type_id
						WHERE patient_id = pid AND voided = 0
						AND pidt.uuid = "0e0c7cc2-3491-4675-b705-746e372ff346"
						LIMIT 1 INTO old_id;

            SELECT M2BP_PERSONID
            FROM biopluginserverse.m2bp_person_template
            WHERE M2BP_REGISTRATIONNO = old_id
            LIMIT 1 INTO fingerprint_id;

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
			IF old_id IS NULL THEN
				SET old_id = '';
            END IF;
      IF fingerprint_id IS NULL THEN
				SET fingerprint_id = '';
            END IF;

			INSERT INTO tmp_pid(patient_id, isanteplus_id, st_code, code_national, ecid, old_id, fingerprint_id) VALUES(pid, isanteplus_id, st_code, code_national, ecid, old_id, fingerprint_id);
            SET fingerprint_id = '';
            SET old_id = '';
            SET code_national = '';
            SET st_code = '';
            SET isanteplus_id = '';
            SET done = tmpdone;
        END IF;
	UNTIL done = TRUE END REPEAT;

    CLOSE pcur;
END //
DELIMITER ;

CALL create_pid();

SELECT 'isanteplus_id', 'st_code', 'code_national', 'family_name', 'given_name', 'birthdate',
				'gender', 'address1', 'city_village', 'state_province', 'postal_code', 'fingerprint_id', 'old_id', 'ecid'
UNION ALL
SELECT pid.isanteplus_id, pid.st_code, pid.code_national, nam.family_name, nam.given_name, coalesce(per.birthdate, ''),
coalesce(per.gender, 'O'), coalesce(adr.address1, ''), coalesce(adr.city_village, ''), coalesce(adr.state_province, ''),
coalesce(adr.postal_code, ''), pid.fingerprint_id, pid.old_id, pid.ecid
FROM patient pat
JOIN person per ON pat.patient_id = per.person_id AND per.voided = 0
JOIN person_name nam ON nam.person_id = per.person_id AND nam.voided = 0
JOIN person_address adr ON adr.person_id = per.person_id AND adr.voided = 0 AND adr.preferred = 1
JOIN tmp_pid pid ON pat.patient_id = pid.patient_id
WHERE pat.voided = 0
INTO OUTFILE '/var/lib/mysql-files/pixpdq.csv'
FIELDS TERMINATED BY '\^';
