set @startDate = '2024-12-01', @endDate = '2024-12-31';

UPDATE openmrs.patient_appointment b
INNER JOIN (
    SELECT a.patient_id, 
           MAX(DATE(a.encounter_datetime)) AS visit_date, 
           MAX(date(b.date_appointment_scheduled)) AS date_scheduled, 
           MID(MAX(CONCAT(DATE(b.date_appointment_scheduled), b.patient_appointment_id)), 11) AS patient_appointment_id
    FROM openmrs.encounter a
    INNER JOIN openmrs.patient_appointment b 
        ON a.patient_id = b.patient_id
    WHERE a.form_id = (select f.form_id from openmrs.form f where f.uuid = '22c68f86-bbf0-49ba-b2d1-23fa7ccf0259') 
      AND a.voided = 0 
    GROUP BY a.patient_id
) apt ON b.patient_appointment_id = apt.patient_appointment_id
SET b.date_appointment_scheduled = CONCAT(apt.visit_date, ' 09:09:11')
WHERE apt.visit_date <> apt.date_scheduled
and b.patient_appointment_id = apt.patient_appointment_id
AND apt.patient_id IN 
(select t.patient_id
from (
         select fup.visit_date,
                date(d.visit_date),
                fup.patient_id,
                max(e.visit_date)                                               as enroll_date,
                greatest(max(e.visit_date),
                         ifnull(max(date(e.transfer_in_date)), '0000-00-00'))   as latest_enrolment_date,
                greatest(max(fup.visit_date),
                         ifnull(max(d.visit_date), '0000-00-00'))               as latest_vis_date,
                max(fup.visit_date)                                             as max_fup_vis_date,
                greatest(mid(max(concat(fup.visit_date, fup.next_appointment_date)), 11),
                         ifnull(max(d.visit_date), '0000-00-00'))               as latest_tca, timestampdiff(DAY, date(mid(max(concat(fup.visit_date, fup.next_appointment_date)), 11)), date(@endDate)) 'DAYS MISSED',
                mid(max(concat(fup.visit_date, fup.next_appointment_date)), 11) as latest_fup_tca,
                d.patient_id                                                    as disc_patient,
                d.effective_disc_date                                           as effective_disc_date,
                d.visit_date                                                    as date_discontinued,
                d.discontinuation_reason,
                de.patient_id                                                   as started_on_drugs
         from kenyaemr_etl.etl_patient_hiv_followup fup
                  join kenyaemr_etl.etl_patient_demographics p on p.patient_id = fup.patient_id
                  join kenyaemr_etl.etl_hiv_enrollment e on fup.patient_id = e.patient_id
                  left outer join kenyaemr_etl.etl_drug_event de
                                  on e.patient_id = de.patient_id and de.program = 'HIV' and
                                     date(date_started) <= date(curdate())
                  left outer JOIN
              (select patient_id,
                      coalesce(max(date(effective_discontinuation_date)), max(date(visit_date))) as visit_date,
                      max(date(effective_discontinuation_date))                                  as effective_disc_date,
                      discontinuation_reason
               from kenyaemr_etl.etl_patient_program_discontinuation
               where date(visit_date) <= date(@endDate)
                 and program_name = 'HIV'
               group by patient_id
              ) d on d.patient_id = fup.patient_id
         where fup.visit_date <= date(@endDate)
         group by patient_id
         having (
                        (timestampdiff(DAY, date(latest_fup_tca), date(@startDate)) <= 30) and
                        (timestampdiff(DAY, date(latest_fup_tca), date(@endDate)) > 30) and
                        (
                                (date(enroll_date) >= date(d.visit_date) and
                                 date(max_fup_vis_date) >= date(d.visit_date) and
                                 date(latest_fup_tca) > date(d.visit_date))
                                or disc_patient is null
                                or (date(d.visit_date) between date(@startDate) and date(@endDate)
                                and d.discontinuation_reason = 5240))
                    )
     ) t);