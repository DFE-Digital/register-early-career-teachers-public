SELECT
    schools.id AS school_id,
    lead_providers.id AS lead_provider_id,
    contract_periods.year AS contract_period_id,
    -- in_partnership
    EXISTS (
        SELECT 1
        FROM schools s
        INNER JOIN school_partnerships sp ON s.id = sp.school_id
        INNER JOIN lead_provider_delivery_partnerships lpd ON sp.lead_provider_delivery_partnership_id = lpd.id
        INNER JOIN active_lead_providers alp ON lpd.active_lead_provider_id = alp.id
        INNER JOIN contract_periods cp ON alp.contract_period_id = cp.year
        WHERE schools.id = s.id
          AND cp.year = contract_periods.year
        LIMIT 1
    ) AS in_partnership,
    -- training_programme
    CASE
      WHEN EXISTS (
        SELECT 1
        FROM schools s
        INNER JOIN mentor_at_school_periods masp ON s.id = masp.school_id
        INNER JOIN training_periods tp ON masp.id = tp.mentor_at_school_period_id
        INNER JOIN school_partnerships sp ON tp.school_partnership_id = sp.id
        INNER JOIN lead_provider_delivery_partnerships lpd ON sp.lead_provider_delivery_partnership_id = lpd.id
        INNER JOIN active_lead_providers alp ON lpd.active_lead_provider_id = alp.id
        INNER JOIN contract_periods cp ON alp.contract_period_id = cp.year
        WHERE schools.id = s.id
          AND cp.year = contract_periods.year
        LIMIT 1
      ) THEN 'provider_led'
      WHEN EXISTS (
        SELECT 1
        FROM schools s
        INNER JOIN ect_at_school_periods easp ON s.id = easp.school_id
        INNER JOIN training_periods tp ON easp.id = tp.ect_at_school_period_id
        INNER JOIN school_partnerships sp ON tp.school_partnership_id = sp.id
        INNER JOIN lead_provider_delivery_partnerships lpd ON sp.lead_provider_delivery_partnership_id = lpd.id
        INNER JOIN active_lead_providers alp ON lpd.active_lead_provider_id = alp.id
        INNER JOIN contract_periods cp ON alp.contract_period_id = cp.year
        WHERE schools.id = s.id
          AND cp.year = contract_periods.year
        LIMIT 1
      ) THEN (
        CASE
          WHEN (
            SELECT DISTINCT(tp.training_programme)
            FROM schools s
            INNER JOIN ect_at_school_periods easp ON s.id = easp.school_id
            INNER JOIN training_periods tp ON easp.id = tp.ect_at_school_period_id
            INNER JOIN school_partnerships sp ON tp.school_partnership_id = sp.id
            INNER JOIN lead_provider_delivery_partnerships lpd ON sp.lead_provider_delivery_partnership_id = lpd.id
            INNER JOIN active_lead_providers alp ON lpd.active_lead_provider_id = alp.id
            INNER JOIN contract_periods cp ON alp.contract_period_id = cp.year
            WHERE schools.id = s.id
              AND cp.year = contract_periods.year
            ORDER BY tp.training_programme ASC
            LIMIT 1
          ) = 'provider_led'
          THEN 'provider_led'
          WHEN (
            SELECT DISTINCT(tp.training_programme)
            FROM schools s
            INNER JOIN ect_at_school_periods easp ON s.id = easp.school_id
            INNER JOIN training_periods tp ON easp.id = tp.ect_at_school_period_id
            INNER JOIN school_partnerships sp ON tp.school_partnership_id = sp.id
            INNER JOIN lead_provider_delivery_partnerships lpd ON sp.lead_provider_delivery_partnership_id = lpd.id
            INNER JOIN active_lead_providers alp ON lpd.active_lead_provider_id = alp.id
            INNER JOIN contract_periods cp ON alp.contract_period_id = cp.year
            WHERE schools.id = s.id
              AND cp.year = contract_periods.year
            ORDER BY tp.training_programme ASC
            LIMIT 1
          ) = 'school_led'
          THEN 'school_led'
        END
      )
      ELSE 'not_yet_known'
    END AS training_programme,
    -- expression_of_interest
    CASE
      WHEN EXISTS (
        SELECT 1
        FROM schools s
        INNER JOIN mentor_at_school_periods masp ON s.id = masp.school_id
        INNER JOIN training_periods tp ON masp.id = tp.mentor_at_school_period_id
        INNER JOIN active_lead_providers alp ON tp.expression_of_interest_id = alp.id
        INNER JOIN contract_periods cp ON alp.contract_period_id = cp.year
        WHERE schools.id = s.id
          AND cp.year = contract_periods.year
          AND alp.lead_provider_id = lead_providers.id
        LIMIT 1
      ) THEN true
      WHEN EXISTS (
        SELECT 1
        FROM schools s
        INNER JOIN ect_at_school_periods easp ON s.id = easp.school_id
        INNER JOIN training_periods tp ON easp.id = tp.ect_at_school_period_id
        INNER JOIN active_lead_providers alp ON tp.expression_of_interest_id = alp.id
        INNER JOIN contract_periods cp ON alp.contract_period_id = cp.year
        WHERE schools.id = s.id
          AND cp.year = contract_periods.year
          AND alp.lead_provider_id = lead_providers.id
        LIMIT 1
      ) THEN true
      ELSE false
    END AS expression_of_interest
FROM
    schools
    CROSS JOIN lead_providers
    CROSS JOIN contract_periods
