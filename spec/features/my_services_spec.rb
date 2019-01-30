# frozen_string_literal: true

require "rails_helper"

RSpec.feature "My Services" do
  include OmniauthHelper

  context "as logged in user" do

    let(:user) { create(:user) }
    let(:service) { create(:service) }
    let(:offer) { create(:offer, service: service) }

    before { checkin_sign_in_as(user) }


    scenario "I can see only my projects" do
      p1, p2 = create_list(:project, 2, user: user)
      not_owned = create(:project)

      visit projects_path

      expect(page).to have_text(p1.name)
      expect(page).to have_text(p2.name)
      expect(page).to_not have_text(not_owned.name)
    end

    scenario "I can see my projects services" do
      project = create(:project, user: user)
      create(:project_item, project: project, offer: offer)

      visit projects_path

      expect(page).to have_text(service.title)
    end

    scenario "I can see project_item details" do
      project = create(:project, user: user)
      project_item = create(:project_item, project: project, offer: offer)

      visit project_item_path(project_item)

      expect(page).to have_text(project_item.service.title)
    end

    # Test added after hotfix for a bug in `project_items/show.html.haml:30` (v1.2.0)
    scenario "I can see project_item details without research_area" do
      offer = create(:offer, service: create(:open_access_service))
      project = create(:project, user: user)
      project_item = create(:project_item, project: project, offer: offer, research_area: nil)

      visit project_item_path(project_item)

      expect(page).to have_text(project_item.service.title)
    end

    scenario "I cannot se other users project_items" do
      other_user_project_item = create(:project_item, offer: offer)

      visit project_item_path(other_user_project_item)

      # TODO: the given service is showing up in Others pane in home view
      # expect(page).to_not have_text(other_user_project_item.service.title)
      expect(page).to have_text("not authorized")
    end

    scenario "I can see project_item change history" do
      project = create(:project, user: user)
      project_item = create(:project_item, project: project, offer: offer)

      project_item.new_change(status: :created, message: "Service request created")
      project_item.new_change(status: :registered, message: "Service request registered")
      project_item.new_change(status: :ready, message: "Service is ready")

      visit project_item_path(project_item)

      expect(page).to have_text("ready")

      expect(page).to have_text("Service request created")

      expect(page).to have_text("Status changed from created to registered")
      expect(page).to have_text("Service request registered")

      expect(page).to have_text("Status changed from registered to ready")
      expect(page).to have_text("Service is ready")
    end

    scenario "I can ask question about my project_item" do
      project = create(:project, user: user)
      project_item = create(:project_item, project: project, offer: offer)

      visit project_item_path(project_item)
      fill_in "project_item_question_text", with: "This is my question"
      click_button "Send message"

      expect(page).to have_text("This is my question")
    end

    scenario "question message is mandatory" do
      project = create(:project, user: user)
      project_item = create(:project_item, project: project, offer: offer)

      visit project_item_path(project_item)
      click_button "Send message"

      expect(page).to have_text("Question cannot be blank")
    end

    scenario "I can filter services by status", js: true do
      project1, project2 = create_list(:project, 2, user: user)
      project_item = create(:project_item, project: project1, offer: offer)

      visit projects_path

      select "Created", from: "status"

      expect(page).to have_text(project1.name)
      expect(page).to have_text(project_item.service.title)
      expect(page).not_to have_text(project2.name)
    end

    scenario "I see webservice link if service is ready" do
      project = create(:project, user: user)
      project_item = create(:project_item, project: project, offer: offer, status: :ready)

      visit projects_path

      expect(page).to have_link("Access the service", href: project_item.service.webpage_url)
    end
  end

  context "as anonymous user" do
    scenario "I don't see my services page" do
      visit root_path

      expect(page).to_not have_text("My services")
    end
  end
end
