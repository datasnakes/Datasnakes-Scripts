-- -*-Sql-*- mode (to keep my emacs happy)
--
-- API Package Body for Term_Synonym.
--
-- Scaffold auto-generated by gen-api.pl. gen-api.pl is
-- Copyright 2002-2003 Genomics Institute of the Novartis Research Foundation
-- Copyright 2002-2008 Hilmar Lapp
-- 
--  This file is part of BioSQL.
--
--  BioSQL is free software: you can redistribute it and/or modify it
--  under the terms of the GNU Lesser General Public License as
--  published by the Free Software Foundation, either version 3 of the
--  License, or (at your option) any later version.
--
--  BioSQL is distributed in the hope that it will be useful,
--  but WITHOUT ANY WARRANTY; without even the implied warranty of
--  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
--  GNU Lesser General Public License for more details.
--
--  You should have received a copy of the GNU Lesser General Public License
--  along with BioSQL. If not, see <http://www.gnu.org/licenses/>.
--

CREATE OR REPLACE
PACKAGE BODY TSyn IS

TSyn_cached	SG_TERM_SYNONYM.TRM_OID%TYPE DEFAULT NULL;
cache_key		VARCHAR2(128) DEFAULT NULL;

CURSOR TSyn_c (TSyn_TRM_OID	IN SG_TERM_SYNONYM.TRM_OID%TYPE,
	       TSyn_NAME	IN SG_TERM_SYNONYM.NAME%TYPE)
RETURN SG_TERM_SYNONYM%ROWTYPE IS
	SELECT t.* FROM SG_TERM_SYNONYM t
	WHERE
		t.Trm_Oid = TSyn_Trm_Oid
	AND	t.Name    = TSyn_Name
	;

FUNCTION get_oid(
		TSyn_NAME	IN SG_TERM_SYNONYM.NAME%TYPE DEFAULT NULL,
		TRM_OID	IN SG_TERM_SYNONYM.TRM_OID%TYPE DEFAULT NULL,
		Trm_NAME	IN SG_TERM.NAME%TYPE DEFAULT NULL,
		ONT_OID	IN SG_TERM.ONT_OID%TYPE DEFAULT NULL,
		ONT_NAME	IN SG_ONTOLOGY.NAME%TYPE DEFAULT NULL,
		Trm_IDENTIFIER	IN SG_TERM.IDENTIFIER%TYPE DEFAULT NULL,
		do_DML		IN NUMBER DEFAULT BSStd.DML_NO)
RETURN SG_TERM_SYNONYM.TRM_OID%TYPE
IS
	pk	SG_TERM_SYNONYM.TRM_OID%TYPE DEFAULT NULL;
	TSyn_row TSyn_c%ROWTYPE;
	TRM_OID_	SG_TERM.OID%TYPE DEFAULT TRM_OID;
	key_str	VARCHAR2(128) DEFAULT TSyn_Name || '|' || Trm_Oid || '|' || Ont_Oid || '|' || Ont_Name || '|' || Trm_Name || '|' || Trm_Identifier;
BEGIN
	-- initialize
	-- look up
	IF pk IS NULL THEN
		IF (key_str = cache_key) THEN
			pk := TSyn_cached;
		ELSE
			-- reset cache
			cache_key := NULL;
			TSyn_cached := NULL;
                	-- look up SG_TERM
                	IF (TRM_OID_ IS NULL) THEN
                		TRM_OID_ := Trm.get_oid(
                			Trm_NAME => Trm_NAME,
                			ONT_OID => ONT_OID,
                			ONT_NAME => ONT_NAME,
                			Trm_IDENTIFIER => Trm_IDENTIFIER);
                	END IF;
			-- do the look up
			FOR TSyn_row IN TSyn_c (TRM_OID_, TSyn_NAME) LOOP
		        	pk := TSyn_row.TRM_OID;
				-- cache result
			    	cache_key := key_str;
			    	TSyn_cached := pk;
			END LOOP;
		END IF;
	END IF;
	-- insert/update if requested
	IF (pk IS NULL) AND 
	   ((do_DML = BSStd.DML_I) OR (do_DML = BSStd.DML_UI)) THEN
	    	-- look up foreign keys if not provided:
		-- look up SG_TERM successful?
		IF (TRM_OID_ IS NULL) THEN
			raise_application_error(-20101,
				'failed to look up Trm <' || Trm_NAME || '|' || ONT_OID || '|' || ONT_NAME || '|' || Trm_IDENTIFIER || '>');
		END IF;
	    	-- insert the record and obtain the primary key
	    	pk := do_insert(
			NAME => TSyn_NAME,
		        TRM_OID => TRM_OID_);
	END IF; -- no update here
	-- return the foreign key
	RETURN TRM_OID_;
END;

FUNCTION do_insert(
		TRM_OID	IN SG_TERM_SYNONYM.TRM_OID%TYPE,
		NAME	IN SG_TERM_SYNONYM.NAME%TYPE)
RETURN SG_TERM_SYNONYM.TRM_OID%TYPE 
IS
BEGIN
	-- insert the record
	INSERT INTO SG_TERM_SYNONYM (
		NAME,
		TRM_OID)
	VALUES (NAME,
		TRM_OID)
	;
	-- return the foreign key
	RETURN Trm_OID;
END;

END TSyn;
/

