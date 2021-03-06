require 'spec_helper'

describe Travis::Services::FindBuilds do
  include Support::ActiveRecord

  let(:repo)    { Factory(:repository, owner_name: 'travis-ci', name: 'travis-core') }
  let!(:push)   { Factory(:build, repository: repo, event_type: 'push', state: :failed, number: 1) }
  let(:service) { described_class.new(stub('user'), params) }

  attr_reader :params

  describe 'run' do
    it 'finds recent builds when empty params given' do
      @params = { :repository_id => repo.id }
      service.run.should == [push]
    end

    it 'finds running builds when running param is passed' do
      running = Factory(:build, repository: repo, event_type: 'push', state: 'started', number: 2)
      @params = { :running => true }
      service.run.should == [running]
    end

    it 'finds recent builds when no repo given' do
      @params = nil
      service.run.should == [push]
    end

    it 'finds builds older than the given number' do
      @params = { :repository_id => repo.id, :after_number => 2 }
      service.run.should == [push]
    end

    it 'finds builds with a given number, scoped by repository' do
      @params = { :repository_id => repo.id, :number => 1 }
      Factory(:build, :repository => Factory(:repository), :state => :finished, :number => 1)
      Factory(:build, :repository => repo, :state => :finished, :number => 2)
      service.run.should == [push]
    end

    it 'does not find by number if repository_id is missing' do
      @params = { :number => 1 }
      service.run.should == Build.none
    end

    it 'scopes to the given repository_id' do
      @params = { :repository_id => repo.id }
      Factory(:build, :repository => Factory(:repository), :state => :finished)
      service.run.should == [push]
    end

    it 'returns an empty build scope when the repository could not be found' do
      @params = { :repository_id => repo.id + 1 }
      service.run.should == Build.none
    end

    it 'finds builds by a given list of ids' do
      @params = { :ids => [push.id] }
      service.run.should == [push]
    end

    describe 'finds recent builds when event_type' do
      let!(:pull_request) { Factory(:build, repository: repo, state: :finished, number: 2, request: Factory(:request, :event_type => 'pull_request')) }
      let!(:api)          { Factory(:build, repository: repo, state: :finished, number: 2, request: Factory(:request, :event_type => 'api')) }

      it 'given as push' do
        @params = { repository_id: repo.id, event_type: 'push' }
        service.run.should == [push]
      end

      it 'given as pull_request' do
        @params = { repository_id: repo.id, event_type: 'pull_request' }
        service.run.should == [pull_request]
      end

      it 'given as api' do
        @params = { repository_id: repo.id, event_type: 'api' }
        service.run.should == [api]
      end

      it 'given as [push, api]' do
        @params = { repository_id: repo.id, event_type: ['push', 'api'] }
        service.run.sort.should == [push, api]
      end
    end
  end
end
