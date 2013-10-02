require 'yaml'
require 'bundler'

Bundler.require

config = YAML.load_file('config.yaml')

def my_truncate(str, len)
  if len - 1 > str.length
    str
  else
    "#{str[0..len]}..."
  end
end

#bitbucket = BitBucket.new do |bconfig|
#  bconfig.client_id       = config["bitbucket"]["consumer_key"]
#  bconfig.client_secret   = config["bitbucket"]["consumer_secret"]
#  bconfig.adapter         = :net_http
#end

last_notify_time = Time.now - 15 * 60 + 30
bitbucket = BitBucket.new login:config["bitbucket"]["userid"],
  password: config["bitbucket"]["passwd"]

hipchat = HipChat::Client.new config["hipchat"]["api_key"]
username = config["bitbucket"]["userid"]

repos = bitbucket.repos.list

repos.each do |repo|
  reponame = repo.name

  begin
    issues = bitbucket.issues.list_repo(username, reponame)

    issues.select { |item| 
      Time.parse(item.utc_created_on) > last_notify_time
    }.reverse_each do |item|

      html = <<-EOF
    new issue: 
    <b><a href='https://bitbucket.org/#{username}/#{reponame}/issue/#{item.local_id}'>#{item.title}</a></b> 
    to: <b>#{item.responsible.display_name}</b>
    at: <a href='https://bitbucket.org/#{username}/#{reponame}'>#{username}/#{reponame}</a>
    <br>
    at: #{Time.parse(item.utc_created_on).localtime}
    EOF

      hipchat[config["hipchat"]["room"]].send('BitbucketIssue', html, notify: true, color: 'green')
    end

    issues.select { |item| 
      Time.parse(item.utc_last_updated) > last_notify_time
    }.reverse_each do |issue|
      bitbucket.issues.comments.list(username, reponame, issue.local_id).select { |item| 
        Time.parse(item.utc_created_on) > last_notify_time
      }.reverse_each do |comment|
        html = <<-EOF
    new comment: 
    (<b><a href='https://bitbucket.org/#{username}/#{reponame}/issue/#{issue.local_id}'>#{issue.title}</a></b>) 
    from <b>#{comment.author_info.display_name}</b>
    <br>
    content: #{my_truncate(comment.content, 50)}
    <br>
    at: #{Time.parse(comment.utc_created_on).localtime}
    EOF

        hipchat[config["hipchat"]["room"]].send('BitbucketIssue', html, notify: true, color: 'green')
      end
    end
  rescue => ex
    p ex.message
  end
end



