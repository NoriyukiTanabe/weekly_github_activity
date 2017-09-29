require 'active_support/core_ext/date/calculations'
require 'io/console'

class Report
  def initialize(user = ENV['GITHUB_USER'], password = ENV['GITHUB_PASSWORD'], slack_api = ENV['SLACK_API'])
    @user = user || user_prompt
    @password = password || password_prompt
    @slack_api = slack_api

    Octokit.configure do |c|
      c.login = @user
      c.password = @password
    end
  end

  def user_prompt
    print "user: " 
    STDIN.gets.chomp
  end

  def password_prompt
    print "password: "
    password = STDIN.noecho(&:gets).chomp
    puts
    password
  end

  def load!
    issues = {}
    pulls = {}

    Octokit.user_events(@user, per_page: 300).each do |e|
      time = e.created_at.getlocal.to_date

      if time < Date.current.beginning_of_week
        puts "#{time} < #{Date.current.beginning_of_week}"
        break
      end

      case e.type
      when "IssuesEvent"
        issues[e.payload.issue.number] = {title: e.payload.issue.title, date: time}
      when "IssueCommentEvent"
        issues[e.payload.issue.number] = {title: e.payload.issue.title, date: time}
      when "PullRequestEvent"
        pulls[e.payload.pull_request.number] = {title: e.payload.pull_request.title, date: time}
      else
        puts "Unknown Event #{e.type}"
      end
    end

    @issues = issues
    @pulls = pulls
  rescue Octokit::Unauthorized
    puts "ユーザー名またはパスワードが間違っています"
    exit
  end

  def message
    @message ||=
      begin
        load!

        message = ""
        message << "仕様・設計・調査\n"
        @issues.sort_by {|_,x| x[:date] }.each do |id, issue|
          message << "#{issue[:date]} #{id} #{issue[:title]}\n"
        end
        message << "\n"
        message << "開発\n"
        @pulls.sort_by {|_,x| x[:date] }.each do |id, pull|
          message << "#{pull[:date]} #{id} #{pull[:title]}\n"
        end

        message
      end
  end

  def send_message
    if @slack_api
      notifier = Slack::Notifier.new @slack_api, http_options: {open_timeout: 2}
      notifier.ping message
    else
      puts message
    end
  end

  def self.send_message
    new.send_message
  end
end
