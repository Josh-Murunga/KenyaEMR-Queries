select a.person_id, b.identifier unique_patient_identifier, 
max(date(a.obs_datetime)) last_vdrl_date,
mid(max(concat(date(a.obs_datetime), (case a.value_coded 
									  when 1228 then "Reactive" 
                                      when 1229 then "Non-Reactive" 
                                      when 165232 then "Inconclusive" 
                                      when 664 then "Negative"
                                      when 703 then "Positive"
                                      when 1271 then "TESTS ORDERED"
                                      when 1118 then "Not done"
                                      when 1402 then "NEVER TESTED"
                                      else a.value_coded end))),11) last_vdrl_results 
from openmrs.obs a 
left join openmrs.patient_identifier b on a.person_id=b.patient_id and b.identifier_type = (SELECT patient_identifier_type_id FROM openmrs.patient_identifier_type where uuid = '05ee9cf4-7242-4a17-b4d4-00f707265c8a')
where concept_id = 299 and a.voided = 0
group by a.person_id;


