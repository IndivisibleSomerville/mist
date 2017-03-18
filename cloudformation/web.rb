parameter :SlackWebhook
parameter :TLD
parameter :KeyName
parameter :AlternateTLDs, Default: ""
parameter :InstanceType, Default: 't2.micro'

include_template 'fragments/network.rb'
include_template 'fragments/dns.rb'
include_template 'fragments/cloudfront.rb'
include_template 'fragments/ec2.rb'
