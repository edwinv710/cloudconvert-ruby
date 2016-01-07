# CloudConvert-Ruby

CloudConvert-Ruby is a ruby wrapper for the [Cloud Convert](https://www.google.com) api. It takes an object oriented approach to using the API, allowing you to quickly execute and access your conversions.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'cloudconvert-ruby'
```

And then execute:

    $ bundle

## Basic Example

```ruby
@client = CloudConvert::Client.new(api_key: "Your API Key")
@process = @client.build_process(input_format: "jpg", output_format: "pdf")
@process_response = @process.create
@conversion_response = @process.convert(
          input: "download",
          outputformat: "pdf",
          file: "link to image",
          download: "false"
        ) if @process_response[:success]
if @process_response[:success]
     path = File.join(File.dirname(__FILE__), "output")
     @download = @process.download(path)
end
```

## Basic Usage

The first thing we will need is to create a client. You will need to pass the api key in the initializer.

```ruby
@client = CloudConvert::Client.new(api_key: "Your API Key")
```
Once the client object is create, we can build a process for our conversion. In this example, we will convert a jpg image into a pdf.

Note: You can build as many processes as you want, just make sure that you are aware of any limitations placed on your account by Cloud Convert before you start sending processes to the API for creation.

```ruby
@process = @client.build_process(input_format: "jpg", output_format: "pdf")
```
Now that we have a process, we can send the information we provided to Cloud Convert.

```ruby
   @process_response = @process.create
```

The response returned will be a hash containing all the information provided to us by Cloud Convert. (https://cloudconvert.com/apidoc#create)

Note: All the keys for the response hash are symbolized.

To start a conversion, you can execute the `convert` method. For all the parameters supported, visit the Cloud Convert API Doc [here](https://cloudconvert.com/apidoc#start)

```ruby
@conversion_response = @process.convert(
          input: "download",
          outputformat: "pdf",
          file: "link to image",
          download: "false"
        )
```

If you want to upload a file directly to cloud convert, pass the file object to the file argument. Make sure that the file object you are passing responds to the `read` method. Examples: File, Tempfile, ActionDispatch::Http::UploadedFile, etc.

Cloud Convert does a great job of quickly converting files. For coversions that might take longer, you can use the status method to check the progress of the conversion (https://cloudconvert.com/apidoc#status).

```ruby
@status_response = @process.status
```

Once the conversion finishes, you can use the `download` method to grab the converted file. You will need to pass the directory where you want the file to be downloaded. The method will return the full path where the file was downloaded. If the file has yet to be converter, it will return the current status of the conversion as a hash.

Note: If you indicated that you want your files to be uploaded directly to another service, like S3, the file will start uploading once the conversion is finished. There is no need to download the file (https://cloudconvert.com/apidoc#download).

```ruby
   path = File.join(File.dirname(__FILE__), "output")
   @download = @process.download(path)
```

If you would like to handle the download process, you can use the download_url method to grab the url of the file.

```ruby
   @download_url = @process.download_url
```

There will be times when you might want to cancel a conversion. To cancel a conversion, use the `delete` method (https://cloudconvert.com/apidoc#delete).

```ruby
   @delete_response = @process.delete
```

## Diving Deeper

### Accessing API responses throughout the life-cycle of a process

Each time a request is made to Cloud Convert, a copy of the response is saved to the process object. You can access them by using the following attributes.

```ruby
   @process.process_response     # Response returned by @process.create
   @process.conversion_response  # Response returned by @process.convert
   @process.status_response      # * Response returned by @process.status and @process.download
```
* If you try to download before the conversion is completed, the response will be the current status of the conversion. This response wil update the `status_response` attribute.

### Converting objects that outputs multiple files

If a conversion produces multiple files, like converting pdf to html when the css files are not embedded, you will obtain a zip file from the `download` method. If you want to download an individual files, pass the name of the individual file when executing the `download` method.

```ruby
   @css_path = @process.download("base.min.css")

```

### Keeping track of the current step

Every `Process` object keeps the state of the conversion in the step attribute. All the steps are documented in the Cloud Convert API (https://cloudconvert.com/apidoc#status). Keep in mind that there are two steps that are unique to this gem.

   :awaiting_creattion - Initial state of the process
   :awaiting_convertion - The state after the executing the create method

Also note, the step attribute is not up unless you communicate to the api. If you want the most up-to date step, call the `status` method before you call `step`.

### Changing the return type of response from Hash to Net::HTTPResponse

You can change the return type of responses by changing the `return_type` of the client.

```ruby
   @client.return_type = :response
   @process.status     # Will return a Net::HTTPResponse
   @client.return_type = :hash
   @process.status     # Will return a hash

```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/edwinv710/cloudconvert-ruby. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
