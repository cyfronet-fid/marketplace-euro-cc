# frozen_string_literal: true

namespace :migration do
  desc "Add catalogue prefix to the existing services and providers sources"
  task eids: :environment do
    source_types = [
      { type: ServiceSource, method: "service", level: 3 },
      { type: ProviderSource, method: "provider", level: 2 }
    ].freeze
    source_types.each do |hash|
      type = hash[:type]
      puts "Migrating #{type} ids to format {catalogue_id}.{old_id}"
      counter = 0
      type.transaction do
        type.find_each do |source|
          if source.eid.split(".").size >= hash[:level]
            puts "ID #{source.eid} has a new format, omit."
            next
          end
          catalogue_id = source.send(hash[:method])&.catalogue&.pid
          if catalogue_id.present?
            new_eid = "#{catalogue_id}.#{source.eid}"
            source.update!(eid: new_eid)
            source.send(hash[:method]).update!(pid: new_eid)
            counter += 1
            puts "Successfully updated #{type} with eid: #{new_eid}"
            next
          end
          puts "CatalogueID not found. #{type} #{source.eid} not updated"
        end
      end
      puts "Migrated #{counter} objecta of type #{type}"
    end
  end
end
