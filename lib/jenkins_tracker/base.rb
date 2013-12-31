module JenkinsTracker
  class Base
    #include Util

    attr_reader :changelog, :tracker_client, :job_name, :build_url,
      :message_str, :message_file

    def initialize(options = {})
      raise FileNotFoundError, "Changelog file not found at: #{options[:changelog_file]}" unless File.file?(options[:changelog_file])

      if options[:message_file] && !File.file?(options[:message_file])
        msg = "Message file not found at: #{options[:message_file]}"
        raise FileNotFoundError, msg
      end

      @message_file = options[:message_file]
      @message_str = options[:message_str]

      @changelog = File.read(options[:changelog_file])
      @tracker_client = TrackerClient.new(:token => options[:tracker_token], :acceptor_token => options[:acceptor_token])
      @job_name = options[:job_name]
      @build_url = options[:build_url]
    end

    def integrate_job_with_tracker(project_id)
      parse_changelog.each do |change|
        note = build_note(change)

        tracker_client.add_note_to_story(project_id, change.story_id, note)
        tracker_client.deliver_story(project_id, change.story_id)
      end
    end

    def note_variables(change)
      @_note_variables ||= begin
        # ENV keys are strings but formatting needs symbols
        variables = ENV.inject({}){ |memo, (k, v)| memo[k.to_sym] = v; memo }
        variables[:COMMIT_MESSAGE] = change.commit_message
        variables[:STORY_ID] = change.story_id
        variables
      end
    end

    def build_note(change)
      variables = note_variables(change)

      if message_str
        return message_str % variables
      end

      if message_file
        return message_file_contents % variables
      end

      "*#{change.commit_message}* delivered in *#{job_name}* (#{build_url})"
    end

    def parse_changelog
      results = []

      changelog.scan(/(\[[#a-zA-Z0-9\s]+\])(.*)/) do |ids, msg|
        parse_tracker_story_ids(ids).each do |id|
          results << ChangelogItem.new(:story_id => id, :commit_message => "#{ids}#{msg}".strip)
        end
      end

      results.uniq
    end

    def message_file_contents
      File.read(@message_file)
    end


    private

    def parse_tracker_story_ids(str)
      str.strip.gsub(/[\[#\]]/, '').split(' ').map(&:to_i).reject { |i| i == 0 }
    end

  end
end
