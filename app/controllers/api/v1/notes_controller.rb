module Api
  module V1
    class NotesController < BaseController
      before_action :set_note, only: %i[show update destroy toggle_pin]

      def index
        scope = Note.all

        if params[:project_id].present?
          scope = scope.where(project_id: params[:project_id])
        elsif params[:scope] == "standalone"
          scope = scope.standalone
        end

        if params[:pinned].present?
          scope = params[:pinned].to_s == "true" ? scope.where(pinned: true) : scope.where(pinned: false)
        end

        if params[:q].present?
          scope = scope.search(params[:q])
        end

        # Preserve pinned ordering if specifically requested or default recent
        scope = if params[:pinned].to_s == "true"
          scope.pinned
        else
          scope.recent
        end

        paginated_notes, meta = paginate_scope(scope)
        render json: {
          notes: paginated_notes.map { |n| note_json(n, include_body: true) },
          meta: meta
        }
      end

      def show
        render_md = params[:render_markdown].to_s == "true" || params[:render_markdown].to_s == "1"
        render json: note_json(@note, include_body: true, render_markdown: render_md, include_attachments: true)
      end

      def create
        note = Note.new(note_params)

        if note.save
          render json: note_json(note, include_body: true, include_attachments: true), status: :created
        else
          render_error("Validation failed", status: :unprocessable_entity, details: note.errors.full_messages)
        end
      end

      def update
        if @note.update(note_params)
          render_md = params[:render_markdown].to_s == "true" || params[:render_markdown].to_s == "1"
          render json: note_json(@note, include_body: true, render_markdown: render_md, include_attachments: true)
        else
          render_error("Validation failed", status: :unprocessable_entity, details: @note.errors.full_messages)
        end
      end

      def destroy
        @note.destroy
        render json: { status: "ok", message: "Note deleted successfully" }
      end

      def toggle_pin
        @note.toggle_pin!
        render json: {
          status: "ok",
          pinned: @note.pinned?,
          pinned_position: @note.pinned_position,
          note: note_json(@note)
        }
      end

      def reorder_pinned
        note_ids = params[:note_ids] || []

        Note.transaction do
          note_ids.each_with_index do |id, index|
            Note.where(id: id, pinned: true).update_all(pinned_position: index + 1)
          end
        end

        render json: { status: "ok", message: "Pinned notes reordered successfully" }
      end

      private

      def set_note
        @note = Note.find(params[:id])
      end

      def note_params
        payload = params[:note].is_a?(ActionController::Parameters) ? params[:note] : params
        payload.permit(:title, :body, :project_id, :pinned, :pinned_position)
      end
    end
  end
end
