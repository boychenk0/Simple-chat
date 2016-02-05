require 'streamer/sse'

class MessagesController < ApplicationController
  include ActionController::Live

  def index
    @messages = Message.all
  end

  def create
    response.headers['Content-Type'] = 'text/javascript'
    @message = params.require(:message).permit(:name, :content)
    $redis.publish('messages.create', @message.to_json)
    render nothing: true
  end

  def events
    response.headers['Content-Type'] = 'text/event-stream'
    sse = Streamer::SSE.new(response.stream)
    redis = Redis.new
    begin
      redis.subscribe('messages.create') do |on|
        on.message do |event, data|
          sse.write(data, event: 'messages.create')
        end
      end
    rescue IOError
      #Client disconnected
    ensure
      redis.quit
      sse.close
    end
    render nothing: true
  end
end
