# frozen_string_literal: true

require "rails_helper"

RSpec.describe Catalogue::PcCreateOrUpdate, backend: true do
  let(:published_catalogue_response) { create(:jms_catalogue_response) }
  let(:logger) { Logger.new($stdout) }

  it "should create catalogue" do
    original_stdout = $stdout
    $stdout = StringIO.new
    expect { described_class.new(published_catalogue_response, true, Time.now).call }.to change { Catalogue.count }.by(
      1
    )

    catalogue = Catalogue.last

    expect(catalogue.name).to eq("Test Catalogue tp")
    expect(catalogue.pid).to eq("tp")

    $stdout = original_stdout
  end

  it "should update catalogue" do
    original_stdout = $stdout
    $stdout = StringIO.new
    catalogue = create(:catalogue, name: "new catalogue", pid: "tp")

    expect do
      described_class.new(
        create(:jms_catalogue_response, eid: "tp", name: "Test Update Catalogue"),
        true,
        Time.now.to_i
      ).call
    end.to change { Catalogue.count }.by(0)
    updated_catalogue = Catalogue.find(catalogue.id)

    expect(updated_catalogue.name).to eq("Test Update Catalogue")

    $stdout = original_stdout
  end
end
