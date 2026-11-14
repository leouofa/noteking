class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  before_action :load_sidebar_data

  private

  def load_sidebar_data
    @sidebar_projects = Project.order(:name).includes(:notes)
    @sidebar_pinned_notes = Note.pinned
    @sidebar_total_standalone_count = Note.standalone.count
    @sidebar_total_notes_count = Note.count
  end
end
