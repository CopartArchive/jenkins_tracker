require 'spec_helper'

describe JenkinsTracker::TrackerClient do

  describe '#connection' do
    it 'returns an instance of RestClient::Resource' do
      tracker_client = described_class.new(:token => 'xxx')
      expect(tracker_client.connection).to be_an_instance_of(RestClient::Resource)
      expect(tracker_client.connection.to_s).to eq('https://www.pivotaltracker.com/services/v5')
    end

    #it 'does not use an SSL connection by default' do
      #tracker_client = described_class.new(:token => 'xxx')
      #expect(tracker_client.connection.to_s).to eq('http://www.pivotaltracker.com/services/v5')
    #end

    it 'does use an SSL connection by default' do
      tracker_client = described_class.new(:token => 'xxx')
      expect(tracker_client.connection.to_s).to eq('https://www.pivotaltracker.com/services/v5')
    end
  end

end
