require 'spec_helper'
require 'ostruct'

describe JenkinsTracker::Base do

  describe '#initialize' do
    it 'does basic set up' do
      obj = described_class.new(
        :changelog_file => fixture_file_path('git_changelog.txt'),
        :tracker_token => 'xxx',
        :job_name => 'foo_job',
        :build_url => 'http://jenkins.bitium/com/foo_job/3',
        :message_str => 'heyo',
        :message_file => fixture_file_path('tracker-message.txt')
      )
      expect(obj.changelog).to eq( File.read(fixture_file_path('git_changelog.txt')) )
      expect(obj.tracker_client.token).to eq('xxx')
      expect(obj.job_name).to eq('foo_job')
      expect(obj.build_url).to eq('http://jenkins.bitium/com/foo_job/3')
      expect(obj.message_str).to eq('heyo')
      expect(obj.message_file_contents).to eq( File.read(fixture_file_path('tracker-message.txt')) )
    end

    it 'uses an SSL connection for the Tracker Client' do
      obj = described_class.new(
        :changelog_file => fixture_file_path('git_changelog.txt'),
        :tracker_token => 'xxx'
      )
      expect(obj.tracker_client.connection.to_s).to start_with('https://')
    end

    context 'when changelog file does not exist' do
      it 'raises a FileNotFoundError' do
        changelog_file = '/a/non-existent/file/path'

        expect {
          described_class.new(:changelog_file => changelog_file)
        }.to raise_error(JenkinsTracker::FileNotFoundError, "Changelog file not found at: #{changelog_file}")
      end
    end

    context 'when message file does not exist' do
      it 'raises a FileNotFoundError' do
        changelog_file = fixture_file_path('git_changelog.txt')
        message_file = '/a/non-existent/file/path'

        expect {
          described_class.new(
            :changelog_file => changelog_file,
            :message_file => message_file
          )
        }.to raise_error(JenkinsTracker::FileNotFoundError, "Message file not found at: #{message_file}")
      end
    end
  end

  describe 'with passed messages' do
    it 'formats them with ENV' do
      changelog_file = fixture_file_path('git_changelog.txt')
      change = OpenStruct.new :commit_message => 'A message', :story_id => 1234

      with_str = described_class.new(
        :changelog_file => changelog_file,
        :message_str => '%{PATH}'
      )

      with_file = described_class.new(
        :changelog_file => changelog_file,
        :message_file => fixture_file_path('tracker-message.txt')
      )

      expect(with_str.build_note(change)).to eq(ENV['PATH'])
      expect(with_file.build_note(change)).to eq("#{ENV['PATH']} #{change.commit_message}\n")
    end
  end

  describe '#parse_changelog' do
    it 'returns an array of ChangelogItems' do
      changelog_file = fixture_file_path('git_changelog.txt')

      results = described_class.new(:changelog_file => changelog_file).parse_changelog
      expect(results.size).to eq(4)

      expect(results.first.story_id).to eq(123)
      expect(results.first.commit_message).to eq('[#123 #456] added more test')

      expect(results.last.story_id).to eq(789)
      expect(results.last.commit_message).to eq('[Fixes #456 #789] added test 1 to readme')
    end

    it 'does not return duplicate ChangelogItems' do
      changelog_file = fixture_file_path('git_changelog_with_duplicates.txt')

      results = described_class.new(:changelog_file => changelog_file).parse_changelog
      expect(results.size).to eq(4)

      expect(results.first.story_id).to eq(123)
      expect(results.first.commit_message).to eq('[#123 #456] added more test')

      expect(results.last.story_id).to eq(789)
      expect(results.last.commit_message).to eq('[Fixes #456 #789] added test 1 to readme')
    end
  end

end
