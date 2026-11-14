require "test_helper"

class Api::V1::StatsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @project = Project.create!(name: "Stats Project")
    Note.create!(title: "Standalone Note 1", body: "Text")
    Note.create!(title: "Standalone Note 2", body: "Text")
    Note.create!(project: @project, title: "Assigned Note", body: "Text")
    Note.create!(title: "Pinned Note", body: "Text", pinned: true, pinned_position: 1)
  end

  test "GET /api/v1/stats returns platform statistics" do
    get api_v1_stats_url, as: :json
    assert_response :success

    json = JSON.parse(response.body)
    assert_equal 4, json["total_notes"]
    assert_equal 3, json["standalone_notes"]
    assert_equal 1, json["pinned_notes"]
    assert_equal 1, json["total_projects"]
    assert_equal 0, json["total_attachments"]
  end
end
