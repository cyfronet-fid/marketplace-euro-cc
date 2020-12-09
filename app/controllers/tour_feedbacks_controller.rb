# frozen_string_literal: true

class TourFeedbacksController < ApplicationController
  def create
    tour_params = tour_feedback_params

    @tour_controller_name = tour_params[:tour_controller_name]
    @tour_controller_action = tour_params[:tour_controller_action]
    @tour_name = tour_params[:tour_name]
    @feedback = Rails.configuration.tours.list["#{@tour_controller_name}.#{@tour_controller_action}.#{I18n.locale}"]
    @feedback ||= Rails.configuration.tours.list["#{@tour_controller_name}.#{@tour_controller_action}.#{I18n.default_locale}"]
    unless @feedback
      return head 404
    end

    @feedback = @feedback.dig(@tour_name, "feedback")

    unless @feedback
      return head 404
    end

    @form = params.require(:content).permit(@feedback["questions"].map { |question| question["name"].to_sym })
    @errors = Hash[@feedback["questions"].select { |question| !@form[question["name"]].present? }.collect { |question| [question["name"], "This field is required"] }]

    if tour_params["share"] && tour_params["email"].blank? && current_user.nil?
      @errors["email"] = "This field is required"
    elsif tour_params["share"] && current_user.nil? && !(tour_params["email"] =~ /^(.+)@(.+)$/)
      @errors["email"] = "Email required"
    end

    if @errors.present? || !verify_recaptcha
      @form["share"] = tour_params["share"]
      @form["email"] = tour_params["email"]
      return respond_to do |format|
        format.js { render "layouts/show_tour_feedback", status: :bad_request,
                           locals: {
                               feedback_form: "layouts/tours/modal_content",
                               feedback_locals: {
                                   feedback: @feedback,
                                   errors: @errors,
                                   form: @form,
                                   tour_controller_name: @tour_controller_name,
                                   tour_controller_action: @tour_controller_action,
                                   tour_name: @tour_name } } }
      end
    end

    TourFeedback.new(controller_name: @tour_controller_name,
                     action_name: @tour_controller_action,
                     tour_name: @tour_name,
                     user_id: current_user&.id,
                     email: tour_params["email"],
                     content: @form).save

    head 201
  end

  private
    def tour_feedback_params
      params.permit(:tour_controller_name, :tour_controller_action, :tour_name, :email, :share)
    end
end