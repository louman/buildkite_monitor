require 'buildkit'
require 'hipchat'

class AgentsMonitor
  def monitor
    deploy_agents = 0
    default_agents = 0
    agents.each do |agent|
      queue = get_agent_queue(agent)
      next if queue.nil?
      deploy_agents += 1 if queue == 'deploy'
      default_agents += 1 if queue == 'default'
    end
    notify_hipchat('deploy') if deploy_agents == 0
    notify_hipchat('default') if default_agents == 0
  end

  private

  def notify_hipchat(queue)
    hc_client['Engineering'].send('BuildKite Monitor', "No agents available for queue #{queue}")
  end

  def agents
    bk_client.organization('jobready').rels[:agents].get.data
  end

  def bk_client
    Buildkit.new(token: ENV['BUILDKITE_TOKEN'])
  end

  def hc_client
    @hc_client ||= HipChat::Client.new( ENV['HIPCHAT_TOKEN'])
  end

  def get_agent_queue(agent)
    queue = agent['meta_data'].detect { |m| m.match /queue=/}
    return if queue.nil?
    queue.split('=').last
  end
end

AgentsMonitor.new.monitor

