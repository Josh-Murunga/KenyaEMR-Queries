set @startDate = '2024-12-01', @endDate = '2024-12-31';

select t.patient_id, t.patient_name, t.unique_patient_no, t.max_fup_vis_date last_visit_date, t.latest_fup_tca next_appointment_date, t.days_missed, t.appointment_service, t.appointment_status
from (
         select fup.visit_date,
                date(d.visit_date),
                fup.patient_id,
                max(e.visit_date)                                               as enroll_date,
                greatest(max(e.visit_date),ifnull(max(date(e.transfer_in_date)), '0000-00-00'))   as latest_enrolment_date,
                greatest(max(fup.visit_date),ifnull(max(d.visit_date), '0000-00-00'))               as latest_vis_date,
                max(fup.visit_date)                                             as max_fup_vis_date,
                greatest(mid(max(concat(fup.visit_date, fup.next_appointment_date)), 11),ifnull(max(d.visit_date), '0000-00-00'))as latest_tca, 
				timestampdiff(DAY, date(mid(max(concat(fup.visit_date, fup.next_appointment_date)), 11)), date(@endDate)) days_missed,
                mid(max(concat(fup.visit_date, fup.next_appointment_date)), 11) as latest_fup_tca,
                d.patient_id                                                    as disc_patient,
                d.effective_disc_date                                           as effective_disc_date,
                d.visit_date                                                    as date_discontinued,
                d.discontinuation_reason,
                de.patient_id                                                   as started_on_drugs,
                (CASE 
    WHEN appointment_service = 1 THEN 'HIV Consultation'
    WHEN appointment_service = 2 THEN 'Drug Refill'
    WHEN appointment_service = 3 THEN 'KP Clinical Visit'
    WHEN appointment_service = 4 THEN 'MCH Antenatal'
    WHEN appointment_service = 5 THEN 'MCH Postnatal'
    WHEN appointment_service = 6 THEN 'Tb Followup'
    WHEN appointment_service = 7 THEN 'Prep Initial'
    WHEN appointment_service = 8 THEN 'Prep Followup'
    WHEN appointment_service = 9 THEN 'Prep Monthly Refill'
    WHEN appointment_service = 10 THEN 'Family Planning'
    WHEN appointment_service = 11 THEN 'Counselling'
    WHEN appointment_service = 12 THEN 'Lab tests'
    WHEN appointment_service = 13 THEN 'CWC Followup'
    WHEN appointment_service = 14 THEN 'Radiology and Imaging'
    WHEN appointment_service = 15 THEN 'Nutritional and Dietary appointment'
    WHEN appointment_service = 16 THEN 'Cervical cancer Screening'
    WHEN appointment_service = 17 THEN 'Harm/Risk Reduction'
    WHEN appointment_service = 18 THEN 'Psychosocial support appointment'
    WHEN appointment_service = 19 THEN 'Vaccination appointments'
    WHEN appointment_service = 20 THEN 'Physiotherapy and Rehabilitation appointment'
    WHEN appointment_service = 21 THEN 'Post-operative follow-up'
    WHEN appointment_service = 22 THEN 'Chemotherapy/ Radiation Therapy appointment'
    WHEN appointment_service = 23 THEN 'Cancer screening appointment'
    WHEN appointment_service = 24 THEN 'Renal Dialysis appointment'
    WHEN appointment_service = 25 THEN 'Surgery scheduling'
    WHEN appointment_service = 26 THEN 'Oncology (Cancer) consultation'
    WHEN appointment_service = 27 THEN 'Oncology follow-up'
    WHEN appointment_service = 28 THEN 'Chemotherapy sessions'
    WHEN appointment_service = 29 THEN 'Respiratory / pulmonary consultation'
    WHEN appointment_service = 30 THEN 'Pulmonary rehabilitation'
    WHEN appointment_service = 31 THEN 'Diabetic initial consultation'
    WHEN appointment_service = 32 THEN 'Diabetic follow-up'
    WHEN appointment_service = 33 THEN 'Diabetic foot care'
    WHEN appointment_service = 34 THEN 'Cardiology consultation'
    WHEN appointment_service = 35 THEN 'Cardiology follow up'
    WHEN appointment_service = 36 THEN 'Hypertension initial consultation'
    WHEN appointment_service = 37 THEN 'Hypertension follow up'
    WHEN appointment_service = 38 THEN 'Radiotherapy sessions'
    WHEN appointment_service = 39 THEN 'Neurological Appointment'
    WHEN appointment_service = 40 THEN 'Mental health (Psychiatry) consultation'
    WHEN appointment_service = 41 THEN 'Endoscopy/colonoscopy services'
    WHEN appointment_service = 42 THEN 'Renal consultation'
    WHEN appointment_service = 43 THEN 'Orthopedic consultation'
    WHEN appointment_service = 44 THEN 'Palliative care services'
    WHEN appointment_service = 45 THEN 'Gynecological/obstetric consultation services'
    WHEN appointment_service = 46 THEN 'Occupational therapy services'
    WHEN appointment_service = 47 THEN 'Ophthalmologic services'
    WHEN appointment_service = 48 THEN 'ENT (Ear Nose and Throat) services'
    WHEN appointment_service = 49 THEN 'Fertility follow up'
    WHEN appointment_service = 50 THEN 'Pediatrics appointment'
    WHEN appointment_service = 51 THEN 'Rheumatological consultation'
    WHEN appointment_service = 52 THEN 'Dental appointment'
    WHEN appointment_service = 53 THEN 'Dermatological appointment'
    WHEN appointment_service = 54 THEN 'Endocrinology appointment'
    WHEN appointment_service = 55 THEN 'Pre-travel consultation'
    WHEN appointment_service = 56 THEN 'Post-travel consultation'
    WHEN appointment_service = 57 THEN 'Infectious disease consultation'
    WHEN appointment_service = 58 THEN 'Gastroenterology Appointment'
    ELSE 'Unknown Service'
END) appointment_service,
                apt.appointment_status,
                concat(p.family_name,' ',p.given_name, ' ',p.middle_name) patient_name,
                p.unique_patient_no 
         from kenyaemr_etl.etl_patient_hiv_followup fup
                  join kenyaemr_etl.etl_patient_demographics p on p.patient_id = fup.patient_id
                  join kenyaemr_etl.etl_hiv_enrollment e on fup.patient_id = e.patient_id
                  inner join
        (select fup.patient_id, pat.visit_date, max(pat.start_date_time) patAppt, fup.next_appointment_date etlAppt,
			mid(max(concat(pat.visit_date, pat.appointment_service_id)),11) appointment_service,
            mid(max(concat(pat.visit_date, pat.`status`)),11) appointment_status
         from kenyaemr_etl.etl_patient_hiv_followup fup
                  inner join kenyaemr_etl.etl_patient_appointment pat
                             on pat.patient_id = fup.patient_id and pat.visit_date = fup.visit_date
         group by fup.patient_id, fup.visit_date) apt on apt.patient_id = fup.patient_id and apt.visit_date = fup.visit_date
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
     ) t;