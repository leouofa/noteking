# frozen_string_literal: true

class NoteVersionsController < ApplicationController
  before_action :set_note
  before_action :load_versions, only: %i[index show]

  def index
    @selected_version = if params[:version_id].present?
      @versions.find(params[:version_id])
    else
      @versions.first
    end

    prepare_comparison
  end

  def show
    @selected_version = @versions.find(params[:id])
    prepare_comparison
    render :index
  end

  def restore
    @version = @note.versions.find(params[:id])
    @note.restore_version!(@version)

    redirect_to note_path(@note),
                notice: "Restored note to v#{@version.version_number} (saved as v#{@note.current_version_number})."
  end

  private

  def set_note
    @note = Note.find(params[:note_id])
  end

  def load_versions
    @note.record_version_snapshot! if @note.versions.empty?
    @versions = @note.versions.ordered
  end

  def prepare_comparison
    return unless @selected_version

    @view_mode = params[:view].presence_in(%w[diff rendered raw]) || "diff"

    @previous_version = if params[:compare_id].present?
      @versions.find_by(id: params[:compare_id])
    else
      @note.versions
           .where("version_number < ?", @selected_version.version_number)
           .order(version_number: :desc)
           .first
    end

    @diff = NoteDiffer.call(
      @previous_version&.body.to_s,
      @selected_version.body,
      old_title: @previous_version&.title,
      new_title: @selected_version.title
    )
  end
end
