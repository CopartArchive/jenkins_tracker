require 'json'

module JenkinsTracker
  class TrackerClient

    attr_reader :token, :acceptor_token, :acceptor_id, :acceptor_name

    def initialize(options = {})
      @token = options[:token]
      @acceptor_token = options[:acceptor_token]
      #unless @acceptor_id 
      if @acceptor_token
        begin
          conn = RestClient::Resource.new(api_url, :headers => { 'X-TrackerToken' => @acceptor_token, 'Content-Type' => 'application/json' })
          resp = JSON.parse(conn["/me"].get)
          @acceptor_id = resp['id']
          @acceptor_name = resp['name']
        rescue => e
          puts ["An error occurred while trying to find the acceptor id #{@acceptor_token} ", e.message, e.backtrace] * "\n"
        end
      end
    end

    def connection(options = {})
      @connection ||= RestClient::Resource.new(api_url, :headers => { 'X-TrackerToken' => token, 'Content-Type' => 'application/json' })
    end

    def add_note_to_story(project_id, story_id, note)
      begin
	puts "Adding comment to story ##{story_id}..."
        connection["projects/#{project_id}/stories/#{story_id}/comments"].post({ 'text' => note }.to_json)
      rescue => e
        # if the post fails for whatever reason (e.g. invalid story id etc), just ignore it
        puts ["An error occurred while trying to add note to Story ##{story_id} in Project ##{project_id} ", e.message, e.backtrace] * "\n"
      end
    end

    def deliver_story(project_id, story_id)
      begin
	puts "Changing ownership to #{@acceptor_name} and story status (##{story_id}) to 'Delivered'"
        connection["projects/#{project_id}/stories/#{story_id}"].put({ 'current_state' => 'delivered', 'owned_by_id' => @acceptor_id }.to_json)
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
