#TODO
require 'sinatra/base'

class FakeCloudConvert < Sinatra::Base

  post '/process' do
    if (params[:apikey].nil? or params[:apikey].length == 0)
      json_response 400
    else
      json_response 200, 'post_process.json'
    end
  end

  post '/process/:process_id' do
    # puts "============================"
    # puts "===3==3==3 #{params[:file]}"
    # puts "===3==3==3 #{params[:input]}"
    # puts "===3==3==3 #{params[:outputformat]}"
    # puts "==== #{params.inspect}"
    # puts "=============================="
    if params[:input] and params[:file] and params[:outputformat]
      json_response 200, 'post_conversion.json'
    else
      json_response 400
    end
  end

  delete '/process/:process_id' do
     json_response 200, 'delete_process.json'
  end

  get '/process/12345' do
    puts "------ I am in the 12345 section."
     json_response 200, 'get_conversion2.json'
  end

  get '/process/:process_id' do
     json_response 200, 'get_conversion.json'
  end

  get '/download/:process_id' do
    image_response 200, 'demo-image0.jpg'
  end

  get '/processes' do
    if (params[:apikey].nil? or params[:apikey].length == 0)
      json_response 400 
    else
      json_response 200, 'get_list.json'
    end
  end



  private

  def json_response(response_code, file_name = nil)
    content_type :json
    status response_code
    return { "code" => "400"}.to_json if file_name.nil?
    File.open(File.dirname(__FILE__) + '/fixtures/' + file_name, 'rb').read
  end

  def image_response(response_code, file_name)
    content_type 'image/jpg'
    status response_code
    File.open(File.dirname(__FILE__) + '/fixtures/' + file_name, 'rb').read
  end

end
