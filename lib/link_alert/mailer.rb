require 'date'
require 'postmark'
require 'mail'
require 'erb'


module LinkAlert

  class Mailer

    # Initialize the mailer.
    # 
    # api_key - String Postmark API key.
    # from_email - String Postmark verified send from email address.
    # profiles - Hash of Analytics profiles, { profile_id: profile_name }
    # 
    # Returns the mailer instance.
    def initialize(api_key, from_email, profiles)
      @api_key = api_key
      @from_email = from_email
      @profiles = profiles
    end

    # Build the link alert message.
    # 
    # link_data - Hash { profile_id: [link_url, link_url, ...]}
    # 
    # Builds the HTML email message but does not set the recipient address,
    # and does not send it. To send it, call the #deliver_to method.
    # 
    # Returns the message body in HTML.
    def build_message(link_data)
      @message = Mail.new
      @message.delivery_method(Mail::Postmark, :api_key => @api_key)
      @message.from = @from_email
      @message.subject = "Link Report For #{Date.today}"
      @message.content_type = 'text/html'

      html = ''
      template = ERB.new(File.read('email_template.html.erb'), 0, '', 'html')
      template.run(binding)
      @message.body = html
    end

    # Deliver an email alert.
    # 
    # to_email - String email address.
    # 
    # Delivers the message built from #build_message.
    # 
    # Returns the status of the email delivery.
    def deliver_to(to_email)
      if @message
        @message.to = to_email
        @message.deliver
      end
    end
  end
end
