resource :SNS, 'AWS::SNS::Topic' do
  display_name 'slack'
  subscription [
    {
      Endpoint: Fn::ref(:SlackWebhook),
      Protocol: 'https'
    }
  ]
end
