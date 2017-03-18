resource :HostedZone, 'AWS::Route53::HostedZone' do
  name Fn::ref(:TLD)
  hosted_zone_config "Comment" => AWS::stack_name
end

ALTERNATE_TLDS = parameters[:AlternateTLDs].split(',')

ALTERNATE_TLDS.each_with_index do |tld, i|
  resource "AltHostedZone#{i}", 'AWS::Route53::HostedZone' do
    name tld
    hosted_zone_config "Comment" => AWS::stack_name
  end
end
