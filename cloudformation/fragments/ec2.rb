EC2_AZ_ID = 0

mappings \
  "RegionMap": {
    "ap-northeast-1": {
      "64": "ami-d8acfdbf"
    },
    "ap-northeast-2": {
      "64": "ami-fc815292"
    },
    "ap-south-1": {
      "64": "ami-a5b9c9ca"
    },
    "ap-southeast-1": {
      "64": "ami-30cf7c53"
    },
    "ap-southeast-2": {
      "64": "ami-cdcdcfae"
    },
    "eu-central-1": {
      "64": "ami-6039ed0f"
    },
    "eu-west-1": {
      "64": "ami-115d7777"
    },
    "eu-west-2": {
      "64": "ami-c29184a6"
    },
    "sa-east-1": {
      "64": "ami-0c731260"
    },
    "us-east-1": {
      "64": "ami-9dde7f8b"
    },
    "us-east-2": {
      "64": "ami-c27551a7"
    },
    "us-gov-west-1": {
      "64": "ami-39d65358"
    },
    "us-west-1": {
      "64": "ami-9d772efd"
    },
    "us-west-2": {
      "64": "ami-0e2aa66e"
    }
  }

resource :InstanceRole, 'AWS::IAM::Role' do
  assume_role_policy_document CferExt::AWS::IAM::EC2_ASSUME_ROLE_POLICY_DOCUMENT
end

resource :InstanceProfile, 'AWS::IAM::InstanceProfile' do
  roles [ Fn::ref(:InstanceRole) ]
end

resource :InstanceSG, 'AWS::EC2::SecurityGroup' do
  group_description 'Security Group for Indivisible Somerville Server'
  vpc_id Fn::ref(:Vpc)
  tag :Name, AWS::stack_name

  security_group_ingress [
    { # SSH
      CidrIp: '0.0.0.0/0',
      FromPort: 22,
      ToPort: 22,
      IpProtocol: 'tcp'
    },
    { # HTTP
      CidrIp: '0.0.0.0/0',
      FromPort: 80,
      ToPort: 80,
      IpProtocol: 'tcp'
    }
  ]
end

resource :DataVolume, 'AWS::EC2::Volume' do
  availability_zone AZ[EC2_AZ_ID]
  properties Size: 100

  tag :Name, AWS::stack_name
end

resource :InstanceIP, 'AWS::EC2::EIP' do
  domain 'vpc'
end

resource :InstanceDNS, 'AWS::Route53::RecordSet' do
  hosted_zone_id Fn::ref(:HostedZone)
  name Fn::join('.', ['server', Fn::ref(:TLD)])
  type 'A'
  resource_records [ Fn::ref(:InstanceIP) ]
  properties TTL: 3600
end

resource :DataVolumeAttachment, 'AWS::EC2::VolumeAttachment' do
  device '/dev/sdf'
  instance_id Fn::ref(:Instance)
  volume_id Fn::ref(:DataVolume)
end

resource :InstanceIPAssociation, 'AWS::EC2::EIPAssociation' do
  network_interface_id Fn::ref(:InstanceNetInterface)
  allocation_id Fn::get_att(:InstanceIP, 'AllocationId')
end

resource :InstanceNetInterface, 'AWS::EC2::NetworkInterface' do
  subnet_id Fn::ref("PublicAZ#{EC2_AZ_ID}Subnet")
  group_set [ Fn::ref(:InstanceSG) ]
end

resource :Instance, 'AWS::EC2::Instance' do
  availability_zone AZ[EC2_AZ_ID]
  iam_instance_profile Fn::ref(:InstanceProfile)
  image_id Fn::find_in_map("RegionMap", AWS::region, "64")
  instance_initiated_shutdown_behavior 'stop'
  instance_type Fn::ref(:InstanceType)
  key_name Fn::ref(:KeyName)

  network_interfaces [
    {
      DeviceIndex: 0,
      NetworkInterfaceId: Fn::ref(:InstanceNetInterface),
      DeleteOnTermination: false
    }
  ]

  tag :Name, AWS::stack_name
end

