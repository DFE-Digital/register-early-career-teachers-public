class BackfillTRSResponseOnTeachers < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  BATCH_SIZE = 5_000

  def up
    each_batch do |first, last|
      execute(<<~SQL)
        UPDATE teachers SET trs_response = (
          CASE
            WHEN trs_deactivated THEN 'gone'
            WHEN trs_not_found AND EXISTS (
              SELECT 1 FROM events
              WHERE events.teacher_id = teachers.id
                AND events.event_type = 'teacher_trs_merged'
            ) THEN 'permanent_redirect'
            WHEN trs_not_found THEN 'not_found'
            ELSE 'ok'
          END
        )::trs_responses
        WHERE teachers.id BETWEEN #{first} AND #{last}
          AND teachers.trs_response IS NULL
          AND (teachers.trs_deactivated
               OR teachers.trs_not_found
               OR teachers.trs_data_last_refreshed_at IS NOT NULL)
      SQL

      execute(<<~SQL)
        UPDATE teachers SET trs_redirected_to = merged.redirected_to
        FROM (
          SELECT DISTINCT ON (teacher_id)
                 teacher_id,
                 substring(body from 'redirects to TRN (\\d+)') AS redirected_to
          FROM events
          WHERE event_type = 'teacher_trs_merged'
          ORDER BY teacher_id, created_at DESC
        ) AS merged
        WHERE merged.teacher_id = teachers.id
          AND merged.redirected_to IS NOT NULL
          AND teachers.trs_redirected_to IS NULL
          AND teachers.id BETWEEN #{first} AND #{last}
      SQL
    end
  end

  def down
    execute("UPDATE teachers SET trs_response = NULL, trs_redirected_to = NULL")
  end

private

  def each_batch
    first, last = select_rows("SELECT MIN(id), MAX(id) FROM teachers").first
    return if first.nil?

    (first..last).step(BATCH_SIZE) { |batch_start| yield(batch_start, batch_start + BATCH_SIZE - 1) }
  end
end
