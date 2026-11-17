class NotesController < ApplicationController
  before_action :set_note, only: %i[show edit update destroy toggle_pin attach_files purge_attachment]

  def index
    @scope = params[:scope].presence

    base_scope = if params[:q].present?
      @scope == "standalone" ? Note.standalone : Note.all
    elsif @scope == "all"
      Note.all
    else
      @scope = "standalone"
      Note.standalone
    end

    @notes = base_scope.recent
    if params[:q].present?
      @notes = @notes.search(params[:q])
    end
  end

  def show
  end

  def new
    @note = Note.new(project_id: params[:project_id])
  end

  def edit
  end

  def create
    @note = Note.new(note_params)

    if @note.save
      redirect_to @note, notice: "Note created successfully."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    auto_save = params[:auto_save].to_s == "1" || params[:auto_save].to_s == "true"
    @note.skip_versioning = auto_save

    if @note.update(note_params)
      @note.record_version_snapshot! unless auto_save

      respond_to do |format|
        format.html { redirect_to @note, notice: "Note updated successfully." }
        format.json { render json: { status: :ok, note: @note, version_number: @note.current_version_number } }
        format.turbo_stream
      end
    else
      respond_to do |format|
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: { errors: @note.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    redirect_target = @note.project ? project_path(@note.project) : root_path
    @note.destroy
    redirect_to redirect_target, notice: "Note deleted successfully."
  end

  def toggle_pin
    @note.toggle_pin!

    respond_to do |format|
      format.html { redirect_back_or_to @note }
      format.json { render json: { status: :ok, pinned: @note.pinned?, pinned_position: @note.pinned_position } }
    end
  end

  def reorder_pinned
    note_ids = params[:note_ids] || []

    Note.transaction do
      note_ids.each_with_index do |id, index|
        Note.where(id: id, pinned: true).update_all(pinned_position: index + 1)
      end
    end

    respond_to do |format|
      format.json { render json: { status: :ok } }
      format.html { redirect_back_or_to root_path }
    end
  end

  def attach_files
    if params[:files].present?
      @note.files.attach(params[:files])
    end

    respond_to do |format|
      format.html { redirect_to @note, notice: "Files attached successfully." }
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          "note_attachments",
          partial: "notes/attachments",
          locals: { note: @note }
        )
      end
      format.json { render json: { status: :ok, count: @note.files.count } }
    end
  end

  def purge_attachment
    attachment = @note.files.find(params[:attachment_id])
    attachment.purge

    respond_to do |format|
      format.html { redirect_to @note, notice: "Attachment removed." }
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          "note_attachments",
          partial: "notes/attachments",
          locals: { note: @note }
        )
      end
    end
  end

  private

  def set_note
    @note = Note.find(params[:id])
  end

  def note_params
    params.require(:note).permit(:title, :body, :project_id, files: [])
  end
end
