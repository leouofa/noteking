module Api
  module V1
    class StatsController < BaseController
      def show
        render json: {
          total_notes: Note.count,
          standalone_notes: Note.standalone.count,
          pinned_notes: Note.where(pinned: true).count,
          total_projects: Project.count,
          total_attachments: ActiveStorage::Attachment.where(record_type: "Note").count
        }
      end
    end
  end
end
