module JenkinsTracker
  class TrackerClient

    attr_reader :token

    def initialize(options = {})
      @token = options[:token]
    end

    def connection(options = {})
      @connection ||= RestClient::Resource.new(api_url, :headers => { 'X-TrackerToken' => token, 'Content-Type' => 'application/json' })
    end

    def add_note_to_story(project_id, story_id, note)
      begin
        connection["projects/#{project_id}/stories/#{story_id}/comments"].post({ 'text' => note }.to_json)
      rescue => e
        # if the post fails for whatever reason (e.g. invalid story id etc), just ignore it
        puts ["An error occurred while trying to add note to Story ##{story_id} in Project ##{project_id} ", e.message, e.backtrace] * "\n"
      end
    end

    def deliver_story(project_id, story_id)
      begin
        connection["projects/#{project_id}/stories/#{story_id}"].put({ 'current_state' => 'delivered' }.to_json)
      rescue => e
        # if the post fails for whatever reason (e.g. invalid story id etc), just ignore it
        puts ["An error occurred while trying to deliver Story ##{story_id} in Project ##{project_id} ", e.message, e.backtrace] * "\n"
      end
    end

    private

    def api_url
      "https://www.pivotaltracker.com/services/v5"
    end

  end
end
