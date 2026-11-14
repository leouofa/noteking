module Api
  module V1
    class NoteAttachmentsController < BaseController
      before_action :set_note

      def index
        render json: {
          attachments: @note.files.map { |file| attachment_json(file) }
        }
      end

      def create
        if params[:files].blank?
          return render_error("No files provided for attachment", status: :bad_request)
        end

        @note.files.attach(params[:files])

        render json: {
          status: "ok",
          attachments: @note.files.map { |file| attachment_json(file) }
        }, status: :created
      end

      def destroy
        attachment = @note.files.find(params[:attachment_id])
        attachment.purge

        render json: {
          status: "ok",
          message: "Attachment removed successfully"
        }
      end

      private

      def set_note
        @note = Note.find(params[:id])
      end
    end
  end
end
