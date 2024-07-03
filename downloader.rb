require 'dropbox-sign'
require 'dotenv'

Dotenv.load

class Downloader

  Dropbox::Sign.configure do |config|
    # Configure HTTP basic authorization: api_key
    config.username = ENV["DROPBOX_SIGN_API_KEY"]
  end

  def initialize
    @api = Dropbox::Sign::SignatureRequestApi.new
  end

  def signature_requests
    page = 1
    page_size = 20
    continue = true
    signature_requests = []

    while continue
      puts "Fetching page #{page} (#{page_size} per page)"
      sr = @api.signature_request_list(page_size: page_size, page: page)

      if sr.signature_requests.size > 0
        signature_requests += sr.signature_requests
        page += 1
        sleep(2.5) # API restricted to 25 requests per minute
      else
        continue = false
      end
    end

    signature_requests
  end

  def download_signature_request(signature_request)

    if signature_request.signature_request_id
      file = @api.signature_request_files(signature_request.signature_request_id)
      fname = signature_request.title.gsub(/^.*(\\|\/)/, '').gsub(/[^0-9A-Za-z.\-]/, '_')
      FileUtils.cp(file.path, "./downloads/#{signature_request.signature_request_id} - #{fname}.pdf")
    else
      puts "Error - no signature request id, skipping... \n#{signature_request}\n"
    end
  end

end


downloader = Downloader.new
signature_requests = downloader.signature_requests

puts "\nFound #{signature_requests.size} requests\n"

signature_requests.each_with_index do |sr, i|
  puts "Downloading file #{i+1}: #{sr.title}"
  downloader.download_signature_request(sr)
  sleep(2.5) # API restricted to 25 requests per minute
end
