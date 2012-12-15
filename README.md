# Link Alert

LinkAlert is a sinatra app that sends you a daily (or weekly, or...) e-mail
with all the new sites that have linked to you.

LinkAlert works by downloading the referring URLs from your Google Analytics
account and remembering each one. When a new referring URL shows up, you'll get
an e-mail.


## Why?

New links could be important for your business. Maybe somebody blogged about
your product, and you want to jump in and comment on their post? Maybe someone
is talking trash. Or maybe you just want to track your SEO efforts.


## Installation

LinkAlert is a sinatra app, so you'll need Ruby. It stores account details and
links in MongoDB, so you'll need one of those too.

LinkAlert connects to the Google Analytics API using oauth. In order to use
their API you need to register a project at the 
[Google API Console](https://code.google.com/apis/console/), activate access
to Analytics, and then grab an oauth client ID and client secret.

To send e-mails, LinkAlert is setup to use [Postmark](http://postmarkapp.com/).
You'll need an API key and a confirmed e-mail address to send from. You could
also edit the LinkAlert::Mailer class to use another service, or smtp.

MongoDB, Postmark, and Analytics API settings should be entered in config.yml,
or set them as environment variables. The web UI for LinkAlert is password
protected, you can set those credentials in config.yml as well.


## Usage

When you access the web UI, you'll first have to authorize the app on your
Google Analytics account. Once setup you can decide which Analytics profiles
you want to be alerted about, and which e-mail addresses to send alerts to.

Finally, you need to schedule the worker to run in order to send the alerts.
If you want daily alerts, schedule it to run every morning. You could do
weekly or monthly alerts if that's what you wanted, too. You run the
worker like so:

`ruby worker.rb`

This script will download all new links, and send e-mails to all recipients
who asked for them. If there are no new links, no e-mail will be sent.
