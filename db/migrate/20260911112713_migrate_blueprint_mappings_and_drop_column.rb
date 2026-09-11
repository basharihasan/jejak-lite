class MigrateBlueprintMappingsAndDropColumn < ActiveRecord::Migration[8.1]
  def up
    # competency_mapping lama (JSONB bebas teks "Ranah" => bobot) dicocokkan
    # ke CompetencyItem berdasar judul persis — ranah yang tidak cocok
    # (nama beda/typo) sengaja dilewati, bukan dipaksakan, supaya tidak ada
    # mapping salah sasaran senyap-senyap.
    connection.select_all("SELECT id, competency_mapping FROM assessment_blueprints").each do |row|
      mapping = row["competency_mapping"].is_a?(String) ? JSON.parse(row["competency_mapping"]) : (row["competency_mapping"] || {})
      mapping.each do |label, weight|
        item_id = connection.select_value("SELECT id FROM competency_items WHERE title = #{connection.quote(label)} LIMIT 1")
        next unless item_id

        safety_assured do
          execute <<~SQL
            INSERT INTO assessment_blueprint_mappings (assessment_blueprint_id, competency_item_id, weight, created_at, updated_at)
            VALUES (#{row["id"]}, #{item_id}, #{connection.quote(weight)}, NOW(), NOW())
            ON CONFLICT DO NOTHING
          SQL
        end
      end
    end

    safety_assured { remove_column :assessment_blueprints, :competency_mapping }
  end

  def down
    add_column :assessment_blueprints, :competency_mapping, :jsonb, default: {}, null: false
  end
end
