--red banner solutions--
--## missing contact relationship

update openmrs.kenyaemr_hiv_testing_patient_contact as a
set a.relationship_type = 970
where a.relationship_type is null;

--## Have TPT outcome but missing TPT completion date 
update openmrs.patient_program as pp
inner join
(select a.patient_id, a.date_enrolled, a.date_completed, b.encounter_datetime, a.program_id, b.encounter_type
from openmrs.patient_program a
left join openmrs.encounter b on a.patient_id = b.patient_id
where a.program_id = 5
and b.encounter_type = 25
and a.date_completed is null
and b.encounter_datetime > a.date_enrolled) tpt on pp.patient_id=tpt.patient_id
set pp.date_completed = tpt.encounter_datetime
where tpt.program_id = 5
and tpt.encounter_type = 25
and tpt.date_completed is null
and tpt.encounter_datetime > tpt.date_enrolled
