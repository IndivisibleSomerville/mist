#resource :DomainCert, 'AWS::CertificateManager::Certificate' do
#  domain_name Fn::ref(:TLD)
#  subject_alternative_names [
#    Fn::join('.', ['*', Fn::ref(:TLD)])
#  ]
#end

resource :CloudFront, 'AWS::CloudFront::Distribution' do
  distribution_config do
    default_cache_behavior \
      ForwardedValues: { QueryString: true },
      ViewerProtocolPolicy: 'redirect-to-https',
      MinTTL: 0,
      DefaultTTL: 0,
      MaxTTL: 0,
      TargetOriginId: 'indivisiblesomerville'

    enabled true
    price_class 'PriceClass_100'

    origins [
      {
        CustomOriginConfig: {
          OriginProtocolPolicy: 'http-only'
        },
        DomainName: Fn::join('.', ['server', Fn::ref(:TLD)]),
        Id: 'indivisiblesomerville'
      }
    ]
  end
end


CLOUDFRONT_ALIAS_TARGET = {
  DNSName: Fn::get_att(:CloudFront, 'DomainName'),
  HostedZoneId: 'Z2FDTNDATAQYW2'
}

resource :CloudFrontMainDNS, 'AWS::Route53::RecordSetGroup' do
  hosted_zone_id Fn::ref(:HostedZone)
  record_sets [
    {
      Name: Fn::join('.', ['www', Fn::ref(:TLD)]),
      Type: 'A',
      AliasTarget: CLOUDFRONT_ALIAS_TARGET
    },
    {
      Name: Fn::ref(:TLD),
      Type: 'A',
      AliasTarget: CLOUDFRONT_ALIAS_TARGET
    }
  ]
end

ALTERNATE_TLDS.each_with_index do |tld, i|
  resource "CloudFrontAlternateDNS#{i}", 'AWS::Route53::RecordSetGroup' do
    hosted_zone_id Fn::ref("AltHostedZone#{i}")
    record_sets [
      {
        Name: Fn::join('.', ['www', Fn::ref(:TLD)]),
        Type: 'A',
        AliasTarget: CLOUDFRONT_ALIAS_TARGET
      },
      {
        Name: tld,
        Type: 'A',
        AliasTarget: CLOUDFRONT_ALIAS_TARGET
      }
    ]
  end
end
