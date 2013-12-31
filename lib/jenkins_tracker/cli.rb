require 'thor'

module JenkinsTracker
  class Cli < Thor

    desc 'integrate', 'Integrate Jenkins build with Pivotal Tracker project stories'
    method_option 'tracker-token', :required => true, :desc => 'Pivotal Tracker API Token'
    method_option 'tracker-project-id', :required => true, :type => :numeric, :desc => 'Pivotal Tracker Project ID'
    method_option 'acceptor-token', :desc => 'If you want the story to be owned by someone else after it is delivered. Use this to specify the acceptor API token'
    method_option 'job-name', :default => ENV['JOB_NAME'], :desc => 'Jenkins job name'
    method_option 'build-url', :default => ENV['BUILD_URL'], :desc => 'Jenkins build URL'
    method_option 'changelog-file', :desc => 'Absolute path to changelog file.', :default => "#{ENV['JENKINS_HOME']}/jobs/#{ENV['JOB_NAME']}/builds/#{ENV['BUILD_NUMBER']}/changelog.xml"
    method_option 'message', :aliases => '-m', :desc => 'Message to be added to story.'
    method_option 'message-file', :aliases => '-t', :desc => 'Read message from this file.'
    def integrate
      job_name = options['job-name']
      tracker_project_id = options['tracker-project-id']
      begin
        say "Attempting to integrate #{job_name} build info with Pivotal Tracker Project ##{tracker_project_id}", :green
        JenkinsTracker::Base.new(
          :changelog_file => options['changelog-file'],
          :tracker_token  => options['tracker-token'],
          :acceptor_token => options['acceptor-token'],
          :job_name       => job_name,
          :build_url      => options['build-url'],
          :message_str    => options['message'],
          :message_file   => options['message-file']
        ).integrate_job_with_tracker(tracker_project_id)
      rescue FileNotFoundError => e
        say e.message, :red
        abort
      end
    end

    desc 'version', 'Show version information'
    def version
      say JenkinsTracker::VERSION
    end
    map ['-v', '--version'] => 'version'

  end
end
