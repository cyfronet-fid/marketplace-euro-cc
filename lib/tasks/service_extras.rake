# frozen_string_literal: true

require "csv"

namespace :service_extras do
  desc "Set horizontal and categorisation fields "
  task :set, [:path] => :environment do |_t, args|
    args.with_defaults(path: "services.csv")
    table = CSV.parse(File.read(args[:path]), headers: true)
    Service.transaction do
      table.each do |entry|
        puts "Updating #{entry["name"]} with arguments horizontal: #{entry["horizontal"]}" +
               " categories: #{entry["new_categories"]}"
        mapped_categories = entry["new_categories"].split("/").map { |c| Vocabulary::ResearchCategory.find_by(eid: c) }
        service = Service.find_by(name: entry["name"])
        if service.present?
          service.update!(horizontal: entry["horizontal"], research_categories: mapped_categories)
        else
          puts "WARN: #{entry["name"]} not updated, service is blank: #{service}"
        end
      end
    end
  end
end
